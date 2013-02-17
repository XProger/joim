unit jflash;

interface

uses
  jsys, jutils, jxml, jctrl;

{$IFDEF WIN32}
{$REGION 'ActiveX'}
const
  CLASS_ShockwaveFlash   : TGUID = '{D27CDB6E-AE6D-11CF-96B8-444553540000}';
  IID_IShockwaveFlash    : TGUID = '{D27CDB6C-AE6D-11CF-96B8-444553540000}';
  IID_IOleObject         : TGUID = '{00000112-0000-0000-C000-000000000046}';
  IID_IOleInPlaceObject  : TGUID = '{00000113-0000-0000-C000-000000000046}';
  IID_IPersistStreamInit : TGUID = '{7FD52380-4E07-101B-AE2D-08002B2EC713}';

  CLSCTX_INPROC_SERVER     = 1;
  OLECLOSE_NOSAVE          = 1;
  OLEIVERB_INPLACEACTIVATE = -5;

  ole32 = 'ole32.dll';

  function CoCreateInstance(const clsid: TGUID; unkOuter: IUnknown; dwClsContext: Longint; const iid: TGUID; out pv): HResult; stdcall; external ole32;
  function OleInitialize(pwReserved: Pointer): HResult; stdcall; external ole32;

type
  TOleInPlaceFrameInfo = record
    cb: Integer;
    fMDIApp: BOOL;
    hwndFrame: HWND;
    haccel: LongWord;
    cAccelEntries: Integer;
  end;

  IOleClientSite = interface(IUnknown)
    ['{00000118-0000-0000-C000-000000000046}']
    function SaveObject: HResult; stdcall;
    function GetMoniker(dwAssign: Longint; dwWhichMoniker: Longint; out mk: IUnknown): HResult; stdcall;
    function GetContainer(out container: IUnknown): HResult; stdcall;
    function ShowObject: HResult; stdcall;
    function OnShowWindow(fShow: BOOL): HResult; stdcall;
    function RequestNewObjectLayout: HResult; stdcall;
  end;

  IOleWindow = interface(IUnknown)
    ['{00000114-0000-0000-C000-000000000046}']
    function GetWindow(out wnd: HWnd): HResult; stdcall;
    function ContextSensitiveHelp(fEnterMode: BOOL): HResult; stdcall;
  end;

  IOleInPlaceSite = interface(IOleWindow)
    ['{00000119-0000-0000-C000-000000000046}']
    function CanInPlaceActivate: HResult; stdcall;
    function OnInPlaceActivate: HResult; stdcall;
    function OnUIActivate: HResult; stdcall;
    function GetWindowContext(out frame: IUnknown; out doc: IUnknown; out rcPosRect: TRect; out rcClipRect: TRect; out frameInfo: TOleInPlaceFrameInfo): HResult; stdcall;
    function Scroll(scrollExtent: TPoint): HResult; stdcall;
    function OnUIDeactivate(fUndoable: BOOL): HResult; stdcall;
    function OnInPlaceDeactivate: HResult; stdcall;
    function DiscardUndoState: HResult; stdcall;
    function DeactivateAndUndo: HResult; stdcall;
    function OnPosRectChange(const rcPosRect: TRect): HResult; stdcall;
  end;

  IOleInPlaceObject = interface(IOleWindow)
    ['{00000113-0000-0000-C000-000000000046}']
    function InPlaceDeactivate: HResult; stdcall;
    function UIDeactivate: HResult; stdcall;
    function SetObjectRects(const rcPosRect: TRect; const rcClipRect: TRect): HResult; stdcall;
    function ReactivateAndUndo: HResult; stdcall;
  end;

  IOleObject = interface(IUnknown)
    ['{00000112-0000-0000-C000-000000000046}']
    function SetClientSite(const clientSite: IOleClientSite): HResult; stdcall;
    function GetClientSite(out clientSite: IOleClientSite): HResult; stdcall;
    function SetHostNames(szContainerApp: Pointer; szContainerObj: Pointer): HResult; stdcall;
    function Close(dwSaveOption: Longint): HResult; stdcall;
    function SetMoniker(dwWhichMoniker: Longint; const mk: IUnknown): HResult; stdcall;
    function GetMoniker(dwAssign: Longint; dwWhichMoniker: Longint;
      out mk: IUnknown): HResult; stdcall;
    function InitFromData(const dataObject: IUnknown; fCreation: BOOL;
      dwReserved: Longint): HResult; stdcall;
    function GetClipboardData(dwReserved: Longint; out dataObject: IUnknown): HResult; stdcall;
    function DoVerb(iVerb: Longint; msg: Pointer; const activeSite: IOleClientSite;
      lindex: Longint; hwndParent: HWND; const posRect: TRect): HResult; stdcall;
    // blablabla
  end;

  ISequentialStream = interface(IUnknown)
    ['{0c733a30-2a1c-11ce-ade5-00aa0044773d}']
    function Read(pv: Pointer; cb: LongInt; pcbRead: Pointer): HResult; stdcall;
    function Write(pv: Pointer; cb: LongInt; pcbWritten: Pointer): HResult; stdcall;
  end;

  IStream = interface(ISequentialStream)
    ['{0000000C-0000-0000-C000-000000000046}']
    function Seek(dlibMove: Int64; dwOrigin: LongInt; out libNewPosition: Int64): HResult; stdcall;
    function SetSize(libNewSize: Int64): HResult; stdcall;
    function CopyTo(stm: IStream; cb: Int64; out cbRead: Int64; out cbWritten: Int64): HResult; stdcall;
    function Commit(grfCommitFlags: LongInt): HResult; stdcall;
    function Revert: HResult; stdcall;
    function LockRegion(libOffset: Int64; cb: Int64; dwLockType: LongInt): HResult; stdcall;
    function UnlockRegion(libOffset: Int64; cb: Int64; dwLockType: LongInt): HResult; stdcall;
    function Stat(statstg: Pointer; grfStatFlag: LongInt): HResult; stdcall;
    function Clone(out stm: IStream): HResult; stdcall;
  end;

  IPersist = interface(IUnknown)
    ['{0000010C-0000-0000-C000-000000000046}']
    function GetClassID(classID: Pointer): HResult; stdcall;
  end;

  IPersistStreamInit = interface(IPersist)
    ['{7FD52380-4E07-101B-AE2D-08002B2EC713}']
    function IsDirty: HResult; stdcall;
    function Load(const stm: IStream): HResult; stdcall;
    function Save(const stm: IStream; fClearDirty: BOOL): HResult; stdcall;
    function GetSizeMax(out cbSize: Int64): HResult; stdcall;
    function InitNew: HResult; stdcall;
  end;

  TClientSite = class(TInterfacedObject, IOleClientSite, IOleInPlaceSite)
    constructor Create(Owner: TControl);
  public
    Owner : TControl;
  // IOleClientSite
    function SaveObject: HResult; stdcall;
    function GetMoniker(dwAssign: Longint; dwWhichMoniker: Longint;
      out mk: IUnknown): HResult; stdcall;
    function GetContainer(out container: IUnknown): HResult; stdcall;
    function ShowObject: HResult; stdcall;
    function OnShowWindow(fShow: BOOL): HResult; stdcall;
    function RequestNewObjectLayout: HResult; stdcall;
  // IOleWindow
    function GetWindow(out wnd: HWnd): HResult; stdcall;
    function ContextSensitiveHelp(fEnterMode: BOOL): HResult; stdcall;
  // IOleInPlaceSite
    function CanInPlaceActivate: HResult; stdcall;
    function OnInPlaceActivate: HResult; stdcall;
    function OnUIActivate: HResult; stdcall;
    function GetWindowContext(out frame: IUnknown;
      out doc: IUnknown; out rcPosRect: TRect;
      out rcClipRect: TRect; out frameInfo: TOleInPlaceFrameInfo): HResult;
      stdcall;
    function Scroll(scrollExtent: TPoint): HResult; stdcall;
    function OnUIDeactivate(fUndoable: BOOL): HResult; stdcall;
    function OnInPlaceDeactivate: HResult; stdcall;
    function DiscardUndoState: HResult; stdcall;
    function DeactivateAndUndo: HResult; stdcall;
    function OnPosRectChange(const rcPosRect: TRect): HResult; stdcall;
  end;
{$ENDREGION}

