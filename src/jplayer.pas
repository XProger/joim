unit jplayer;

interface

uses
  jsys, jutils, jctrl, jroster, jlastfm;

type
  TPlayerMode  = (pmNormal, pmRepeat, pmShuffle);
  TPlayerNotify = (pnPlay, pnPause, pnComplete, pnPosition);

  TPlayListItem = record
    UID, ID : WideString;
    Artist  : WideString;
    Title   : WideString;
    URL     : AnsiString;
    Length  : LongInt;
    NWidth  : Word;
  end;

  TPlayListItems = array of TPlayListItem;

  TPlayList = class
    constructor Create(const Name: WideString);
  private
    FPosition : LongInt;
    FComplete : Single;
    procedure SetPosition(const Value: LongInt);
    procedure SetComplete(const Value: Single);
  public
    Name   : WideString;
    Artist : TArtistArray;
    Items  : TPlayListItems;
    Index  : LongInt;
  // shuffle history
    HSeed : LongWord;
    HInc  : LongInt;
    Playing : Boolean;
    Valid   : Boolean;
    function Height: LongInt;
    procedure Play(Index: LongInt);
    procedure Pause;
    procedure PlayNext;
    procedure PlayPrev;
    property Position: LongInt read FPosition write SetPosition;
    property Complete: Single read FComplete write SetComplete;
  end;

  TPlayerNotifyProc = procedure (PlayList: TPlayList; Event: TPlayerNotify);

  TPlayer = class(TControl)
    constructor Create(Parent: TControl);
    destructor Destroy; override;
  private
    VolumeCtrl  : TVolume;
    Scrobbled   : Boolean;
    TimerPlayer : LongWord;
    FMode     : TPlayerMode;
    FPlayList : array of TPlayList;
    FVolume   : LongInt;
    BtnPlay, BtnMode : TButton;
    function GetPlayList(const Name: WideString): TPlayList;
    procedure SetMode(const Value: TPlayerMode);
    procedure SetVolume(const Value: LongInt);
  public
    CS : TCriticalSection;
    List : TPlayList;
    NotifyProc : TPlayerNotifyProc;
    procedure Notify(PlayList: TPlayList; Event: TPlayerNotify);
    property PlayList[const Name: WideString]: TPlayList read GetPlayList;
    property Mode: TPlayerMode read FMode write SetMode;
    property Volume: LongInt read FVolume write SetVolume;
  end;

implementation

uses
  jglobal, jmedia;

const
  BTN_MEDIA_MODE   = 10;
  BTN_MEDIA_PREV   = 11;
  BTN_MEDIA_PLAY   = 12;
  BTN_MEDIA_NEXT   = 13;
  BAR_MEDIA_VOLUME = 14;

{$REGION 'TPlayList'}
constructor TPlayList.Create(const Name: WideString);
begin
  Self.Name := Name;
  HSeed := GetTime;
  HInc  := HSeed mod 100;
  Index := -1;
  Media.PlayList := Self;
  Media.GetMedia(mtAudio);
end;

procedure TPlayList.SetPosition(const Value: LongInt);
begin
  FPosition := Value;
  Flash.Call('soundPosSet', [Conv(Value)]);
  Player.Notify(Self, pnPosition);
end;

procedure TPlayList.SetComplete(const Value: Single);
begin
  FComplete := Value;
  Player.Notify(Self, pnComplete);
end;

function TPlayList.Height: LongInt;
//var
//  i : LongInt;
begin
  Result := Length(Items) * ITEM_AUDIO_HEIGHT + 16 + ITEM_AUDIO_TRACK;
//  for i := 0 to Length(Artist) do
//    Result := Result + 86;
end;

procedure TPlayList.Play(Index: LongInt);
var
  i : LongInt;
begin
  if Index < 0 then
    Index := 0;
  if Index >= Length(Items) then
    Exit;
  FlushMemory;
  Player.CS.Lock;
  Player.List := Self;
  Player.BtnPlay.ImageIdx := 33;

  for i := 0 to Length(Player.FPlayList) - 1 do
    if (Player.FPlayList[i] <> Self) and Player.FPlayList[i].Playing then
    begin
      Player.FPlayList[i].Pause;
      Player.FPlayList[i].Index := -1;
      break;
    end;

  if (Self.Index = Index) and (Player.List = Self) then
  begin
    if Playing then
      Position := 0
    else
      Flash.Call('soundContinue', []);
  end else
  begin
    with Items[Index] do
    begin
      LastFM.NowPlaying(Artist, Title, Length div 1000);
      Player.BtnPlay.Hint := Artist + ' - ' + Title;
    end;
    Player.Scrobbled := False;
    Flash.Call('soundPlay', [WideString(Items[Index].URL)]);
    Status.StatusAudioSet(Items[Index].UID + '_' + Items[Index].ID);
    FPosition := 0;
    FComplete := 0;
  end;
  Playing := True;
  Self.Index := Index;
  Player.CS.Unlock;

  Player.Notify(Self, pnPlay);
end;

procedure TPlayList.Pause;
begin
  Player.CS.Lock;
  Playing := False;
  Player.BtnPlay.ImageIdx := 32;
  Flash.Call('soundPause', []);
  Player.CS.Unlock;

  Player.Notify(Self, pnPause);
end;

procedure TPlayList.PlayNext;
var
  i : LongInt;
