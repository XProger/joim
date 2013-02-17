unit jmedia;

interface

uses
  jsys, jutils, jxml, jctrl, jvk, jplayer, jlastfm;

type
  TMediaType = (mtPhoto, mtAudio, mtVideo, mtRecs);

  PMediaItem = ^TMediaItem;
  TMediaItem = record
    UID, ID, Title, URL : WideString;
    Image  : TImage;
    NWidth : Word;
    QueryImage : Boolean;
  end;

  TCommentList = class
    //
  end;

// Photo
  TMediaPhoto = class
    PID  : WideString;
    Text : WideString;
    Image : TImage;
    QueryTime : LongWord;
    Comments  : TCommentList;
  end;

  TMediaAlbum = class
    AID    : WideString;
    Name   : WideString;
    Image  : TImage;
    Photos : array of TMediaPhoto;
    QueryTime : LongWord;
  end;

  TMediaListPhoto = class
    Album : array of TMediaAlbum;
    QueryTime : LongWord;
  end;

// Audio



// Video
  TMediaVideo = class
    VID   : WideString;
    Title : WideString;
    Text  : WideString;
    Image : TImage;
    QueryTime : LongWord;
  end;

  TMediaListVideo = class

  end;

// LastFM
  TListRecs = class(TControl)
    constructor Create(Parent: TControl);
  public
    PLogon : TFrame;
    EUser, EPass : TEdit;
    function OnEvent(const Event: TControlEvent): Boolean; override;
  end;

  TMedia = class;

  TMediaFrame = class(TControl)
    constructor Create(Parent: TControl);
  public
    Media : TMedia;
    List  : array [TMediaType] of TControl;
  // buttons
    BtnRefresh : TButton;
    BtnRecs    : TButton;
  // search bar
    PSearch  : TFrame;
    ESearch  : TEdit;
    BSearch  : TButton;
    procedure SearchBar(Show: Boolean);
    function OnEvent(const Event: TControlEvent): Boolean; override;
  end;

  TMedia = class(TScrollBox)
    constructor Create(Parent: TControl);
    destructor Destroy; override;
  private
    CS   : TCriticalSection;
    Over      : LongInt;
    FCurMedia : TMediaType;
    FCurPage  : LongInt;
    ReqItems  : array [TMediaType] of LongInt;
    BtnFrame : TFrame;
    BtnPlay, BtnPause, BtnAdd, BtnSite, BtnSend : TButton;
    procedure SetCurMedia(const Value: TMediaType);
    procedure SetCurPage(const Value: LongInt);
  public
    NeedRange : Boolean;
    BarTrack : TTrack;
    PlayList : TPlayList;
    PlayItem : LongInt;
    Items : array [TMediaType] of array of PMediaItem;
    procedure Clear(MediaType: TMediaType);
    procedure ScrollToIndex(Index: LongInt);
    procedure GetMedia(MediaType: TMediaType);
    function GetPhotoRowHeight(Index, Count: LongInt): LongInt;
    procedure UpdateRange; override;
    function OnEvent(const Event: TControlEvent): Boolean; override;
    procedure UpdateCtrlRect;
    property CurMedia: TMediaType read FCurMedia write SetCurMedia;
    property CurPage: LongInt read FCurPage write SetCurPage;
  end;

implementation

uses
  jglobal;

const
  ITEM_PHOTO_WIDTH  = 85;
  ITEM_VIDEO_WIDTH  = 145;
  ITEM_VIDEO_HEIGHT = 106;

  BTN_MEDIA_CLOSE   = 1;
  BTN_MEDIA_REFRESH = 2;
  BTN_MEDIA_RECS    = 3;

  BTN_PLAY    = 10;
  BTN_PAUSE   = 11;
  BTN_REPEAT  = 12;
  BTN_ADD     = 13;
  BTN_DEL     = 14;
  BTN_SEND    = 15;
  BTN_SITE    = 16;

  BAR_TRACK   = 20;
  BAR_VOLUME  = 21;

{$REGION 'Common'}
procedure OnImage(MediaItem: PMediaItem; const Header: AnsiString; const Content: WideString; Data, RawData: Pointer; RawSize: LongInt);
var
  Stream : TFileStream;
  SURL : WideString;
  Img : TImage;
begin
  if RawData <> nil then
  begin
    CheckFolders;
    SURL := ConvSURL(MediaItem^.URL);

    Img := TImage.Create(RawData, RawSize);
    if Img.Valid then
    begin
      MediaItem^.Image := Img;
      Media.NeedRange := True;
    end else
      Img.Free;

    Stream := TFileStream.Create(RootDir + 'img/' + SURL, fmWrite);
    if Stream.Valid then
      Stream.Write(RawData^, RawSize);
    Stream.Free;
    MFrame.Repaint;
  end;