{$REGION 'IShockwaveFlash'}
  IShockwaveFlash = interface(IDispatch)
    ['{D27CDB6C-AE6D-11CF-96B8-444553540000}']
    function Get_ReadyState: Integer; safecall;
    function Get_TotalFrames: Integer; safecall;
    function Get_Playing: WordBool; safecall;
    procedure Set_Playing(pVal: WordBool); safecall;
    function Get_Quality: Integer; safecall;
    procedure Set_Quality(pVal: Integer); safecall;
    function Get_ScaleMode: Integer; safecall;
    procedure Set_ScaleMode(pVal: Integer); safecall;
    function Get_AlignMode: Integer; safecall;
    procedure Set_AlignMode(pVal: Integer); safecall;
    function Get_BackgroundColor: Integer; safecall;
    procedure Set_BackgroundColor(pVal: Integer); safecall;
    function Get_Loop: WordBool; safecall;
    procedure Set_Loop(pVal: WordBool); safecall;
    function Get_Movie: WideString; safecall;
    procedure Set_Movie(const pVal: WideString); safecall;
    function Get_FrameNum: Integer; safecall;
    procedure Set_FrameNum(pVal: Integer); safecall;
    procedure SetZoomRect(left: Integer; top: Integer; right: Integer; bottom: Integer); safecall;
    procedure Zoom(factor: Integer); safecall;
    procedure Pan(x: Integer; y: Integer; mode: Integer); safecall;
    procedure Play; safecall;
    procedure Stop; safecall;
    procedure Back; safecall;
    procedure Forward; safecall;
    procedure Rewind; safecall;
    procedure StopPlay; safecall;
    procedure GotoFrame(FrameNum: Integer); safecall;
    function CurrentFrame: Integer; safecall;
    function IsPlaying: WordBool; safecall;
    function PercentLoaded: Integer; safecall;
    function FrameLoaded(FrameNum: Integer): WordBool; safecall;
    function FlashVersion: Integer; safecall;
    function Get_WMode: WideString; safecall;
    procedure Set_WMode(const pVal: WideString); safecall;
    function Get_SAlign: WideString; safecall;
    procedure Set_SAlign(const pVal: WideString); safecall;
    function Get_Menu: WordBool; safecall;
    procedure Set_Menu(pVal: WordBool); safecall;
    function Get_Base: WideString; safecall;
    procedure Set_Base(const pVal: WideString); safecall;
    function Get_Scale: WideString; safecall;
    procedure Set_Scale(const pVal: WideString); safecall;
    function Get_DeviceFont: WordBool; safecall;
    procedure Set_DeviceFont(pVal: WordBool); safecall;
    function Get_EmbedMovie: WordBool; safecall;
    procedure Set_EmbedMovie(pVal: WordBool); safecall;
    function Get_BGColor: WideString; safecall;
    procedure Set_BGColor(const pVal: WideString); safecall;
    function Get_Quality2: WideString; safecall;
    procedure Set_Quality2(const pVal: WideString); safecall;
    procedure LoadMovie(layer: Integer; const url: WideString); safecall;
    procedure TGotoFrame(const target: WideString; FrameNum: Integer); safecall;
    procedure TGotoLabel(const target: WideString; const label_: WideString); safecall;
    function TCurrentFrame(const target: WideString): Integer; safecall;
    function TCurrentLabel(const target: WideString): WideString; safecall;
    procedure TPlay(const target: WideString); safecall;
    procedure TStopPlay(const target: WideString); safecall;
    procedure SetVariable(const name: WideString; const value: WideString); safecall;
    function GetVariable(const name: WideString): WideString; safecall;
    procedure TSetProperty(const target: WideString; property_: Integer; const value: WideString); safecall;
    function TGetProperty(const target: WideString; property_: Integer): WideString; safecall;
    procedure TCallFrame(const target: WideString; FrameNum: Integer); safecall;
    procedure TCallLabel(const target: WideString; const label_: WideString); safecall;
    procedure TSetPropertyNum(const target: WideString; property_: Integer; value: Double); safecall;
    function TGetPropertyNum(const target: WideString; property_: Integer): Double; safecall;
    function TGetPropertyAsNumber(const target: WideString; property_: Integer): Double; safecall;
    function Get_SWRemote: WideString; safecall;
    procedure Set_SWRemote(const pVal: WideString); safecall;
    function Get_FlashVars: WideString; safecall;
    procedure Set_FlashVars(const pVal: WideString); safecall;
    function Get_AllowScriptAccess: WideString; safecall;
    procedure Set_AllowScriptAccess(const pVal: WideString); safecall;
    function Get_MovieData: WideString; safecall;
    procedure Set_MovieData(const pVal: WideString); safecall;
    function Get_InlineData: IUnknown; safecall;
    procedure Set_InlineData(const ppIUnknown: IUnknown); safecall;
    function Get_SeamlessTabbing: WordBool; safecall;
    procedure Set_SeamlessTabbing(pVal: WordBool); safecall;
    procedure EnforceLocalSecurity; safecall;
    function Get_Profile: WordBool; safecall;
    procedure Set_Profile(pVal: WordBool); safecall;
    function Get_ProfileAddress: WideString; safecall;
    procedure Set_ProfileAddress(const pVal: WideString); safecall;
    function Get_ProfilePort: Integer; safecall;
    procedure Set_ProfilePort(pVal: Integer); safecall;
    function CallFunction(const request: WideString): WideString; safecall;
    procedure SetReturnValue(const returnValue: WideString); safecall;
    procedure DisableLocalSecurity; safecall;
    function Get_AllowNetworking: WideString; safecall;
    procedure Set_AllowNetworking(const pVal: WideString); safecall;
    function Get_AllowFullScreen: WideString; safecall;
    procedure Set_AllowFullScreen(const pVal: WideString); safecall;
  end;

  TFlashStream = class(TInterfacedObject, IStream)
    constructor Create(MemData: Pointer; MemSize: LongInt);
  private
    Data : Pointer;
    Size : LongInt;
    Pos  : LongInt;
  public
    function Read(pv: Pointer; cb: LongInt; pcbRead: Pointer): HResult; stdcall;
    function Write(pv: Pointer; cb: LongInt; pcbWritten: Pointer): HResult; stdcall;
    function Seek(dlibMove: Int64; dwOrigin: LongInt; out libNewPosition: Int64): HResult; stdcall;
    function SetSize(libNewSize: Int64): HResult; stdcall;
    function CopyTo(stm: IStream; cb: Int64; out cbRead: Int64; out cbWritten: Int64): HResult; stdcall;
    function Commit(grfCommitFlags: LongInt): HResult; stdcall;
    function Revert: HResult; stdcall;
    function LockRegion(libOffset: Int64; cb: Int64; dwLockType: LongInt): HResult; stdcall;
    function UnlockRegion(libOffset: Int64; cb: Int64; dwLockType: LongInt): HResult; stdcall;
    function Stat(statstg: Pointer; grfStatFlag: LongInt): HResult; stdcall;
    function Clone(out stm: IStream): HResult; stdcall;
  end;
{$ENDREGION}
{$ENDIF}

