unit jhistory;

interface

uses
  jsys, jdata, jutils, jxml, jctrl, jroster;

const
  HEAD_HEIGHT = 22;
  LINE_HEIGHT = 17;
  DATE_HEIGHT = 14;
  SMILE_SPACE = 19;

type
  TMessageState = (msIn, msOut, msInfo, msFave);

  TMessageTable = record
    Offset : LongInt;
    Table  : array [0..63] of LongWord;
  end;

  PMessage = ^TMessage;

  TTextType = (ttText, ttLink, ttSmile, ttPhoto, ttAudio, ttVideo);
  TSmileID = LongWord;

  TMediaObj = class
    ID, UID : WideString;
    //
  end;

  PTextObj = ^TTextObj;
  TTextObj = record
    X, Y  : Word;
    Part  : TStringPart;
    Lines : TStringPartArray;
    Link  : WideString;
    case TextType: TTextType of
      ttSmile : (SmileID: TSmileID);
      ttPhoto,
      ttAudio,
      ttVideo : (MediaObj: TMediaObj);
  end;

  TLogSelect = record
    Msg  : PMessage;
    Line : LongInt;
    Obj  : LongInt;
    X, Y : LongInt;
  end;

  TLogSelection = record
    Left, Right : TLogSelect;
  end;

  TMsgState = (msUnread, msRead, msError);

  PMsgLine = ^TMsgLine;
  TMsgLine = record
    State  : TMsgState;
    LY, LH : Word;
    Time   : TMsgTime;
    MID    : LongWord;
    Text   : WideString;
    Attach : WideString;
    Obj    : array of TTextObj;
  end;

  TMessage = record
    Prev   : PMessage;
    Next   : PMessage;
    Date   : TMsgDate;
    User   : TUser;
    Height : LongInt;
    Line   : array of PMsgLine;
  end;

  TSelection = record
    Left, Right : record
      Msg   : PMessage;
      Line  : LongInt;
      Caret : LongInt;
    end;
  end;

  TLogMode = (lmDay, lmWeek, lmMonth, lmYear, lmAll);

  TLog = class
    constructor Create(const UID: WideString);
    destructor Destroy; override;
  protected
    First  : PMessage;
    Last   : PMessage;
    FWidth : LongInt;
    MsgCount : LongInt;
    MaxCount : LongInt;
    function GetMsgLine(MID: LongWord): PMsgLine;
    procedure SetWidth(const Value: LongInt);
  public
    UID  : WideString;
    User : TUser;
    Text : WideString;
    Mode : TLogMode;
    QueryFlag : Boolean;
    procedure QueryHistory;
    function GetLastMessage: PMessage;
    function InMode(Msg: PMessage): Boolean;
    function MsgAdd(MUser: TUser; const Text, Attach: WideString; const DateTime: TMsgDateTime; const MID: LongWord = 0): PMsgLine; overload;
    function MsgAdd(XML: TXML; User: TUser = nil; Insert: Boolean = False): PMsgLine; overload;
    function MsgInsert(MUser: TUser; const Text, Attach: WideString; const DateTime: TMsgDateTime; const MID: LongWord = 0): PMsgLine;
    function DrawMsg(Canvas: TCanvas; var Rect: TRect; Height: LongInt; Msg: PMessage): PMessage;
    function MouseOver(const Rect: TRect; x, y, Offset: LongInt): PTextObj;
    property MsgLine[MID: LongWord]: PMsgLine read GetMsgLine;
    property Width: LongInt read FWidth write SetWidth;
  end;

  THistory = class(TScrollBox)
    constructor Create(Parent: TControl);
    destructor Destroy; override;
  private
    CS      : TCriticalSection;
    FLog    : array of TLog;
    FCurLog : TLog;
    Over    : PTextObj;
    MIDBuf : WideString;
    function GetLog(const UID: WideString): TLog;
    procedure SetCurLog(const Value: TLog);
  public
    procedure ReadMake(MID: LongWord);
    procedure ReadFlush;
    procedure UpdateRange; override;
    function OnEvent(const Event: TControlEvent): Boolean; override;
    function FindLog(const UID: WideString): TLog;
    property Log[const UID: WideString]: TLog read GetLog;
    property CurLog: TLog read FCurLog write SetCurLog;
  end;

