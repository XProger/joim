unit jroster;

interface

uses
  jsys, jutils, jhash, jimg, jctrl, jxml;

const
  ROSTER_VERSION     = 8;

  AVATAR_CACHE       = 16;
  AVATAR_AREA_ICON   = 20;
  AVATAR_AREA_IMAGE  = 50;
  AVATAR_UPDATE_TIME = 1 * 60 * 1000; // request invalid avatar time
  STATUS_UPDATE_TIME = 4 * 60 * 1000;
  GROUP_ID_ACTIVE  = '+';
  GROUP_ID_GENERAL = '-';
  GROUP_ID_SEARCH  = '*';

type
  TAvatarSize = record
    Width, Height : LongInt;
  end;

  TAvatar = class
    destructor Destroy; override;
  private
    FLink : WideString;
    procedure Push;
    procedure SetLink(const Value: WideString);
  public
    Query : LongWord;
    Image : TImage;
    Icon  : TImage;
    function LoadIcon: Boolean;
    function LoadImage: Boolean;
    class function Save(const SLink: WideString; Data: Pointer; Size: LongInt): Boolean;
    property Link: WideString read FLink write SetLink;
  end;

  TUserState = (usNone, usMessage, usTyping);

  TGroup = class;

  TUser = class
    constructor Create;
    destructor Destroy; override;
  private
    FOnline    : Boolean;
    FStatusMsg : WideString;
    StatusTime : LongWord;
    FState : TUserState;
    FXStatus : LongInt;
    procedure SetOnline(const Value: Boolean);
    procedure SetStatusMsg(const Value: WideString);
    procedure SetState(Value: TUserState);
    procedure SetXStatus(const Value: LongInt);
  public
    JoimUser : Boolean;
    Blink    : Boolean;
    UID     : WideString;
    Name    : WideString;
    CityID  : LongInt;
    City    : WideString;
    BDate   : WideString;
    HPhone  : WideString;
    MPhone  : WideString;
    Avatar  : TAvatar;

    Active  : Boolean;
    Hover   : Boolean;
    Select  : Boolean;
    Tab     : Boolean;

    function StateIcon(ShowOffline: Boolean = False): TIcon;
    function StatusImage(out Index: LongInt; ShowOffline: Boolean = False): TImage;
    procedure QueryStatusMsg;
    function Visible(Group: TGroup): Boolean;
    procedure DrawAvatar(Canvas: TCanvas; X, Y: LongInt; Big: Boolean; Alpha: Byte = 255);
    procedure Draw(Canvas: TCanvas; var Rect: TRect);
    property Online: Boolean read FOnline write SetOnline;
    property StatusMsg: WideString read FStatusMsg write SetStatusMsg;
    property State: TUserState read FState write SetState;
    property XStatus: LongInt read FXStatus write SetXStatus;
  end;

  TUserArray = array of TUser;

  TGroup = class
  public
    GID   : WideString;
    Name   : WideString;
    Users  : TUserArray;
    Folded : Boolean;
    Filter : Boolean;
    function Add(User: TUser): LongInt;
    procedure Del(User: TUser);
    procedure Sort;
    procedure Draw(Canvas: TCanvas; var Rect: TRect);
  end;
{
  TRosterPopupMenu = class(TPopupMenu)
    constructor Create(ParentWindow: TWindow);
  protected
    procedure SetVisible(const Value: Boolean); override;
  public
    GroupSelect : TGroup;
    GroupOver   : TGroup;
    GroupEdit   : TEdit;
    function OnEvent(const Event: TControlEvent): Boolean; override;
  end;
}
  TRosterTools = class(TControl)
    constructor Create(Parent: TControl);
  public
    StatusBtn : TButton;
  end;

  TRoster = class(TScrollBox)
    constructor Create(Parent: TControl);
    destructor Destroy; override;
  private
    CS : TCriticalSection;
    TimerBlink : LongWord;
    QueryBuf  : WideString;
    QuerySave : Boolean;
    FOnline : Boolean;
    BorderBlink : Boolean;
    procedure SetOnline(Value: Boolean);
  public
    OwnerUser : TUser;
    Users : array of TUser;
//    PopupMenu : TRosterPopupMenu;
    Selected : TUserArray;
    Groups   : array of TGroup;
    CurGroup : TGroup;
    Unread   : Boolean;
    procedure Lock;
    procedure Unlock;
    procedure LoadInfo;
    procedure SaveQuery;
    procedure SaveFlush;
    procedure InfoQuery(const UID: WideString);
    procedure InfoFlush;
    procedure Clear;
    procedure ClearEmpty;
    function UnHover: Boolean;
    function UnSelect: Boolean;
    function OnEvent(const Event: TControlEvent): Boolean; override;
    procedure Sort;
    procedure UpdateRange; override;    
    function AddGroup(const GID: WideString): TGroup;
    function AddUser(const UID: WideString): TUser; overload;
    function AddUser(XML: TXML): TUser; overload;
    function GetUserByUID(const UID: WideString; CreateNew: Boolean): TUser;
    function GetGroupByGID(const GID: WideString; CreateNew: Boolean): TGroup;
    function GetSelected: TUserArray;
    procedure Activate(User: TUser; RecvMsg: Boolean = True);
    procedure ResetIcon;
    procedure SelectUser(User: TUser);
    procedure NextActive;
    procedure Update;
    property Online: Boolean read FOnline write SetOnline;
  end;

var
  Avatars : array [0..AVATAR_CACHE - 1] of TAvatar;

implementation

uses
  jglobal, jvk, jmedia;

const
  BTN_PAGE   = 0;
  BTN_MEDIA  = 1;
  BTN_STATUS = 2;


{$REGION 'Query Events'}
procedure OnImage(User: TUser; const Header: AnsiString; const Content: WideString; Data, RawData: Pointer; RawSize: LongInt);
begin
  if RawData <> nil then
  begin
    {$IFDEF DEBUG}
      Writeln('-- ava: ', User.Avatar.Link);
    {$ENDIF}
    if TAvatar.Save(User.Avatar.Link, RawData, RawSize) then
    begin
      User.Avatar.Query := 0;
      Roster.Repaint;
      Info.CheckRepaint(User);
    end;
  end;
end;

procedure OnCity(ID: Integer; XML: TXML);
var
  i : LongInt;

  procedure SetCity(Index: LongInt; const Value: WideString);
  var
    i : LongInt;
  begin
    for i := 0 to Length(Roster.Users) - 1 do
      with Roster.Users[i] do
        if (CityID = Index) and (City = '') then
          City := Value;
  end;

begin
  if XML = nil then Exit;
  Roster.Lock;
  for i := 0 to XML.Count - 1 do
    with XML.NodeI[i] do
      if Tag = 'city' then
        SetCity(Conv(Node['cid'].Content, 0), Node['name'].Content);
  Roster.Unlock;
end;