type
  TFlash = class(TControl)
    constructor Create(Parent: TControl);
    destructor Destroy; override;
  private
  {$IFDEF WIN32}
    ClientSite : IOleClientSite;
    FlashObj   : IShockwaveFlash;
    OleObject  : IOleObject;
  {$ENDIF}
    FValid     : Boolean;
  public
    procedure Load(Data: Pointer; Size: LongInt);
    function Call(const Name: WideString; const Param: array of WideString): WideString;
    function OnEvent(const Event: TControlEvent): Boolean; override;
    property Valid: Boolean read FValid;
  end;

implementation

uses
  jglobal;

{$IFDEF WIN32}
{$REGION 'TClientSite'}
constructor TClientSite.Create(Owner: TControl);
begin
  inherited Create;
  Self.Owner := Owner;
end;

function TClientSite.CanInPlaceActivate: HResult; stdcall;
begin
  Result := S_OK;
end;

function TClientSite.ContextSensitiveHelp(fEnterMode: BOOL): HResult; stdcall;
begin
  Result := S_OK;
end;

function TClientSite.DeactivateAndUndo: HResult; stdcall;
begin
  Result := S_OK;
end;

function TClientSite.DiscardUndoState: HResult; stdcall;
begin
  Result := S_OK;
end;

function TClientSite.GetContainer(out container: IUnknown): HResult; stdcall;
begin
  container := nil;
  Result := E_NOINTERFACE;
