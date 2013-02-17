unit jstatus;

interface

uses
  jsys, jutils, jxml, jctrl, jroster, jvk;

// hint: XStatus 666 = joim "no" XStatus (can't save 0 on server)
const
  XSTATUS_KEY = '1300';

type
  TStatusFrame = class(TPopupMenu)
    constructor Create;
  protected
    procedure SetVisible(const Value: Boolean); override;
  public
    EStatus : TEdit;
    IStatus : TImageList;
    procedure StatusGet(User: TUser);
    procedure StatusSet(const Text: WideString);
    procedure StatusAudioSet(const AudioID: WideString);
    procedure Update;
    procedure FirstCheck;
  end;

implementation

uses
  jglobal;

const
  EDIT_STATUS = 1;
  BTN_ACCEPT  = 2;
  BTN_CANCEL  = 3;

function StatusImageText(Index: LongInt): WideString;
begin
  Result := StatusText[Index];
end;

procedure OnStatus(User: TUser; XML: TXML);
var
  idx : LongInt;
begin
  if XML = nil then Exit;
// status
  with XML['s'] do
    User.StatusMsg := XML['s'].Value['text'];
// x-status
  Idx := 0;
  with XML['x'] do
    if Content <> '' then
    begin
      Idx := Conv(Content, 666);
      User.JoimUser := True;
    end;
  User.XStatus := Idx;
end;

procedure OnFirstCheck(User: TUser; XML: TXML);
begin
  if (XML = nil) or (XML.Content = '') then // first start
  begin
    User.XStatus := 37;
    vk.QueryValueSet(User.XStatus, XSTATUS_KEY);
  end else
    User.XStatus := Conv(XML.Content, 0);
  Status.StatusGet(User);
end;

function StatusProc(Control: TControl; const Event: TControlEvent): Boolean;

  procedure Accept;
  begin
    if Roster.OwnerUser.StatusMsg <> Status.EStatus.Text then
    begin
      Roster.OwnerUser.StatusMsg := Status.EStatus.Text;
      Status.StatusSet(Roster.OwnerUser.StatusMsg);
    end;

    if Roster.OwnerUser.XStatus <> Status.IStatus.Index then
    begin
      Roster.OwnerUser.XStatus := Status.IStatus.Index;
      if Roster.OwnerUser.XStatus = 0 then
        vk.QueryValueSet(666, XSTATUS_KEY)
      else
        vk.QueryValueSet(Roster.OwnerUser.XStatus, XSTATUS_KEY);
    end;
    Status.Visible := False;
  end;

begin
  Result := False;
  case Event.ID of
    etKeyDown :
      if Control.ID = EDIT_STATUS then
        case Event.Key.Value of
          13 :
            begin
              Result := True;
              Accept;
            end;
          27 : Status.Visible := False;
        end;
    etClick :
      with TButton(Control) do
        case Control.ID of
          BTN_ACCEPT : Accept;
          BTN_CANCEL : Status.Visible := False;
        end;
  end;
end;

constructor TStatusFrame.Create;
const
  COLS  = 14;
  COUNT = 92;
var
  Button : TButton;
begin
  inherited Create(Window);

  Frame := TFrame.Create(Self);
  Frame.Color  := POPUP_WINDOW;
  Frame.Border := POPUP_BORDER;
  Frame.Move(0, 0, -1, -1);

  EStatus := TEdit.Create(Frame);
  EStatus.Dereturn  := True;
  EStatus.HoldFocus := True;
  EStatus.Move(8, 8, -17, 50);
  EStatus.ID := EDIT_STATUS;
  EStatus.EventProc := TEventProc(@StatusProc);

  IStatus := TImageList.Create(Frame);
  IStatus.Image := ImgMood;
  IStatus.Cols  := COLS;
  IStatus.Count := COUNT;
  IStatus.Index := 1;
  IStatus.Over  := 3;
  IStatus.ImageText := @StatusImageText;
  IStatus.Move(8, 64, COLS * 20 + 8, (COUNT div COLS + 1) * 20 + 8 + 24);

  Button := TButton.Create(IStatus, nil, -1);
  Button.Text := LangMsg[lmCancel];
  Button.Move(-45 - 3, -20, 48, 20);
  Button.ID := BTN_CANCEL;
  Button.EventProc := TEventProc(@StatusProc);

  Button := TButton.Create(IStatus, nil, -1);
  Button.Text := LangMsg[lmOK];
  Button.Font := Font_Tahoma_11b;
  Button.Move(-64 - 24, -20, 32, 20);
  Button.ID := BTN_ACCEPT;
  Button.EventProc := TEventProc(@StatusProc);

  Move(0, 0, IStatus.Width + 21, EStatus.Height + IStatus.Height + 24);
end;

procedure TStatusFrame.SetVisible(const Value: Boolean);
begin
  inherited;
  if Value then
  begin
    Status.EStatus.Text  := Roster.OwnerUser.StatusMsg;
    Status.IStatus.Index := Roster.OwnerUser.XStatus;
    Status.Focus := Status.EStatus;
    Fore;
  end else
    Roster.GetSelected;
end;

procedure TStatusFrame.StatusGet(User: TUser);
var
  Code : WideString;
begin
//  vk.Query([Param('uid', User.UID)], 'status.get', Integer(User), @OnStatus);

  code := 'return {s:API.status.get({uid:' + User.UID + '}),x:API.getVariable({key:1300,user_id:' + User.UID + '})};';
  vk.Query([Param('code', Code)], 'execute', Integer(User), @OnStatus);
end;

procedure TStatusFrame.StatusSet(const Text: WideString);
begin
  vk.Query([Param('text', CharToSpec(Text))], 'status.set', 0, nil, True);
end;

procedure TStatusFrame.StatusAudioSet(const AudioID: WideString);
begin
  vk.Query([Param('audio', AudioID)], 'status.set', 0, nil, True);
end;

{
procedure TStatusFrame.Update;
const
  NORMAL_IDLE = 8 * 60 * 1000;
  SELECT_IDLE = 4 * 60 * 1000;
var
  i : LongInt;
  Time : LongWord;
begin
  Time := GetTime;
  Roster.Lock;
  with Roster do
    for i := 0 to Length(Users) - 1 do
      with Users[i] do
        if Online and ((Time - XStatusTime > NORMAL_IDLE) or (Select and (Time - XStatusTime > SELECT_IDLE))) then
          Query(Users[i]);
  Roster.Unlock;
end;
}
procedure TStatusFrame.Update;
begin
end;

procedure TStatusFrame.FirstCheck;
begin
  vk.QueryValueGet(XSTATUS_KEY, Roster.OwnerUser, @OnFirstCheck);
end;

end.