begin
  i := Length(Items);
  if i > 0 then
  begin
    case Player.Mode of
      pmNormal  : i := (Index + 1) mod i;
      pmShuffle :
        begin
          Inc(HInc);
          Inc(HSeed, HInc);
          RandSeed := HSeed;
          i := Random(i);
        end;
    else
      i := Index;
    end;
    Play(i);
  end;
end;

procedure TPlayList.PlayPrev;
var
  i : LongInt;
begin
  i := Length(Items);
  if i > 0 then
  begin
    if Index < 0 then
      Index := 0;
    case Player.Mode of
      pmNormal  : i := (i + Index - 1) mod i;
      pmShuffle :
        begin
          Dec(HSeed, HInc);
          Dec(HInc);
          RandSeed := HSeed;
          i := Random(i);
        end;
    else
      i := Index;
    end;
    Play(i);
  end;
end;
{$ENDREGION}

{$REGION 'TPlayer'}
function PlayerProc(Control: TControl; const Event: TControlEvent): Boolean;
begin
  Result := False;
  with Player do
    case Event.ID of
      etHotKey :
        begin
          if List <> nil then
            case Event.Key.HotKey of
              hkPlayNext   : List.PlayNext;
              hkPlayPrev   : List.PlayPrev;
              hkStop       :
                if List.Playing then
                  List.Pause;
              hkPlayPause  :
                if List.Playing then
                  List.Pause
                else
                  List.Play(List.Index);
            end;

          if Event.Key.HotKey in [hkPlayNext, hkPlayPrev, hkStop, hkPlayPause] then
            Result := True;
        end;
      etClick :
        with TButton(Control) do
          case Control.ID of
            BTN_MEDIA_PLAY :
              if List <> nil then
                if List.Playing then
                  List.Pause
                else
                  List.Play(List.Index);
            BTN_MEDIA_NEXT :
              if Player.List <> nil then
                Player.List.PlayNext;
            BTN_MEDIA_PREV :
              if Player.List <> nil then
                Player.List.PlayPrev;
            BTN_MEDIA_MODE :
              Player.Mode := TPlayerMode((Ord(Player.Mode) + 1) mod 3);
          end;
      etChange : 
        if Control.ID = BAR_MEDIA_VOLUME then
          Player.Volume := TVolume(Control).Value;        
    end;
end;

procedure PlayerTimer;
var
  i : LongInt;
begin
  with Media, Player do
    for i := 0 to Length(FPlayList) - 1 do
      with FPlayList[i] do
      begin
        if (Complete < 0.99999) and (Index > -1) then
          Complete := Conv(Flash.Call('soundBuf', []), 0.0);
        if Playing then
        begin
          FPosition := Trunc(Conv(Flash.Call('soundPosGet', []), 0.0));
          Notify(List, pnPosition);

          if (not Player.Scrobbled) and (FPosition > Items[Index].Length * 0.8) then // scrobble after 80%
            with Player.List, Items[Index] do
            begin
              LastFM.Scrobble(Artist, Title, Length div 1000);
              Player.Scrobbled := True;
            end;

          if Position >= Items[Index].Length then
            PlayNext;
          break;
        end;
      end;
end;

constructor TPlayer.Create(Parent: TControl);
begin
  inherited;
  CS.Init;
  BtnPlay := CreateButton(Self, 32, -32, 0, BTN_MEDIA_PLAY, @PlayerProc, lmNone);
  BtnMode := CreateButton(Self, 29, -68, 0, BTN_MEDIA_MODE, @PlayerProc, lmModeNormal);
  CreateButton(Self, 34, -16, 0, BTN_MEDIA_NEXT, @PlayerProc, lmPlayNext);
  CreateButton(Self, 35, -48, 0, BTN_MEDIA_PREV, @PlayerProc, lmPlayPrev);

  VolumeCtrl := TVolume.Create(Self);
  with VolumeCtrl do
  begin
    ID := BAR_MEDIA_VOLUME;
    EventProc := @PlayerProc;
    Move(0, 2, 25, 12);
    Value := 4;
  end;

  TimerPlayer := InitTimer(250, @PlayerTimer);
end;

destructor TPlayer.Destroy;
var
  i : LongInt;
begin
  FreeTimer(TimerPlayer);
  Player := nil;
  for i := 0 to Length(FPlayList) - 1 do
    FPlayList[i].Free;
  CS.Free;
  inherited;
end;

function TPlayer.GetPlayList(const Name: WideString): TPlayList;
var
  i : LongInt;
begin
  CS.Lock;
// search playlist
  for i := 0 to Length(FPlayList) - 1 do
    if FPlayList[i].Name = Name then
    begin
      Result := FPlayList[i];
      CS.Unlock;
      Exit;
    end;
// or create new
  i := Length(FPlayList);
  SetLength(FPlayList, i + 1);
  FPlayList[i] := TPlayList.Create(Name);
  Result := FPlayList[i];
  CS.Unlock;
end;

procedure TPlayer.SetMode(const Value: TPlayerMode);
begin
  FMode := Value;
  BtnMode.ImageIdx := 29 + Ord(FMode);
  BtnMode.Hint := LangMsg[TLangMsg(Ord(lmModeNormal) + Ord(FMode))];
end;

procedure TPlayer.SetVolume(const Value: LongInt);
begin
  FVolume := Min(5, Max(0, Value));
  Flash.Call('soundVol', [Conv(FVolume / 5)]);
  VolumeCtrl.Value := FVolume;
end;

procedure TPlayer.Notify(PlayList: TPlayList; Event: TPlayerNotify);
begin    
  if @NotifyProc <> nil then
    NotifyProc(PlayList, Event);
end;
{$ENDREGION}

end.