procedure OnInfo(ID: Integer; XML: TXML);
var
  i, c : LongInt;
  User : TUser;
  NXML : TXML;
  CityArr : array of LongInt;
  CityStr : WideString;

  procedure AddCity(City: LongInt);
  var
    i : LongInt;
  begin
    for i := 0 to Length(CityArr) - 1 do
      if CityArr[i] = City then
        Exit;
    SetLength(CityArr, Length(CityArr) + 1);
    CityArr[Length(CityArr) - 1] := City;
    if CityStr <> '' then
      CityStr := CityStr + ',';
    CityStr := CityStr + Conv(City);
  end;

begin
  if XML = nil then Exit;
  CityArr := nil;
  CityStr := '';

  for i := 0 to XML.Count - 1 do
    with XML.NodeI[i] do
    begin
      NXML := Node['uid'];
      if NXML = nil then
        continue;

      User := Roster.GetUserByUID(NXML.Content, False);
      if User = nil then
      begin
        if Roster.OwnerUser.UID = NXML.Content then
          User := Roster.OwnerUser
        else
          continue;
      end;
    // name
      User.Name := Node['first_name'].Content + ' ' + Node['last_name'].Content;
      if User.uid = vk.mid then
        User.Name := User.Name;
    // city
      if Node['city'] <> nil then
      begin
        c := Conv(Node['city'].Content, -1);
        if c = 0 then
          c := -1;
        if User.CityID <> c then
        begin
          User.CityID := c;
          User.City := '';
          if c > 0 then
            AddCity(c);
        end;
      end;
    // birth date, phone
      User.BDate  := Value['bdate'];
      User.HPhone := Value['home_phone'];
      User.MPhone := Value['mobile_phone'];
    // avatar
      NXML := Node['photo_rec'];
      if NXML <> nil then
      begin
        User.Avatar.Link := NXML.Content;
        if User.Avatar.Query <> 0 then
          HTTP.QueryImage(User.Avatar.Link, LongInt(User), @OnImage);
      end;
    end;

// get cities
  if CityStr <> '' then
    vk.Query([Param('cids', CityStr)], 'getCities', 0, @OnCity, True);

  Roster.SaveQuery;
end;
{$ENDREGION}

{$REGION 'TAvatar'}
destructor TAvatar.Destroy;
begin
  if Icon <> nil then
    Icon.Free;
  if Image <> nil then
    Image.Free;
  inherited;
end;

procedure TAvatar.Push;
var
  i, idx : LongInt;
begin
  idx := AVATAR_CACHE - 1;
// push avatar to cache
  for i := 0 to AVATAR_CACHE - 1 do
    if Avatars[i] = Self then
    begin
      idx := i;
      break;
    end;
// free "old" image
  if idx = AVATAR_CACHE - 1 then
    if Avatars[AVATAR_CACHE - 1] <> nil then
      with Avatars[AVATAR_CACHE - 1] do
        if Image <> nil then
        begin
          Image.Free;
          Image := nil;
        end;
// stack move
  for i := idx downto 1 do
    Avatars[i] := Avatars[i - 1];
  Avatars[0] := Self;
end;

procedure TAvatar.SetLink(const Value: WideString);
begin
  if FLink <> Value then
  begin
    FLink := Value;
    if Icon <> nil then
      Icon.Free;
    if Image <> nil then
      Image.Free;
    Icon  := nil;
    Image := nil;
    Roster.Repaint;
    Info.Repaint;
  end;
end;

function TAvatar.LoadIcon: Boolean;
var
  FStream : TFileStream;
  ImgData : PByteArray;
  Size    : TAvatarSize;
begin
  Result := True;
  if Icon <> nil then
    Exit;
  Result := False;
  if Link = '' then
    Exit;
  FStream := TFileStream.Create(RootDir + 'avatar/' + ConvSURL(Link));
  if FStream.Valid then
  begin
    FStream.Read(Size, SizeOf(Size));
    ImgData := GetMemory(Size.Width * Size.Height * 4);
    FStream.Read(ImgData^, Size.Width * Size.Height * 4);
    Icon := TImage.Create(ImgData, Size.Width, Size.Height);
    FreeMemory(ImgData);
    Result := True;
  end;
  FStream.Free;
end;

function TAvatar.LoadImage: Boolean;
var
  FStream : TFileStream;
  ImgData : PByteArray;
  Size    : TAvatarSize;
begin
  Push;
  Result := True;
  if Image <> nil then
    Exit;
  Result := False;
  if Link = '' then
    Exit;
  FStream := TFileStream.Create(RootDir + 'avatar/' + ConvSURL(Link));
  if FStream.Valid then
  begin
  // load icon
    FStream.Read(Size, SizeOf(Size));
    FStream.Position := FStream.Position + Size.Width * Size.Height * 4;
  // load image
    FStream.Read(Size, SizeOf(Size));
    ImgData := GetMemory(Size.Width * Size.Height * 4);
    FStream.Read(ImgData^, Size.Width * Size.Height * 4);
    Image := TImage.Create(ImgData, Size.Width, Size.Height);
    FreeMemory(ImgData);
    Result := True;
  end;
  FStream.Free;
end;

class function TAvatar.Save(const SLink: WideString; Data: Pointer; Size: LongInt): Boolean;
var
  MStream : TMemoryStream;
  FStream : TFileStream;
  ImgData, p : PByteArray;
  Width, Height, w, h : LongInt;
begin
  Result := False;
  CheckFolders;

  MStream := TMemoryStream.Create(Data, Size);
  if LoadIMG(MStream, ImgData, Width, Height) then
  begin
    FStream := TFileStream.Create(RootDir + 'avatar/' + ConvSURL(SLink), fmWrite);
    if FStream.Valid then
    begin
    // resample to icon
      if Width > Height then
      begin
        w := ROSTER_ICON_SIZE;
        h := Round(ROSTER_ICON_SIZE * (Height / Width));
      end else
      begin
        w := Round(ROSTER_ICON_SIZE * (Width / Height));
        h := ROSTER_ICON_SIZE;
      end;
      ResampleIMG(ImgData, Width, Height, p, w, h);
    // save icon
      FStream.WriteInt32(w);
      FStream.WriteInt32(h);
      FStream.Write(p^, w * h * 4);
      FreeMemory(p);
    // resample to standart image
      if Width > Height then
      begin
        w := INFO_AVATAR_SIZE;
        h := Round(INFO_AVATAR_SIZE * (Height / Width));
      end else
      begin
        w := Round(INFO_AVATAR_SIZE * (Width / Height));
        h := INFO_AVATAR_SIZE;
      end;
      ResampleIMG(ImgData, Width, Height, p, w, h);
    // save icon
      FStream.WriteInt32(w);
      FStream.WriteInt32(h);
      FStream.Write(p^, w * h * 4);
      FreeMemory(p);
      Result := True;
    end;
    FreeMemory(ImgData);
    FStream.Free;
  end;
  MStream.Free;
end;
{$ENDREGION}

