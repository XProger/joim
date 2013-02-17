unit jnet;

interface

{$R-}

uses
  jsys, jutils;

const
  NET_BUF_SIZE  = 4096;

type
  TProxyFamily = (pfNone, pfUnknown, pfHTTP, pfSOCKS4);

  TNetStatus = (nsConnect, nsDisconnect, nsReceive, nsError, nsErrorProxy);

  TNet = class;

  TOnNetStatus = procedure (Net: TNet; NetStatus: TNetStatus);
  TOnNetEvent  = procedure (Net: TNet);

  TNet = class(TStream)
    constructor Create;
    destructor Destroy; override;
  private
    Sock   : TNetSocket;
    Thread : TThread;
    FConnected : Boolean;
    Buffer  : array [0..NET_BUF_SIZE - 1] of Byte;
    CS : TCriticalSection;
    function ProxyConnect: Boolean;
    function DetectProxy: Boolean;
  public
    Host : AnsiString;
    Port : Word;
    Data      : Pointer;
    OnStatus  : TOnNetStatus;
    function Read(out DData; DSize: LongInt): LongInt; override;
    function Write(const DData; DSize: LongInt): LongInt; override;
    procedure Connect(Block: Boolean = False);
    procedure Disconnect;
    property Connected: Boolean read FConnected;
  end;

var
  Proxy : record
      Family : TProxyFamily;
      Host   : AnsiString;
      Port   : Word;
      Pass   : AnsiString;
    end;

  procedure NetFakeStatus(Net: TNet; NetStatus: TNetStatus);

implementation

uses
  jglobal;

procedure NetThread(Net: TNet);
var
  Count : LongInt;
label
  lError, lErrorProxy, lErrorDisconnect;

  procedure LastStatus(Status: TNetStatus);
  begin
    try
      Net.Thread.Free;
      Net.OnStatus(Net, Status);
    except
      {$IFDEF DEBUG}Writeln('error: NetThread LastStatus ', Ord(Status));{$ENDIF}
    end;
  end;

begin
  with Net do
  begin
    if Proxy.Family = pfNone then
    begin
      if not Sock.Init(Host, Port) then
        goto lError;
    end else
      if not Sock.Init(Proxy.Host, Proxy.Port) then
        goto lErrorProxy;
    if Sock.Connect then
    begin
      FConnected := True;
      if Proxy.Family = pfNone then
        OnStatus(Net, nsConnect)
      else
        if (not DetectProxy) or (not ProxyConnect) then
          goto lErrorProxy;
    end else
      if Proxy.Family = pfNone then
        goto lError
      else
        goto lErrorProxy;
    while Connected do
    begin
      Count := Sock.Recv(Buffer, SizeOf(Buffer));
      if Count > 0 then
      begin
        FPosition := 0;
        FSize     := Count;
      {$IFDEF DEBUG}
        Writeln('r: ', Count);
      {$ENDIF}
        OnStatus(Net, nsReceive);
      end else
        if Count <= 0 then
          break;
    end;
    LastStatus(nsDisconnect);
    Exit;
  lError :
    LastStatus(nsError);
    Exit;
  lErrorProxy :
    LastStatus(nsErrorProxy);
    Exit;
  end;
end;

{ TNet }
procedure NetFakeStatus(Net: TNet; NetStatus: TNetStatus);
begin
  //
end;

constructor TNet.Create;
begin
  CS.Init;
  OnStatus := @NetFakeStatus;
end;

destructor TNet.Destroy;
begin
  Disconnect;
  Thread.FreeWait;
  CS.Free;
  inherited;
end;

function TNet.DetectProxy: Boolean;
var
  ProxySock : TNetSocket;
  Hello : AnsiString;
  Count : LongInt;
  Buf   : array [0..3] of AnsiChar;
