unit jhttp;

interface

uses
  jsys, jutils, jzip, jnet;

const
  HTTP_CRLF : AnsiString = #13#10;
  HTTP_SEP  : AnsiString = #13#10#13#10;

type
// Query
  TQuery = class;
  TQueryProc = procedure (ID: Integer; const Header: AnsiString; const Content: WideString; Data, RawData: Pointer; RawSize: LongInt);

  TQuery = class
    ID      : LongInt;     // query callback id
    Proc    : TQueryProc;  // callback proc
    Data    : Pointer;     // some query data pointer
    Host    : AnsiString;  // http host
    URL     : AnsiString;
    Req     : AnsiString;  // http request
    Header  : AnsiString;  // http response header
    Chunks  : array of UTF8String;  // http chunked transfer data
    RawData : PByteArray;  // raw data
    RawSize : LongInt;     // raw size
    Count   : LongInt;     // transfer data count
    Chunked   : Boolean;   // chunked transfer
    KeepAlive : Boolean;   // keep-alive connection
    SSL       : Boolean;   // use HTTPS
  end;

  TQueryMethod = (qmHEAD, qmGET, qmPOST, qmCONNECT);

// Session
  THTTPSession = class
    constructor Create(const Host: AnsiString; KeepAlive: Boolean);
    destructor Destroy; override;
  public
    CS       : TCriticalSection;
    Net      : TNet;
    Query    : array of TQuery;
    Response : AnsiString;
    Closed    : Boolean;
    KeepAlive : Boolean;
    procedure Start;
    procedure QueryAdd(q: TQuery);
    procedure QueryNext;
    procedure QueryWrite(q: TQuery);
    function QueryCheck: Boolean;
  end;

// HTTP manager
  TValueArray = array of AnsiString;

  THTTP = class
    constructor Create;
    destructor Destroy; override;
  public
    Queue   : TQueue;
    CS      : TCriticalSection;
    Cookie  : AnsiString;
    Session : array of THTTPSession;
    function SessionAdd(const Host: AnsiString; KeepAlive: Boolean): THTTPSession;
    procedure SessionDel(s: THTTPSession);
    procedure Query(Method: TQueryMethod; const Host, URL, Cookie, Content: AnsiString; ID: LongInt; Proc: TQueryProc; Data: Pointer = nil; KeepAlive: Boolean = True; SSL: Boolean = False);
    procedure QueryImage(const URL: WideString; ID: Integer; Proc: TQueryProc);
    class function GetHeader(const Text: AnsiString): AnsiString;
    class function GetContent(const Text: AnsiString): AnsiString;
    class function GetValue(const Text, Param: AnsiString; out Value: TValueArray): Boolean;
    class function GetCookie(const HTTP: AnsiString; out Value: TValueArray): Boolean;
    class function Decompress(const Text: UTF8String): UTF8String;
  end;

implementation

uses
  jglobal;

{$REGION 'WinInet'}
function WinInetRequest(const Host, URL: AnsiString; blnSSL: Boolean = True): AnsiString;
var
  i : Integer;
  Buffer      : array [0..1023] of AnsiChar;
  Header      : AnsiString;
  BytesRead   : LongWord;
  pSession    : Pointer;
  pConnection : Pointer;
  pRequest    : Pointer;
  port        : Integer;
  flags       : LongWord;
begin
  Result := '';

  pSession := InternetOpenA(nil, 0, nil, nil, 0);

  if pSession = nil then Exit;

  if blnSSL then
    Port := 443
  else
    Port := 80;
  pConnection := InternetConnectA(pSession, PAnsiChar(Host), port, nil, nil, 3 {INTERNET_SERVICE_HTTP}, 0, 0);

  if pConnection = nil then Exit;

  if blnSSL then
    flags := $00800000 or $00400000 {INTERNET_FLAG_SECURE or INTERNET_FLAG_KEEP_CONNECTION}
  else
    flags := 3 {INTERNET_SERVICE_HTTP};

  pRequest := HTTPOpenRequestA(pConnection, 'GET', PAnsiChar(URL), nil, nil, nil, flags, 0);

  if pRequest = nil then Exit;

  Header := 'Host: ' + Host + HTTP_CRLF + HTTP_CRLF;
  HttpAddRequestHeadersA(pRequest, PAnsiChar(Header), Length(Header), $20000000{HTTP_ADDREQ_FLAG_ADD});

  if HTTPSendRequestA(pRequest, nil, 0, nil, 0) then
    while InternetReadFile(pRequest, @Buffer, SizeOf(Buffer), BytesRead) do
    begin
      if (BytesRead = 0) then break;
      i := Length(Result);
      SetLength(Result, i + LongInt(BytesRead));
      Move(Buffer, Result[i + 1], BytesRead);
    end;

  InternetCloseHandle(pRequest);
  InternetCloseHandle(pConnection);
  InternetCloseHandle(pSession);