{$REGION 'TUser'}
constructor TUser.Create;
begin
  Avatar := TAvatar.Create;
end;

destructor TUser.Destroy;
begin
  Avatar.Free;
  inherited;
end;

procedure TUser.SetOnline(const Value: Boolean);
begin
  if Value <> FOnline then
  begin
//    if Value then
//      jglobal.Status.Query(Self);
    FOnline := Value;
    Roster.Sort;
    Info.CheckRepaint(Self);
    Roster.UpdateRange;
    Roster.Repaint;
  end;
end;

procedure TUser.SetStatusMsg(const Value: WideString);
begin
  if Value <> FStatusMsg then
  begin
    FStatusMsg := SpecToChar(Value);
    Info.CheckRepaint(Self);
    Roster.Repaint;
  end;
end;

procedure TUser.SetState(Value: TUserState);
var
  i : LongInt;
  Flag : Boolean;
begin
  if (Value = usMessage) and (Select) and (Length(Roster.Selected) = 1) and (Window.IsFore) and (not MFrame.Visible) then
    Value := usNone;

  if (FState = Value) or ((FState = usMessage) and (Value = usTyping)) then
    Exit;

  FState := Value;

// check users for messages
  with Roster do
  begin
    Lock;
    Flag := False;
    for i := 0 to Length(Users) - 1 do
      if Users[i].State = usMessage then
      begin
        Flag := True;
        break;
      end;
    Unlock;
  end;
// set state & app icon
  AppWindow.TrayBlink := Flag;

  case FState of
    usNone    : if not Flag then Roster.ResetIcon;
    usMessage :
      begin
        AppWindow.Icon := Icon[itMessage];
        AppWindow.Flashing := not Window.IsFore;
      end;
    usTyping  : if not Flag then AppWindow.Icon := Icon[itTyping];
  end;

  Roster.Repaint;
  Info.CheckRepaint(Self);
end;

procedure TUser.SetXStatus(const Value: LongInt);
begin
  if Value <> FXStatus then
  begin
    JoimUser := True;

    FXStatus := Value;
    if FXStatus = 666 then
      FXStatus := 0;

    Roster.Repaint;
    Info.CheckRepaint(Self);
    if Self = Roster.OwnerUser then
      if XStatus <= 0 then
      begin
        RTools.StatusBtn.ImageIdx := 0;
        RTools.StatusBtn.Image    := Icon[itOnline].Small;
      end else
      begin
        RTools.StatusBtn.ImageIdx := XStatus - 1;
        RTools.StatusBtn.Image    := ImgMood;
      end;
    Roster.SaveQuery;
  end;
end;

function TUser.StateIcon(ShowOffline: Boolean): TIcon;
begin
  Result := nil;
  if State = usMessage then
  begin
    if Blink then
      Result := Icon[itMessage].Small;
  end else
    if ShowOffline and (not Online) then
      Result := Icon[itOffline].Small
    else
      if State = usTyping then
        Result := Icon[itTyping].Small
      else
        if Online then
          Result := Icon[itOnline].Small;
end;

function TUser.StatusImage(out Index: LongInt; ShowOffline: Boolean): TImage;
begin
  Index  := 0;
  Result := StateIcon(ShowOffline);
  if (Result <> nil) and (Result = Icon[itOnline].Small) and (XStatus > 0) then
  begin
    Index  := XStatus - 1;
    Result := ImgMood;
  end;
end;

procedure TUser.QueryStatusMsg;
var
  Time : LongWord;
begin
  Time := GetTime;
  if (Time < StatusTime) or (Time - StatusTime >= STATUS_UPDATE_TIME) then
  begin
    Status.StatusGet(Self);
    StatusTime := Time;
  end;
end;

function TUser.Visible(Group: TGroup): Boolean;
begin
  if Tab and (Group <> Roster.Groups[0]) then
    Result := not Group.Filter
  else
    Result := Online or (not Group.Filter) or Select;
end;

procedure TUser.DrawAvatar(Canvas: TCanvas; X, Y: LongInt; Big: Boolean; Alpha: Byte = 255);
var
  Flag : Boolean;

  procedure GetAvatar;
  begin
    if Avatar.Query = 0 then
    begin
      Avatar.Query := GetTime;
      if Avatar.Link <> '' then
        HTTP.QueryImage(Avatar.Link, LongInt(Self), @OnImage)
      else
        Roster.InfoQuery(UID);
    end;
  end;

begin
  if Avatar.Query <> 0 then
    if GetTime - Avatar.Query > AVATAR_UPDATE_TIME * 1000 then
      Avatar.Query := 0
    else
      Exit;

  Flag := True;
  with Avatar do
    if Big then
    begin
      if Image = nil then
        Flag := LoadImage;
      if Flag then
        Image.Draw(Canvas, X, Y, AVATAR_AREA_IMAGE, AVATAR_AREA_IMAGE, Alpha);
    end else
    begin
      if Icon = nil then
        Flag := LoadIcon;
      if Flag then      
        Icon.Draw(Canvas, X, Y, AVATAR_AREA_ICON, AVATAR_AREA_ICON, Alpha)
    end;

  if not Flag then
    GetAvatar;
end;

procedure TUser.Draw(Canvas: TCanvas; var Rect: TRect);
var
  IRect, HRect : TRect;
  Icon : TImage;
  IconIdx : LongInt;

  function MoodRect(Index: LongInt): TRect;
  begin
    Result.Left := (Index - 100) mod 8 * 16;
    Result.Top  := (Index - 100) div 8 * 16;
    Result.Right  := Result.Left + 16;
    Result.Bottom := Result.Top + 16;
  end;

