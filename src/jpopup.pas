unit jpopup;

interface

uses
  jsys, jutils, jctrl, jroster;

const
  POPUP_WND_WIDTH = 320;
  POPUP_IDLE_TIME = 7 * 1000;
  POPUP_IDLE_OVER = 2 * 1000;

type
  TPopupWnd = class(TWindow)
    constructor Create(User: TUser; const Text: WideString; MID: LongWord);
  public
    User  : TUser;
    Text  : WideString;
    Edit  : TEdit;
    Btn   : TButton;
    Lines : TStringPartArray;
    Time  : LongWord;
    MID   : LongWord;
    Over  : Boolean;
    Dots  : Boolean;
    function OnEvent(const Event: TControlEvent): Boolean; override;
  end;

  TPopupMan = class
    constructor Create;
    destructor Destroy; override;
  private
    TimerUpdate : LongWord;
    CS : TCriticalSection;
    Popup : array of TPopupWnd;
    QueryBuf : array of record
        User : TUser;
        Text : WideString;
        MID  : LongWord;
      end;
    function Add(User: TUser; const Text: WideString; MID: LongWord): TPopupWnd;
  public
    procedure AddQuery(User: TUser; const Text: WideString; MID: LongWord);
    procedure Update;
  end;

implementation

uses
  jglobal;

const
  BTN_REPLY = 1;
  BTN_SEND  = 2;
  BTN_CLOSE = 3;
  EDIT_SEND = 4;

{$REGION 'TPopupWnd'}
function EditProc(Edit: TEdit; const Event: TControlEvent): Boolean;
begin
  Result := False;
  if Edit.ID = EDIT_SEND then
    case Event.ID of
      etKeyUp :
        if ((Event.Key.Value = Ord('W')) and (ssCtrl in Event.Key.Shift)) or (Event.Key.Value = 27) then
        begin
          Edit.CParent.Visible := False;
          TPopupWnd(Edit.CParent).User.State := usNone;
        end;
      etChar :
        if (Event.Key.Value = 13) and (Config.SimpleSend xor (ssCtrl in Event.Key.Shift)) then
          if SendMessage(Edit.Text, TPopupWnd(Edit.CParent).User) then
          begin
            Edit.CParent.Visible := False;
            TPopupWnd(Edit.CParent).User.State := usNone;
          end;
    end;
end;

function ButtonProc(Button: TButton; const Event: TControlEvent): Boolean;
begin
  Result := False;
  if Event.ID = etClick then
    case Button.ID of
      BTN_REPLY :
        begin
          with TPopupWnd(Button.CParent) do
          begin
            Edit.Resize;
            Edit.Visible := True;
            Focus := Edit;
            User.State := usNone;
          end;
          Button.ID := BTN_SEND;
          Button.Text := LangMsg[lmPopupSend];
          Dec(Button.Size.Left, 24);
          Inc(Button.Size.Width, 4);
          Button.Resize;
          CreateButton(Button.CParent, 18, -20, 4, BTN_CLOSE, TEventProc(@ButtonProc), lmNone);
        end;
      BTN_SEND :
        with TPopupWnd(Button.CParent) do
          if SendMessage(Edit.Text, User) then
          begin
            Button.CParent.Visible := False;
            User.State := usNone;
          end;
      BTN_CLOSE :
        begin
          Button.CParent.Visible := False;
          TPopupWnd(Button.CParent).User.State := usNone;
        end;
    end;
end;

constructor TPopupWnd.Create(User: TUser; const Text: WideString; MID: LongWord);
begin
  inherited Create(nil, True);
  SepFocus := True;
  Shadow := True;
  Self.User := User;
  Self.Text := Text;
  Self.MID  := MID;
  DCanvas.Lock;
  DCanvas.Font := Font_Tahoma_13;
  DCanvas.TextWrap(PWideChar(Text), Length(Text), 0, POPUP_WND_WIDTH - 52 - 24, Lines);
  DCanvas.Unlock;
  if Length(Lines) > 6 then
  begin
    SetLength(Lines, 6);
    Lines[5].Length := 3;
    Insert('...', Self.Text, Lines[5].Start + 1);
  end;
  ASize.Height := Max(52 + 8 + 28, 28 + Length(Lines) * 16 + 8);
  Edit := TEdit.Create(Self);
  Edit.Visible := False;
  Edit.Move(52 + 15, 28, -52 - 19, -28 - 8 - 1);
  Edit.ID := EDIT_SEND;
  Edit.EventProc := @EditProc;

  Btn := TButton.Create(Self, nil, -1);
  Btn.Text := LangMsg[lmPopupReply];
  Btn.Font := Font_Tahoma_11;
  Btn.Move(-64 - 8, 6, 64, 18);
  Btn.ID := BTN_REPLY;
  Btn.EventProc := @ButtonProc;

  Time := GetTime;