end;
{$ENDREGION}

{$REGION 'THTTPSession'}
procedure ProcHTTP(Net: TNet; Status: TNetStatus);
var
  SBuf   : array [1..1024] of AnsiChar;
  i      : LongInt;
  Readed : LongInt;
begin
  with THTTPSession(Net.Data) do
  begin
    case Status of
      nsConnect :
        begin
          {$IFDEF DEBUG}Writeln('http: connect ', Net.Host);{$ENDIF}
          CS.Lock;
          for i := 0 to Length(Query) - 1 do
            QueryWrite(Query[i]);
          CS.Unlock;
        end;
      nsReceive :
        begin
          CS.Lock;
          if Length(Query) > 0 then
            with Query[0] do
            begin
            // collect response buffer
              Readed := Net.Read(SBuf[1], SizeOf(SBuf));
              while Readed > 0 do
              begin
                i := Length(Response);
                SetLength(Response, i + Readed);
                Move(SBuf[1], Response[i + 1], Readed);
                Readed := Net.Read(SBuf[1], SizeOf(SBuf));
              end;
            // get query response
              while QueryCheck do
                QueryNext;
            end;
          CS.Unlock;
        end;
      nsDisconnect, nsError, nsErrorProxy :
        begin
          {$IFDEF DEBUG}Writeln('http: disconnect ', Net.Host);{$ENDIF}
          CS.Lock;
          Net.Host := '';
        // server close connection
          if Closed and (Length(Query) > 0) then
          begin
            Query[0].Count := Length(Response);
            while QueryCheck do
              QueryNext;
          end;
          {$IFDEF DEBUG}if Length(Query) > 0 then Writeln('http: lost ', Length(Query));{$ENDIF}
        // no responded queries
          for i := 0 to Length(Query) - 1 do  // for all query with content = ''
            with Query[i] do
              if @Proc <> nil then
                Proc(ID, '', '', Data, nil, 0);
          CS.Unlock;
          Free; // free http session
        end;
    end;
  end;
end;

constructor THTTPSession.Create(const Host: AnsiString; KeepAlive: Boolean);
begin
  Self.KeepAlive := KeepAlive;
  CS.Init;
  Net := TNet.Create;
  Net.Host := Host;
  Net.Port := 80;
  Net.Data := Self;
  Net.OnStatus := @ProcHTTP;
end;

destructor THTTPSession.Destroy;
var
  i : LongInt;
begin
  Net.OnStatus := NetFakeStatus;
  HTTP.SessionDel(Self);
  for i := 0 to Length(Query) - 1 do
    Query[i].Free;
  Net.Free;
  CS.Free;
  inherited;
end;

procedure THTTPSession.Start;
begin
  if not Net.Connected then
    Net.Connect(True);
end;

procedure THTTPSession.QueryAdd(q: TQuery);
begin
  CS.Lock;
  SetLength(Query, Length(Query) + 1);
  Query[Length(Query) - 1] := q;
  if Net.Connected then
    QueryWrite(q);
  CS.Unlock;
end;

procedure THTTPSession.QueryNext;
var
  i : LongInt;
begin
  Query[0].Free;
  for i := 0 to Length(Query) - 2 do
    Query[i] := Query[i + 1];
  SetLength(Query, Length(Query) - 1);
  if (Length(Query) = 0) and (not KeepAlive) then
    Net.Disconnect;
end;

procedure THTTPSession.QueryWrite(q: TQuery);
var
  Content : WideString;
begin
  with q do
  if q.SSL then
    begin
      Content := WideString(WinInetRequest(Host, URL, SSL));
      Count   := Length(Response);
      Chunked := False;
      Chunks  := nil;
      Header  := 'Content-Type: text';
      if @Proc <> nil then
        Proc(ID, Header, Content, nil, nil, 0);
      Proc := nil;
    end else
      Net.Write(Req[1], Length(Req));
end;

function THTTPSession.QueryCheck: Boolean;
var
  i, j : LongInt;
  Value : TValueArray;
  RData : UTF8String;
  Content : WideString;
  Compress : Boolean;
label  
  ext;