begin
  if (Rect.Top > Canvas.PaintRect.Bottom) or
     (Rect.Top + ROSTER_SIZE_CONTACT < Canvas.PaintRect.Top) then
  begin
    Inc(Rect.Top, ROSTER_SIZE_CONTACT);
    Exit;
  end;

  with Rect do
    HRect := SetRect(Left, Top, Right - 1, Top + ROSTER_SIZE_CONTACT);

  if State = usMessage then
  begin
    Canvas.BrushColor := ROSTER_CONTACT_OVER;
    Canvas.TextColor  := ROSTER_CONTACT_OVER_TEXT;
    Canvas.FillRect(HRect);
  end else
    if Active then
    begin
      Canvas.BrushColor := ROSTER_CONTACT_ACTIVE;
      Canvas.TextColor  := ROSTER_CONTACT_ACTIVE_TEXT;
    end else
      if Select then
      begin
        Canvas.BrushColor := ROSTER_CONTACT_SELECT;
        Canvas.TextColor  := ROSTER_CONTACT_SELECT_TEXT;
        Canvas.FillRect(HRect);
      end else
        if Hover then
        begin
          Canvas.BrushColor := ROSTER_CONTACT_OVER;
          Canvas.TextColor  := ROSTER_CONTACT_OVER_TEXT;
          Canvas.FillRect(HRect);
        end else
          Canvas.TextColor  := ROSTER_CONTACT_TEXT;

  if (not Online) and (not Select) and (not Hover) then
    Canvas.TextColor := $AAAAAA;

  Canvas.Font := Font_Tahoma_13;
  Canvas.TextOut(HRect.Left + 28, HRect.Top + 5, Name);

  with HRect do
    IRect := SetRectSize(Left + 3, Top + 3, ROSTER_ICON_SIZE, ROSTER_ICON_SIZE);

  if Online or Select or Hover then
    DrawAvatar(Canvas, IRect.Left, IRect.Top, False)
  else
  begin
    DrawAvatar(Canvas, IRect.Left, IRect.Top, False, 128);
    ImgFilter.Draw(Canvas, IRect.Left, IRect.Top, 20, 20, 32);
  end;

  Canvas.PenColor := ROSTER_CONTACT_AVATAR_BORDER;
  with IRect do
    Canvas.FrameRect(SetRect(Left - 1, Top - 1, Right + 1, Bottom + 1));

  with HRect do
    IRect := SetRect(Right - 22, Top + 5, Right - 2, Top + 18);

  Icon := StatusImage(IconIdx);
  if (Icon <> nil) and (Icon <> jglobal.Icon[itOnline].Small)  then
    Icon.DrawFrame(Canvas, IRect.Left, IRect.Top, IconIdx, 16);

  Inc(Rect.Top, ROSTER_SIZE_CONTACT);
end;
{$ENDREGION}

{$REGION 'TGroup'}
function TGroup.Add(User: TUser): LongInt;
var
  i : LongInt;
begin
  for i := 0 to Length(Users) - 1 do
    if Users[i] = User then
    begin
      Result := i;
      Exit;
    end;
  Result := Length(Users);
  SetLength(Users, Result + 1);
  Users[Result] := User;
end;

procedure TGroup.Del(User: TUser);
var
  i, j : LongInt;
begin
  for i := 0 to Length(Users) - 1 do
    if Users[i] = User then
    begin
      for j := i to Length(Users) - 2 do
        Users[j] := Users[j + 1];
      SetLength(Users, Length(Users) - 1);
      if GID = GROUP_ID_ACTIVE then
        User.Tab := False;
      break;
    end;
end;

function UserCompare(Item1, Item2: Pointer): LongInt;
var
  u1 : TUser absolute Item1;
  u2 : TUser absolute Item2;
begin
 if u1.Online > u2.Online then
   Result := -1
 else
   if u1.Online < u2.Online then
     Result := +1
   else
     if u1.Name < u2.Name then
       Result := -1
     else
       if u1.Name > u2.Name then
         Result := +1
       else
         Result := 0;
end;

procedure TGroup.Sort;
begin
  if (Roster <> nil) and Roster.FUpdate then
    Exit;
  if Length(Users) > 1 then
    QSort(@Users[0], 0, Length(Users) - 1, @UserCompare);
end;

procedure TGroup.Draw(Canvas: TCanvas; var Rect: TRect);
var
  i, dx : LongInt;
  HRect : TRect;
  Str : WideString;
begin
  if (Rect.Top > Canvas.PaintRect.Bottom) or (Length(Users) = 0) then
    Exit;

  if Self = Roster.Groups[0] then
  begin
    Filter := False;
    Folded := False;
  end;

  with Rect do
    HRect := SetRect(Left, Top, Right - 1, Top + ROSTER_SIZE_GROUP);

  if (Self = Roster.Groups[0]) and Roster.Unread then
  begin
    Canvas.BrushColor := $86E1FF;
    Canvas.PenColor   := $9ECFD7;
    Canvas.TextColor  := $296069;
  end else
    if Folded then
    begin
      Canvas.PenColor   := ROSTER_GROUP_FOLD_BORDER;
      Canvas.BrushColor := ROSTER_GROUP_FOLD;
      Canvas.TextColor  := ROSTER_GROUP_FOLD_TEXT;
    end else
    begin
      Canvas.PenColor   := ROSTER_GROUP_BORDER;
      Canvas.BrushColor := ROSTER_GROUP;
      Canvas.TextColor  := ROSTER_GROUP_TEXT;
    end;
  Canvas.FillRect(HRect);
  Canvas.Line(HRect.Left, HRect.Top, HRect.Right, HRect.Top);

  if Self <> Roster.Groups[0] then
    ImgBase.DrawFrame(Canvas, HRect.Left + 3, HRect.Top + 2, 2 + Ord(Folded), 16);

  if Name = '' then
    Str := LangMsg[lmGroupDefault]
  else
    Str := Name;
  Canvas.Font := Font_Tahoma_11b;

  if Self = Roster.Groups[0] then
    dx := ((HRect.Right - HRect.Left) - Canvas.TextWidth(PWideChar(Str), Length(Str))) div 2
  else
    dx := 22;

  Canvas.TextOut(HRect.Left + dx, HRect.Top + 4, Str);

  Inc(Rect.Top, ROSTER_SIZE_GROUP);

  if not Folded then
    for i := 0 to Length(Users) - 1 do
      if Users[i].Visible(Self) then
        Users[i].Draw(Canvas, Rect);

  Inc(Rect.Top, ROSTER_SIZE_SEPARATOR);
end;
{$ENDREGION}

