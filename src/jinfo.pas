unit jinfo;

interface

uses
  jsys, jutils, jctrl, jroster, jmedia;

type
  TInfoStatus = class(TLabel)
  protected
    procedure SetText(const Value: WideString); override;
  end;

  TInfo = class(TControl)
    constructor Create(Parent: TControl);
  private
    FUsers : TUserArray;
    procedure SetUsers(const Value: TUserArray);
  public
    LPanel  : TControl;
    LStatus : TLabel;
    BClose  : TButton;
    BStatus : TButton;
    procedure CheckRepaint(User: TUser);
    function OnEvent(const Event: TControlEvent): Boolean; override;
    property Users: TUserArray read FUsers write SetUsers;
  end;

  TInfoThumb = class(TControl)
    User : TUser;
    function OnEvent(const Event: TControlEvent): Boolean; override;
  end;

  TInfoHint = class(THint)
    constructor Create;
  protected
    procedure SetText(const Value: WideString); override;
    procedure SetVisible(const Value: Boolean); override;
  public
    Thumb : TInfoThumb;
  end;

implementation

uses
  jglobal;

const
  BTN_PAGE   = 0;
  BTN_PHOTO  = 1;
  BTN_AUDIO  = 2;
  BTN_VIDEO  = 3;
  BTN_NOTE   = 4;
  BTN_CLOSE  = 5;

{$REGION 'TInfoStatus'}
procedure TInfoStatus.SetText(const Value: WideString);
begin
  inherited;
  Hint := Value;
end;
{$ENDREGION}

{$REGION 'TInfo'}
function InfoBtnProc(Control: TButton; const Event: TControlEvent): Boolean;
begin
  Result := False;
  if Event.ID = etClick then
  begin
    if Length(Info.FUsers) <> 1 then
      Exit;
    with Info.Users[0] do
      case Control.ID of
        BTN_PAGE  : BrowseURL(VK_URL + 'id' + UID);
        BTN_PHOTO : BrowseURL(VK_URL + 'albums' + UID);
        BTN_AUDIO : //BrowseURL(VK_URL + 'audio.php?id=' + UID);
          MediaSwitch(mtAudio, Roster.Selected[0].UID);
        BTN_VIDEO : BrowseURL(VK_URL + 'videos' + UID);
        BTN_NOTE  : BrowseURL(VK_URL + 'notes.php?id=' + UID);
        BTN_CLOSE :
          begin
            Info.Users[0].Select := False;
            Roster.Lock;
            Roster.Groups[0].Del(Info.Users[0]);
            Roster.Unlock;
            Roster.GetSelected;
          end;
      end;
  end;
end;

constructor TInfo.Create(Parent: TControl);
var
  i : LongInt;
begin
  inherited;
  LPanel := TControl.Create(Self);
  LPanel.Move(INFO_AVATAR_SIZE + 34, 4, -1 - INFO_AVATAR_SIZE - 34, 16);
  for i := 0 to 4 do
    CreateButton(LPanel, 6 + i, 24 * i, 0, BTN_PAGE + i, TEventProc(@InfoBtnProc), TLangMsg(Ord(lmHintUserPage) + i));
  LStatus := TInfoStatus.Create(Self);
  LStatus.WordWrap := True;
  LStatus.Font := Font_Tahoma_10;
  LStatus.Color := $666666;
  LStatus.LineHeight := 12;
  LStatus.LineCount  := 2;
  LStatus.Move(INFO_AVATAR_SIZE + 10, 24, -1 - INFO_AVATAR_SIZE - 10 - 8, 28);

  BClose := CreateButton(Self, 18, -22, 4, BTN_CLOSE, TEventProc(@InfoBtnProc), lmHintDialogClose);

  BStatus := CreateButton(Self, 0, INFO_AVATAR_SIZE + 10, 4, 0, nil);
  BStatus.MinAlpha := 255;
  BStatus.Cursor   := ctArrow;
end;

procedure TInfo.SetUsers(const Value: TUserArray);
begin
  FUsers := Value;
  InfoThumb.User := nil;
  case Length(FUsers) of
    1 :
      with FUsers[0] do
      begin
        BClose.Visible := FUsers[0] <> Roster.OwnerUser;
        LPanel.Visible := True;
        LStatus.Text := StatusMsg;
        InfoThumb.User := FUsers[0];
      {
        if (Avatar = nil) or (Avatar.Icon = nil) then
          XMPP.VCardGet(FUsers[0].User.JID);
      }
        History.CurLog := History.Log[UID];
        QueryStatusMsg;
        Window.Focus := Edit;
      end;
  else
    LPanel.Visible := False;
    InfoThumb.User := nil;
  end;
  Repaint;
end;

procedure TInfo.CheckRepaint(User: TUser);
var
  i : LongInt;
begin
  for i := 0 to Length(FUsers) - 1 do
    if User = FUsers[i] then
    begin
      LStatus.Text := User.StatusMsg;
      Repaint;
      Exit;
    end;
end;

function TInfo.OnEvent(const Event: TControlEvent): Boolean;
var
  HRect : TRect;
  Icon  : TImage;
  IconIdx : LongInt;
