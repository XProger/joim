program joim;

{$IFDEF WIN32}
  //{$SETPEFlAGS 1} // IMAGE_FILE_RELOCS_STRIPPED
  //{$SETPEFlAGS IMAGE_FILE_DEBUG_STRIPPED or IMAGE_FILE_LINE_NUMS_STRIPPED or IMAGE_FILE_LOCAL_SYMS_STRIPPED OR IMAGE_FILE_RELOCS_STRIPPED}
  {$SETPEFlAGS $0200 or $0004 or $0008 or $0001}
{$ENDIF}

{$IFDEF WINDOWS}
  {$DEFINE WIN32}
{$ELSE}
//  {$LINKLIB c}
//  {$LINKLIB pthread}
{$ENDIF}

{$IFDEF WIN32}
  {$IFDEF DEBUG}
    {$APPTYPE CONSOLE}
  {$ELSE}
    {$APPTYPE GUI}
  {$ENDIF}
{$ENDIF}

{$IFDEF VER210}
  {$WEAKLINKRTTI ON}
  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$ENDIF}


{$APPTYPE CONSOLE}

uses
  jdata in 'jdata.pas',
  jsys in 'jsys.pas',
  jutils in 'jutils.pas',
  jhash in 'jhash.pas',
  jxml in 'jxml.pas',
  jjson in 'jjson.pas',
  jzip in 'jzip.pas',
  jimg in 'jimg.pas',
  jglobal in 'jglobal.pas',
  jnet in 'jnet.pas',
  jhttp in 'jhttp.pas',
  jctrl in 'jctrl.pas',
  jflash in 'jflash.pas',
  jroster in 'jroster.pas',
  jinfo in 'jinfo.pas',
  jhistory in 'jhistory.pas',
  jvk in 'jvk.pas',
  jupdate in 'jupdate.pas',
  jlogon in 'jlogon.pas',
  jmedia in 'jmedia.pas',
  jvchat in 'jvchat.pas',
  jplayer in 'jplayer.pas',
  jstatus in 'jstatus.pas',
  jpopup in 'jpopup.pas',
  jlastfm in 'jlastfm.pas';

{$IFDEF WIN32}
  {$R 'joim.res'}
{$ENDIF}
{
var
  d : PByteArray;
  Stream : TMemoryStream;
  i, t, w, h : LongInt;
begin
  Stream := TFileStream.CreateInMemory('back01.jpg');
  t := GetTime;
  for i := 1 to 100 do
  begin
    LoadJPG(Stream, d, w, h);
    FreeMem(d);
    Stream.Position := 0;
  end;
  Writeln('time: ', GetTime - t);
  Stream.Free;
  Readln;
  TestImg('back01.jpg');
}

procedure InfoProc(Artist: TArtist; const Header: AnsiString; const Content: WideString; Data, RawData: Pointer; RawSize: LongInt);
begin
  {$IFDEF DEBUG}
//    Writeln(Header);
    Writeln(Content);
  {$ENDIF}
end;

begin
{$IFNDEF FPC}
  IsMultiThread := True;
  {$IFDEF DEBUG}
    IsConsole := False;
    ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
{$ENDIF}
//  TestImg('test.jpg');
{
  BinToPas('ImgBase.png', 'ImgBase.pas');
  BinToPas('ImgMood.png', 'ImgMood.pas');
  BinToPas('ImgSmile.png', 'ImgSmile.pas');
//  BinToPas('src/swf/bin/joim.swf', 'swf.pas');
  BinToPas('ImgIcon.png', 'ImgIcon.pas');
  BinToPas('in.wav', 'in.pas');
  Exit;
}
  InitGlobal;
//  LastFM.Connect('xproger', 'blablabla');

  CheckUpdate;

//  LastFM.Query([Param('artist', 'Alien Vampires'), Param('lang', 'ru')], 'artist.getInfo', 0, @InfoProc);
{
  Activate_Roster;
  vk.ResReady := False;
  Roster.OwnerUser.Name := 'XProger';
  Roster.OwnerUser.JID  := 'xproger@vk.com';
  Roster.Add('none', 'lala@vk.com', 'lalala');
}
  jctrl.MessageLoop;
  FreeGlobal;
end.