{$REGION 'TRosterPopupMenu'}
(*
function GroupEditEvent(Control: TEdit; const Event: TControlEvent): Boolean;
begin
  Result := False;
  if Event.ID = etKeyUp  then
    case Event.Key.Value of
      VK_RETURN :
        if Trim(Control.Text) <> '' then
        begin
          Roster.MoveToGroup(Roster.AddGroup(Trim(Control.Text)), Roster.Selected);
          Control.CParent.Visible := False;
        end;
      VK_ESCAPE :
        Control.CParent.Visible := False;
    end;
end;

constructor TRosterPopupMenu.Create(ParentWindow: TWindow);
begin
  inherited;
  GroupEdit := TEdit.Create(Self);
  GroupEdit.Move(8, 8, -9, POPUP_SIZE_ITEM);
  GroupEdit.WordWrap := False;
  GroupEdit.EventProc := TEventProc(@GroupEditEvent);
  GroupEdit.HoldFocus := True;
end;

procedure TRosterPopupMenu.SetVisible(const Value: Boolean);
var
  i, w, h : LongInt;
begin
  if Value then
  begin
    if Window.HintWnd <> nil then
      Window.HintWnd.Visible := False;

    w := 32;

    DCanvas.Lock;
    DCanvas.Font := Font_Tahoma_13;
    w := Max(w, DCanvas.TextWidth(PWideChar(LangMsg[lmGroupDefault]), Length(LangMsg[lmGroupDefault])));
    for i := 2 to Length(Roster.Groups) - 1 do
      with Roster.Groups[i] do
        w := Max(w, DCanvas.TextWidth(PWideChar(Name), Length(Name)));
    DCanvas.Unlock;

    w := Max(128, 8 + 4 + w + 4 + 8);
    if GroupSelect <> nil then
      h := 8 + POPUP_SIZE_ITEM + 8 + POPUP_SIZE_ITEM + 8 + (Length(Roster.Groups) - 2) * POPUP_SIZE_ITEM + 8
    else
      h := 8 + POPUP_SIZE_ITEM + 8 + (Length(Roster.Groups) - 1) * POPUP_SIZE_ITEM + 8;
    Move(0, 0, w, h);
    GroupEdit.Text := '';
    Focus := GroupEdit;
  end;
  inherited;

  if Value then
    Fore;
end;

function TRosterPopupMenu.OnEvent(const Event: TControlEvent): Boolean;
var
  i : LongInt;
  HRect, BRect : TRect;
  OldOver : TGroup;

  procedure DrawItem(Y: LongInt; CWindow, CBorder, CText: TColor; const Text: WideString);
  var
    Rect : TRect;
  begin
    with ARect do
      Rect := SetRect(8, Y, Right - 8, Y + POPUP_SIZE_ITEM);
    if CWindow <> POPUP_WINDOW then
    begin
      Canvas.BrushColor := CWindow;
      Canvas.FillRect(Rect);
    end;
    if CBorder <> CWindow then
    begin
      Canvas.PenColor   := CBorder;
      Canvas.FrameRect(Rect);
    end;
    Canvas.TextColor := CText;
    if Text = '' then
      Canvas.TextOut(Rect.Left + 4, Rect.Top + 2, LangMsg[lmGroupDefault])
    else
      Canvas.TextOut(Rect.Left + 4, Rect.Top + 2, Text);
  end;

begin
  case Event.ID of
    etMouseMove :
      with Event.Mouse do
      begin
        OldOver := GroupOver;
        GroupOver := nil;

        if GroupSelect <> nil then
          HRect := SetRect(8, 8 + POPUP_SIZE_ITEM + 8 + POPUP_SIZE_ITEM + 8, Width - 8, 0)
        else
          HRect := SetRect(8, 8 + POPUP_SIZE_ITEM + 8, Width - 8, 0);
        HRect.Bottom := HRect.Top + POPUP_SIZE_ITEM;

        for i := 1 to Length(Roster.Groups) - 1 do
          if Roster.Groups[i] <> GroupSelect then
            if RectIntersect(HRect, Pos.x, Pos.y) then
            begin
              GroupOver := Roster.Groups[i];
              break;
            end else
            begin
              Inc(HRect.Top, POPUP_SIZE_ITEM);
              Inc(HRect.Bottom, POPUP_SIZE_ITEM);
            end;
        if GroupOver <> OldOver then
          Repaint;
      end;
    etMouseUp :
      if GroupOver <> nil then
      begin
        Roster.MoveToGroup(GroupOver, Roster.Selected);
        Visible := False;
      end;
    etDraw :
      with Event.Draw do
      begin
        Canvas.BrushColor := POPUP_WINDOW;
        Canvas.PenColor   := POPUP_BORDER;
        Canvas.FillRect(ARect);
        Canvas.FrameRect(ARect);

        Canvas.TextColor := POPUP_TEXT;
        Canvas.Font      := Font_Tahoma_13;
      // selected group
        if GroupSelect <> nil then
        begin
          DrawItem(8 + POPUP_SIZE_ITEM + 8, POPUP_SELECT, POPUP_SELECT_BORDER, POPUP_SELECT_TEXT, GroupSelect.Name);
          HRect := SetRect(8, 8 + POPUP_SIZE_ITEM + 8 + POPUP_SIZE_ITEM + 8, Width - 8, 0);
        end else
          HRect := SetRect(8, 8 + POPUP_SIZE_ITEM + 8, Width - 8, 0);
        HRect.Bottom := HRect.Top + POPUP_SIZE_ITEM;
      // separator
        Canvas.PenColor := POPUP_SEPARATOR;
        with HRect do
          Canvas.Line(Left, Top - 4, Right, Top - 4);
      // over & other group items
        for i := 1 to Length(Roster.Groups) - 1 do
        begin
          BRect := HRect;
          Dec(BRect.Bottom);
          if Roster.Groups[i] = GroupSelect then
            continue
          else
            if Roster.Groups[i] = GroupOver then
              DrawItem(HRect.Top, POPUP_OVER, POPUP_OVER_BORDER, POPUP_OVER_TEXT, Roster.Groups[i].Name)
            else
              DrawItem(HRect.Top, POPUP_WINDOW, POPUP_WINDOW, POPUP_TEXT, Roster.Groups[i].Name);

          Inc(HRect.Top, POPUP_SIZE_ITEM);
          Inc(HRect.Bottom, POPUP_SIZE_ITEM);
        end;
      end;
  end;
  Result := inherited OnEvent(Event); // draw GroupEdit
end;
*)
{$ENDREGION}

{$REGION 'TRosterTools'}
function RToolsProc(Control: TControl; const Event: TControlEvent): Boolean;
begin
  Result := False;
  case Event.ID of
    etClick :
      with TButton(Control) do
        case Control.ID of
          BTN_PAGE   : BrowseURL(VK_URL + 'id' + Roster.OwnerUser.UID);
          BTN_MEDIA  :
            begin
              Media.PlayList := Player.List;
              MediaSwitch(mtAudio, Player.List.Name);
            end;
          BTN_STATUS :
            begin
              Status.Move(ARect.Left + Window.ScreenRect.Left, ARect.Top + Window.ScreenRect.Top, Status.Width, Status.Height);
              Status.Visible := True;
            end;
        end;
  end;
end;

constructor TRosterTools.Create(Parent: TControl);
begin
  inherited;
  CreateButton(Self,  6,  4, -27, BTN_PAGE,  TEventProc(@RToolsProc), lmHintMyPage);
  CreateButton(Self, 11, 28, -27, BTN_MEDIA, TEventProc(@RToolsProc), lmHintMedia);
  StatusBtn := CreateButton(Self, 0, 52, -27, BTN_STATUS, TEventProc(@RToolsProc), lmHintMyStatus);
  StatusBtn.Image := Icon[itOnline].Small;
  StatusBtn.MinAlpha := 255;
end;
{$ENDREGION}

{$REGION 'TRoster'}
procedure BlinkProc;
var
  i : LongInt;
  Flag : Boolean;
begin
  Flag := False;
  with Roster do
    for i := 0 to Length(Users) - 1 do
      with Users[i] do
        if State = usMessage then
        begin
          Blink := not Blink;
          Flag := True;
          Info.CheckRepaint(Users[i]);
        end;

// roster border blink
  if Flag or Roster.BorderBlink then
    Roster.BorderBlink := not Roster.BorderBlink;

  AppWindow.Flashing := Flag and (not Window.IsFore);

  if (Roster.Unread <> Flag) or Flag or Roster.BorderBlink then
  begin
    Roster.Unread := Flag;
    Roster.Repaint;
  end;
end;

