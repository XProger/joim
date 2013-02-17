unit jupdate;

interface

uses
  jsys, jutils, jxml, jctrl, jhttp, jzip;

const
  UPDATE_HOST = 'mentalx.org';
  UPDATE_FILE = '/joim.xml';

  procedure CheckUpdate;

implementation

uses
  jglobal, jvk;

const
  OLD_EXT   = '.old';

procedure OnUpdate(ID: Integer; const Header: AnsiString; const Content: WideString; Data, RawData: Pointer; RawSize: LongInt); forward;

procedure CheckUpdate;
begin
  Activate_Logon;
  Logon.ShowLoading;
  Window.Text := LangMsg[lmUpdateCheck];
  DeleteFile(AppPath + OLD_EXT);
  HTTP.Query(qmGET, UPDATE_HOST, UPDATE_FILE, '', '', 0, onUpdate, nil, False);
end;

function CheckAccess: Boolean;
begin
  Result := MoveFile(AppPath, AppPath + OLD_EXT);
  if Result then
    Result := MoveFile(AppPath + OLD_EXT, AppPath);
end;

procedure UpdateSkip;
begin
  Window.Text := LangMsg[lmLogonWnd];
  Activate_Logon;
end;

procedure Update(XML: TXML);
begin
  with XML do
    if Value['version'] > CLIENT_VER then
    begin
      if CheckAccess then
      begin
        HTTP.QueryImage(XML.Value['url'], 1, onUpdate);
        Logon.ShowLoading;
      end else
      begin
      {$IFNDEF FPC}
        if MessageBoxW(AppWindow.Handle, PWideChar(LangMsg[lmUpdateError]), nil, MB_YESNO or MB_ICONWARNING) = IDYES then
          BrowseURL(VK_URL + 'pages?oid=-19132165&p=faq');
      {$ENDIF}
        UpdateSkip;
      end
    end else
      UpdateSkip;
end;

procedure UpdateSave(Data: PByteArray; Size: LongInt);
var
  Stream : TFileStream;
  DStream : TDecompressor;
  DSize : LongWord;
  ptr : Pointer;
begin
  if (Data = nil) or (Size <= 0) then
  begin
    UpdateSkip;
    Exit;
  end;

  DStream := TDecompressor.Create;
  DSize := DStream.SizeGZIP(Data, Size);
  ptr := GetMemory(DSize);
  DStream.ReadGZIP(Data, ptr);
  DStream.Free;

  MoveFile(AppPath, AppPath + OLD_EXT);
  Stream := TFileStream.Create(AppPath, fmWrite);
  if not Stream.Valid then
  begin
    MoveFile(AppPath + OLD_EXT, AppPath);
    UpdateSkip;
  end else
    Stream.Write(ptr^, DSize);
  FreeMemory(ptr);
  Stream.Free;

  RestartApp;
  Window.Close;
end;

procedure OnUpdate(ID: Integer; const Header: AnsiString; const Content: WideString; Data, RawData: Pointer; RawSize: LongInt);
var
  XML : TXML;
begin
  case ID of
    0 :
      begin
        XML := TXML.Create(Content, 1);
        if XML.DataLen > 1 then
          Update(XML);
        XML.Free;
      end;
    1 : UpdateSave(RawData, RawSize);
  end;
end;

end.
