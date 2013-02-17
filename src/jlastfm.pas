unit jlastfm;

interface

uses
  jsys, jutils, jhash, jhttp, jxml, jctrl;

const
  LASTFM_VERSION = 1;  // last.fm config file version

  LFM_API    = 'ws.audioscrobbler.com';
  LFM_KEY    = '59d674cb75cbfccb312cb204116cddae';
  LFM_SECRET = '22f94b1e37ca94a0c7ee281f14c8251f';

// no response query repeat interval
  ARTIST_MAX_TIME_INFO   = 60 * 1000; // 1 min
  ARTIST_MAX_TIME_IMAGE  = 60 * 1000;
// artist update time
  ARTIST_MAX_TIME_UPDATE = 7 * 24 * 60 * 60 * 1000; // 1 week

type
  TArtistTrack = class
    Name : WideString;
    Link : WideString;
  end;

  TArtist = class
    constructor Create(const Name: WideString); overload;
    constructor Create(Stream: TStream); overload;
    destructor Destroy; override;
  private
    procedure Save(Stream: TStream);
    procedure Parse(XML: TXML);
  public
    Name    : WideString;
    Link    : WideString;  // image link
    Info    : WideString;
    Similar : array of WideString;
    Top     : array of WideString; // top tracks list
    Image   : TImage;
    UpdateTime     : LongWord;    // last update
    QueryTimeInfo  : LongWord;
    QueryTimeImage : LongWord;
    procedure QueryInfo(const Lang: WideString);
    function DrawImage(Canvas: TCanvas; X, Y: LongInt): LongInt;
    function Draw(Canvas: TCanvas; X, Y, Width: LongInt): LongInt; // return height
  end;

  TArtistArray = array of TArtist;

  TLastFM = class
    constructor Create;
    destructor Destroy; override;
  private
    CS      : TCriticalSection;
    skey    : WideString;
    FArtist : TArtistArray;
    FSaveQuery : Boolean;
    function GetArtist(const Name: WideString): TArtist;
  public
    Recs : TArtistArray;
    PlayTime : LongWord;
    procedure Save;
    procedure SaveQuery;
    procedure Update;
    procedure Connect(const User, Pass: WideString); overload;
    procedure Connect(const User: WideString; Pass: TMD5Digest); overload;
    procedure Query(const Params: array of TParam; const Method: WideString; ID: Integer; Proc: TQueryProc);
    procedure QueryRecs;
    procedure Scrobble(const Artist, Track: WideString; Duration: LongInt);
    procedure NowPlaying(const Artist, Track: WideString; Duration: LongInt);
    property Artist[const Name: WideString]: TArtist read GetArtist;
  end;

implementation

uses
  jglobal;

const
  LFM_GET_SESSION = 0;
  LFM_GET_RECS    = 1;

{$REGION 'Callbacks'}
procedure TopProc(Artist: TArtist; const Header: AnsiString; const Content: WideString; Data, RawData: Pointer; RawSize: LongInt);
var
  i : LongInt;
  XML : TXML;
begin
  {$IFDEF DEBUG}Writeln(Content);{$ENDIF}
  XML := TXML.Create(Content, 1);
  if (XML.DataLen > 0) and (XML.Params['status'] = 'ok') then
    with XML['toptracks'] do
    begin
      SetLength(Artist.Top, Count);
      for i := 0 to Count - 1 do
        Artist.Top[i] := NodeI[i].Value['name'];
      LastFM.SaveQuery;
    end;
  XML.Free;
end;

procedure InfoProc(Artist: TArtist; const Header: AnsiString; const Content: WideString; Data, RawData: Pointer; RawSize: LongInt);
var
  XML : TXML;
begin
  XML := TXML.Create(Content, 1);
  if (XML.DataLen > 0) and (XML.Params['status'] = 'ok') then
  begin
    Artist.Parse(XML['artist']);
    LastFM.Query([Param('artist', Artist.Name)], 'artist.getTopTracks', Integer(Artist), @TopProc);
  end;
  XML.Free;
end;

procedure ImageProc(Artist: TArtist; const Header: AnsiString; const Content: WideString; Data, RawData: Pointer; RawSize: LongInt);
var
  Stream : TFileStream;
begin
  if RawData <> nil then
  begin
    Stream := TFileStream.Create(RootDir + 'img/' + ConvSURL(Artist.Link), fmWrite);
    if Stream.Valid then
      Stream.Write(RawData^, RawSize);
    Stream.Free;
    Artist.Image := TImage.Load(RootDir + 'img/' + ConvSURL(Artist.Link));
  end;
end;

procedure LastProc(CallID: Integer; const Header: AnsiString; const Content: WideString; Data, RawData: Pointer; RawSize: LongInt);
var
  i : LongInt;
  XML : TXML;