constructor TRoster.Create(Parent: TControl);
begin
  inherited;
  CS.Init;

//  PopupMenu := TRosterPopupMenu.Create(Window);
//  PopupMenu.Move(0, 0, 196, 320);

  AddGroup(GROUP_ID_ACTIVE).Name  := LangMsg[lmGroupActive];
  AddGroup(GROUP_ID_GENERAL).Name := LangMsg[lmGroupDefault];
  AddGroup(GROUP_ID_SEARCH).Name  := LangMsg[lmGroupSearch];

  OwnerUser := AddUser('0');//TUser.Create;
  Groups[0].Add(OwnerUser);


  Groups[0].Filter := False;
  Groups[0].Folded := False;
  TimerBlink := InitTimer(500, @BlinkProc);
end;

destructor TRoster.Destroy;
begin
  FreeTimer(TimerBlink);
  Lock;
//  OwnerUser.Free;
//  PopupMenu.Free;
  Clear;
  Unlock;
  CS.Free;
  inherited;
end;

procedure TRoster.SetOnline(Value: Boolean);
var
  i : LongInt;
begin
  OwnerUser.online := Value;
  if FOnline <> Value then
  begin
    FOnline := Value;
    if not FOnline then
    begin
      BeginUpdate;
      Lock;
      for i := 0 to Length(Users) - 1 do
        Users[i].FOnline := False;
      Unlock;
      EndUpdate;
      Sort;
    end;
    ResetIcon;
    Repaint;
  end;
end;

procedure TRoster.Lock;
begin
  CS.Lock;
end;

procedure TRoster.Unlock;
begin
  CS.Unlock;
end;

procedure TRoster.LoadInfo;
var
  Stream : TFileStream;
  i, Count, Status : LongInt;
  UID : WideString;
  usr : TUser;
begin
  if (vk = nil) or (vk.mid = '') then
    Exit;

  Lock;
  Stream := TFileStream.Create(RootDir + vk.mid + '.lst');
  if Stream.Valid and (Stream.ReadInt32 = ROSTER_VERSION) then
  begin
    OwnerUser.XStatus := Stream.ReadInt32;
    Count := Stream.ReadInt32;
    for i := 0 to Count - 1 do
    begin
      UID    := Stream.ReadStr;
      Status := Stream.ReadInt32;
      usr := GetUserByUID(UID, False);
      if usr <> nil then
      begin
        usr.UID     := UID;
        usr.XStatus := Status;
      end;
    end;
  end;
  Stream.Free;
  Unlock;
end;

procedure TRoster.SaveQuery;
begin
  QuerySave := True;
end;

procedure TRoster.SaveFlush;
var
  i : LongInt;
  Stream : TFileStream;
begin
  if (not QuerySave) or (vk = nil) or (vk.mid = '') then
    Exit;
  CheckFolders;
  Lock;
  Stream := TFileStream.Create(RootDir + vk.mid + '.lst', fmWrite);
  if Stream.Valid then
  begin
    Stream.WriteInt32(ROSTER_VERSION);
    Stream.WriteInt32(OwnerUser.XStatus);
    Stream.WriteInt32(Length(Users)); // save count
    for i := 0 to Length(Users) - 1 do
      with Users[i] do
      begin
        Stream.WriteStr(UID);
        Stream.WriteInt32(XStatus);
      end;
  end;
  Stream.Free;
  Unlock;
  QuerySave := False;
end;

procedure TRoster.InfoQuery(const UID: WideString);
begin
  if QueryBuf = '' then
    QueryBuf := UID
  else
    QueryBuf := QueryBuf + ',' + UID;
end;

procedure TRoster.InfoFlush;
begin
  if QueryBuf <> '' then
  begin
    vk.QueryUsersInfo(QueryBuf, 'bdate,city,contacts,photo_rec', 0, @OnInfo);
    QueryBuf := '';
  end;
end;

procedure TRoster.Clear;
var
  i : LongInt;
begin
  Lock;
  for i := 0 to Length(Groups) - 1 do
    Groups[i].Free;
  for i := 0 to Length(Users) - 1 do
    Users[i].Free;
  Groups := nil;
  Users  := nil;
  Unlock;
  inherited;
end;

procedure TRoster.ClearEmpty;
var
  i, j : LongInt;
begin
  i := 2;
  Lock;
  while i < Length(Groups) do
    if Length(Groups[i].Users) = 0 then
    begin
      Groups[i].Free;
      for j := i to Length(Groups) - 2 do
        Groups[j] := Groups[j + 1];
      SetLength(Groups, Length(Groups) - 1);
    end else
      Inc(i);
  Unlock;
  UpdateRange;
end;

function TRoster.UnHover: Boolean;
var
  i : LongInt;
begin
  Result := False;
  Lock;
  for i := 0 to Length(Users) - 1 do
    with Users[i] do
    begin
      if Hover then
        Result := True;
      Hover := False;
    end;
  Unlock;
end;

function TRoster.UnSelect: Boolean;
var
  i : LongInt;
begin
  Result := False;
  Lock;
  for i := 0 to Length(Users) - 1 do
    with Users[i] do
    begin
      if Select then
        Result := True;
      Select := False;
    end;
  Selected := nil;
  Unlock;
end;

function TRoster.OnEvent(const Event: TControlEvent): Boolean;

  procedure GetGroupUser(X, Y: LongInt; out Group: TGroup; out User: TUser);
  var
    i, j, YPos : LongInt;
    HRect : TRect;
  begin
    Group := nil;
    User  := nil;
    with ARect do
      HRect := SetRect(Left + 1, Top + 1, Right - 1 - VScroll.Width, Bottom - 1);

    if not RectIntersect(HRect, X, Y) then
      Exit;

    YPos := HRect.Top + VScroll.Offset;
    for i := 0 to Length(Groups) - 1 do
      with Groups[i] do
        if Length(Users) > 0 then
          if (Y >= YPos) and (Y <= YPos + ROSTER_SIZE_GROUP) then
          begin
            Group := Groups[i];
            Exit;
          end else
          begin
            Inc(YPos, ROSTER_SIZE_GROUP);
            if not Folded then
              for j := 0 to Length(Users) - 1 do
                if Users[j].Visible(Groups[i]) then
                  if (Y >= YPos) and (Y <= YPos + ROSTER_SIZE_CONTACT) then
                  begin
                    User := Users[j];
                    Exit;
                  end else
                    Inc(YPos, ROSTER_SIZE_CONTACT);
            Inc(YPos, ROSTER_SIZE_SEPARATOR);
          end;
  end;

var
  i : LongInt;
  Flag  : Boolean;
  HRect : TRect;
  Group : TGroup;
  User  : TUser;