begin
  Result := False;
  if Proxy.Family = pfUnknown then
  begin
    if not ProxySock.Init(Proxy.Host, Proxy.Port) then
      Exit;
    if ProxySock.Connect then
    begin
      Hello := 'GET / HTTP/1.x'#13#10#13#10;
      ProxySock.Send(Hello[1], Length(Hello));
      Buf := '    ';
      Count := ProxySock.Recv(Buf[0], 4);
      while (Count < 4) and (Count > 0) do
        Count := Count + ProxySock.Recv(Buf[Count], 4 - Count);
      if Buf = 'HTTP' then
        Proxy.Family := pfHTTP
      else
        Proxy.Family := pfSOCKS4;
      Result := True;
    end;
    ProxySock.Free;
  end else
    Result := True;
end;

function TNet.ProxyConnect: Boolean;
var
  Count : LongInt;
  Msg   : AnsiString;
  Hello : AnsiString;
  IP : LongInt;
begin
  Result := False;
  Hello := '';
  case Proxy.Family of
    pfHTTP   :
      Hello := 'CONNECT ' + Host + ':' + AnsiString(Conv(LongWord(Port))) + ' HTTP/1.x'#13#10#13#10;
    pfSOCKS4 :
      begin
        IP := Sock.HostByName(Host);
        if IP = 0 then
        begin
          OnStatus(Self, nsErrorProxy);
          Disconnect;
          Exit;
        end;
        SetLength(Hello, 9);
        PWordArray(@Hello[1])^[0] := $0104;
        PWordArray(@Hello[1])^[1] := Sock.ConvPort(Port);
        PLongArray(@Hello[1])^[1] := IP;
        PByteArray(@Hello[1])^[9] := 0;
      end;
  end;
  Write(Hello[1], Length(Hello));

  Msg := '';
  while Connected do
  begin
    Count := Sock.Recv(Buffer, SizeOf(Buffer));
    if Count > 0 then
    begin
      case Proxy.Family of
        pfHTTP :
          begin
            Msg := Msg + Copy(PAnsiChar(@Buffer), 1, Count);
            if Pos(AnsiString(#13#10#13#10), Msg) > 0 then
            begin
            {$IFDEF DEBUG}
              Writeln(Msg);
            {$ENDIF}
              case Conv(WideString(Copy(Msg, 10, 3)), 0) of
                200 :
                  begin
                    OnStatus(Self, nsConnect);
                    Result := True;
                    break;
                  end;
              //  407 : ; // Proxy-authorization...
              else
                Disconnect;
              end;
            end;
          end;
        pfSOCKS4 :
          case Buffer[1] of
            $5A :
              begin
                OnStatus(Self, nsConnect);
                Result := True;
                break
              end
          else
          {$IFDEF DEBUG}
            Writeln('error');
          {$ENDIF}
            Disconnect;
          end;
      end;
    end else
      Disconnect;
  end;
end;

procedure TNet.Connect(Block: Boolean);
begin
  if Block then
    NetThread(Self)
  else
    Thread.Init(TThreadProc(@NetThread), Pointer(Self));
end;

procedure TNet.Disconnect;
begin
  if FConnected then
  begin
    OnStatus(Self, nsDisconnect);
    FConnected := False;
    Sock.Free;
  end;
end;

function TNet.Read(out DData; DSize: LongInt): LongInt;
begin
  if DSize > Size - FPosition then
    Result := Size - FPosition
  else
    Result := DSize;
  Move(Buffer[FPosition], DData, Result);
  Inc(FPosition, Result);
end;

function TNet.Write(const DData; DSize: LongInt): LongInt;
var
  i : LongInt;
begin
  if Connected then
  begin
    CS.Lock;
    Result := 0;
    i := 0;
    while (Result < DSize) and (i <> -1) do
    begin
      i := Sock.Send(PByteArray(@DData)[Result], DSize - Result);
      Inc(Result, i);
    end;
    if i = -1 then
      Disconnect;
    CS.Unlock;
  {$IFDEF DEBUG}
    Writeln('s: ', Result);
  {$ENDIF}
  end else
    Result := 0;
end;

end.