implementation

uses
  jglobal, jvk;

{$REGION 'Common'}
function MsgParseURL(Pos: LongInt; const PreURL, Text: WideString; out Part: TStringPart): Boolean;
var
  i : LongInt;
begin
  Part.Start  := PosEx(Pos + 1, PreURL, Text);
  Part.Length := 0;
  if Part.Start > 0 then
  begin
    Dec(Part.Start);
    for i := Part.Start + 1 + Length(PreURL) to Length(Text) do
      if AnsiChar(Text[i]) in [' ', '"', '''', '!', #13, #10] then
      begin
        Part.Length := i - Part.Start - 1;
        Result := Part.Length > 0;
        Exit;
      end;
    Part.Length := Length(Text) - Part.Start;
  end;
  Result := Part.Length > 0;
end;

function MsgParseSmile(Pos, Count: LongInt; const Text: WideString; out SmileID: LongInt; out Part: TStringPart): Boolean;
var
  i, p : LongInt;
begin
  Result := False;
  Part.Start  := Pos + Count;
  Part.Length := 0;
  for i := Length(SmileTag) - 1 downto 0 do
  begin
    p := PosBuf(Pos + 1, Count, SmileTag[i], Text);
    if (p > 0) and (p < Part.Start) then
    begin
      SmileID := i;
      Part.Start  := p - 1;
      Part.Length := Length(SmileTag[i]);
      Result := True;
    end;
  end;
end;

procedure MsgParse(Msg: PMessage; Line: LongInt);
var
  TP, LP, SP, PP : TStringPart;
  SmileID : LongInt;

  procedure AddObj(const Part: TStringPart; TextType: TTextType);
  var
    i : LongInt;
  begin
    if Part.Length > 0 then
      with Msg^.Line[Line]^ do
      begin
        i := Length(Obj);
        SetLength(Obj, i + 1);
        FillChar(Obj[i], SizeOf(Obj[i]), 0);
        Obj[i].Part     := Part;
        Obj[i].TextType := TextType;
        case TextType of
          ttLink  : Obj[i].Link := Copy(Text, Part.Start + 1, Part.Length);
          ttSmile : Obj[i].SmileID := SmileID;
        end;
      end;
  end;

begin
  with Msg^.Line[Line]^ do
  begin
    Text := ReplaceMediaTags(Text);
  // parse message text (text, url, smile)
    TP.Start  := 0;
    TP.Length := 0;
    while TP.Start < Length(Text) do
    begin
    // get url part if it exists
      if MsgParseURL(TP.Start, TOKEN_HTTP, Text, LP) or
         MsgParseURL(TP.Start, TOKEN_HTTPS, Text, LP) or
         MsgParseURL(TP.Start, TOKEN_FTP, Text, LP) then
        TP.Length := LP.Start - TP.Start
      else
        TP.Length := Length(Text) - TP.Start;

      if TP.Length > 0 then
      begin
        PP := TP;
        while MsgParseSmile(TP.Start, TP.Length, Text, SmileID, SP) do
        begin
          if SP.Start > TP.Start then
          begin
            PP.Start  := TP.Start;
            PP.Length := SP.Start - TP.Start;
            AddObj(PP, ttText);
          end else
            PP.Length := 0;
          AddObj(SP, ttSmile);
          Inc(TP.Start, PP.Length + SP.Length);
          Dec(TP.Length, PP.Length + SP.Length);
        end;
        AddObj(TP, ttText);
      end;

      if LP.Length > 0 then
        AddObj(LP, ttLink);
      Inc(TP.Start, TP.Length + LP.Length);
    end;
  end;
end;

procedure MsgLineWrap(MsgLine: PMsgLine; Width: LongInt); //inline;
var
  i, j, X, Y : LongInt;
begin
  X := 0;
  Y := 0;
  with MsgLine^ do
  begin
    for i := 0 to Length(Obj) - 1 do
    begin
    // smile wrap
      if (Obj[i].TextType = ttSmile) and (X + SMILE_SPACE > Width) then
      begin
        X := 0;
        Inc(Y, LINE_HEIGHT);
      end;
    // set text object pos
      Obj[i].Y := Y;
      case Obj[i].TextType of
        ttText, ttLink :
          begin
          // text & link wrap
          { TODO : optimize (if width < right then resize) }
            if (Obj[i].X <> X) or (Length(Obj[i].Lines) <> 1) or (Obj[i].Lines[0].Right > Width) then
              DCanvas.TextWrap(@Text[Obj[i].Part.Start + 1], Obj[i].Part.Length, X, Width, Obj[i].Lines);
            Obj[i].X := X;
            j := Length(Obj[i].Lines);
            if j > 0 then
            begin
              X := Obj[i].Lines[j - 1].Right;
              Inc(Y, (j - 1) * LINE_HEIGHT);
            end;
          end;
        ttSmile :
          begin
            Obj[i].X := X;
            Inc(X, SMILE_SPACE);
          end;
      end;
    end;
    Inc(Y, LINE_HEIGHT);
    LH := Y;
  end;
end;

procedure MsgWrap(Msg: PMessage; Width: LongInt);
var
  i : LongInt;
begin
  if Width <= 0 then
    Exit;

  with Msg^ do
  begin
    Height := 0;
    for i := 0 to Length(Line) - 1 do
    begin
      Line[i]^.LY := Height;
      MsgLineWrap(Line[i], Width);
      Inc(Height, Line[i].LH);
    end;
  end;
end;

{$ENDREGION}

{$REGION 'TLog'}
procedure OnHistory(Log: TLog; XML: TXML);
var
  NXML : TXML;
  i : LongInt;
  User : TUser;
//  DateTime : TMsgDateTime;
//  MsgLine : PMsgLine;
begin
  Log.QueryFlag := False;
  if (XML = nil) or (XML.Tag = 'error') then
  begin
  {$IFDEF DEBUG}
    Writeln('history error');
    if XML <> nil then
      Writeln(XML.Content);
  {$ENDIF}
    Exit;
  end;

  with XML do
  begin
    NXML := XML['count'];
    if NXML = nil then
      Exit; // some error

    for i := 0 to Count - 1 do
      with NodeI[i] do
        if Tag = 'message' then
        begin
          if Value['from_id'] <> vk.mid then
            User := Log.User
          else
            User := Roster.OwnerUser;
          Log.MsgAdd(XML.NodeI[i], User, True);
        end;

    Log.MaxCount := Conv(NXML.Content, 0);

//    if Log.ReqCount < i then
//      vk.QueryHistory(Log.User.UID, Log.ReqCount, 100, Integer(Log), @OnHistory, False);
  end;

  Log.FWidth := 0;
  if Log = History.CurLog then
    History.CurLog := Log; // resize / get range / repaint log
end;

constructor TLog.Create(const UID: WideString);
begin
  Self.UID := UID;
  Mode := lmAll;

  MsgCount := 0;
  MaxCount := 1;

  User := Roster.GetUserByUID(UID, True);
  FWidth := 0;
  QueryHistory;
end;

destructor TLog.Destroy;
var
  i : LongInt;
  PMsg : PMessage;
begin
//  Stream.Free;
  while First <> nil do
  begin
    PMsg := First;
    First := First^.Next;
    for i := 0 to Length(PMsg^.Line) - 1 do
      Dispose(PMsg^.Line[i]);
    Dispose(PMsg);
  end;
  inherited;
end;

procedure TLog.QueryHistory;
begin
  if (not QueryFlag) and (MsgCount < MaxCount) and (UID <> '') then
  begin
    QueryFlag := True;
    vk.QueryHistory(UID, MsgCount, 50, LongInt(Self), @OnHistory, True);
  end;
end;

function TLog.GetMsgLine(MID: LongWord): PMsgLine;
var
  Msg : PMessage;
  i: Integer;
begin
  Msg := Last;
  while Msg <> nil do
  begin
    for i := 0 to Length(Msg^.Line) - 1 do
      if Msg^.Line[i]^.MID = MID then
      begin
        Result := Msg^.Line[i];
        Exit;
      end;
    Msg := Msg^.Prev;
  end;
  Result := nil;
end;

procedure TLog.SetWidth(const Value: LongInt);
var
  Msg : PMessage;
begin
  if Width <> Value then
  begin
    FWidth := Value;
    Msg := First;
    DCanvas.Lock;
    DCanvas.Font := Font_Tahoma_13;
    while Msg <> nil do
    begin
      MsgWrap(Msg, FWidth);
      Msg := Msg^.Next;
    end;
    DCanvas.Unlock;

    if History.CurLog = Self then
      History.UpdateRange;
  end;
end;

function TLog.GetLastMessage;
var
  Msg : PMessage;
begin
  Msg := Last;
  while Msg <> nil do
  begin
    if Msg^.User = Roster.OwnerUser then
    begin
      Result := Msg;
      Exit;
    end;
    Msg := Msg^.Prev;
  end;
  Result := nil;
end;

function TLog.InMode(Msg: PMessage): Boolean;
begin
  if Msg = nil then
    Result := False
  else
    with Last^, Msg^.Date do
      case Mode of
        lmDay   : Result := MsgDateCompare(Date, Msg^.Date);
{        lmWeek  : ;//Result := (Date.Year = Year) and ;
        lmMonth : ;
        lmYear  : ;
 }     else
        Result := True;
      end;
end;

function TLog.MsgAdd(MUser: TUser; const Text, Attach: WideString; const DateTime: TMsgDateTime; const MID: LongWord = 0): PMsgLine;
var
  Msg : PMessage;
  HOffset, h, i : LongInt;
  Flag : Boolean;
begin
  Result := nil;
  if (Text = '') and (Attach = '') then
    Exit;

// search message by MID
  Msg := Last;
  Flag := True;
  if MID <> 0 then
    while (Msg <> nil) and Flag do
    begin
      for i := Length(Msg^.Line) - 1 downto 0 do
        if Msg^.Line[i].MID = MID then
          Exit
        else
          if Msg^.Line[i].MID < MID then
          begin
            Flag := False;
            break;
          end;
      Msg := Msg^.Prev;
    end;
  HOffset := 0;

  if (Last = nil) or (Last^.User <> MUser) or (not MsgDateCompare(Last^.Date, DateTime.Date)) then
  begin
    New(Msg);
    FillChar(Msg^, SizeOf(TMessage), 0);
    if Last = nil then
      First := Msg
    else
      Last^.Next := Msg;
    Msg^.Prev := Last;
    Msg^.Date := DateTime.Date;
    Msg^.User := MUser;
    HOffset := HEAD_HEIGHT;
    if (Last <> nil) and (not MsgDateCompare(Last^.Date, DateTime.Date)) then
      Inc(HOffset, DATE_HEIGHT);
    Last := Msg;
  end else
    Msg := Last;

  with Msg^ do
  begin
    i := Length(Line);
    SetLength(Line, i + 1);

    New(Result);
    FillChar(Result^, SizeOf(TMsgLine), 0);
    Result^.Time := DateTime.Time;
    Result^.MID  := MID;
    Result^.Text := Text;
    Result^.Obj  := nil;
    Result^.Attach := Attach;
    Line[i] := Result;

    MsgParse(Msg, i);
    h := Msg^.Height;
    DCanvas.Lock;
    DCanvas.Font := Font_Tahoma_13;
    MsgWrap(Msg, FWidth);
    DCanvas.Unlock;
    h := Msg^.Height - h;

    Inc(MsgCount);
    Inc(MaxCount);

    if Self = History.CurLog then
    begin
      if History.VScroll.Offset < -16 then
        History.VScroll.Offset := History.VScroll.Offset - (HOffset + h)
      else
        History.VScroll.Offset := 0;
      History.UpdateRange;
      History.Repaint;
    end;
  end;

  if MUser <> Roster.OwnerUser then
  begin
    PopupMan.AddQuery(MUser, Text, MID);
    Roster.Activate(MUser);
    if Config.Sound then
      PlaySound(@SND_IN_DATA);
  end;
end;

function TLog.MsgAdd(XML: TXML; User: TUser; Insert: Boolean): PMsgLine;

  function ParseAttach(XML: TXML): WideString;
  begin
    with XML do
    begin
      Result := '';
      if Tag <> 'attachment' then
        Exit;
      with Node[Value['type']] do
      begin
        if Tag = 'photo' then
          Result := VK_URL + Tag + Value['owner_id'] + '_' + Value['pid'];
        if Tag = 'video' then
          Result := VK_URL + Tag + Value['owner_id'] + '_' + Value['vid'];
        if Tag = 'doc' then
          Result := VK_URL + Tag + Value['owner_id'] + '_' + Value['did'] + ' "' + SpecToChar(Value['title']) + '"';
        if Tag = 'audio' then
          Result := VK_URL + 'audio.php?id=' + Value['owner_id'] + '&audio_id=' + Value['aid'] +
                    ' "' + SpecToChar(Value['performer'] + ' - ' + Value['title']) + '"';
      end;
    end;
  end;

var
  mid  : LongWord;
  line : PMsgLine;
  time : TMsgDateTime;
  text : WideString;
  Attachment : TXML;
  attach : WideString;
  i : LongInt;
  str : WideString;
begin
  Result := nil;
  if XML = nil then
    Exit;

  with XML do
  begin
    mid  := Conv(Value['mid'], 0);
    line := MsgLine[mid];
    if line = nil then
    begin
      time := MsgDateTime(Conv(Value['date'], 0));
      text := SpecToChar(Value['body']);
      Attachment := Node['attachments'];

      attach := ''; // TODO
      if Attachment <> nil then
        with Attachment do
          for i := 0 to Count - 1 do
          begin
            str := ParseAttach(NodeI[i]);
            if str <> '' then
            begin
              if text <> '' then
                text := text + #13;
              text := text + str;
            end;
          end;

      if User = nil then
        User := Self.User;

      if Insert then
        line := MsgInsert(User, text, attach, time, mid)
      else
        line := MsgAdd(User, text, attach, time, mid);
    end;
  // set state
    if line <> nil then
      if Value['read_state'] <> '1' then
        line^.State := msUnread
      else
        line^.State := msRead;
  end;
end;

function TLog.MsgInsert(MUser: TUser; const Text, Attach: WideString; const DateTime: TMsgDateTime; const MID: LongWord = 0): PMsgLine;
var
  Msg  : PMessage;
  i    : LongInt;
  Flag : Boolean;
begin
  Result := nil;
  if (Text = '') and (Attach = '') then
    Exit;

  Msg := First;
  Flag := True;
  while (Msg <> nil) and Flag do
  begin
    for i := 0 to Length(Msg^.Line) - 1 do
      if Msg^.Line[i].MID = MID then
        Exit
      else
        if Msg^.Line[i].MID > MID then
        begin
          Flag := False;
          break;
        end;
    Msg := Msg^.Next;
  end;

  if (First = nil) or (First^.User <> MUser) or (not MsgDateCompare(First^.Date, DateTime.Date)) then
  begin
    New(Msg);
    FillChar(Msg^, SizeOf(TMessage), 0);
    if First = nil then
      Last := Msg
    else
      First^.Prev := Msg;
    Msg^.Next := First;
    Msg^.Date := DateTime.Date;
    Msg^.User := MUser;
    First := Msg;
  end else
    Msg := First;

  with Msg^ do
  begin
    SetLength(Line, Length(Line) + 1);
    for i := Length(Line) - 1 downto 1 do
      Line[i] := Line[i - 1];

    New(Result);
    FillChar(Result^, SizeOf(TMsgLine), 0);
    Result^.Time := DateTime.Time;
    Result^.MID  := MID;
    Result^.Text := Text;
    Result^.Obj  := nil;
    Result^.Attach := Attach;;
    Line[0] := Result;

    MsgParse(Msg, 0);
    Inc(MsgCount);
    Inc(MaxCount);
  end;
end;

function TLog.DrawMsg(Canvas: TCanvas; var Rect: TRect; Height: LongInt; Msg: PMessage): PMessage;
var
  i, j : LongInt;
  Str : WideString;
//  SLeft : LongInt;
begin
  Result := nil;
  if (Msg = nil) or (Rect.Top > Rect.Bottom + LINE_HEIGHT) then
    Exit;

  if Rect.Bottom - Msg^.Height - HEAD_HEIGHT - DATE_HEIGHT > Rect.Top + Height then
  begin
    Dec(Rect.Bottom, Msg^.Height + HEAD_HEIGHT);
    if (Msg^.Prev = nil) or (not MsgDateCompare(Msg^.Date, Msg^.Prev^.Date)) then
      Dec(Rect.Bottom, DATE_HEIGHT);
    Result := Msg^.Prev;
    Exit;
  end;

  with Msg^ do
  begin
    Dec(Rect.Bottom, Height - LINE_HEIGHT);
    for i := 0 to Length(Line) - 1 do
      with Line[i]^ do
      begin
      // draw background (message state)
        if State <> msRead then // no background
        begin
          if State = msUnread then
            if (Msg^.User <> Roster.OwnerUser) or (Self.UID = Roster.OwnerUser.UID) then
              if Window.IsFore and (MID <> 0) then // make read
              begin
                State := msRead;
                History.ReadMake(MID);
              end else
                Canvas.BrushColor := $CCFFF5//$E6FFFA
            else
              Canvas.BrushColor := $FAEDD4//$FBF9F5
          else // msError
            Canvas.BrushColor := $BFCBFF;//$E8EFFF;

          if State <> msRead then
            Canvas.FillRect(SetRect(Rect.Left, Rect.Bottom + LY - 2, Rect.Right + 6, Rect.Bottom + LY + LH - 2));
        end;
      // draw time
        Canvas.Font := Font_Tahoma_11;
        Canvas.TextColor := $999999;
        Canvas.TextOut(Rect.Left + 4, Rect.Bottom + LY, MsgConvTime(Time));

      // draw message
        Canvas.Font := Font_Tahoma_13;
        for j := 0 to Length(Obj) - 1 do
        begin
          case Obj[j].TextType of
            ttText : Canvas.TextColor := COLOR_8;
            ttLink :
              if @Obj[j] = History.Over then
                Canvas.TextColor := $3E3EB2
              else
                Canvas.TextColor := $B9640C;
            ttSmile :
              begin
                ImgSmile.DrawFrame(Canvas, Rect.Left + 41 + Obj[j].X, Rect.Bottom - 2 + LY + Obj[j].Y, Obj[j].SmileID, 16);
                continue;
              end;
          end;
          Canvas.TextOut(Rect.Left + 40, Rect.Bottom - 2 + LY + Obj[j].Y, LINE_HEIGHT, @Text[Obj[j].Part.Start + 1], Obj[j].Lines);
        end;
      end;
    Dec(Rect.Bottom, LINE_HEIGHT);
  end;

// name
  Canvas.Font := Font_Tahoma_13b;
  if Msg^.User = Roster.OwnerUser then
    Canvas.TextColor := $7A582B
  else
    Canvas.TextColor := $3E3EB2;
  Canvas.TextOut(Rect.Left + 4, Rect.Bottom - 3, Msg^.User.Name);
  Dec(Rect.Bottom, HEAD_HEIGHT);
// date
  if (Msg^.Prev = nil) or (not MsgDateCompare(Msg^.Date, Msg^.Prev^.Date)) then
  begin
    Canvas.Font := Font_Tahoma_11;
    Canvas.TextColor := $A28C79;
    Str := MsgConvDate(Msg^.Date);
    i := Canvas.TextWidth(PWideChar(Str), Length(Str));
    Canvas.TextOut(Rect.Right - i - 2, Rect.Bottom + 8, Str);
  // line
    Canvas.PenColor := EDIT_BORDER;
    Canvas.Line(Rect.Left + 4, Rect.Bottom + 15, Rect.Right - i - 10, Rect.Bottom + 15);
    Dec(Rect.Bottom, DATE_HEIGHT);
  end;

  if Msg^.Prev = nil then
    QueryHistory;

  Result := Msg^.Prev;
end;

function TLog.MouseOver(const Rect: TRect; x, y, Offset: LongInt): PTextObj;
var
  Msg : PMessage;
  i, j, k, PosY : LongInt;
begin
  Result := nil;

  if not RectIntersect(Rect, x, y) then
    Exit;
  PosY := Rect.Bottom - Offset;
//  Rect.Bottom
  Msg := Last;
  while Msg <> nil do
  begin
    Dec(PosY, Msg^.Height);
    if (y >= PosY) and (y < PosY + Msg^.Height) then
    begin
      for i := 0 to Length(Msg^.Line) - 1 do
        with Msg^.Line[i]^ do
          for j := 0 to Length(Obj) - 1 do
            if (y >= PosY + Obj[j].Y + LY) and (y < PosY + Obj[j].Y + LY + Length(Obj[j].Lines) * LINE_HEIGHT) then
            begin
              k := (y - PosY - Obj[j].Y - LY) div 16;
              if (Length(Obj[j].Lines) > k) and (x >= Rect.Left + Obj[j].Lines[k].Left) and (x < Rect.Left + Obj[j].Lines[k].Right) then
              begin
                Result := @Obj[j];
                Exit;
              end;
            end;
      Exit;
    end;
    Dec(PosY, HEAD_HEIGHT);
    if (Msg^.Prev = nil) or (not MsgDateCompare(Msg^.Date, Msg^.Prev^.Date)) then
      Dec(PosY, DATE_HEIGHT);
    if PosY < y then
      break;
    Msg := Msg^.Prev;
  end;
end;
{$ENDREGION}

{$REGION 'THistory'}
constructor THistory.Create(Parent: TControl);
begin
  inherited;
  CS.Init;
  VScroll.Invert := True;
end;

destructor THistory.Destroy;
var
  i : LongInt;
begin
  for i := 0 to Length(FLog) - 1 do
    FLog[i].Free;
  CS.Free;
  inherited;
end;

function THistory.GetLog(const UID: WideString): TLog;
begin
  Result := FindLog(UID);
  if Result <> nil then
    Exit;
  CS.Lock;
  Result := TLog.Create(UID);
  SetLength(FLog, Length(FLog) + 1);
  FLog[Length(FLog) - 1] := Result;
  CS.Unlock;
end;

procedure THistory.SetCurLog(const Value: TLog);
begin
  if FCurLog <> nil then
    FCurLog.Text := Edit.Text;
  FCurLog := Value;
  VScroll.Offset := 0;
  Edit.Text := FCurLog.Text;
  FCurLog.Width := Width - 60;
  Repaint;
end;

procedure THistory.ReadMake(MID: LongWord);
begin
  if MID > 0 then
  begin
    if MIDBuf <> '' then
      MIDBuf := MIDBuf + ',';
    MIDBuf := MIDBuf + Conv(MID);
  end;
end;

procedure THistory.ReadFlush;
begin
  if MIDBuf <> '' then
  begin
    vk.MsgSetRead(MIDBuf);
    MIDBuf := '';
  end;
end;

procedure THistory.UpdateRange;
var
  Msg : PMessage;
begin
  if FUpdate or (CurLog = nil) then
    Exit;
  VScroll.Range := 0;
  Msg := CurLog.Last;
  while Msg <> nil do
  begin
  // text
    Inc(VScroll.Range, Msg^.Height);
  // header
    Inc(VScroll.Range, HEAD_HEIGHT);
  // date
    if (Msg^.Prev = nil) or (not MsgDateCompare(Msg^.Date, Msg^.Prev^.Date)) then
      Inc(VScroll.Range, DATE_HEIGHT);
    Msg := Msg^.Prev;

{    if not CurLog.InMode(Msg^.Prev) then
      break;}
  end;
  inherited;
end;

function THistory.OnEvent(const Event: TControlEvent): Boolean;
var
  HRect : TRect;
  PMsg : PMessage;
  HOver : PTextObj;
begin
  Result := inherited OnEvent(Event);

  case Event.ID of
    etMouseMove, etMouseWheel :
      if CurLog <> nil then
        with Event.Mouse.Pos, ARect do
        begin
          HOver := CurLog.MouseOver(SetRect(Left + 45, Top + 1, Right - VScroll.Width - 5, Bottom - 1), x, y, VScroll.Offset);
          if HOver <> Over then
          begin
            Over := HOver;
            Repaint;
          end;
          if Over <> nil then
            if Over^.TextType = ttLink then
              Cursor := ctHand
            else
              Cursor := ctArrow
          else
            Cursor := ctArrow;
        end;

    etMouseUp :
      if (CurLog <> nil) and (Over <> nil) and (Over^.TextType = ttLink) then
        BrowseURL(Over^.Link);

    etSize :
      if CurLog <> nil then
        CurLog.Width := Width - 60;

    etDraw :
      with Event.Draw do
      begin
        Canvas.BrushColor := EDIT_WINDOW;
        Canvas.PenColor   := EDIT_BORDER;

        with ARect do
          HRect := SetRect(Left, Top, Right - VScroll.Width div 2, Bottom);
        Canvas.FillRect(HRect);
        Canvas.FrameRect(HRect);

        with ARect do
          HRect := SetRect(Left + 1, Top + 1, Right - VScroll.Width - 1, Bottom - 1);

        Canvas.ClipInit(HRect);
        if FCurLog <> nil then
        begin
          HRect.Left   := HRect.Left + 4;
          HRect.Right  := HRect.Right - 4;
          HRect.Top    := HRect.Top;
          HRect.Bottom := HRect.Bottom - 17 - VScroll.Offset;

          PMsg := CurLog.Last;
          while (PMsg <> nil) {and CurLog.InMode(PMsg)} do
            PMsg := CurLog.DrawMsg(Canvas, HRect, Height, PMsg);
        end;
        Canvas.ClipFree;
        ReadFlush;
      end;
  end;
end;

function THistory.FindLog(const UID: WideString): TLog;
var
  i : LongInt;
begin
  Result := nil;
  CS.Lock;
  for i := 0 to Length(FLog) - 1 do
    if FLog[i].UID = UID then
    begin
      Result := FLog[i];
      break;
    end;
  CS.Unlock;
end;
{$ENDREGION}

end.