end;

procedure GetMediaImage(MediaItem: PMediaItem; const URL: AnsiString);
var
  Img : TImage;
begin
  if (URL = '') or (MediaItem^.QueryImage and (MediaItem.Image = nil)) then
    Exit;
  MediaItem^.QueryImage := True;
  Img := TImage.Load(RootDir + 'img/' + ConvSURL(WideString(URL)));
  if Img <> nil then
  begin
    MediaItem^.Image := Img;
    Media.NeedRange := True;
  end else
    HTTP.QueryImage(WideString(URL), LongInt(MediaItem), @OnImage);
//    vk.GetFile(URL, LongInt(MediaItem), @OnImage);
end;
{$ENDREGION}

{$REGION 'TListRecs'}
constructor TListRecs.Create(Parent: TControl);
{var
  LCtrl : TLabel;
  BCtrl : TButton;
}
begin
  inherited;
// Last.fm logon frame
{
  PLogon := TFrame.Create(Self);

  LCtrl := TLabel.Create(PLogon);
  LCtrl.Font  := Font_Tahoma_11b;
  LCtrl.Color := $666666;
  LCtrl.Text  := LangMsg[lmName];
  LCtrl.Move(0, 0, 100, 12);

  LCtrl := TLabel.Create(PLogon);
  LCtrl.Font  := Font_Tahoma_11b;
  LCtrl.Color := $666666;
  LCtrl.Text := LangMsg[lmPass];
  LCtrl.Move(0, 40, 100, 12);

  LCtrl := TLabel.Create(PLogon);
  LCtrl.Font  := Font_Tahoma_11;
  LCtrl.Color := $666666;
  LCtrl.Text := LangMsg[lmAboutLastFM];
  LCtrl.Move(100, 0, -1 - 100, -1);

  EUser := TEdit.Create(PLogon);
  EUser.WordWrap := False;
  EUser.Move(8, 16, 92, 20);

  EPass := TEdit.Create(PLogon);
  EPass.WordWrap := False;
  EPass.Password := True;
  EPass.Move(8, 56, 92, 20);

  PLogon.Move(8, 8, -16, -16);
  }
//http://lastfm.ru/join?lang=ru
end;

function TListRecs.OnEvent(const Event: TControlEvent): Boolean;
begin
  Result := inherited OnEvent(Event);
end;
{$ENDREGION}

{$REGION 'TMediaFrame'}
procedure OnAudioAdd(ID: Integer; XML: TXML);
begin
//  Writeln(Content);
end;

function MediaEvent(Control: TEdit; const Event: TControlEvent): Boolean;
var
  i : LongInt;
  Link, Attach : WideString;
  PList : TPlayList;
begin
  Result := False;
  with Media do
    case Event.ID of
      etMouseUp :
        case Control.ID of
          BTN_MEDIA_CLOSE :
            MediaClose;
          BTN_MEDIA_REFRESH :
            begin
              ReqItems[CurMedia] := 0;
              Clear(CurMedia);
              GetMedia(CurMedia);
            end;
          BTN_MEDIA_RECS :
            MediaSwitch(mtRecs, '');
          BTN_PLAY :
            begin
              PlayItem := Over;
              PlayList.Play(Over);
            end;
          BTN_PAUSE : PlayList.Pause;
          BTN_ADD :
            if Over > -1 then
            begin
              Player.CS.Lock;
              vk.Query([Param('aid', PlayList.Items[Over].ID),
                        Param('oid', PlayList.Items[Over].UID)],
                       'audio.add', 0, @OnAudioAdd);

              with Player.PlayList[Roster.OwnerUser.UID] do
              begin
                SetLength(Items, Length(Items) + 1);
                for i := Length(Items) - 1 downto 1 do
                  Items[i] := Items[i - 1];
                Items[0] := PlayList.Items[Over];
                if (Player.List.Name = Roster.OwnerUser.UID) and Player.List.Playing then
                  Inc(Player.List.Index);
              end;
              Player.CS.Unlock;
              BtnAdd.Visible := False;

              PList := PlayList;
              PlayList := Player.PlayList[Roster.OwnerUser.UID];
              Clear(mtAudio);
              GetMedia(mtAudio);
              PlayList := PList;
            end;
          BTN_DEL :
            if Over > -1 then
            begin
              Player.CS.Lock;
              vk.Query([Param('aid', PlayList.Items[Over].ID),
                        Param('oid', PlayList.Items[Over].UID)],
                       'audio.delete', 0, nil);

              with Player.PlayList[Roster.OwnerUser.UID] do
              begin
                for i := Over to Length(Items) - 2 do
                  Items[i] := Items[i + 1];
                if (Index = Over) and Playing then
                begin
                  Index := -1;
                  PlayItem := -1;
                  Pause;
                  BarTrack.Visible := False;
                  BtnPause.Visible := False;
                end;
                if Index > Over then
                  Dec(Index);
                if PlayItem > Over then
                  Dec(PlayItem);
                SetLength(Items, Length(Items) - 1);
              end;
              Player.CS.Unlock;
              UpdateRange;
            end;
          BTN_SITE, BTN_SEND :
            if Over > -1 then
            begin
              Link := '';
              if CurMedia = mtAudio then
              begin
                with PlayList.Items[Over] do
                begin
                  Link := 'audio.php?id=' + UID + '&audio_id=' + ID + ' "' + Artist + ' - ' + Title + '"';
                  Attach := 'audio' + UID + '_' + ID;
                end;
              end else
              begin
                with Items[CurMedia][Over]^ do
                  case CurMedia of
                    mtPhoto : Link := 'photo' + UID + '_' + ID;
                    mtVideo : Link := 'video' + UID + '_' + ID;
                  end;
                Attach := Link;
              end;
              Link := VK_URL + Link;

              if Control.ID = BTN_SEND then
              begin
              //  SendMessage(Link, History.CurLog.User);
                SendMessage(Link, History.CurLog.User, Attach);
                MediaClose;
              end else
                BrowseURL(Link);
            end;
        end;
      etChange :
        if PlayList = Player.List then
          case Control.ID of
            BAR_TRACK : PlayList.Position := BarTrack.Position;
          end;
    end;