end;

function TClientSite.GetMoniker(dwAssign, dwWhichMoniker: Integer; out mk: IUnknown): HResult; stdcall;
begin
  mk := nil;
  Result := E_NOTIMPL;
end;

function TClientSite.GetWindow(out wnd: HWnd): HResult; stdcall;
begin
  wnd := Window.Handle;
  Result := S_OK;
end;

function TClientSite.GetWindowContext(out frame: IUnknown; out doc: IUnknown; out rcPosRect, rcClipRect: TRect; out frameInfo: TOleInPlaceFrameInfo): HResult; stdcall;
begin
  frameInfo.fMDIApp       := False;
  frameInfo.hwndFrame     := Window.Handle;
  frameInfo.haccel        := 0;
  frameInfo.cAccelEntries := 0;

  rcPosRect  := Owner.Rect;
  rcClipRect := Owner.Rect;

  Result := S_OK;
end;

function TClientSite.OnInPlaceActivate: HResult; stdcall;
begin
  Result := S_OK;
end;

function TClientSite.OnInPlaceDeactivate: HResult; stdcall;
begin
  Result := S_OK;
end;

function TClientSite.OnPosRectChange(const rcPosRect: TRect): HResult; stdcall;
begin
  Result := E_NOINTERFACE;
end;

function TClientSite.OnShowWindow(fShow: BOOL): HResult; stdcall;
begin
  Result := S_OK;