begin
  Result := inherited OnEvent(Event);
  case Event.ID of
    etDraw :
      with Event.Draw do
      begin
        if Length(FUsers) = 0 then
          Exit;

        if Length(FUsers) = 1 then
        begin
          with ARect do
            HRect := SetRect(Left, Top, Left + INFO_AVATAR_SIZE + 2, Top + INFO_AVATAR_SIZE + 2);
          Canvas.PenColor := INFO_BORDER;
          Canvas.FrameRect(HRect);

          with FUsers[0] do
          begin
            DrawAvatar(Canvas, HRect.Left + 1, HRect.Top + 1, True);

            Icon := StatusImage(IconIdx, True);
            if Icon <> nil then
            begin
              BStatus.Image    := Icon;
              BStatus.ImageIdx := IconIdx;
              if XStatus = 0 then
                BStatus.Hint := ''
              else
                BStatus.Hint := StatusText[XStatus];
            end;
          end;

        end else
        begin


        end;
      end;
  end;
end;
{$ENDREGION}

{$REGION 'TInfoThumb'}
function FormatBDate(const BDate: WideString): WideString;
var
  i, j, m : LongInt;
begin
  if BDate <> '' then
  begin
    Result := BDate;
    i := Pos('.', Result);
    if i > 0 then
    begin
      Result[i] := ' ';
      j := Pos('.', Result);
      if j = 0 then
        j := Length(Result) + 1;
      if i <> j then
      begin
        m := Conv(Copy(Result, i + 1, j - i - 1), 1) - 1;
        Delete(Result, i + 1, j - i);
        Insert(LangMsg[TLangMsg(Ord(lmMJan) + m)] + ' ', Result, i + 1);
      end;
    end;
  end else
    Result := '';
end;

function TInfoThumb.OnEvent(const Event: TControlEvent): Boolean;
var
  HRect : TRect;

  procedure DrawInfo(Index: LongInt; const Value: WideString);
  begin
    if Value <> '' then
    begin
      ImgMood.DrawFrame(Event.Draw.Canvas, HRect.Left, HRect.Top, Index, 16);
      Event.Draw.Canvas.TextOut(HRect.Left + 23, HRect.Top + 1, Value);
      Inc(HRect.Top, 21);
    end;
  end;

var
  i : LongInt;
begin
  Result := inherited OnEvent(Event);
  if Event.ID = etDraw then
    with Event.Draw do
    begin
      Canvas.BrushColor := COLOR_0;
      Canvas.PenColor   := COLOR_5;
      Canvas.FillRect(ARect);
      Canvas.FrameRect(ARect);
      with ARect do
      begin
        Canvas.FrameRect(SetRect(Left + 2, Top + 2, Right - 2, Bottom - 2));
        Canvas.ClipInit(SetRect(Left + 4, Top + 4, Right - 4, Bottom - 4));
      end;
      if User <> nil then
      begin
        HRect := SetRectSize(ARect.Left + 8, ARect.Top + (Height - 52) div 2, INFO_AVATAR_SIZE + 2, Top + INFO_AVATAR_SIZE + 2);

        User.DrawAvatar(Canvas, HRect.Left + 1, HRect.Top + 1, True);
        Canvas.FrameRect(HRect);

        HRect.Left := HRect.Right + 6;
        Canvas.Font := Font_Tahoma_11;
        Canvas.TextColor := COLOR_8;
        with User do
        begin
          i := 0;
          if City   <> '' then Inc(i, 21);
          if BDate  <> '' then Inc(i, 21);
          if MPhone <> '' then Inc(i, 21);
          if HPhone <> '' then Inc(i, 21);

          HRect.Top := ARect.Top + (Height - i) div 2 + 3;

          DrawInfo(0, City);
          DrawInfo(34, FormatBDate(BDate));
          DrawInfo(56, MPhone);
          DrawInfo(57, HPhone);
        end;
        Canvas.ClipFree;
      end else
        Icon[itOnline].Draw(Canvas, ARect.Left + (Width - 16) div 2, ARect.Top + (Height - 16) div 2);
    end;
end;
{$ENDREGION}

{$REGION 'TInfoHint'}
constructor TInfoHint.Create;
const
  INFO_HINT_IDLE = 7;
begin
  inherited Create(Window, True);
  Idle := INFO_HINT_IDLE;
  Thumb := TInfoThumb.Create(Self);
  Thumb.Move(0, 0, -1, -1);
end;

procedure TInfoHint.SetText(const Value: WideString);
var
  w, h : LongInt;

  procedure AddSize(const Str: WideString);
  begin
    if Str <> '' then
    begin
      Inc(h, 21);
      w := Max(w, DCanvas.TextWidth(PWideChar(Str), Length(Str)) + 32);
    end;
  end;

begin
  if (Thumb.User <> nil) {and (not Roster.PopupMenu.Visible)} then
  begin
    h := 0;
    w := 0;
    DCanvas.Lock;
    DCanvas.Font := Font_Tahoma_11;
    with Thumb.User do
    begin
      AddSize(City);
      AddSize(FormatBDate(BDate));
      AddSize(MPhone);
      AddSize(HPhone);
    end;
    DCanvas.Unlock;
    ASize.Width  := Min(52 + w, 320) + 16;
    ASize.Height := Max(52, h) + 16;
  end;
end;

procedure TInfoHint.SetVisible(const Value: Boolean);
begin
  if Value then
  begin
    if (Thumb.User <> nil) {and (not Roster.PopupMenu.Visible)} then
      inherited;
  end else
    inherited;
end;
{$ENDREGION}

end.