end;

constructor TMediaFrame.Create(Parent: TControl);
begin
  inherited;
  Media := TMedia.Create(Self);

  CreateButton(Self, 18, -26, 4, BTN_MEDIA_CLOSE, TEventProc(@MediaEvent), lmMediaClose);
  BtnRefresh := CreateButton(Self, 19, -46, 4, BTN_MEDIA_REFRESH, TEventProc(@MediaEvent), lmMediaRefresh);
  BtnRecs    := CreateButton(Self, 38, -68, 4, BTN_MEDIA_RECS, TEventProc(@MediaEvent), lmMyRecs);

  PSearch := TFrame.Create(Self);
  ESearch := TEdit.Create(PSearch);
  BSearch := TButton.Create(PSearch, nil, -1);
  ESearch.Move(0, 0, -64, 20);
  BSearch.Move(-64, 1, 64, 18);
  PSearch.Move(0, 27, -6, 20);
  BSearch.Text := LangMsg[lmMediaSearch];
  ESearch.WordWrap := False;
  PSearch.Color  := COLOR_WINDOW;
  PSearch.Border := COLOR_WINDOW;
  SearchBar(False);

  List[mtRecs] := TListRecs.Create(Media);
end;

procedure TMediaFrame.SearchBar(Show: Boolean);
begin
  PSearch.Visible := Show;
  if Show then
    Media.Move(0, 23 + 27, -1, -24 - 27)
  else
    Media.Move(0, 23, -1, -24);
  if Show then
    Window.Focus := ESearch;
end;

function TMediaFrame.OnEvent(const Event: TControlEvent): Boolean;
begin
  case Event.ID of
    etDraw :
      with Event.Draw do
      begin
        Canvas.BrushColor := $86E1FF;
        Canvas.PenColor   := $9ECFD7;
        Canvas.TextColor  := $296069;
        Canvas.Font       := Font_Tahoma_11b;
        with ARect do
        begin
          Canvas.FillRect(SetRect(Left, Top, Right - 5, Top + 24));
          Canvas.FrameRect(SetRect(Left, Top, Right - 5, Top + 24));
          if Media.CurMedia = mtRecs then
            ImgBase.DrawFrame(Canvas, Left + 5, Top + 4, BtnRecs.ImageIdx, 16)
          else
            ImgBase.DrawFrame(Canvas, Left + 5, Top + 4, 7 + Ord(Media.CurMedia), 16);
          Canvas.TextOut(Left + 8 + 20, Top + 5, FText);
        end;
      end;
  end;
  Result := inherited OnEvent(Event);
end;
{$ENDREGION}

{$REGION 'TMedia'}
procedure OnMedia(ID: LongInt; XML: TXML);
var
  b, i : LongInt;
  MediaType : TMediaType;
  PlayList  : TPlayList absolute ID;
  PlayID : WideString;
begin
  if XML = nil then Exit;