end;

function TPopupWnd.OnEvent(const Event: TControlEvent): Boolean;
begin
  case Event.ID of
    etMouseMove :
      with Event.Mouse.Pos do
      begin
        Over := (x <> -1) and (y <> -1);
        if Over and (MID > 0) then
        begin
          History.ReadMake(MID);
          History.ReadFlush;
          MID := 0;
        end;
      end;
    etMouseUp :
      begin
        if Event.Mouse.Button = mbLeft then
        begin
          Window.Fore;
          Roster.SelectUser(User);
        end else
          User.State := usNone;
        Visible := False;
      end;
    etDraw :
      with Event.Draw do
      begin
        Canvas.BrushColor := POPUP_WINDOW;
        Canvas.PenColor   := POPUP_BORDER;
        Canvas.FillRect(ARect);
        Canvas.FrameRect(ARect);

        jglobal.Icon[itMessage].Small.Draw(Canvas, 8, 6);
        Canvas.TextColor := COLOR_T1;
        Canvas.TextOut(8 + 20, 6, User.Name);

        User.DrawAvatar(Canvas, 8 + 1, 28 + 1, True);
        Canvas.PenColor := INFO_BORDER;
        Canvas.FrameRect(SetRectSize(8, 28, 52, 52));

        Canvas.Font := Font_Tahoma_13;
        Canvas.TextColor := COLOR_8;
        Canvas.TextOut(8 + 52 + 8, 28, 16, PWideChar(Text), Lines);
      end;
  end;
  Result := inherited OnEvent(Event);
end;
{$ENDREGION}

{$REGION 'TPopupMan'}
procedure UpdateProc;
begin
  PopupMan.Update;
end;

constructor TPopupMan.Create;
begin
  CS.Init;
  TimerUpdate := InitTimer(100, @UpdateProc);
end;

destructor TPopupMan.Destroy;
var
  i : LongInt;
begin
  FreeTimer(TimerUpdate);
  CS.Lock;
  for i := 0 to Length(Popup) - 1 do
    Popup[i].Free;
  CS.Unlock;
  CS.Free;
end;

function TPopupMan.Add(User: TUser; const Text: WideString; MID: LongWord): TPopupWnd;
var
  i, h : LongInt;
begin
  Result := nil;
  if Config.Popup and (not Window.IsFore) then
  begin
    CS.Lock;
    UpdateScreen;
    Result := TPopupWnd.Create(User, Text, MID);
    h := Screen.Top + Screen.Height;
    for i := 0 to Length(Popup) - 1 do
      h := Min(h, Popup[i].ScreenRect.Top);

    with Screen do
      Result.Move(Left + Width - POPUP_WND_WIDTH - 8, h - Result.Height - 8,
                  POPUP_WND_WIDTH, Result.Height);
    Result.Resize;
    Result.Visible := True;
    SetLength(Popup, Length(Popup) + 1);
    Popup[Length(Popup) - 1] := Result;
    CS.Unlock;
  end;
end;

procedure TPopupMan.AddQuery(User: TUser; const Text: WideString; MID: LongWord);
begin
  CS.Lock;
  SetLength(QueryBuf, Length(QueryBuf) + 1);
  QueryBuf[Length(QueryBuf) - 1].User := User;
  QueryBuf[Length(QueryBuf) - 1].Text := Text;
  QueryBuf[Length(QueryBuf) - 1].MID  := MID;
  CS.Unlock;
end;

procedure TPopupMan.Update;
var
  i : LongInt;
  Time : LongWord;
begin
  CS.Lock;
// flush query
  for i := 0 to Length(QueryBuf) - 1 do
    with QueryBuf[i] do
      Add(User, Text, MID);
  QueryBuf := nil;

  Time := GetTime;
  i := 0;
  while i < Length(Popup) do
    if (not Popup[i].Visible) or ((Time - Popup[i].Time > POPUP_IDLE_TIME) and
       (not Popup[i].Edit.Visible) and (not Popup[i].Over)) then
    begin
      Popup[i].Free;
      Popup[i] := Popup[Length(Popup) - 1];
      SetLength(Popup, Length(Popup) - 1);
    end else
      Inc(i);
  CS.Unlock;
end;
{$ENDREGION}

end.