end;

function TClientSite.OnUIActivate: HResult; stdcall;
begin
  Result := S_OK;
end;

function TClientSite.OnUIDeactivate(fUndoable: BOOL): HResult; stdcall;
begin
  Result := S_OK;
end;

function TClientSite.RequestNewObjectLayout: HResult; stdcall;
begin
  Result := E_NOTIMPL;
end;

function TClientSite.SaveObject: HResult; stdcall;
begin
  Result := S_OK;
end;

function TClientSite.Scroll(scrollExtent: TPoint): HResult; stdcall;
begin
  Result := S_OK;
end;

function TClientSite.ShowObject: HResult; stdcall;
begin
  Result := S_OK;
end;
{$ENDREGION}

{$REGION 'TFlashStream'}
constructor TFlashStream.Create(MemData: Pointer; MemSize: LongInt);
begin
  Data := MemData;
  Size := MemSize;
  Pos  := 0;
end;

function TFlashStream.Read(pv: Pointer; cb: LongInt; pcbRead: Pointer): HResult; stdcall;
begin
  Result := S_OK;
  if (Pos = 0) and (cb = 4) then
  begin
    Move(PAnsiChar('fUfU')^, pv^, 4);
    Inc(Pos, 4);
  end else
    if (Pos = 4) and (cb = 4) then
    begin
      Move(Size, pv^, 4);
      Inc(Size, 8);
      Inc(Pos, 4);
    end else
      begin
        if (Pos + cb > Size) then
          cb := Size - Pos;
        if cb <> 0 then
        begin
          Move(PByteArray(Data)^[Pos - 8], pv^, cb);
          if pcbRead <> nil then
            LongInt(pcbRead^) := cb;
          Inc(Pos, cb);
        end else
          Result := S_FALSE;
      end;
end;

function TFlashStream.Write(pv: Pointer; cb: LongInt; pcbWritten: Pointer): HResult; stdcall;
begin
  Result := E_NOTIMPL;
end;

function TFlashStream.Seek(dlibMove: Int64; dwOrigin: LongInt; out libNewPosition: Int64): HResult; stdcall;
begin
  Result := E_NOTIMPL;
end;

function TFlashStream.SetSize(libNewSize: Int64): HResult; stdcall;
begin
  Result := E_NOTIMPL;
end;

function TFlashStream.CopyTo(stm: IStream; cb: Int64; out cbRead: Int64; out cbWritten: Int64): HResult; stdcall;
begin
  Result := E_NOTIMPL;
end;

function TFlashStream.Commit(grfCommitFlags: LongInt): HResult; stdcall;
begin
  Result := E_NOTIMPL;
end;

function TFlashStream.Revert: HResult; stdcall;
begin
  Result := E_NOTIMPL;
end;