begin
//  Writeln(Header);
//  Writeln(Content);
  XML := TXML.Create(Content, 1);
  if (XML.DataLen > 0) and (XML.Params['status'] = 'ok') then
  begin
    case CallID of
      LFM_GET_SESSION :
        begin
          LastFM.skey := XML['session'].Value['key'];
          LastFM.QueryRecs;
        end;
      LFM_GET_RECS :
        with XML['recommendations'] do
        begin
          SetLength(LastFM.Recs, Count);
          for i := 0 to Count - 1 do
          begin
            LastFM.Recs[i] := LastFM.Artist[NodeI[i].Value['name']];
            LastFM.Recs[i].Parse(NodeI[i]);
            if LastFM.Recs[i].Info = '' then
              LastFM.Recs[i].QueryInfo('ru');
          end;
        end;
    end;
  end;
  XML.Free;
end;
{$ENDREGION}

{$REGION 'TArtist'}
constructor TArtist.Create(const Name: WideString);
begin
  Self.Name := Name;
end;

constructor TArtist.Create(Stream: TStream);
var
  i : LongInt;
begin
  UpdateTime := Stream.ReadInt32;
  Name := Stream.ReadStr;
  Link := Stream.ReadStr;
  Info := Stream.ReadStr;
// similar
  SetLength(Similar, Stream.ReadInt32);
  for i := 0 to Length(Similar) - 1 do
    Similar[i] := Stream.ReadStr;
// top
  SetLength(Top, Stream.ReadInt32);
  for i := 0 to Length(Top) - 1 do
    Top[i] := Stream.ReadStr;
end;

destructor TArtist.Destroy;
begin
  if Image <> nil then
    Image.Free;
  inherited;
end;

procedure TArtist.Save(Stream: TStream);
var
  i : LongInt;
begin
  Stream.WriteInt32(UpdateTime);
  Stream.WriteStr(Name);
  Stream.WriteStr(Link);
  Stream.WriteStr(Info);
// similar
  Stream.WriteInt32(Length(Similar));
  for i := 0 to Length(Similar) - 1 do
    Stream.WriteStr(Similar[i]);
// top
  Stream.WriteInt32(Length(Top));
  for i := 0 to Length(Top) - 1 do
    Stream.WriteStr(Top[i]);
end;

procedure TArtist.Parse(XML: TXML);
var
  i : LongInt;
  s : WideString;
begin
  if XML = nil then
    Exit;
  LastFM.CS.Lock;
// ... get correct name ... { TODO : correct artist name }

// get similar artists
  if XML.Node['similar'] <> nil then
    with XML.Node['similar'] do
    begin
      SetLength(Similar, Count);
      for i := 0 to Count - 1 do
        Similar[i] := SpecToChar(NodeI[i].Value['name']);
    end;

// get summary info
  if XML.Node['bio'] <> nil then
    with XML['bio'] do
      if Node['summary'] <> nil then
      begin
        s := SpecToChar(Value['summary']);
      // remove cdata tag
        s := ReplaceStr(s, '<![CDATA[', '');
        s := ReplaceStr(s, ']]>', '');
        if (Info = '') and (s = '') then
        begin
          Info := ' ';
          QueryTimeInfo := 0;
          QueryInfo('en');
        end else
          Info := s;
      end;

// get image link
  for i := 0 to XML.Count - 1 do
    if (XML.NodeI[i].Tag = 'image') and (XML.NodeI[i].Params['size'] = 'large') then
    begin
      Link := XML.NodeI[i].Content;
      break;
    end;
  LastFM.CS.Unlock;
end;

procedure TArtist.QueryInfo(const Lang: WideString);
begin
  if GetTime - QueryTimeInfo > ARTIST_MAX_TIME_INFO then
  begin
    QueryTimeInfo := GetTime;
    LastFM.Query([Param('artist', Name),
                  Param('lang', Lang)], 'artist.getInfo', Integer(Self), @InfoProc);
  end;
end;

function TArtist.DrawImage(Canvas: TCanvas; X, Y: LongInt): LongInt;
begin
  Result := 64;
  if (Image = nil) and (GetTime - QueryTimeInfo > ARTIST_MAX_TIME_IMAGE) then
  begin
    QueryTimeImage := GetTime;
    HTTP.QueryImage(Link, Integer(Self), @ImageProc);
  end;
// draw image
  if Image <> nil then
    with Image do
    begin
      Canvas.PenColor := COLOR_5;
      Draw(Canvas, SetRect(0, 0, Width, Height), SetRect(X + 1, Y + 1, X + Width + 1, Y + Height + 1));
      Canvas.FrameRect(SetRect(X, Y, X + Width + 2, Y + Height + 2));
    end;
end;

function TArtist.Draw(Canvas: TCanvas; X, Y, Width: LongInt): LongInt;
var
  HRect : TRect;
begin
  HRect := SetRect(X, Y, X + Width, 64);
  Canvas.BrushColor := $FFFFFF;
  Canvas.PenColor   := $FFFFFF;
  Canvas.FillRect(HRect);
  Canvas.FrameRect(HRect);

  Result := DrawImage(Canvas, X + 4, Y + 4);