begin
  Result := False;
  if Length(Query) = 0 then
    Exit;

  with Query[0] do
  begin
    if Copy(Req, 1, 4) = 'HEAD' then
    begin
    {$IFDEF DEBUG}Writeln('http: skip HEAD');{$ENDIF}
      Result := True;
      Exit;
    end;
  // header
    if Header = '' then
    begin
      Header := THTTP.GetHeader(Response);
      if Header <> '' then
      begin
        Delete(Response, 1, Length(Header) + 4);
        Chunked := THTTP.GetValue(Header, 'Transfer-Encoding', Value) and (Value[0] = 'chunked');
        Closed  := THTTP.GetValue(Header, 'Connection', Value) and (Value[0] = 'close');
        if THTTP.GetValue(Header, 'Content-Length', Value) then
          Count := Conv(WideString(Value[0]), 0)
        else
          Count := -1;
      end else
        Exit;
    end;
  // content length
    if Chunked then
    begin
      i := Pos(HTTP_CRLF, Response);
      while i > 0 do
      begin
        Count := Conv(WideString('$' + Copy(Response, 1, i - 1)), 0);
      // check available data
        if ((Count = 0) and (Length(Response) < 5)) or
           ((Count > 0) and (Length(Response) < i + 1 + Count + 2)) then
          Exit;
        if Count > 0 then // some chunk
        begin
          j := Length(Chunks);
          SetLength(Chunks, j + 1);
          SetLength(Chunks[j], Count);
          Move(Response[i + 2], Chunks[j][1], Count);
          Delete(Response, 1, i + 1 + Count + 2);
        end else // last chunk
        begin
          Delete(Response, 1, 5); // 0 CRLR CRLR
          goto ext;
        end;
        i := Pos(HTTP_CRLF, Response);
      end;
      Exit;      
    end else
      if (Length(Response) < Count) or (Count = -1) then
        Exit;
  ext:
  // content
    if @Proc <> nil then
    begin
      RData := '';
      Compress := THTTP.GetValue(Header, 'Content-Encoding', Value) and (Value[0] = 'gzip');
      if Chunks = nil then
      begin
        SetLength(RData, Count);
        Move(Response[1], RData[1], Count);
        if Compress then
          RData := THTTP.Decompress(RData);
        Delete(Response, 1, Count);
      end else // collect chunks into RData
      begin
        Count := 0;
        for i := 0 to Length(Chunks) - 1 do
          Inc(Count, Length(Chunks[i]));
        SetLength(RData, Count);
        Count := 0;
        for i := 0 to Length(Chunks) - 1 do
        begin
          Move(Chunks[i][1], RData[Count + 1], Length(Chunks[i]));
          Inc(Count, Length(Chunks[i]));
        end;
        RData := THTTP.Decompress(RData);
{
        for i := 0 to Length(Chunks) - 1 do
        begin
          if Compress then
            Chunks[i] := THTTP.Decompress(Chunks[ Length(Chunks) - 1 ]);
          RData := RData + Chunks[i];
        end;
}
      end;
    // convert text/raw content
      if not (THTTP.GetValue(Header, 'Content-Type', Value) and (
               (Pos(AnsiString('xml'), Value[0]) > 0) or
               (Pos(AnsiString('text'), Value[0]) > 0) or
               (Pos(AnsiString('json'), Value[0]) > 0))) then
      begin
        Content := '';
        RawData := @RData[1];
        RawSize := Length(RData);
      end else
        Content := UTF8Decode(RData);
    // callback
      Proc(ID, Header, Content, Data, RawData, RawSize);
    end;
    {$IFDEF DEBUG}Writeln('http: response');{$ENDIF}
    Result := True;
  end;
end;
{$ENDREGION}

{$REGION 'THTTP'}
procedure QueryTaskProc(q: TQuery);
var
  s : THTTPSession;
begin
  HTTP.CS.Lock;
  s := HTTP.SessionAdd(q.Host, q.KeepAlive);
  s.QueryAdd(q);
  HTTP.CS.Unlock;
  s.Start;
end;

constructor THTTP.Create;
begin
  CS.Init;
  Queue.Init(@QueryTaskProc, 10);
end;

destructor THTTP.Destroy;
begin
  Queue.Free;
  CS.Lock;
  while Length(Session) > 0 do
    Session[0].Free;
  CS.Unlock;
  CS.Free;
  Session := nil;
end;

function THTTP.SessionAdd(const Host: AnsiString; KeepAlive: Boolean): THTTPSession;
var
  i : LongInt;
begin
  if KeepAlive then
    for i := 0 to Length(Session) - 1 do
      if (Session[i].Net.Host = Host) and (not Session[i].Closed) then
      begin
        Result := Session[i];
        Exit;
      end;
{$IFDEF DEBUG}
  Writeln('Session add: ', Host, ' (', Length(Session), ')');
{$ENDIF}
  Result := THTTPSession.Create(Host, KeepAlive);
  SetLength(Session, Length(Session) + 1);
  Session[Length(Session) - 1] := Result;
end;

procedure THTTP.SessionDel(s: THTTPSession);
var
  i : LongInt;