begin
  Result := False;
  if Event.ID = etMouseWheel then
    Result := inherited OnEvent(Event);
  Lock;
  case Event.ID of
    etMouseMove, etMouseUp, etMouseWheel :
      if not VScroll.MDrag then
      begin
        GetGroupUser(Event.Mouse.Pos.x, Event.Mouse.Pos.y, Group, User);

      // user info hint
        if (Event.ID in [etMouseWheel..etMouseMove]) and Window.Active and
           {(not PopupMenu.Visible) and} (not Status.Visible) then
          if User <> nil then
          begin
            if (Window.HintWnd <> InfoHint) or (not User.Hover) then
            begin
              if Window.HintWnd <> nil then
                Window.HintWnd.Visible := False;
              Window.HintWnd := InfoHint;
              Window.HintWnd.Tick := Window.HintWnd.Idle;
              Window.HintWnd.Target := Self;
              InfoHint.Thumb.User := User;
              Hint := User.Name;
            end;
          end else
            if Window.HintWnd = InfoHint then
            begin
              if Window.HintWnd <> nil then
                Window.HintWnd.Visible := False;
              Window.HintWnd := jglobal.Hint;
              Window.HintWnd.Tick   := Window.HintWnd.Idle;
              Window.HintWnd.Target := nil;
              Hint := '';
            end;

        if (Group <> nil) and (Group <> Groups[0]) then
          Cursor := ctHand
        else
          Cursor := ctArrow;

        if (Group <> nil) and (Group <> Groups[0]) then
          case Event.ID of
            etMouseUp :
              case Event.Mouse.Button of
                mbLeft :
                  begin
                    if Group.Folded then
                    begin
                      Group.Folded := False;
                      Group.Filter := False;
                    end else
                      Group.Filter := not Group.Filter;
                    UpdateRange;
                  end;
                mbRight :
                  begin
                    Group.Folded := not Group.Folded;
                    if Group.Folded then
                      Group.Filter := True;
                    UpdateRange;
                  end;
              end;
          end;

        if User <> nil then
          case Event.ID of
            etMouseMove, etMouseWheel :
              if not User.Hover then
              begin
                UnHover;
                User.Hover := True;
                Repaint;
              end;
            etMouseUp :
              begin
                if Window.HintWnd <> nil then
                  Window.HintWnd.Tick := -1;

                if User.State = usMessage then
                  Flag := False
                else
                  Flag := User.Select;

                if (Event.Mouse.Button = mbLeft) or
                  ((Event.Mouse.Button = mbRight) and (not Flag)) then
                begin
                  if not (ssCtrl in Event.Mouse.Shift) then
                    UnSelect;
                  User.Select := not Flag;
                  GetSelected;
                  UpdateRange;
                  if Selected = nil then
                    Window.Focus := Window
                  else
                    Window.Focus := Edit;
                  Repaint;
                end;
              {
              // popup menu
                if (Event.Mouse.Button = mbRight) and (Selected <> nil) then
                begin
                  PopupMenu.GroupOver   := nil;
                  PopupMenu.GroupSelect := Selected[0].Group;
                  for i := 1 to Length(Selected) - 1 do
                    if Selected[i].Group <> PopupMenu.GroupSelect then
                    begin
                      PopupMenu.GroupSelect := nil;
                      break;
                    end;
                  PopupMenu.Visible := True;
                end;
              }
              end;
        end else
          if UnHover then
            Repaint;
      end;
    etDraw :
      with Event.Draw do
      begin
        Canvas.BrushColor := ROSTER_WINDOW;
        if Roster.BorderBlink then
          Canvas.PenColor := EDIT_ACTIVE
        else
          Canvas.PenColor := ROSTER_BORDER;
        with ARect do
          HRect := SetRect(Left, Top, Right - VScroll.Width div 2, Bottom);
        Canvas.FillRect(HRect);
        Canvas.FrameRect(HRect);
        with ARect do
          HRect := SetRect(Left + 1, Top + 1, Right - VScroll.Width div 2, Bottom - 1);
        Canvas.ClipInit(HRect);
        Inc(HRect.Top, VScroll.Offset - 1);
        Inc(HRect.Bottom, VScroll.Offset);
        for i := 0 to Length(Groups) - 1 do
          Groups[i].Draw(Canvas, HRect);
        Canvas.ClipFree;
      end;
  end;
  Unlock;
  if Event.ID <> etMouseWheel then
    Result := inherited OnEvent(Event);
end;
{
function GroupCompare(Item1, Item2: Pointer): LongInt;
var
 g1 : TGroup absolute Item1;
 g2 : TGroup absolute Item2;
begin
 if g1.Name = g2.Name then
   Result := 0
 else
   if g1.Name > g2.Name then
     Result := +1
   else
     Result := -1;
end;
}
procedure TRoster.Sort;
var
  i : LongInt;
begin
  if FUpdate then
    Exit;
  Lock;
{
  if Length(Groups) > 2 then
    QSort(@Groups[0], 2, Length(Groups) - 1, @GroupCompare);
}
  for i := 1 to Length(Groups) - 1 do  // active group always unsorted
    Groups[i].Sort;
  Unlock;
end;

procedure TRoster.UpdateRange;
var
  i, j : LongInt;
begin
  if FUpdate then
    Exit;
  VScroll.Range := 0;
  Lock;
  for i := 0 to Length(Groups) - 1 do
    with Groups[i] do
      if Length(Users) > 0 then
      begin
        Inc(VScroll.Range, ROSTER_SIZE_GROUP);
        if not Folded then
          for j := 0 to Length(Users) - 1 do
            if Users[j].Visible(Groups[i]) then
              Inc(VScroll.Range, ROSTER_SIZE_CONTACT);
        Inc(VScroll.Range, ROSTER_SIZE_SEPARATOR);
      end;
  Unlock;
  inherited;
end;

function TRoster.AddGroup(const GID: WideString): TGroup;
var
  i : LongInt;
begin
  Lock;
// search group
  for i := 1 to Length(Groups) - 1 do
    if Groups[i].GID = GID then
    begin
      Result := Groups[i];
      Unlock;
      Exit;
    end;
// if group not exists -> create new
  Result := TGroup.Create;
  Result.GID := GID;
  Result.Filter := True;
  i := Length(Groups);
  SetLength(Groups, i + 1);
  Groups[i] := Result;
  Unlock;
  Sort;
end;

function TRoster.AddUser(const UID: WideString): TUser;
var
  i : LongInt;
begin
  Lock;
  for i := 0 to Length(Users) - 1 do
    if Users[i].UID = UID then
    begin
      Result := Users[i];
      Unlock;
      Exit;
    end;
  i := Length(Users);
  Result := TUser.Create;
  Result.UID := UID;
  SetLength(Users, i + 1);
  Users[i] := Result;
  Unlock;
end;

function TRoster.AddUser(XML: TXML): TUser;
var
  i : LongInt;