end;
{$ENDREGION}

{$REGION 'TLastFM'}
constructor TLastFM.Create;
var
  i : LongInt;
  Stream : TFileStream;
begin
  CS.Init;
  Stream := TFileStream.Create(RootDir + 'lastfm.dat', fmRead);
  if Stream.Valid and (Stream.ReadInt32 = LASTFM_VERSION) then
  begin
    SetLength(FArtist, Stream.ReadInt32);
    for i := 0 to Length(FArtist) - 1 do
      FArtist[i] := TArtist.Create(Stream);
  end;
  Stream.Free;
end;

destructor TLastFM.Destroy;
var
  i : LongInt;
begin
  CS.Lock;
  for i := 0 to Length(FArtist) - 1 do
    FArtist[i].Free;
  FArtist := nil;
  CS.Unlock;
  CS.Free;
  inherited;
end;

procedure TLastFM.Save;
var
  i : LongInt;
  Stream : TFileStream;
begin
  CheckFolders;
  CS.Lock;
  Stream := TFileStream.Create(RootDir + 'lastfm.dat', fmWrite);
  if Stream.Valid then
  begin
    Stream.WriteInt32(LASTFM_VERSION);
    Stream.WriteInt32(Length(FArtist));
    for i := 0 to Length(FArtist) - 1 do
      FArtist[i].Save(Stream);
  end;
  Stream.Free;
  FSaveQuery := False;
  CS.Unlock;
end;

procedure TLastFM.SaveQuery;
begin
  FSaveQuery := True;
end;

procedure TLastFM.Update;
begin
  if FSaveQuery then
    Save;
end;

function TLastFM.GetArtist(const Name: WideString): TArtist;
var
  i : LongInt;
  Str : WideString;
begin
  Str := LowerCase(Trim(Name));
  CS.Lock;
  for i := 0 to Length(FArtist) - 1 do
    if Str = FArtist[i].Name then
    begin
      Result := FArtist[i];
      CS.Unlock;
      Exit;
    end;
  Result := TArtist.Create(Str);
  SetLength(FArtist, Length(FArtist) + 1);
  FArtist[Length(FArtist) - 1] := Result;
  CS.Unlock;
end;

procedure TLastFM.Connect(const User, Pass: WideString);
begin
  Connect(User, MD5String(Pass));
end;

procedure TLastFM.Connect(const User: WideString; Pass: TMD5Digest);
var
  dAuth : TMD5Digest;
begin
  dAuth := MD5String(User + ConvHex(Pass, SizeOf(TMD5Digest)));
  Query([Param('authToken', ConvHex(dAuth, SizeOf(TMD5Digest))),
         Param('username', User)], 'auth.getMobileSession', LFM_GET_SESSION, @LastProc);
end;

procedure TLastFM.Query(const Params: array of TParam; const Method: WideString; ID: Integer; Proc: TQueryProc);
var
  sig, URL : WideString;
begin
  if skey <> '' then
    sig := ParamSigURL([Param('api_key', LFM_KEY),
                        Param('method', Method),
                      //  Param('format', 'json'),
                        Param('sk', skey)], Params, '', '', LFM_SECRET, URL)
  else
    sig := ParamSigURL([Param('api_key', LFM_KEY),
                        Param('method', Method)], Params, '', '', LFM_SECRET, URL);
  URL := URL + '&api_sig=' + sig;
  HTTP.Query(qmPOST, LFM_API, '/2.0/', '', AnsiString(URL), ID, Proc, nil, True);
end;

procedure TLastFM.QueryRecs;
begin
  Query([], 'user.getRecommendedArtists', LFM_GET_RECS, @LastProc);
end;

procedure ScrobbleProc(ID: Integer; const Header: AnsiString; const Content: WideString; Data, RawData: Pointer; RawSize: LongInt);
begin
  {$IFDEF DEBUG}Writeln(ID);{$ENDIF}
  {$IFDEF DEBUG}Writeln(Content);{$ENDIF}
end;

procedure TLastFM.Scrobble(const Artist, Track: WideString; Duration: LongInt);
begin
  if (skey = '') or (Artist = '') or (Track = '') then
    Exit;
  Query([Param('artist[0]', Artist),
//         Param('duration', Conv(Duration)),
         Param('timestamp[0]', Conv(vk.ServerTime)),
         Param('track[0]', Track)], 'track.scrobble', 0, @ScrobbleProc);
end;

procedure TLastFM.NowPlaying(const Artist, Track: WideString; Duration: LongInt);
begin
  if (skey = '') or (Artist = '') or (Track = '') then
    Exit;
  PlayTime := vk.ServerTime;
  Query([Param('artist', Artist),
         Param('duration', Conv(Duration)),
         Param('track', Track)], 'track.updateNowPlaying', 1, @ScrobbleProc);
end;
{$ENDREGION}

{$REGION 'TLastFMPanel'}


{$ENDREGION}

end.