begin
  CS.Lock;
  for i := 0 to Length(Session) - 1 do
    if Session[i] = s then
    begin
      Session[i] := Session[Length(Session) - 1];
      SetLength(Session, Length(Session) - 1);
      break;
    end;

{$IFDEF DEBUG}
  Writeln('Session remove (', Length(Session), ')');
  for i := 0 to Length(Session) - 1 do
    Writeln(' - ' + Session[i].Net.Host);
{$ENDIF}

  CS.Unlock;
end;

procedure THTTP.Query(Method: TQueryMethod; const Host, URL, Cookie, Content: AnsiString; ID: LongInt; Proc: TQueryProc; Data: Pointer; KeepAlive, SSL: Boolean);
const
  MethodName : array [TQueryMethod] of AnsiString = ('HEAD ', 'GET ', 'POST ', 'CONNECT ');
var
  q : TQuery;
begin
  q := TQuery.Create;
  q.ID   := ID;
  q.Proc := Proc;
  q.URL  := URL;
  q.Req  := MethodName[Method] + URL + ' HTTP/1.1' + HTTP_CRLF +
            'Host: ' + Host + HTTP_CRLF;
  q.Req := q.Req + 'User-Agent: ' + AnsiString(CLIENT_NAME + '/' + CLIENT_VER) + HTTP_CRLF;

  if Copy(URL, Length(URL) - 3, 4) <> '.jpg' then
    q.Req := q.Req + 'Accept-Encoding: gzip' + HTTP_CRLF;

//  q.Req := q.Req + 'Connection: keep-alive' + HTTP_CRLF; // by default HTTP/1.1

  if (Method = qmPOST) and (Content <> '') then
    q.Req := q.Req + 'Content-Type: application/x-www-form-urlencoded; charset="UTF-8"' + HTTP_CRLF;

  if Cookie <> '' then
    q.Req := q.Req + 'Cookie: ' + Cookie + HTTP_CRLF;

  if Content <> '' then
    q.Req := q.Req + 'Content-Length: ' + AnsiString(Conv(Length(Content))) + HTTP_CRLF;
  q.Req  := q.Req + HTTP_CRLF + Content;
  q.Data := Data;
  q.Host := Host;
  q.KeepAlive := KeepAlive;
  q.SSL := SSL;
  Queue.Push(Pointer(q));
end;

procedure THTTP.QueryImage(const URL: WideString; ID: Integer; Proc: TQueryProc);
var
  Host, Req : WideString;
begin
  if URL = '' then
    Exit;
  URLtoHostReq(URL, Host, Req);
  Query(qmGET, AnsiString(Host), AnsiString(Req), '', '', ID, Proc, nil, False);
end;

class function THTTP.GetHeader(const Text: AnsiString): AnsiString;
var
  i : LongInt;
begin
  i := Pos(HTTP_SEP, Text);
  if i > 0 then
    Result := Copy(Text, 1, i - 1)
  else
    Result := '';
end;

class function THTTP.GetContent(const Text: AnsiString): AnsiString;
var
  i : LongInt;
begin
  i := Pos(HTTP_SEP, Text);
  if i > 0 then
    Result := Copy(Text, i + 4, Length(Text))
  else
    Result := Text;
end;

class function THTTP.GetValue(const Text, Param: AnsiString; out Value: TValueArray): Boolean;
var
  i, b, e : LongInt;
  Str : AnsiString;
begin
  Value := nil;
  Str := Text;
  Result := False;
  b := Pos(Param + ': ', Str);
  while b > 0 do
  begin
    Str[b] := ' ';
    b := b + Length(Param) + 2;
    Result := True;
    SetLength(Value, Length(Value) + 1);
    e := Length(Str) + 1;
    for i := b to Length(Str) do
      if Str[i] = #13 then
      begin
        e := i;
        break;
      end;
    Value[Length(Value) - 1] := Copy(Str, b, e - b);
    b := Pos(Param + ': ', Str);
  end;
end;

class function THTTP.GetCookie(const HTTP: AnsiString; out Value: TValueArray): Boolean;
var
  i : LongInt;
begin
  Result := GetValue(HTTP, 'Set-Cookie', Value);
  if Result then
    for i := 0 to Length(Value) - 1 do
      Value[i] := Copy(Value[i], 1, Pos(AnsiChar(';'), Value[i]) - 1);
end;

class function THTTP.Decompress(const Text: UTF8String): UTF8String;
var
  DStream : TDecompressor;
  Len     : LongInt;
begin
  Result := '';
  DStream := TDecompressor.Create;
  Len := DStream.SizeGZIP(@Text[1], Length(Text));
  if Len > 0 then
  begin
    SetLength(Result, Len);
    DStream.ReadGZIP(@Text[1], @Result[1]);
  end;
  DStream.Free;
end;
{$ENDREGION}

end.