begin
  Result := Roster.AddUser(XML.Value['uid']);
  Result.Name   := XML.Value['first_name'] + ' ' + XML.Value['last_name'];
  Result.BDate  := XML.Value['bdate'];
  Result.HPhone := XML.Value['home_phone'];
  Result.MPhone := XML.Value['mobile_phone'];
  Result.Avatar.Link := XML.Value['photo_rec'];
  if XML['lists'] <> nil then
  begin
    with XML['lists'] do
      for i := 0 to Count - 1 do
        Roster.GetGroupByGID(NodeI[i].Content, True).Add(Result);
  end else
    Roster.Groups[1].Add(Result);
end;

{
function TRoster.Add(const GroupID, UID, Name: WideString): TUser;
var
  i   : LongInt;
  grp : TGroup;
  usr : TUser;
begin
  grp := AddGroup('X', GroupID);
// search user jid in group contacts
  Lock;
  usr := nil;
  for i := 0 to Length(grp.Contacts) - 1 do
  begin
    usr := grp.Contacts[i].GetUser(JID);
    if usr <> nil then
    begin
      cnt := grp.Contacts[i];
      break;
    end;
  end;

  if cnt = nil then
  begin
    cnt := TContact.Create;
    cnt.Group := grp;
    usr := TUser.Create;
    usr.Contact := cnt;
    cnt.User    := usr;
    with cnt do
    begin
      SetLength(Users, Length(Users) + 1);
      Users[Length(Users) - 1] := usr;
    end;
    SetLength(grp.Contacts, Length(grp.Contacts) + 1);
    grp.Contacts[Length(grp.Contacts) - 1] := cnt;
  end;

  usr.Contact := cnt;
  cnt.User    := usr;

  usr.JID := JID;
  if Name = '' then
    usr.Name := Copy(JID, 1, Pos('@', JID) - 1)
  else
    usr.Name := Name;

  if not FUpdate then
  begin
    usr.UID := usr.Name;
    if Pos(WideString('id'), usr.UID) = 1 then
    begin
      usr.UID := Copy(usr.UID, 3, Length(usr.UID));
      if Conv(usr.UID, 0) = 0 then
        usr.UID := usr.Name;
    end;
  end;
//  usr.ImageIdx := Ord(usr.Status);
  usr.Status := xsOffline;
  Result := usr;
  if not FUpdate then
    InfoQuery(JID);
  Unlock;
  UpdateRange;
end;
}

function TRoster.GetUserByUID(const UID: WideString; CreateNew: Boolean): TUser;
var
  i : LongInt;
begin
  Lock;
  for i := 0 to Length(Users) - 1 do
    if Users[i].UID = UID then
    begin
      Result := Users[i];
      Unlock;
      Exit;
    end;
  Unlock;
  if CreateNew then
  begin
    Result := AddUser(UID);
    Groups[1].Add(Result);
  end else
    Result := nil;
end;

function TRoster.GetGroupByGID(const GID: WideString; CreateNew: Boolean): TGroup;
var
  i : LongInt;
begin
  Lock;
  for i := 0 to Length(Groups) - 1 do
    if Groups[i].GID = GID then
    begin
      Result := Groups[i];
      Unlock;
      Exit;
    end;
  Unlock;
  if CreateNew then
    Result := AddGroup(GID)
  else
    Result := nil;
end;

function TRoster.GetSelected: TUserArray;
var
  i, j : LongInt;
  Flag : Boolean;
begin
  Selected := nil;
  if (not Visible) or (not FParent.Visible) then
    Exit;

  Result := nil;
  Lock;
  for i := 0 to Length(Users) - 1 do
    if Users[i].Select then
    begin
      Flag := True;
      for j := 0 to Length(Result) - 1 do // don't duplicate
        if Users[i] = Result[j] then
        begin
          Flag := False;
          break;
        end;
      if Flag then
      begin
        SetLength(Result, Length(Result) + 1);
        Result[Length(Result) - 1] := Users[i];
      end;
    end;
// push avatars
  Selected := Result;
  Info.Users := Result;
  if Length(Result) <> 1 then
  begin
    Window.Text := CLIENT_NAME;
    Window.Folded := True;
  end else
  begin
//    Window.Text := LangMsg[lmMultiMsg];
    Window.Text := Result[0].Name;
    Window.Folded := False;
  end;
  Unlock;
  if Length(Result) = 1 then
    if Result[0].State = usMessage then
    begin
      MediaClose;
      if Window.IsFore then
        Result[0].State := usNone;
      Info.CheckRepaint(Result[0]);
    end else
      MediaUpdate;
end;

{
procedure TRoster.MoveToGroup(Group: TGroup; Contacts: TContactArray);
var
  i : LongInt;
  JIDs : TStringArray;
  JCount : LongInt;
begin
  if Group = nil then
    Exit;
  JCount := 0;
  Lock;
  SetLength(JIDs, Length(Contacts));
  for i := 0 to Length(Contacts) - 1 do
    if Group <> Contacts[i].Group then
    begin
      Contacts[i].Group.Del(Contacts[i]);
      Contacts[i].Group := Group;
      Group.Add(Contacts[i]);
      JIDs[JCount] := Contacts[i].User.JID;
      Inc(JCount);
    end;
  Unlock;
  if JCount <> Length(JIDs) then
    SetLength(JIDs, JCount);
  ClearEmpry;
  Lock;
  Group.Sort;
  Unlock;
  Repaint;
  XMPP.RosterSetGroup(Group.Name, JIDs);
end;
}

procedure TRoster.Activate(User: TUser; RecvMsg: Boolean = True);
var
  i, idx : LongInt;
begin
// activate contact in "active" group
  if Length(Groups) = 0 then
    Exit;
  idx := -1;
  with Groups[0] do
  begin
    Lock;
  // search contact in "active" group
    for i := 0 to Length(Users) - 1 do
      if Users[i] = User then
      begin
        idx := i;
        break;
      end;
  // if contact not found then add
    if idx = -1 then
      idx := Add(User);
  // Bump it up
    for i := idx downto 1 do
      Users[i] := Users[i - 1];
    Users[0] := User;
    User.Tab := True;
    Unlock;
    if RecvMsg then
      User.State := usMessage;
    Repaint;
  end;
end;

procedure TRoster.ResetIcon;
begin
  if Online then
    AppWindow.Icon := Icon[itOnline]
  else
    AppWindow.Icon := Icon[itOffline];
end;

procedure TRoster.SelectUser(User: TUser);
begin
  if User <> nil then
  begin
    UnSelect;
    User.Select := True;
    GetSelected;
  end;
end;

procedure TRoster.NextActive;
var
  i: Integer;
begin
  if (Length(Roster.Selected) = 1) and (Roster.Selected[0].State = usMessage) then
  begin
    GetSelected;
    Exit;
  end;

  with Groups[0] do
    for i := 0 to Length(Users) - 1 do
      if Users[i].State = usMessage then
      begin
        UnSelect;
        Users[i].Select := True;
        GetSelected;
        break;
      end;
end;

procedure TRoster.Update;
begin
  if Length(Info.Users) = 1 then
    Info.Users[0].QueryStatusMsg;
  InfoFlush;
  SaveFlush;
end;
{$ENDREGION}

end.