function TFlashStream.LockRegion(libOffset: Int64; cb: Int64; dwLockType: LongInt): HResult; stdcall;
begin
  Result := E_NOTIMPL;
end;

function TFlashStream.UnlockRegion(libOffset: Int64; cb: Int64; dwLockType: LongInt): HResult; stdcall;
begin
  Result := E_NOTIMPL;
end;

function TFlashStream.Stat(statstg: Pointer; grfStatFlag: LongInt): HResult; stdcall;
begin
  Result := E_NOTIMPL;
end;

function TFlashStream.Clone(out stm: IStream): HResult; stdcall;
begin
  Result := E_NOTIMPL;
end;
{$ENDREGION}
{$ENDIF}

{$REGION 'TFlash'}
constructor TFlash.Create(Parent: TControl);
begin
  inherited;
{$IFNDEF FPC}
{$IFDEF WIN32}
  ClientSite := TClientSite.Create(Self);

  FValid := (CoCreateInstance(CLASS_ShockwaveFlash, nil, CLSCTX_INPROC_SERVER, IID_IShockwaveFlash, FlashObj) = S_OK) and
            (FlashObj.FlashVersion >= 655360) and // 10.0
            (FlashObj.QueryInterface(IID_IOleObject, OleObject) = S_OK) and
            (OleObject.SetClientSite(ClientSite) = S_OK) and
            (OleObject.DoVerb(OLEIVERB_INPLACEACTIVATE, nil, ClientSite, 0, Window.Handle, ARect) = S_OK);

  if FValid then
    FlashObj.DisableLocalSecurity;
  SetFocus(Window.Handle);
{$ENDIF}
{$ENDIF}
end;

destructor TFlash.Destroy;
begin
{$IFDEF WIN32}
  if FlashObj <> nil then
  begin
    if OleObject <> nil then
    begin
      OleObject.Close(OLECLOSE_NOSAVE);
      OleObject := nil;
    end;
    FlashObj := nil;
  end;
{$ENDIF}
  inherited;
end;

procedure TFlash.Load(Data: Pointer; Size: LongInt);
{$IFDEF WIN32}
var
  FlashStream : TFlashStream;
  StreamInit  : IPersistStreamInit;
begin
  if Valid then
  begin
//    FlashObj.Set_Movie('H:\Projects\joim\src\swf\bin\joim.swf');
    FlashStream := TFlashStream.Create(Data, Size);
    FlashObj.QueryInterface(IID_IPersistStreamInit, StreamInit);
    if StreamInit <> nil then
    begin
      StreamInit.InitNew;
      StreamInit.Load(IStream(FlashStream));
      StreamInit := nil;
    end;
    FlashStream.Free;
  end;
end;
{$ELSE}
begin
end;
{$ENDIF}

function TFlash.Call(const Name: WideString; const Param: array of WideString): WideString;
{$IFDEF WIN32}
var
  Req : WideString;
  i   : LongInt;
  XML : TXML;
begin
  if Valid then
  begin
    Req := '<invoke name="' + Name + '" returntype="xml"><arguments>';
    for i := 0 to Length(Param) - 1 do
      Req := Req + '<string>' + Param[i] + '</string>';
    Req := Req + '</arguments></invoke>';
    try
      Result := FlashObj.CallFunction(Req);
    except
    end;
    XML := TXML.Create(Result, 1);
    Result := XML.Content;
    XML.Free;
  end;
end;
{$ELSE}
begin
  Result := '';
end;
{$ENDIF}

function TFlash.OnEvent(const Event: TControlEvent): Boolean;
{$IFDEF WIN32}
var
  OleInPlaceObject : IOleInPlaceObject;
begin
  Result := inherited OnEvent(Event);
  if Valid then
    case Event.ID of
      etSize :
        if FlashObj.QueryInterface(IID_IOleInPlaceObject, OleInPlaceObject) = S_OK then
          OleInPlaceObject.SetObjectRects(ARect, ARect);
  //    etDraw : PostMessage(ClientSite., WM_PAINT, (WPARAM)mhDC, 0);
    end;
end;
{$ELSE}
begin
  Result := inherited OnEvent(Event);
end;
{$ENDIF}
{$ENDREGION}

{$IFDEF WIN32}
initialization
  OleInitialize(nil);
{$ENDIF}

end.