//  Writeln(Content);
  MediaType := TMediaType(ID);
  if ID > 2 then // hack! >_<
    MediaType := mtAudio;

  Media.CS.Lock;
  DCanvas.Lock;
  DCanvas.Font := Font_Tahoma_11b;

  if MediaType = mtAudio then
  begin
    Player.CS.Lock;
    if (Player.List = PlayList) and (PlayList.Index > -1) then
      PlayID := PlayList.Items[PlayList.Index].ID
    else
      PlayID := '';
    b := 0;
    SetLength(PlayList.Items, XML.Count);
  end else
  begin
    b := Length(Media.Items[MediaType]);
    if XML['count'] = nil then
      SetLength(Media.Items[MediaType], b + XML.Count)
    else
      SetLength(Media.Items[MediaType], b + XML.Count - 1);
  end;

  for i := 0 to XML.Count - 1 do
    with XML.NodeI[i] do
    begin
      if Tag = 'count' then
      begin
      {$IFDEF DEBUG}
        Writeln(Content);
      {$ENDIF}
        continue;
      end;

      if MediaType = mtAudio then
      begin
        with PlayList.Items[b] do
        begin
          UID := Node['owner_id'].Content;
          ID  := Node['aid'].Content;
          Artist := SpecToChar(Node['artist'].Content);
          Title  := SpecToChar(Node['title'].Content);
          URL    := AnsiString(Node['url'].Content);
          Length := Conv(Node['duration'].Content, 0) * 1000;
          NWidth := DCanvas.TextWidth(PWideChar(Artist), System.Length(Artist));
        {$IFDEF DEBUG}
          Writeln(UID, #9, ID, #9, Artist, ' - ', Title);
        {$ENDIF}
        end;
      end else
      begin
        New(Media.Items[MediaType][b]);
        FillChar(Media.Items[MediaType][b]^, SizeOf(TMediaItem), 0);
        with Media.Items[MediaType][b]^ do
          case MediaType of
            mtPhoto :
              begin
                UID := Node['owner_id'].Content;
                ID  := Node['pid'].Content;
                URL := Node['src_small'].Content;
              {$IFDEF DEBUG}
                Writeln(UID, #9, ID, #9, URL);
              {$ENDIF}
              end;
            mtVideo :
              begin
                UID   := Node['owner_id'].Content;
                ID    := Node['vid'].Content;
                Title := SpecToChar(Node['title'].Content);
                URL   := Node['image'].Content;
              {$IFDEF DEBUG}
                Writeln(UID, #9, ID, #9, Title, #9, URL);
              {$ENDIF}
              end;
          end;
      end;
      Inc(b);
    end;

    with XML do
      if (MediaType in [mtPhoto, mtVideo]) and (Node['count'] <> nil) then
      begin
        Inc(Media.ReqItems[MediaType], Count - 1);
        if Media.ReqItems[MediaType] < Conv(Node['count'].Content, 0) then
          Media.GetMedia(MediaType)
        else
          MFrame.BtnRefresh.Visible := True;
      end else
      begin
        MFrame.BtnRefresh.Visible := True;
        if MediaType = mtAudio then
        begin
          if (Player.List = PlayList) and (PlayList.Index > -1) then
          begin
            for i := 0 to Length(PlayList.Items) - 1 do
              if PlayList.Items[i].ID = PlayID then
              begin
                PlayList.Index := i;
                if Media.PlayList = PlayList then
                  Media.PlayItem := PlayList.Index;
                PlayID := '';
                break;
              end;
            if PlayID <> '' then
            begin
              if PlayList.Playing then
                PlayList.Pause;
              Media.PlayItem := -1;
              PlayList.Index := -1;
              Media.BarTrack.Visible := False;
              Media.BtnPause.Visible := False;
            end;
          end;
          PlayList.Valid := True;
          Player.CS.Unlock;
        end;
      end;
  DCanvas.Unlock;
  Media.CS.Unlock;

  if (Media.CurMedia = MediaType) then
  begin
    if (MediaType = mtAudio) and (Media.PlayList <> PlayList) then
      Exit;
    Media.NeedRange := True;
    Media.Repaint;
  end;
end;

procedure PlayerNotify(PList: TPlayList; Event: TPlayerNotify);
begin
  with Media do
    case Event of
      pnPlay :
        begin
          BarTrack.MDrag    := False;
          BarTrack.MaxValue := PList.Items[PList.Index].Length;
          BarTrack.Position := PList.Position;
          BarTrack.Complete := PList.Complete;
          if (PlayList = PList) and (CurMedia = mtAudio) then
          begin
            PlayItem := PList.Index;
            ScrollToIndex(PList.Index);
            BarTrack.Visible := True;
            BtnPause.Visible := True;
            BtnPlay.Visible  := False;
          end;
        end;
      pnPause :
        if (PlayList = PList) and (CurMedia = mtAudio) then
        begin
          BtnPause.Visible := False;
          if (Over = PlayItem) and (Over > -1) then
            BtnPlay.Visible := True;
        end;
      pnComplete : BarTrack.Complete := PList.Complete;
      pnPosition : BarTrack.Position := PList.Position;
    end;
end;

constructor TMedia.Create(Parent: TControl);
begin
  inherited;
  CS.Init;
  Player.NotifyProc := @PlayerNotify;
// buttons
  BtnFrame := TFrame.Create(Self);
  BtnFrame.Border := 0;
  BtnFrame.Color  := 0;
  BtnFrame.Clip   := True;
  BtnFrame.Move(1, 1, -VScroll.Width - 2, -3);
// play
  BtnPlay := TButton.Create(BtnFrame, ImgBase, 32);
  BtnPlay.Move(8, 0, 16, 16);
  BtnPlay.ID := BTN_PLAY;
  BtnPlay.EventProc := TEventProc(@MediaEvent);
  BtnPlay.MinAlpha := 128;
// pause
  BtnPause := TButton.Create(BtnFrame, ImgBase, 33);
  BtnPause.Move(8, 0, 16, 16);
  BtnPause.ID := BTN_PAUSE;
  BtnPause.EventProc := TEventProc(@MediaEvent);
  BtnPause.MinAlpha := 128;
// add
  BtnAdd := TButton.Create(BtnFrame, ImgBase, 24);
  BtnAdd.Move(-44, 0, 16, 16);
  BtnAdd.Hint := LangMsg[lmHintMediaAdd];
  BtnAdd.ID := BTN_ADD;
  BtnAdd.EventProc := TEventProc(@MediaEvent);
  BtnAdd.MinAlpha := 128;
// site
  BtnSite := TButton.Create(BtnFrame, ImgBase, 27);
  BtnSite.Move(-24, 0, 16, 16);
  BtnSite.Hint := LangMsg[lmHintMediaSite];
  BtnSite.ID := BTN_SITE;
  BtnSite.EventProc := TEventProc(@MediaEvent);
  BtnSite.MinAlpha := 128;
// send
  BtnSend := TButton.Create(BtnFrame, ImgBase, 28);
  BtnSend.Move(-64, 0, 16, 16);
  BtnSend.Hint := LangMsg[lmHintMediaSend];
  BtnSend.ID := BTN_SEND;
  BtnSend.EventProc := TEventProc(@MediaEvent);
  BtnSend.MinAlpha := 128;
// track position bar
  BarTrack := TTrack.Create(BtnFrame);
  BarTrack.Move(32, 0, -48, ITEM_AUDIO_TRACK);
  BarTrack.ID := BAR_TRACK;
  BarTrack.EventProc := TEventProc(@MediaEvent);
  BarTrack.BarWidth := 13;
  BarTrack.Time := True;
end;

destructor TMedia.Destroy;
var
  mt : TMediaType;
begin
  for mt := Low(mt) to High(mt) do
    Clear(mt);
  CS.Free;
  inherited;
end;

procedure TMedia.SetCurMedia(const Value: TMediaType);
begin
  FCurMedia := Value;
  CurPage := 0;
  BtnPlay.Visible := False;
  BtnAdd.Visible  := False;
  BtnSite.Visible := False;
  BtnSend.Visible := False;

  if (PlayList <> nil) and (FCurMedia = mtAudio) and (PlayList = Player.List) then
  begin
    PlayItem := PlayList.Index;
    ScrollToIndex(PlayItem);
    BarTrack.Visible := PlayItem > -1;
    BtnPause.Visible := PlayList.Playing;
  end else
  begin
    PlayItem := -1;
    BtnPause.Visible := False;
    BarTrack.Visible := False;
  end;

  if FCurMedia = mtAudio then
    if PlayList.Name = Roster.OwnerUser.UID then
    begin
      BtnAdd.ID       := BTN_DEL;
      BtnAdd.ImageIdx := 25;
      BtnAdd.Hint     := LangMsg[lmHintMediaDel];
    end else
    begin
      BtnAdd.ID       := BTN_ADD;
      BtnAdd.ImageIdx := 24;
      BtnAdd.Hint     := LangMsg[lmHintMediaAdd];
    end;

  MFrame.BtnRecs.Visible := False;//FCurMedia = mtAudio;

  if not (FCurMedia in [mtAudio, mtRecs]) then
    if Items[FCurMedia] = nil then
      GetMedia(FCurMedia);
end;

procedure TMedia.SetCurPage(const Value: LongInt);
begin
  FCurPage := Value;
  Over := -1;
  VScroll.Offset := 0;
  UpdateRange;
  Repaint;
end;

procedure TMedia.Clear(MediaType: TMediaType);
var
  i : LongInt;
begin
  CS.Lock;
  for i := 0 to Length(Items[MediaType]) - 1 do
    if Items[MediaType][i] <> nil then
    begin
      if Items[MediaType][i]^.Image <> nil then
        Items[MediaType][i]^.Image.Free;
      Dispose(Items[MediaType][i]);
    end;
  Items[MediaType] := nil;

{
  if (Player <> nil) and (CurMedia = mtAudio) and (PlayList <> nil) and (PlayList = Player.List) then
  begin
    PlayList.Index := -1;
    PlayItem := -1;
    if PlayList.Playing then
      PlayList.Pause;
    BarTrack.Visible := False;
    BtnPause.Visible := False;
  end;
}

  Over := -1;
  CS.Unlock;
end;

procedure TMedia.ScrollToIndex(Index: LongInt);
var
  i : LongInt;
begin
  if Index > 0 then
  begin
    i := VScroll.Offset + (Index + 1) * ITEM_AUDIO_HEIGHT + ITEM_AUDIO_TRACK + 9;
    if (i < 0) or (i > Height) then
      VScroll.Offset := -Index * ITEM_AUDIO_HEIGHT + Height div 2 - ITEM_AUDIO_HEIGHT * 2;
  end else
    VScroll.Offset := 0;
  Repaint;
end;

procedure TMedia.GetMedia(MediaType: TMediaType);
begin
  MFrame.BtnRefresh.Visible := MediaType in [];
  case MediaType of
    mtPhoto : vk.Query([Param('count', '100'),
                        Param('offset', Conv(ReqItems[MediaType]))],
                        'photos.getAll', Ord(MediaType), @OnMedia, True);
    mtAudio : vk.Query([Param('uid', PlayList.Name)], 'audio.get', Integer(PlayList), @OnMedia, True);
    mtVideo : vk.Query([Param('uid', Roster.OwnerUser.UID),
                        Param('width', '130'),
                        Param('count', '100'),
                        Param('offset', Conv(ReqItems[MediaType]))],
                        'video.get', Ord(MediaType), @OnMedia, True);
  end;
end;

function TMedia.GetPhotoRowHeight(Index, Count: LongInt): LongInt;
var
  i : LongInt;
begin
  Result := 64;
  for i := 0 to Count - 1 do
    if Index * Count + i < Length(Items[CurMedia]) then
      with Items[CurMedia][Index * Count + i]^ do
        if (Image <> nil) and (Image.Height + 10 > Result) then
          Result := Image.Height + 10;
end;

procedure TMedia.UpdateRange;
var
  i, HCount : Integer;
begin
  if FUpdate then
    Exit;
  CS.Lock;
  VScroll.Range := 0;
  with ARect do
    case CurMedia of
      mtPhoto :
        begin
          Inc(VScroll.Range, 10);
          HCount := (Right - VScroll.Width - Left - 10) div ITEM_PHOTO_WIDTH;
          if HCount > 0 then
            for i := 0 to Length(Items[CurMedia]) div HCount do
              Inc(VScroll.Range, GetPhotoRowHeight(i, HCount));
        end;
      mtAudio : VScroll.Range := PlayList.Height;
      mtVideo : VScroll.Range := Length(Items[CurMedia]) * ITEM_VIDEO_HEIGHT + 16;
    end;
  inherited;
  CS.Unlock;
end;

function TMedia.OnEvent(const Event: TControlEvent): Boolean;
var
  HRect, IRect : TRect;
  i, j, h, d : LongInt;
  HOver : LongInt;
  HCount  : LongInt;
  Flag  : Boolean;
begin
  if NeedRange then
  begin
    UpdateRange;
    NeedRange := False;
  end;

  Result := False;
  if Event.ID = etMouseWheel then
    Result := inherited OnEvent(Event);
  CS.Lock;
  case Event.ID of
    etMouseMove, etMouseWheel :
      with Event.Mouse, Pos do
      begin
        HOver := -1;
        with ARect do
          HRect := SetRect(Left + 1, Top + 1, Right - VScroll.Width - 1, Bottom - 1);

        if RectIntersect(HRect, x, y) then
          case CurMedia of
            mtPhoto :
              with ARect do
              begin
                d := y - Top - VScroll.Offset - 10;
                HCount := (Right - VScroll.Width - Left - 10) div ITEM_PHOTO_WIDTH;
                for i := 0 to Length(Items[CurMedia]) div HCount do
                begin
                  h := GetPhotoRowHeight(i, HCount);
                  Dec(d, h);
                  if d < 0 then
                  begin
                    j := i * HCount + (x - Left - 5) * HCount div (Right - VScroll.Width - Left - 10);
                    if (j >= 0) and (j < Length(Items[CurMedia])) then
                      HOver := j;
                    break;
                  end;
                end;
              end;
            mtAudio :
              with HRect do
              begin
                Top    := Top + 8 + VScroll.Offset;
                Bottom := Top;
                for i := 0 to Length(PlayList.Items) - 1 do
                begin
                  Inc(Bottom, ITEM_AUDIO_HEIGHT);
                  if i = PlayItem then
                    Inc(Bottom, ITEM_AUDIO_TRACK);
                  if (y > Top) and (y <= Bottom) then
                  begin
                    HOver := i;
                    break;
                  end;
                  Top := Bottom;
                end;
              end;
            mtVideo :
              begin
                i := (y - (VScroll.Offset + ARect.Top + 9)) div ITEM_VIDEO_HEIGHT;
                if (i >= 0) and (i < Length(Items[CurMedia])) then
                  HOver := i;
              end;
          end;

        if HOver <> Over then
        begin
          Over := HOver;
          if CurMedia = mtAudio then
          begin
            if PlayItem = Over then
              BtnPlay.Visible := (Over > -1) and (not BtnPause.Visible)
            else
              BtnPlay.Visible := (Over > -1);
            BtnAdd.Visible  := Over > -1;
          end;
          BtnSite.Visible := (Over > -1);
          BtnSend.Visible := (Over > -1) and Info.Visible;
          Repaint;
        end;
      end;

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
          HRect := SetRect(Left + 1, Top + 1, Right - VScroll.Width - 5, Bottom - 1);
        Canvas.ClipInit(HRect);

        HRect := SetRect(HRect.Left + 4, HRect.Top + 8, HRect.Right, HRect.Bottom);

        with HRect do
        begin
          Inc(Top, VScroll.Offset);
          Inc(Bottom, VScroll.Offset);
          Canvas.TextColor := COLOR_8;
          Canvas.Font := Font_Tahoma_13;

          UpdateCtrlRect;
          case CurMedia of
            mtPhoto :
              begin
                IRect.Top    := Top;
                IRect.Bottom := IRect.Top;
                HCount := (Right - Left) div ITEM_PHOTO_WIDTH;

                if HCount > 0 then
                  for i := 0 to Length(Items[CurMedia]) div HCount do
                  begin
                  // get row height
                    h := GetPhotoRowHeight(i, HCount);
                    Inc(IRect.Bottom, h);
                  // draw row
                    if (IRect.Bottom > ARect.Top) and (IRect.Top < ARect.Bottom) then
                    begin
                      for j := 0 to HCount - 1 do
                        if i * HCount + j < Length(Items[CurMedia]) then
                        begin
                          IRect.Left  := Left + j * (Right - Left) div HCount;
                          IRect.Right := Left + (j + 1) * (Right - Left) div HCount;

                          Flag := i * HCount + j = Over;

                          if Flag then
                          begin
                            Canvas.BrushColor := MEDIA_OVER;
                            Canvas.FillRect(IRect);
                          end;

                          with Items[CurMedia][i * HCount + j]^, IRect do
                            if Image <> nil then
                              Image.Draw(Canvas, Left, Top, Right - Left, Bottom - Top, 192 + Ord(Flag) * 63)
                            else
                              GetMediaImage(Items[CurMedia][i * HCount + j], AnsiString(URL));
                        end;
                    end;

                    IRect.Top := IRect.Bottom;
                  end;
              end;
            mtAudio :
              begin
                Player.CS.Lock;
{
                if Artist <> nil then
                  Artist.Draw(Canvas, Left, Top, Width);
 }               DCanvas.TextColor := $7A582B;

                for i := 0 to Length(PlayList.Items) - 1 do
                begin
                  if (Top + ITEM_AUDIO_HEIGHT + ITEM_AUDIO_TRACK > ARect.Top) and (Top < ARect.Bottom) then
                    with PlayList.Items[i] do
                    begin
                      if i = PlayItem then
                      begin
                        Canvas.BrushColor := POPUP_OVER;
                        Canvas.FillRect(SetRect(Left, Top, Right, Top + ITEM_AUDIO_HEIGHT + ITEM_AUDIO_TRACK));
                      end else
                        if i = Over then
                        begin
                          Canvas.BrushColor := MEDIA_OVER;
                          Canvas.FillRect(SetRect(Left, Top, Right, Top + ITEM_AUDIO_HEIGHT));
                        end;

                      Canvas.Font := Font_Tahoma_11b;
                      Canvas.TextOut(Left + 24, Top + 4, PlayList.Items[i].Artist);
                      Canvas.Font := Font_Tahoma_11;
                      Canvas.TextOut(Left + 24 + NWidth, Top + 4,  ' - ' + PlayList.Items[i].Title);

                      if i = Over then
                        Canvas.FillRect(SetRect(Right - 64, Top + 3, Right, Top + 3 + 16));
                    end;
                  if i = PlayItem then
                    Inc(Top, ITEM_AUDIO_TRACK);
                  Inc(Top, ITEM_AUDIO_HEIGHT);
                end;

                Player.CS.Unlock;
              end;
            mtVideo :
              for i := 0 to Length(Items[CurMedia]) - 1 do
              begin
                if (Top + ITEM_VIDEO_HEIGHT > ARect.Top) and (Top < ARect.Bottom) then
                  with Items[CurMedia][i]^ do
                  begin
                    if i = Over then
                    begin
                      Canvas.BrushColor := MEDIA_OVER;
                      Canvas.FillRect(SetRect(Left, Top, Right, Top + ITEM_VIDEO_HEIGHT));
                    end;

                    if Image <> nil then
                      Image.Draw(Canvas, Left, Top, ITEM_VIDEO_WIDTH, ITEM_VIDEO_HEIGHT, 192 + Ord(i = Over) * 63)
                    else
                      GetMediaImage(Items[CurMedia][i], AnsiString(URL));

                    Canvas.TextOut(Left + ITEM_VIDEO_WIDTH + 8, Top + 8, Title);
                  end;
                Inc(Top, ITEM_VIDEO_HEIGHT);
              end;
          end;
        end;
        Canvas.ClipFree;
      end;
  end;
  CS.Unlock;
  if Event.ID <> etMouseWheel then
    Result := inherited OnEvent(Event);
end;

procedure TMedia.UpdateCtrlRect;
var
  i, j, y : LongInt;
  HRect, IRect : TRect;
  HCount, h : LongInt;

  procedure SetCtrlPos(Ctrl: TControl; x, y: LongInt);
  begin
    Ctrl.ARect := SetRectSize(x, y, Ctrl.Width, Ctrl.Height);
  end;

  procedure SetCtrlTop(Ctrl: TControl; y: LongInt);
  begin
    Ctrl.ARect.Top    := y;
    Ctrl.ARect.Bottom := y + Ctrl.Height;
  end;

begin
  case FCurMedia of
    mtPhoto :
      begin
        with ARect do
          HRect := SetRect(Left + 5, Top + 9, Right - VScroll.Width - 5, Bottom - 1);

        with HRect do
        begin
          Inc(Top, VScroll.Offset);
          Inc(Bottom, VScroll.Offset);

          IRect.Top    := Top;
          IRect.Bottom := IRect.Top;
          HCount := (Right - Left) div ITEM_PHOTO_WIDTH;

          if HCount > 0 then
            for i := 0 to Length(Items[CurMedia]) div HCount do
            begin
            // get row height
              h := GetPhotoRowHeight(i, HCount);
              Inc(IRect.Bottom, h);
            // draw row
              if (IRect.Bottom > ARect.Top) and (IRect.Top < ARect.Bottom) then
                for j := 0 to HCount - 1 do
                  if i * HCount + j < Length(Items[CurMedia]) then
                  begin
                    IRect.Left  := Left + j * (Right - Left) div HCount;
                    IRect.Right := Left + (j + 1) * (Right - Left) div HCount;
                    if i * HCount + j = Over then
                    begin
                      SetCtrlPos(BtnSite, IRect.Right - 18, IRect.Top + 2);
                      SetCtrlPos(BtnSend, IRect.Left - 2, IRect.Top + 2);
                      Exit;
                    end;
                  end;
              IRect.Top := IRect.Bottom;
            end;
        end;
      end;
    mtAudio :
      begin
        y := ARect.Top + VScroll.Offset + 9;
        for i := 0 to Length(PlayList.Items) - 1 do
        begin
          if i = Over then
            SetCtrlTop(BtnPlay, y + 3);

          if i = PlayItem then
          begin
            SetCtrlTop(BtnPause, y + 3);
            SetCtrlTop(BarTrack, y + ITEM_AUDIO_HEIGHT);
          end;

          if ((i = PlayItem) and (Over = -1)) or (i = Over) then
          begin
            SetCtrlTop(BtnAdd,  y + 3);
            SetCtrlTop(BtnSite, y + 3);
            SetCtrlTop(BtnSend, y + 3);
          end;

          if i = PlayItem then
            Inc(Y, ITEM_AUDIO_TRACK);
          Inc(Y, ITEM_AUDIO_HEIGHT);
        end;
      end;
    mtVideo :
      if Over > -1 then
      begin
        y := ARect.Top + VScroll.Offset + 9 + Over * ITEM_VIDEO_HEIGHT;
//        SetCtrlTop(BtnAdd,  y + 3);
        SetCtrlTop(BtnSite, y + 3);
        SetCtrlPos(BtnSend, Width - 27 - 20, y + 3);
      end;
  end;
end;
{$ENDREGION}

end.
