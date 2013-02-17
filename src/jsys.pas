unit jsys;

interface

{$R-}

{$IFDEF LINUX}
uses
  cthreads, ctypes, x, xlib, xutil;
{$ENDIF}
{$IFDEF DARWIN}
uses
  cthreads, MacOSAll;
{$ENDIF}

const
  IBYTE = 1 / 255;
  INFINITE = LongWord($FFFFFFFF);

{$REGION 'Keys'}
const
  VK_SHIFT   = $10;
  VK_BACK    = 8;
  VK_TAB     = 9;
  VK_RETURN  = 13;
  VK_CONTROL = 17;
  VK_MENU    = 18;
  VK_ESCAPE  = 27;
  VK_SPACE   = 32;
  VK_PRIOR   = 33;
  VK_NEXT    = 34;
  VK_END     = 35;
  VK_HOME    = 36;
  VK_LEFT    = 37;
  VK_UP      = 38;
  VK_RIGHT   = 39;
  VK_DOWN    = 40;
  VK_INSERT  = 45;
  VK_DELETE  = 46;
{$ENDREGION}

{$REGION 'BaseTypes'}
type
  TRGBA = record
    B, G, R, A: Byte;
  end;
  PRGBA = ^TRGBA;

  PPoint = ^TPoint;
  TPoint = record
    X, Y : LongInt;
  end;

  PRect = ^TRect;
  TRect = record
    Left, Top, Right, Bottom : LongInt;
  end;

  PSize = ^TSize;
  TSize = record
    Left, Top, Width, Height : SmallInt;
  end;

  TFloatSize = record
    Left, Top, Width, Height : Single;
  end;

  TUnixTime = LongWord;
  TUTime = record
    Year, Month, Day, Hour, Minute, Second : Word;
  end;

  TCharSet = set of AnsiChar;
  TSpecials = set of AnsiChar;

  TByteArray = array [Word] of Byte;
  PByteArray = ^TByteArray;

  TWordArray = array [Word] of Word;
  PWordArray = ^TWordArray;

  TSmallIntArray = array [Word] of SmallInt;
  PSmallIntArray = ^TSmallIntArray;

  TIntArray = array [Word] of LongInt;
  PIntArray = ^TIntArray;

  TLongArray = array [Word] of LongWord;
  PLongArray = ^TLongArray;

  TFloatArray = array [Word] of Single;
  PFloatArray = ^TFloatArray;

  TPointerArray = array [Word] of Pointer;
  PPointerArray = ^TPointerArray;

  TStringArray = array of WideString;

  TColor = LongWord;

  TAutorun = (arCheck, arEnable, arDisable);

  TMsgDate = record
    Day   : Byte;
    Month : Byte;
    Year  : Word;
  end;

  TMsgTime = record
    Hour   : Byte;
    Minute : Byte;
  end;

  TMsgDateTime = record
    Date : TMsgDate;
    Time : TMsgTime;
  end;

  TStringPart = record
    Start, Length, Left, Right : Word;
  end;

  TStringPartArray = array of TStringPart;

  TTimerProc = procedure;
{$ENDREGION}

{$REGION 'Windows'}
{$IFDEF WIN32}
const
  kernel32 = 'kernel32.dll';
  gdi32    = 'gdi32.dll';
  user32   = 'user32.dll';
  advapi32 = 'advapi32.dll';
  winmm    = 'winmm.dll';
  shell32  = 'shell32.dll';

  IDC_ARROW  = PWideChar(32512);
  IDC_HAND   = PWideChar(32649);
  IDC_IBEAM  = PWideChar(32513);
  IDC_SIZEWE = PWideChar(32644);
  IDC_SIZENS = PWideChar(32645);

  CP_UTF8 = 65001;

  WS_POPUP         = LongWord($80000000);
  WS_SYSMENU       = $80000;
  WS_THICKFRAME    = $40000;
  WS_CAPTION       = $C00000;
  WS_MAXIMIZEBOX   = $10000;
  WS_MINIMIZEBOX   = $20000;
  WS_EX_TOPMOST    = 8;
  WS_EX_TOOLWINDOW = $80;
  WS_EX_APPWINDOW  = $40000;

  SW_HIDE = 0;
  SW_SHOW = 5;

  GWL_STYLE    = -16;
  GWL_WNDPROC  = -4;
  GWL_USERDATA = -21;
  GWL_EXSTYLE  = -20;

  GCL_STYLE     = -26;
  CS_DROPSHADOW = $20000;

  IDANI_OPEN    = 1;
  IDANI_CLOSE   = 2;
  IDANI_CAPTION = 3;

  SPI_GETWORKAREA = $0030;

  SND_ASYNC       = $0001;
  SND_MEMORY      = $0004;

  NIM_ADD         = $00000000;
  NIM_MODIFY      = $00000001;
  NIM_DELETE      = $00000002;
  NIF_MESSAGE     = $00000001;
  NIF_ICON        = $00000002;
  NIF_TIP         = $00000004;

  WM_DESTROY          = $0002;
  WM_MOVE             = $0003;
  WM_SIZE             = $0005;
  WM_ACTIVATE         = $0006;
  WM_ERASEBKGND       = $0014;
  WM_PAINT            = $000F;
  WM_ACTIVATEAPP      = $001C;
  WM_SETCURSOR        = $0020;
  WM_GETMINMAXINFO    = $0024;
  WM_SETICON          = $0080;
  WM_NCHITTEST        = $0084;
  WM_NCMOUSEMOVE      = $00A0;

  WM_KEYDOWN          = $0100;
  WM_KEYUP            = $0101;
  WM_CHAR             = $0102;

  WM_SYSKEYDOWN       = $0104;
  WM_SYSKEYUP         = $0105;
  WM_SYSCHAR          = $0106;


  WM_TIMER            = $0113;

  WM_MOUSEMOVE        = $0200;
  WM_LBUTTONDOWN      = $0201;
  WM_LBUTTONUP        = $0202;
  WM_LBUTTONDBLCLK    = $0203;
  WM_RBUTTONDOWN      = $0204;
  WM_RBUTTONUP        = $0205;
  WM_RBUTTONDBLCLK    = $0206;
  WM_MBUTTONDOWN      = $0207;
  WM_MBUTTONUP        = $0208;
  WM_MBUTTONDBLCLK    = $0209;
  WM_MOUSEWHEEL       = $020A;

  WM_SIZING           = 532;
  WM_HOTKEY           = $0312;
  WM_USER             = $0400;
  WM_TRAYICON         = WM_USER + 1;

  WM_SYSCOMMAND       = $0112;
  WM_NCACTIVATE       = $0086;

  SIZE_MINIMIZED = 1;

  SC_MINIMIZE = 61472;
  SC_CLOSE    = 61536;

  MK_LBUTTON = 1;
  MK_RBUTTON = 2;
  MK_SHIFT   = 4;
  MK_CONTROL = 8;
  MK_MBUTTON = $10;

  VK_MEDIA_NEXT_TRACK = $B0;
  VK_MEDIA_PREV_TRACK = $B1;
  VK_MEDIA_STOP       = $B2;
  VK_MEDIA_PLAY_PAUSE = $B3;

  MOD_ALT     = 1;
  MOD_CONTROL = 2;

  SRCCOPY    = $00CC0020;

  MB_YESNO        = $00000004;
  MB_ICONWARNING  = $00000030;
  MB_ICONQUESTION = $00000020;
  IDYES = 6;

  HTCLIENT      = 1;
  HTCAPTION     = 2;
  HTLEFT        = 10;
  HTRIGHT       = 11;
  HTTOP         = 12;
  HTTOPLEFT     = 13;
  HTTOPRIGHT    = 14;
  HTBOTTOM      = 15;
  HTBOTTOMLEFT  = $10;
  HTBOTTOMRIGHT = 17;

  SWP_NOSIZE     = 1;
  SWP_NOMOVE     = 2;
  SWP_NOZORDER   = 4;
  SWP_NOREDRAW   = 8;
  SWP_NOACTIVATE = $10;
  SWP_SHOWWINDOW = $40;
  SWP_HIDEWINDOW = $80;

  FLASHW_STOP      = $0;
  FLASHW_CAPTION   = $1;
  FLASHW_TRAY      = $2;
  FLASHW_ALL       = FLASHW_CAPTION or FLASHW_TRAY;
  FLASHW_TIMERNOFG = $C;

  FW_NORMAL = 400;
  FW_BOLD   = 700;

  SYNCHRONIZE              = $00100000;
  STANDARD_RIGHTS_REQUIRED = $000F0000;
  PROCESS_ALL_ACCESS       = (STANDARD_RIGHTS_REQUIRED or SYNCHRONIZE or $FFF);
  HKEY_CURRENT_USER = LongWord($80000001);
  CF_UNICODETEXT = 13;
  GMEM_MOVEABLE  = 2;

var
  WM_TASKBARCREATED       : LongWord = 0;
//  WM_TASKBARBUTTONCREATED : LongWord = 0;

type
  BOOL    = LongBool;
  DWORD   = LongWord;
  PDWORD  = ^DWORD;
  UINT    = LongWord;
  SHORT   = SmallInt;
  HWND    = LongWord;
  LPCSTR  = PAnsiChar;
  LPWSTR  = PWideChar;
  HRESULT = LongInt;
  LPARAM  = Integer;
  WPARAM  = Integer;
  LRESULT = Integer;
  HKEY    = LongWord;

  HGDIOBJ = LongWord;
  HDC     = LongWord;
  HMENU   = LongWord;
  HICON   = HGDIOBJ;
  HCURSOR = HGDIOBJ;
  HBITMAP = HGDIOBJ;
  HBRUSH  = HGDIOBJ;
  HPEN    = HGDIOBJ;
  HFONT   = HGDIOBJ;
  HRGN    = HGDIOBJ;
  HGLOBAL = THandle;
  HINST   = THandle;

  COLORREF  = DWORD;
  TThreadID = Integer;

  TFileTime = record
    dwLowDateTime  : DWORD;
    dwHighDateTime : DWORD;
  end;

  TSystemTime = record
    wYear      : Word;
    wMonth     : Word;
    wDayOfWeek : Word;
    wDay       : Word;
    wHour      : Word;
    wMinute    : Word;
    wSecond    : Word;
    wMilliseconds : Word;
  end;

  TTimeZoneInformation = record
    Bias: Longint;
    StandardName: array[0..31] of WideChar;
    StandardDate: TSystemTime;
    StandardBias: Longint;
    DaylightName: array[0..31] of WideChar;
    DaylightDate: TSystemTime;
    DaylightBias: Longint;
  end;

  TMsg = packed record
    hwnd: HWND;
    message: UINT;
    wParam: WPARAM;
    lParam: LPARAM;
    time: DWORD;
    pt: TPoint;
  end;

  TPaintStruct = packed record
    hdc: HDC;
    fErase: BOOL;
    rcPaint: TRect;
    fRestore: BOOL;
    fIncUpdate: BOOL;
    rgbReserved: array[0..31] of Byte;
  end;

  PMinMaxInfo = ^TMinMaxInfo;
  TMinMaxInfo = packed record
    ptReserved: TPoint;
    ptMaxSize: TPoint;
    ptMaxPosition: TPoint;
    ptMinTrackSize: TPoint;
    ptMaxTrackSize: TPoint;
  end;

  TFlashInfo = record
    cbSize: UINT;
    hwnd: HWND;
    dwFlags: DWORD;
    uCount: UINT;
    dwTimeout: DWORD;
  end;

  TBitmapInfoHeader = packed record
    biSize: DWORD;
    biWidth: LongInt;
    biHeight: LongInt;
    biPlanes: Word;
    biBitCount: Word;
    biCompression: DWORD;
    biSizeImage: DWORD;
    biXPelsPerMeter: LongInt;
    biYPelsPerMeter: LongInt;
    biClrUsed: DWORD;
    biClrImportant: DWORD;
  end;

  TBitmapInfo = packed record
    bmiHeader : TBitmapInfoHeader;
    bmiColors : array [0..0] of LongWord;
  end;

  TBlendFunction = packed record
    BlendOp: BYTE;
    BlendFlags: BYTE;
    SourceConstantAlpha: BYTE;
    AlphaFormat: BYTE;
  end;

  PNotifyIconDataW = ^TNotifyIconDataW;
  TNotifyIconDataW = record
    cbSize: DWORD;
    Wnd: HWND;
    uID: UINT;
    uFlags: UINT;
    uCallbackMessage: UINT;
    hIcon: HICON;
    szTip: array [0..127] of WideChar;
    dwState: DWORD;
    dwStateMask: DWORD;
    szInfo: array [0..255] of WideChar;
    uVersion: UINT;
    szInfoTitle: array [0..63] of WideChar;
    dwInfoFlags: DWORD;
    guidItem: array [0..3] of LongWord;
    hBalloonIcon: HICON;
  end;

{$IFNDEF FPC}
  TRTLCriticalSection = record
    DebugInfo: Pointer;
    LockCount: LongInt;
    RecursionCount: LongInt;
    OwningThread: THandle;
    LockSemaphore: THandle;
    Reserved: DWORD;
  end;

  procedure InitializeCriticalSection(out lpCriticalSection: TRTLCriticalSection); stdcall; external kernel32;
  procedure EnterCriticalSection(var lpCriticalSection: TRTLCriticalSection); stdcall; external kernel32;
  procedure LeaveCriticalSection(var lpCriticalSection: TRTLCriticalSection); stdcall; external kernel32;
  procedure DeleteCriticalSection(var lpCriticalSection: TRTLCriticalSection); stdcall; external kernel32;
{$ENDIF}

// Windows
  procedure Sleep(dwMilliseconds: DWORD); stdcall; external kernel32;
  function MoveFileExW(lpExistingFileName, lpNewFileName: PWideChar; dwFlags: DWORD): BOOL; stdcall; external kernel32;
  function DeleteFileW(lpFileName: PWideChar): BOOL; stdcall; external kernel32;
//  function CreateThread(lpThreadAttributes: Pointer; dwStackSize: DWORD; lpStartAddress: Pointer; lpParameter: Pointer; dwCreationFlags: DWORD; var lpThreadId: DWORD): THandle; stdcall; external kernel32;
  function TerminateThread(hThread: THandle; dwExitCode: DWORD): BOOL; stdcall; external kernel32;
  function SetThreadPriority(hThread: THandle; nPriority: Integer): BOOL; stdcall; external kernel32;
  function GetCurrentThread: THandle; stdcall; external kernel32;
  function WaitForSingleObject(hHandle: THandle; dwMilliseconds: DWORD): DWORD; stdcall; external kernel32;
  function CreateSemaphoreW(lpSemaphoreAttributes: Pointer; lInitialCount, lMaximumCount: Longint; lpName: PWideChar): THandle; stdcall; external kernel32;
  function ReleaseSemaphore(hSemaphore: THandle; lReleaseCount: Longint; lpPreviousCount: Pointer): BOOL; stdcall; external kernel32;
  function GetTickCount: DWORD; stdcall; external kernel32;
//  function CreateDirectoryW(lpPathName: PWideChar; lpSecurityAttributes: Pointer): BOOL; stdcall; external kernel32;
  function OpenProcess(dwDesiredAccess: DWORD; bInheritHandle: BOOL; dwProcessId: DWORD): THandle; stdcall; external kernel32;
  function GetCurrentProcessId: DWORD; stdcall; external kernel32;
  function SetProcessWorkingSetSize(hProcess: THandle; dwMinimumWorkingSetSize, dwMaximumWorkingSetSize: DWORD): BOOL; stdcall; external kernel32;
  function CloseHandle(hObject: THandle): BOOL; stdcall; external kernel32;
  function GlobalAlloc(uFlags: UINT; dwBytes: DWORD): HGLOBAL; stdcall; external kernel32;
  function GlobalLock(hMem: HGLOBAL): Pointer; stdcall; external kernel32;
  function GlobalUnlock(hMem: HGLOBAL): BOOL; stdcall; external kernel32;
  function GlobalFree(hMem: HGLOBAL): HGLOBAL; stdcall; external kernel32;

  function MessageBoxW(hWnd: HWND; lpText, lpCaption: PWideChar; uType: UINT): Integer; stdcall; external user32;

  function MultiByteToWideChar(CodePage: UINT; dwFlags: DWORD; const lpMultiByteStr: LPCSTR; cchMultiByte: Integer; lpWideCharStr: LPWSTR; cchWideChar: Integer): Integer; stdcall; external kernel32;
  function GetTimeZoneInformation(out lpTimeZoneInformation: TTimeZoneInformation): DWORD; stdcall; external kernel32;
  function FileTimeToSystemTime(const lpFileTime: TFileTime; out lpSystemTime: TSystemTime): BOOL; stdcall; external kernel32;
  procedure GetLocalTime(out lpSystemTime: TSystemTime); stdcall; external kernel32;

  function FindWindowW(lpClassName, lpWindowName: PWideChar): HWND; stdcall; external user32;
  function FindWindowExW(Parent, Child: HWND; ClassName, WindowName: PWideChar): HWND; stdcall; external user32;
  function FlashWindowEx(var pfwi: TFlashInfo): BOOL; stdcall; external user32;

  function CreateWindowExW(dwExStyle: DWORD; lpClassName: PWideChar; lpWindowName: PWideChar; dwStyle: DWORD; X, Y, nWidth, nHeight: Integer; hWndParent: HWND; hMenu: HMENU; hInstance: HINST; lpParam: Pointer): HWND; stdcall; external user32;
  function DestroyWindow(hWnd: HWND): BOOL; stdcall; external user32;
  function SetWindowPos(hWnd: HWND; hWndInsertAfter: HWND; X, Y, cx, cy: Integer; uFlags: UINT): BOOL; stdcall; external user32;
  function SetWindowTextW(hWnd: HWND; lpString: PWideChar): BOOL; stdcall; external user32;
  function SendMessageW(hWnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall; external user32;
  function GetMessageW(out lpMsg: TMsg; hWnd: HWND; wMsgFilterMin, wMsgFilterMax: UINT): BOOL; stdcall; external user32;
  function TranslateMessage(const lpMsg: TMsg): BOOL; stdcall; external user32;
  function DispatchMessageW(const lpMsg: TMsg): Longint; stdcall; external user32;
//  procedure PostQuitMessage(nExitCode: Integer); stdcall; external user32;
  function PostMessageW(hWnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall; external user32;

  function RegisterWindowMessageW(lpString: PWideChar): UINT; stdcall; external user32;
  function DefWindowProcW(hWnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall; external user32;
  function UpdateWindow(hWnd: HWND): BOOL; stdcall; external user32;
  function GetCursorPosEx(out lpPoint: TPoint): BOOL; stdcall; external user32 name 'GetCursorPos';
  function ScreenToClient(hWnd: HWND; var lpPoint: TPoint): BOOL; stdcall; external user32;
  function GetWindowLongW(hWnd: HWND; nIndex: Integer): LongInt; stdcall; external user32;
  function SetWindowLongW(hWnd: HWND; nIndex: Integer; dwNewLong: LongInt): LongInt; stdcall; external user32;
  function SetClassLongW(hWnd: HWND; nIndex: Integer; dwNewLong: Longint): DWORD; stdcall; external user32;
  function GetWindowRect(hWnd: HWND; out lpRect: TRect): BOOL; stdcall; external user32;
  function GetClientRect(hWnd: HWND; out lpRect: TRect): BOOL; stdcall; external user32;
  function GetForegroundWindow: HWND; stdcall; external user32;
  function SetForegroundWindow(hWnd: HWND): BOOL; stdcall; external user32;
  function SetFocus(hWnd: HWND): HWND; stdcall; external user32;
  function SetTimer(hWnd: HWND; nIDEvent, uElapse: UINT; lpTimerFunc: Pointer): UINT; stdcall; external user32;
  function KillTimer(hWnd: HWND; uIDEvent: UINT): BOOL; stdcall; external user32;
  function RegisterHotKey(hWnd: HWND; id: Integer; fsModifiers, vk: UINT): BOOL; stdcall; external user32;

  function GetAsyncKeyState(vKey: Integer): SHORT; stdcall; external user32;
  function GetCapture: HWND; stdcall; external user32;
  function SetCapture(hWnd: HWND): HWND; stdcall; external user32;
  function ReleaseCapture: BOOL; stdcall; external user32;
  function SetCursor(hCursor: HICON): HCURSOR; stdcall; external user32;

  function InvalidateRect(hWnd: HWND; lpRect: PRect; bErase: BOOL): BOOL; stdcall; external user32;
  function GetDC(hWnd: HWND): HDC; stdcall; external user32;
  function ReleaseDC(hWnd: HWND; hDC: HDC): Integer; stdcall; external user32;
  function BeginPaint(hWnd: HWND; out lpPaint: TPaintStruct): HDC; stdcall; external user32;
  function EndPaint(hWnd: HWND; const lpPaint: TPaintStruct): BOOL; stdcall; external user32;
  function DrawAnimatedRects(hwnd: HWND; idAni: Integer; const lprcFrom, lprcTo: TRect): BOOL; stdcall; external user32;

  function LoadCursorW(hInstance: HINST; lpCursorName: PWideChar): HCURSOR; stdcall; external user32;
  function DestroyCursor(hCursor: HICON): BOOL; stdcall; external user32;
  function CreateIcon(hInstance: HINST; nWidth, nHeight: Integer; cPlanes, cBitsPixel: Byte; lpbANDbits, lpbXORbits: Pointer): HICON; stdcall; external user32;
  function DestroyIcon(hIcon: HICON): BOOL; stdcall; external user32;
  function SystemParametersInfoW(uiAction, uiParam: UINT; pvParam: Pointer; fWinIni: UINT): BOOL; stdcall; external user32;

  function IsClipboardFormatAvailable(format: UINT): BOOL; stdcall; external user32;
  function OpenClipboard(hWndNewOwner: HWND): BOOL; stdcall; external user32;
  function GetClipboardData(uFormat: UINT): THandle; stdcall; external user32;
  function CloseClipboard: BOOL; stdcall; external user32;
  function EmptyClipboard: BOOL; stdcall; external user32;
  function SetClipboardData(uFormat: UINT; hMem: THandle): THandle; stdcall; external user32;

  function RegOpenKeyW(hKey: HKEY; lpSubKey: PWideChar; out phkResult: HKEY): Longint; stdcall; external advapi32;
  function RegQueryValueExW(hKey: HKEY; lpValueName: PWideChar; lpReserved: Pointer; lpType: PDWORD; lpData: PByte; lpcbData: PDWORD): Longint; stdcall; external advapi32;
  function RegDeleteValueW(hKey: HKEY; lpValueName: PWideChar): Longint; stdcall; external advapi32;
  function RegSetValueExW(hKey: HKEY; lpValueName: PWideChar; Reserved: DWORD; dwType: DWORD; lpData: Pointer; cbData: DWORD): Longint; stdcall; external advapi32;
  function RegCloseKey(hKey: HKEY): LongInt; stdcall; external advapi32;

  function CreateCompatibleBitmap(DC: HDC; Width, Height: Integer): HBITMAP; stdcall; external gdi32;
  function CreateCompatibleDC(DC: HDC): HDC; stdcall; external gdi32;
  function CreateDIBSection(DC: HDC; const p2: TBitmapInfo; p3: UINT; out p4: Pointer; p5: THandle; p6: DWORD): HBITMAP; stdcall; external gdi32;
  function DeleteDC(DC: HDC): BOOL; stdcall; external gdi32;
  function SelectObject(DC: HDC; p2: HGDIOBJ): HGDIOBJ; stdcall; external gdi32;
  function DeleteObject(p1: HGDIOBJ): BOOL; stdcall; external gdi32;
  function SetWindowOrgEx(DC: HDC; X, Y: Integer; Point: PPoint): BOOL; stdcall; external gdi32;
  function BitBlt(DestDC: HDC; X, Y, Width, Height: Integer; SrcDC: HDC; XSrc, YSrc: Integer; Rop: DWORD): BOOL; stdcall; external gdi32;
  function CreateFontW(nHeight, nWidth, nEscapement, nOrientaion, fnWeight: Integer; fdwItalic, fdwUnderline, fdwStrikeOut, fdwCharSet, fdwOutputPrecision, fdwClipPrecision, fdwQuality, fdwPitchAndFamily: DWORD; lpszFace: PWideChar): HFONT; stdcall; external gdi32;
  function SetBkMode(DC: HDC; BkMode: Integer): Integer; stdcall; external gdi32;
  function SetTextColor(DC: HDC; Color: COLORREF): COLORREF; stdcall; external gdi32;
  function GetClipRgn(DC: HDC; rgn: HRGN): Integer; stdcall; external gdi32;
  function IntersectClipRect(DC: HDC; X1, Y1, X2, Y2: Integer): Integer; stdcall; external gdi32;
  function SelectClipRgn(DC: HDC; Region: HRGN): Integer; stdcall; external gdi32;
  function CreatePen(Style, Width: Integer; Color: COLORREF): HPEN; stdcall; external gdi32;
  function CreateSolidBrush(p1: COLORREF): HBRUSH; stdcall; external gdi32;
  function MoveToEx(DC: HDC; p2, p3: Integer; p4: PPoint): BOOL; stdcall; external gdi32;
  function LineTo(DC: HDC; X, Y: Integer): BOOL; stdcall; external gdi32;
  function FrameRect(hDC: HDC; const lprc: TRect; hbr: HBRUSH): Integer; stdcall; external user32;
  function FillRect(hDC: HDC; const lprc: TRect; hbr: HBRUSH): Integer; stdcall; external user32;
  function GetTextExtentPoint32W(DC: HDC; Str: PWideChar; Count: Integer; out Size: TPoint): BOOL; stdcall; external gdi32;
  function TextOutW(DC: HDC; X, Y: Integer; Str: PWideChar; Count: Integer): BOOL; stdcall; external gdi32;

  function AlphaBlend(DC: HDC; p2, p3, p4, p5: Integer; DC6: HDC; p7, p8, p9, p10: Integer; p11: TBlendFunction): BOOL; stdcall; external 'msimg32.dll';

// MMSystem
  function sndPlaySoundW(lpszSoundName: PWideChar; uFlags: UINT): BOOL; stdcall; external winmm;
// ShellAPI
  function ShellExecuteW(hWnd: HWND; Operation, FileName, Parameters, Directory: PWideChar; ShowCmd: Integer): HINST; stdcall; external shell32;
  function SHGetFolderPathW(hwnd: HWND; csidl: Integer; hToken: THandle; dwFlags: DWORD; pszPath: LPWSTR): HRESULT; stdcall; external shell32;
  function SHGetSpecialFolderPathW(hwndOwner: HWND; lpszPath: PWideChar; nFolder: Integer; fCreate: BOOL): BOOL; stdcall; external shell32;
  function Shell_NotifyIconW(dwMessage: DWORD; lpData: PNotifyIconDataW): BOOL; stdcall; external shell32;
{$ENDIF}
{$ENDREGION}

{$REGION 'Linux'}
{$IFDEF LINUX}
// link library
{$LINKLIB 'libXft'}

const
 XFT_CORE      : PAnsiChar = 'core';
 FC_FAMILY     : PAnsiChar = 'family';
 FC_WEIGHT     : PAnsiChar = 'weight';
 FC_PIXEL_SIZE : PAnsiChar = 'pixelsize';
 FC_ANTIALIAS  : PAnsiChar = 'antialias';

type
  TFcType = (FcTypeVoid, FcTypeInteger, FcTypeDouble, FcTypeString, FcTypeBool, FcTypeMatrix, FcTypeCharSet, FcTypeFTFace, FcTypeLangSet);

  PXftFont = ^TXftFont;
  TXftFont = record
    ascent  : Integer;
    descent : Integer;
    height  : Integer;
    max_advance_width : Integer;
    charset : Pointer;
    attern  : Pointer;
  end;

  TXRenderColor = record
    R, G, B, A : Word;
  end;

  PXftColor = ^TXftColor;
  TXftColor =  record
    pixel : culong;
    color : TXRenderColor;
  end;

  PXftDraw = Pointer;

  function XftInit(config: PAnsiChar): LongBool; cdecl; external;
  function XftFontOpen(dpy: PDisplay; screen: LongInt; args: array of const): PXftFont; cdecl; external;
  procedure XftFontClose(dpy: PDisplay; pub: PXftFont); cdecl; external;
  function XftDrawCreate(dpy: PDisplay; drawable: TXID; visual: Pointer; colormap: TXID): PXftDraw; cdecl; external;
  procedure XftDrawString16(draw: PXftDraw; color: PXftColor; pub: PXftFont; x, y: LongInt; _string: PWideChar; len: LongInt); cdecl; external;

var
  XDisplay : TXID;
  XScreen  : LongInt;
{$ENDIF}
{$ENDREGION}

{$REGION 'Mac'}
{$IFDEF DARWIN}
  function UCConvertUTCDateTimeToCFAbsoluteTime(const iUTCDate: Int64; var oCFTime: CFAbsoluteTime): OSStatus; external name '_UCConvertUTCDateTimeToCFAbsoluteTime';
{$ENDIF}
{$ENDREGION}

{$REGION 'Sockets'}
// WinSock
const
  SOCKET_ERROR   = -1;
  INVALID_SOCKET = Integer(NOT(0));
  SOCK_STREAM    = 1;
  AF_INET        = 2;
  WSADESCRIPTION_LEN = 256;
  WSASYS_STATUS_LEN  = 128;

  SOL_SOCKET  = $FFFF;
  SO_SNDTIMEO = $1005;
  SO_RCVTIMEO = $1006;

type
  u_char  = AnsiChar;
  u_short = Word;
  u_int   = Integer;
  u_long  = LongInt;
  TSocket = u_int;

  TWSAData = record
    wVersion: Word;
    wHighVersion: Word;
    szDescription: array[0..WSADESCRIPTION_LEN] of AnsiChar;
    szSystemStatus: array[0..WSASYS_STATUS_LEN] of AnsiChar;
    iMaxSockets: Word;
    iMaxUdpDg: Word;
    lpVendorInfo: PAnsiChar;
  end;

  PInAddr = ^TInAddr;
  TInAddr = record
    S_addr : u_long;
  end;
  
  TSockAddrIn = record
    case Integer of
      0: (sin_family: u_short;
          sin_port: u_short;
          sin_addr: TInAddr;
          sin_zero: array[0..7] of AnsiChar);
      1: (sa_family: u_short;
          sa_data: array[0..13] of AnsiChar)
  end;

  PHostEnt = ^THostEnt;
  THostEnt = record
    h_name     : PAnsiChar;
    h_aliases  : ^PAnsiChar;
    h_addrtype : {$IFDEF WIN32}SmallInt{$ELSE}LongInt{$ENDIF};
    h_length   : {$IFDEF WIN32}SmallInt{$ELSE}LongWord{$ENDIF};
    h_addr     : ^PAnsiChar;
  end;

const
{$IFDEF WIN32}
  netlib = 'wsock32.dll';
  winetdll = 'wininet.dll';

  function WSAStartup(wVersionRequired: word; out WSData: TWSAData): Integer; stdcall; external netlib;
  function WSACleanup: Integer; stdcall; external netlib;
  function gethostbyname(name: PAnsiChar): PHostEnt; stdcall; external netlib;
  function htons(hostshort: u_short): u_short; stdcall; external netlib;
  function socket(af, Struct, protocol: Integer): TSocket; stdcall; external netlib;
  function shutdown(s: TSocket; how: Integer): Integer; stdcall; external netlib;
  function connect(s: TSocket; var name: TSockAddrIn; namelen: Integer): Integer; stdcall; external netlib;
  function recv(s: TSocket; out Buf; len, flags: Integer): Integer; stdcall; external netlib;
  function send(s: TSocket; const Buf; len, flags: Integer): Integer; stdcall; external netlib;
  function setsockopt(s: TSocket; level, optname: Integer; optval: PAnsiChar; optlen: Integer): Integer; stdcall; external netlib;
// WinInet
  function InternetConnectA(hInet: Pointer; lpszServerName: PAnsiChar; nServerPort: Word; lpszUsername: PAnsiChar; lpszPassword: PAnsiChar; dwService: DWORD; dwFlags: DWORD; dwContext: DWORD): Pointer; stdcall; external winetdll;
  function InternetOpenA(lpszAgent: PAnsiChar; dwAccessType: DWORD; lpszProxy, lpszProxyBypass: PAnsiChar; dwFlags: DWORD): Pointer; stdcall; external winetdll;
  function HttpOpenRequestA(hConnect: Pointer; lpszVerb: PAnsiChar; lpszObjectName: PAnsiChar; lpszVersion: PAnsiChar; lpszReferrer: PAnsiChar; lplpszAcceptTypes: Pointer; dwFlags: DWORD; dwContext: DWORD): Pointer; stdcall; external winetdll;
  function HttpAddRequestHeadersA(hRequest: Pointer; lpszHeaders: PAnsiChar; dwHeadersLength: DWORD; dwModifiers: DWORD): BOOL; stdcall; external winetdll;
  function HttpSendRequestA(hRequest: Pointer; lpszHeaders: PAnsiChar; dwHeadersLength: DWORD; lpOptional: Pointer; dwOptionalLength: DWORD): BOOL; stdcall; external winetdll;
  function InternetReadFile(hFile: Pointer; lpBuffer: Pointer; dwNumberOfBytesToRead: DWORD; var lpdwNumberOfBytesRead: DWORD): BOOL; stdcall; external winetdll;
  function InternetCloseHandle(hInet: Pointer): BOOL; stdcall; external winetdll;

{
  WSAStartup  : function (wVersionRequired: word; out WSData: TWSAData): Integer; stdcall;
  WSACleanup  : function : Integer; stdcall;
  gethostbyname : function (name: PAnsiChar): PHostEnt; stdcall;
  htons         : function (hostshort: u_short): u_short; stdcall;
  socket        : function (af, Struct, protocol: Integer): TSocket; stdcall;
  shutdown      : function (s: TSocket; how: Integer): Integer; stdcall;
  connect       : function (s: TSocket; var name: TSockAddrIn; namelen: Integer): Integer; stdcall;
  recv          : function (s: TSocket; out Buf; len, flags: Integer): Integer; stdcall;
  send          : function (s: TSocket; const Buf; len, flags: Integer): Integer; stdcall;
  setsockopt    : function (s: TSocket; level, optname: Integer; optval: PAnsiChar; optlen: Integer): Integer; stdcall;
// WinInet
  InternetConnectA : function (hInet: Pointer; lpszServerName: PAnsiChar; nServerPort: Word; lpszUsername: PAnsiChar; lpszPassword: PAnsiChar; dwService: DWORD; dwFlags: DWORD; dwContext: DWORD): Pointer; stdcall;
  InternetOpenA    : function (lpszAgent: PAnsiChar; dwAccessType: DWORD; lpszProxy, lpszProxyBypass: PAnsiChar; dwFlags: DWORD): Pointer; stdcall;
  HttpOpenRequestA : function (hConnect: Pointer; lpszVerb: PAnsiChar; lpszObjectName: PAnsiChar; lpszVersion: PAnsiChar; lpszReferrer: PAnsiChar; lplpszAcceptTypes: Pointer; dwFlags: DWORD; dwContext: DWORD): Pointer; stdcall;
  HttpAddRequestHeadersA : function (hRequest: Pointer; lpszHeaders: PAnsiChar; dwHeadersLength: DWORD; dwModifiers: DWORD): BOOL; stdcall;
  HttpSendRequestA : function (hRequest: Pointer; lpszHeaders: PAnsiChar; dwHeadersLength: DWORD; lpOptional: Pointer; dwOptionalLength: DWORD): BOOL; stdcall;
  InternetReadFile : function (hFile: Pointer; lpBuffer: Pointer; dwNumberOfBytesToRead: DWORD; var lpdwNumberOfBytesRead: DWORD): BOOL; stdcall;
  InternetCloseHandle : function (hInet: Pointer): BOOL; stdcall;
}
{$ELSE}
  netlib = 'libc';
  {$MACRO ON}
  {$DEFINE stdcall := cdecl}  // ^___^
  function gethostbyname(name: PAnsiChar): PHostEnt; stdcall; external netlib;
  function htons(hostshort: u_short): u_short; stdcall; external netlib;
  function socket(af, Struct, protocol: Integer): TSocket; stdcall; external netlib;
  function shutdown(s: TSocket; how: Integer): Integer; stdcall; external netlib;
  function connect(s: TSocket; var name: TSockAddrIn; namelen: Integer): Integer; stdcall; external netlib;
  function recv(s: TSocket; out Buf; len, flags: Integer): Integer; stdcall; external netlib;
  function send(s: TSocket; const Buf; len, flags: Integer): Integer; stdcall; external netlib;
  function setsockopt(s: TSocket; level, optname: Integer; optval: PAnsiChar; optlen: Integer): Integer; stdcall; external netlib;
{$ENDIF}

{$REGION 'System objects'}
type
  TCriticalSection = object
  private
    CS : TRTLCriticalSection;
  public
    procedure Init;
    procedure Free;
    procedure Lock; inline;
    procedure Unlock; inline;
  end;

  TThreadProc = procedure (Param: Pointer);

  PThread = ^TThread;
  TThread = object
  private
    FID    : TThreadID;
    FProc  : TThreadProc;
    FParam : Pointer;
  public
    procedure Init(Proc: TThreadProc; Param: Pointer);
    procedure Free;
    procedure FreeWait;
  end;

  PQueue = ^TQueue;
  TQueue = object
  private
    CS        : TCriticalSection;
    Proc      : TThreadProc;
    Semaphore : LongWord;
    Task      : array of Pointer;
    Thread    : array of TThread;
  public
    procedure Init(TaskProc: TThreadProc; ThreadCount: LongInt);
    procedure Free;
    procedure Push(Data: Pointer);
    function Pop: Pointer;
  end;

  TNetSocket = object
  private
    Sock : TSocket;
    Addr : TSockAddrIn;
  public
    function Init(const Host: AnsiString; Port: Word): Boolean;
    procedure Free;
    function Connect: Boolean;
    function Recv(out Data; Size: LongInt): LongInt;
    function Send(const Data; Size: LongInt): LongInt;
    function HostByName(const Host: AnsiString): LongInt;
    function ConvPort(Port: Word): Word;
  end;

  TCharInfo = record
    Width : ShortInt;
  end;

  TFont = class
    constructor Create(Name: PWideChar; Size: LongInt; Bold: Boolean = False);
    destructor Destroy; override;
  private
    CharInfo : array [System.WideChar] of TCharInfo;
  {$IFDEF WIN32}
    FFont : HFONT;
  {$ENDIF}
  {$IFDEF LINUX}
    XFont : PXftFont;
  {$ENDIF}
  {$IFDEF DARWIN}
    Style  : ATSUStyle;
    Ascent : ATSUTextMeasurement;
  {$ENDIF}
    procedure InitTable;
  end;

  TCursor = class
    constructor Create(Name: PWideChar);
    destructor Destroy; override;
  public
  {$IFDEF WIN32}
    Cursor : HCURSOR;
  {$ENDIF}
  {$IFDEF DARWIN}
    Cursor : LongWord;
  {$ENDIF}
  end;

  TCanvas = class
    constructor Create(Handle: LongWord); overload;
    constructor Create(ImgData: PByteArray; Width, Height: LongInt); overload;
    destructor Destroy; override;
  public
    DataPtr : PByteArray;
  private
    CS : TCriticalSection;
    Handle  : LongWord;
    FFont   : TFont;
    FTextColor  : TColor;
    FPenColor   : TColor;
    FBrushColor : TColor;
  {$IFDEF WIN32}
    OldClip : HRGN;
  {$ENDIF}
    procedure SetFont(Value: TFont);
    procedure SetPenColor(const Value: TColor);
    procedure SetBrushColor(const Value: TColor);
    procedure SetTextColor(Value: TColor);
  public
    PaintRect : TRect;
  {$IFDEF WIN32}
    DC : HDC;
    procedure SetContext(const Value: HDC);
  {$ENDIF}
  {$IFDEF LINUX}
    GC      : TGC;
    XftDraw : PXftDraw;
    procedure SetContext(const Value: TGC);
  {$ENDIF}
  {$IFDEF DARWIN}
    Context   : CGContextRef;
    Layout    : ATSUTextLayout;
    Image     : CGImageRef;
    ImgHeight : LongInt;
    procedure SetContext(const Value: CGContextRef);
  {$ENDIF}
    procedure Lock;
    procedure Unlock;
    procedure ClipInit(const Rect: TRect);
    procedure ClipFree;
    procedure Line(x1, y1, x2, y2: LongInt);
    procedure FrameRect(const Rect: TRect);
    procedure FillRect(const Rect: TRect);
    function TextWidth(Text: PWideChar; Count: LongInt): LongInt;
    procedure TextWrap(Text: PWideChar; Count, X, Width: LongInt; out Lines: TStringPartArray);
    procedure TextOut(X, Y: LongInt; Text: PWideChar; Length: LongInt); overload;
    function TextOut(X, Y, LineHeight: LongInt; Text: PWideChar; const Lines: TStringPartArray): LongInt; overload;
    procedure TextOut(X, Y: LongInt; const Text: WideString); overload;
    function TextPosToCaret(X, Y: LongInt; Text: PWideChar; const Lines: TStringPartArray): LongInt;
    function TextCaretToPos(Caret: LongInt; Text: PWideChar; const Lines: TStringPartArray): TPoint;
    procedure Draw(Canvas: TCanvas; const SrcRect, DstRect: TRect; Alpha: Byte = 255);
    property Font: TFont read FFont write SetFont;
    property PenColor: TColor read FPenColor write SetPenColor;
    property BrushColor: TColor read FBrushColor write SetBrushColor;
    property TextColor: TColor read FTextColor write SetTextColor;
  end;

  TImage = class
    constructor Create(ImgData: Pointer; Width, Height: LongInt); overload;
    constructor Create(Data: Pointer; Size: LongInt; KeepData: Boolean = False); overload;
    class function Load(const FileName: WideString): TImage;
    destructor Destroy; override;
  protected
    FCanvas : TCanvas;
    ImgData : PByteArray;
  public
    Valid : Boolean;
    Width, Height : LongInt;
    procedure FreeData;
    function GetPixel(x, y: LongInt): LongWord;
    procedure Draw(Canvas: TCanvas; const SrcRect, DstRect: TRect; Alpha: Byte = 255); overload;
    procedure Draw(Canvas: TCanvas; X, Y, AreaWidth, AreaHeight: LongInt; Alpha: Byte = 255); overload;
    procedure Draw(Canvas: TCanvas; sX, sY, sW, sH, dX, dY, dW, dH: LongInt; Alpha: Byte = 255); overload;
    procedure DrawFrame(Canvas: TCanvas; X, Y, Index, Size: LongInt; Alpha: Byte = 255);
    procedure DrawWindow(Canvas: TCanvas; Rect: TRect; sX, sY, Size: LongInt; Alpha: Byte = 255);
    procedure DrawWindowH(Canvas: TCanvas;  sX, sY, dX, dY, Width, Size: LongInt; Alpha: Byte = 255);
  end;

  PAtlasItem = ^TAtlasItem;
  TAtlasItem = record
    Index : LongInt;
    Time  : LongInt;
  end;

  TImageAtlas = class
    constructor Create(MapSize, ItemSize: LongInt);
    destructor Destroy; override;
  private
    MapSize, ItemSize : LongInt;
    Items : array of PAtlasItem;
  public
    Atlas : TCanvas;
    procedure Push(ImgData: PByteArray; var Item: TAtlasItem);
    procedure Pop(var Item: TAtlasItem);
    procedure Draw(Canvas: TCanvas; X, Y: LongInt; var Item: TAtlasItem; Alpha: Byte = 255);
  end;

  TIcon = class(TImage)
    constructor Create(ImgData: PByteArray; X, Y, Size: LongInt);
    destructor Destroy; override;
  public
  {$IFDEF WIN32}
    Icon  : HICON;
  {$ENDIF}
    Small : TIcon;
    procedure Draw(Canvas: TCanvas; X, Y: LongInt; Alpha: Byte = 255);
  end;
{$ENDREGION}

{$REGION 'Common'}
  procedure Wait(ms: LongWord);
  function UnixTimeDecode(UnixTime: LongWord): TUTime;
  function ConvZ(x: LongInt): WideString;
  function MsgConvDate(Date: TMsgDate): WideString;
  function MsgConvTime(Time: TMsgTime): WideString;
  function MsgDateTime(UnixTime: TUnixTime): TMsgDateTime;
  function MsgDateCompare(const Date1, Date2: TMsgDate): Boolean;
{$ENDREGION}

  procedure NetInit;
  procedure NetFree;

  procedure PlaySound(const Data: Pointer);
  function MakeDir(const Path: WideString): Boolean;
  function GetAppDir: WideString;
  function GetRootDir: WideString;
  function GetRootVIK: WideString;
  function GetCursorPos: TPoint;
  procedure UpdateScreen;
  procedure RegisterHotKeys;
  function GetTime: LongWord;
  function MoveFile(const Path1, Path2: WideString): Boolean;
  function DeleteFile(const Path: WideString): Boolean;
  procedure BrowseURL(const URL: WideString);
  procedure RestartApp;
  procedure CheckFolders;
  procedure FlushMemory;
  function CheckAutorun(Autorun: TAutorun): Boolean;
  function ClipboardGet: WideString;
  procedure ClipboardSet(const Text: WideString);
  function GetDateTime: TMsgDateTime;
  function InitTimer(Interval: LongWord; TimerProc: TTimerProc): LongWord;
  procedure FreeTimer(ID: LongWord);

{$IFDEF DARWIN}
  function CGRectMake(const Rect: TRect; Crop: Boolean = True): CGRect;
{$ENDIF}

implementation

uses
  jglobal, jutils, jimg, jctrl;

{$REGION 'TCriticalSection'}
procedure TCriticalSection.Init;
begin
{$IFNDEF FPC}
  InitializeCriticalSection(CS);
{$ELSE}
  InitCriticalSection(CS);
{$ENDIF}
end;

procedure TCriticalSection.Free;
begin
{$IFNDEF FPC}
  DeleteCriticalSection(CS);
{$ELSE}
  DoneCriticalSection(CS);
{$ENDIF}
end;

procedure TCriticalSection.Lock;
begin
  EnterCriticalSection(CS);
end;

procedure TCriticalSection.Unlock;
begin
  LeaveCriticalSection(CS);
end;
{$ENDREGION}

{$REGION 'TThread'}
function ProxyThreadProc(Thread: PThread): Integer;
begin
  Result := 0;
  with Thread^ do FProc(FParam);
  EndThread(0);
end;

procedure TThread.Init(Proc: TThreadProc; Param: Pointer);
begin
  FProc  := Proc;
  FParam := Param;
{$IFDEF FPC}
  FID := BeginThread(@ProxyThreadProc, @Self);
{$ELSE}
  FID := BeginThread(nil, 0, @ProxyThreadProc, @Self, 0, LongWord(nil^));
{$ENDIF}
  SetThreadPriority(FID, -1);
//  FID := CreateThread(nil, 0, @ProxyThreadProc, @Self, 0, LongWord(nil^));
end;

procedure TThread.Free;
begin
  TerminateThread(FID, 0);
  LongInt(FID) := 0;
end;

procedure TThread.FreeWait;
begin
  if LongInt(FID) <> 0 then
{$IFDEF FPC}
    WaitForThreadTerminate(FID, INFINITE);
{$ELSE}
    WaitForSingleObject(FID, INFINITE);
{$ENDIF}
end;
{$ENDREGION}

{$REGION 'TQueue'}
procedure TaskThreadProc(Queue: PQueue);
begin
  while WaitForSingleObject(Queue.Semaphore, INFINITE) = 0 do
    Queue.Proc(Queue.Pop);
end;

procedure TQueue.Init(TaskProc: TThreadProc; ThreadCount: LongInt);
var
  i : LongInt;
begin
  CS.Init;
  Self.Proc := TaskProc;
  Semaphore := CreateSemaphoreW(nil, 0, 10000, nil);
  SetLength(Thread, ThreadCount);
  for i := 0 to ThreadCount - 1 do
    Thread[i].Init(@TaskThreadProc, @Self);
end;

procedure TQueue.Free;
var
  i : LongInt;
begin
  CS.Lock;
  CloseHandle(Semaphore);
  Semaphore := 0;
  for i := 0 to Length(Thread) - 1 do
    Thread[i].Free;
  CS.Unlock;
  CS.Free;
end;

procedure TQueue.Push(Data: Pointer);
begin
  CS.Lock;
  SetLength(Task, Length(Task) + 1);
  Task[Length(Task) - 1] := Data;
  ReleaseSemaphore(Semaphore, 1, nil);
  CS.Unlock;
end;

function TQueue.Pop: Pointer;
var
  i : LongInt;
begin
  CS.Lock;
  if Length(Task) > 0 then
  begin
    Result := Task[0];
    for i := 0 to Length(Task) - 2 do
      Task[i] := Task[i + 1];
    SetLength(Task, Length(Task) - 1);
  end else
    Result := nil;
  CS.Unlock;
end;
{$ENDREGION}

{$REGION 'TNetSocket'}
function TNetSocket.Init(const Host: AnsiString; Port: Word): Boolean;
const
  SOCK_TIMEOUT : LongInt = 30 * 1000;
var
  IP : LongInt;
begin
  Result := False;

  IP := HostByName(Host);
  if IP = 0 then
    Exit;

  FillChar(Addr, SizeOf(Addr), 0);
  Addr.sin_family := AF_INET;
  Addr.sin_port   := ConvPort(Port);
  Addr.sin_addr.s_addr := IP;

  Sock := socket(AF_INET, SOCK_STREAM, 0);
  if Sock = INVALID_SOCKET then
    Exit;

  setsockopt(Sock, SOL_SOCKET, SO_SNDTIMEO, @SOCK_TIMEOUT, SizeOf(SOCK_TIMEOUT));
  setsockopt(Sock, SOL_SOCKET, SO_RCVTIMEO, @SOCK_TIMEOUT, SizeOf(SOCK_TIMEOUT));

  Result := True;
end;

procedure TNetSocket.Free;
begin
  if Sock <> INVALID_SOCKET then
    shutdown(Sock, 2);
end;

function TNetSocket.Connect: Boolean;
begin
  Result := jsys.connect(Sock, Addr, SizeOf(Addr)) <> SOCKET_ERROR;
end;

function TNetSocket.Recv(out Data; Size: LongInt): LongInt;
begin
  Result := jsys.recv(Sock, Data, Size, 0);
end;

function TNetSocket.Send(const Data; Size: LongInt): LongInt;
begin
  Result := jsys.send(Sock, Data, Size, 0);
end;

function TNetSocket.HostByName(const Host: AnsiString): LongInt;
var
  phe : PHostEnt;
begin
  phe := gethostbyname(PAnsiChar(Host));
  if phe <> nil then
    Result := PInAddr(phe^.h_addr^)^.S_addr
  else
    Result := 0;
end;

function TNetSocket.ConvPort(Port: Word): Word;
begin
  Result := htons(Port);
end;
{$ENDREGION}

{$REGION 'TFont'}
{ TFont }
constructor TFont.Create(Name: PWideChar; Size: LongInt; Bold: Boolean);
{$IFDEF WIN32}
var
  DC : HDC;
  WeightFlag : LongInt;
begin
  if Bold then
    WeightFlag := FW_BOLD
  else
    WeightFlag := FW_NORMAL;

  DC := GetDC(0);
  FFont := CreateFontW(-Size, 0, 0, 0, WeightFlag, 0, 0, 0, 1, 0, 0, 0, 0, Name);
  ReleaseDC(0, DC);
  InitTable;
end;
{$ENDIF}
{$IFDEF LINUX}
  function LoadFont(Name: PAnsiChar): Boolean;
  begin
    XFont := XftFontOpen(XDisplay, XScreen,
      [FC_FAMILY, FcTypeString, Name,
       FC_PIXEL_SIZE, FcTypeDouble, Size * Double(1.0),
       FC_WEIGHT, FcTypeInteger, LongInt(200 * Ord(Bold)),
       FC_ANTIALIAS, FcTypeBool, False,
       XFT_CORE, FcTypeBool, False, 0]);
    Result := XFont <> nil;
  end;

begin
  LoadFont(PAnsiChar(AnsiString(Name))) or LoadFont('sans') or LoadFont('fixed');
end;
{$ENDIF}
{$IFDEF DARWIN}
  function GetID(Name: PWideChar): ATSUFontID;
  var
    NameRef : CFStringRef;
    FontRef : ATSFontRef;
  begin
    Result := 0;
    NameRef := CFStringCreateWithCharacters(nil, Pointer(Name), Length(Name));
    FontRef := ATSFontFindFromName(NameRef, kATSOptionFlagsDefault);
    CFRelease(NameRef);
    Result := FMGetFontFromATSFontRef(FontRef);
  end;

var
  FSize  : ATSUTextMeasurement;
  FontID : ATSUFontID;
  Matrix : CGAffineTransform;
  Attr : record
    Tag   : array [0..3] of ATSUAttributeTag;
    Count : array [0..3] of ByteCount;
    Value : array [0..3] of ATSUAttributeValuePtr;
  end;
begin
  ATSUCreateStyle(Style);

  FontID := GetID(Name);
  if FontID = 0 then
    FontID := GetID('Arial');
  FSize  := Size shl 16;
  Matrix := CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, 0.0);
  with Attr do
  begin
    Tag[0]   := kATSUFontTag;
    Tag[1]   := kATSUSizeTag;
    Tag[2]   := kATSUQDBoldfaceTag;
    Tag[3]   := kATSUFontMatrixTag;
    Count[0] := SizeOf(FontID);
    Count[1] := SizeOf(FSize);
    Count[2] := SizeOf(Bold);
    Count[3] := SizeOf(Matrix);
    Value[0] := @FontID;
    Value[1] := @FSize;
    Value[2] := @Bold;
    Value[3] := @Matrix;
    ATSUSetAttributes(Style, 4, @Tag, @Count, @Value);
  end;
  InitTable;
end;
{$ENDIF}

destructor TFont.Destroy;
begin
{$IFDEF WIN32}
  DeleteObject(FFont);
{$ENDIF}
{$IFDEF LINUX}
  XftFontClose(XDisplay, XFont);
{$ENDIF}
{$IFDEF DARWIN}
  ATSUDisposeStyle(Style);
{$ENDIF}
end;

procedure TFont.InitTable;
var
  ch : System.WideChar;
begin
  for ch := Low(ch) to High(ch) do
    CharInfo[ch].Width := -1;
end;
{$ENDREGION}

{$REGION 'TCursor'}
{ TCursor }
constructor TCursor.Create(Name: PWideChar);
begin
{$IFDEF WIN32}
  Cursor := LoadCursorW(0, Name);
{$ENDIF}
{$IFDEF LINUX}
  Cursor := 0;
{$ENDIF}
{$IFDEF DARWIN}
  Cursor := 0;
{$ENDIF}
end;

destructor TCursor.Destroy;
begin
{$IFDEF WIN32}
  DestroyCursor(Cursor);
{$ENDIF}
  inherited;
end;
{$ENDREGION}

{$REGION 'TCanvas'}
{ TCanvas }
{$IFDEF WIN32}
constructor TCanvas.Create(Handle: LongWord);
begin
  Self.Handle := Handle;
  DC := GetDC(Handle);
  CS.Init;
end;
{$ENDIF}
{$IFDEF LINUX}
constructor TCanvas.Create(Handle: LongWord);
var
  GCAttr : TXGCValues;
begin
  GC := XCreateGC(XDisplay, Handle, 0, @GCAttr);
  XftDraw := XftDrawCreate(XDisplay, Handle,
    XDefaultVisual(XDisplay, XScreen),
    XDefaultColormap(XDisplay, XScreen));
end
{$ENDIF}
{$IFDEF DARWIN}
constructor TCanvas.Create(Handle: LongWord);
const
  Options : ATSLineLayoutOptions =
    kATSLineFractDisable or
    kATSLineDisableAutoAdjustDisplayPos or
    kATSLineDisableAllLayoutOperations or
    kATSLineUseDeviceMetrics;
var
  Attr : record
    Tag   : ATSUAttributeTag;
    Count : ByteCount;
    Value : ATSUAttributeValuePtr;
  end;
begin
  if Handle = 0 then
    Exit;
  ATSUCreateTextLayout(Layout);
  with Attr do
  begin
    Tag   := kATSULineLayoutOptionsTag;
    Count := SizeOf(Options);
    Value := @Options;
    ATSUSetLayoutControls(Layout, 1, @Tag, @Count, @Value);
  end;
  CS.Init;
end;
{$ENDIF}

constructor TCanvas.Create(ImgData: PByteArray; Width, Height: LongInt) overload;
var
{$IFDEF WIN32}
  BMP : HBITMAP;
  BI  : TBitmapInfo;
{$ENDIF}
{$IFDEF DARWIN}
  ColorSpace : CGColorSpaceRef;
{$ENDIF}
  img : PRGBA;
  i   : LongInt;
  k   : Single;
begin
{$IFDEF WIN32}
  FillChar(BI, SizeOf(BI), 0);
  with BI.bmiHeader do
  begin
    biSize      := SizeOf(BI.bmiHeader);
    biBitCount  := 32;
    biPlanes    := 1;
    biWidth     := Width;
    biHeight    := Height;
    biSizeImage := biWidth * biHeight * 4;
  end;
  DC := CreateCompatibleDC(0);
  BMP := CreateDIBSection(DC, BI, 0, Pointer(DataPtr), 0, 0);
  SelectObject(DC, BMP);
  DeleteObject(BMP);
  if DataPtr = nil then // out of resources
    Exit;
{$ELSE}
  DataPtr := GetMemory(Width * Height * 4);
{$ENDIF}
// premultiple
  if ImgData <> nil then
  begin
    for i := 0 to Width * Height - 1 do
      with PRGBA(@DataPtr^[i * 4])^ do
      begin
        img := PRGBA(@ImgData^[i * 4]);
        k := img^.A * IBYTE;
      {$IFDEF WIN32}
        B := Round(img^.B * k);
        R := Round(img^.R * k);
      {$ELSE}
        B := Round(img^.R * k);
        R := Round(img^.B * k);
      {$ENDIF}
        G := Round(img^.G * k);
        A := img^.A;
      end;
  end;
{$IFDEF LINUX}
  //
{$ENDIF}
{$IFDEF DARWIN}
  ColorSpace := CGColorSpaceCreateDeviceRGB;
  Context := CGBitmapContextCreate(DataPtr, Width, Height, 8, Width * 4, ColorSpace, kCGImageAlphaPremultipliedLast);
  CGContextSetShouldAntialias(Context, 0);
  CGColorSpaceRelease(ColorSpace);
  Image := CGBitmapContextCreateImage(Context);
  ImgHeight := Height;
{$ENDIF}
{$IFNDEF WIN32}
  FreeMemory(DataPtr);
{$ENDIF}
end;

destructor TCanvas.Destroy;
begin
{$IFDEF WIN32}
  if Handle <> 0 then
  begin
    CS.Free;
    ReleaseDC(Handle, DC);
  end else
    DeleteDC(DC);
{$ENDIF}
{$IFDEF LINUX}
  if XImage <> nil then
  begin
    FreeMemory(XData);
    XImage.data := nil;
    XDestroyImage(XImage);
  end;
  if GC <> nil then
    XFreeGC(XDisplay, GC);
{$ENDIF}
{$IFDEF DARWIN}
  if Layout <> nil then
    ATSUDisposeTextLayout(Layout);
  if Image <> nil then
  begin
    CGImageRelease(Image);
    CGContextRelease(Context);
  end else
    CS.Free;
{$ENDIF}
end;

{$IFDEF WIN32}
procedure TCanvas.SetContext(const Value: HDC);
begin
  DC := Value;
{$ENDIF}
{$IFDEF LINUX}
procedure TCanvas.SetContext(const Value: TGC);
begin
  GC := Value;
{$ENDIF}
{$IFDEF DARWIN}
procedure TCanvas.SetContext(const Value: CGContextRef);
var
  T : ATSUAttributeTag;
  C : ByteCount;
  V : ATSUAttributeValuePtr;
begin
  Context := Value;
  T := kATSUCGContextTag;
  C := SizeOf(Context);
  V := @Context;
  ATSUSetLayoutControls(Layout, 1, @T, @C, @V);
{$ENDIF}
  FBrushColor := 1;
  FPenColor   := 1;
  FTextColor  := 1;
  FFont       := nil;
  BrushColor  := 0;
  PenColor    := 0;
  TextColor   := 0;
end;

{$IFDEF DARWIN}
function CGRectMake(const Rect: TRect; Crop: Boolean = True): CGRect;
begin
  Result.origin.y    := Rect.Top;
  Result.origin.x    := Rect.Left;
  Result.size.width  := Rect.Right - Rect.Left;
  Result.size.height := Rect.Bottom - Rect.Top;
  if Crop then
  begin
    Result.size.width  := Result.size.width - 1;
    Result.size.height := Result.size.height - 1;
  end;
end;
{$ENDIF}

procedure TCanvas.SetFont(Value: TFont);
begin
  FFont := Value;
{$IFDEF WIN32}
  SelectObject(DC, FFont.FFont);
{$ENDIF}
{$IFDEF DARWIN}
  if Font.Ascent = 0 then
    TextWidth('a', 1); // init ascent
{$ENDIF}
end;

procedure TCanvas.SetPenColor(const Value: TColor);
begin
  if Value <> FPenColor then
  begin
    FPenColor := Value;
  {$IFDEF DARWIN}
    CGContextSetRGBStrokeColor(Context, (Value and $FF) * IBYTE, (Value shr 8 and $FF) * IBYTE, (Value shr 16 and $FF) * IBYTE, 1.0);
  {$ENDIF}
  end;
end;

procedure TCanvas.SetBrushColor(const Value: TColor);
begin
  if Value <> FBrushColor then
  begin
    FBrushColor := Value;
  {$IFDEF DARWIN}
    CGContextSetRGBFillColor(Context, (Value and $FF) * IBYTE, (Value shr 8 and $FF) * IBYTE, (Value shr 16 and $FF) * IBYTE, 1.0);
  {$ENDIF}
  end;
end;

procedure TCanvas.SetTextColor(Value: TColor);
begin
  FTextColor := Value;
{$IFDEF WIN32}
  SetBkMode(DC, 1);
  jsys.SetTextColor(DC, FTextColor);
{$ENDIF}
end;

procedure TCanvas.Lock;
begin
  CS.Lock;
end;

procedure TCanvas.Unlock;
begin
  CS.Unlock;
end;

procedure TCanvas.ClipInit(const Rect: TRect);
{$IFDEF WIN32}
var
  ClipRgn : HRGN;
begin
  OldClip := GetClipRgn(DC, OldClip);
  ClipRgn := IntersectClipRect(DC, Rect.Left, Rect.Top, Rect.Right, Rect.Bottom);
  SelectClipRgn(DC, ClipRgn);
  DeleteObject(ClipRgn);
end;
{$ENDIF}
{$IFDEF LINUX}
  //
{$ENDIF}
{$IFDEF DARWIN}
var
  r : CGRect;
begin
  r := CGRectMake(Rect, False);
  r.origin.y := r.origin.y - 1;
  CGContextSaveGState(Context);
  CGContextClipToRect(Context, r);
end;
{$ENDIF}

procedure TCanvas.ClipFree;
begin
{$IFDEF WIN32}
  SelectClipRgn(DC, OldClip);
{$ENDIF}
{$IFDEF LINUX}
  //
{$ENDIF}
{$IFDEF DARWIN}
  CGContextRestoreGState(Context);
{$ENDIF}
end;

procedure TCanvas.Line(x1, y1, x2, y2: LongInt);
{$IFDEF WIN32}
var
  Pen : HPEN;
begin
  Pen := CreatePen(0, 1, PenColor);
  SelectObject(DC, Pen);
  MoveToEx(DC, x1, y1, nil);
  LineTo(DC, x2, y2);
  DeleteObject(Pen);
end;
{$ENDIF}
{$IFDEF LINUX}
begin
  XSetForeground(XDisplay, GC, BGR2RGB(FPenColor));
  XDrawLine(XDisplay, Handle, GC, x1, y1, x2, y2);
end;
{$ENDIF}
{$IFDEF DARWIN}
var
  v : array [0..3] of Single;
begin
  v[0] := x1;
  v[2] := x2;
  if x1 = x2 then
  begin
    v[1] := y1 - 1;
    v[3] := y2 - 1;
  end else
  begin
    v[1] := y1;
    v[3] := y2;
  end;
  CGContextStrokeLineSegments(Context, @v, 2);
end;
{$ENDIF}

procedure TCanvas.FrameRect(const Rect: TRect);
{$IFDEF WIN32}
var
  Brush : HBRUSH;
begin
  Brush := CreateSolidBrush(PenColor);
  jsys.FrameRect(DC, Rect, Brush);
  DeleteObject(Brush);
end;
{$ENDIF}
{$IFDEF LINUX}
begin
  XSetForeground(XDisplay, GC, BGR2RGB(FPenColor));
  with Rect do
    XDrawRectangle(XDisplay, Handle, GC, Left, Top, Right - Left - 1, Bottom - Top - 1);
end;
{$ENDIF}
{$IFDEF DARWIN}
begin
  CGContextStrokeRect(Context, CGRectMake(Rect));
end;
{$ENDIF}

procedure TCanvas.FillRect(const Rect: TRect);
{$IFDEF WIN32}
var
  Brush : HBRUSH;
begin
  Brush := CreateSolidBrush(BrushColor);
  jsys.FillRect(DC, Rect, Brush);
  DeleteObject(Brush);
end;
{$ENDIF}
{$IFDEF LINUX}
begin
  XSetForeground(XDisplay, GC, BGR2RGB(FBrushColor));
  with Rect do
    XFillRectangle(XDisplay, Handle, GC, Left, Top, Right - Left, Bottom - Top);
end;
{$ENDIF}
{$IFDEF DARWIN}
var
  r : CGRect;
begin
  r := CGRectMake(Rect, False);
  r.origin.y := r.origin.y - 1;
  CGContextFillRect(Context, r);
end;
{$ENDIF}

function TCanvas.TextWidth(Text: PWideChar; Count: LongInt): LongInt;
{$IFDEF DARWIN}
var
  SetupFlag : Boolean;
{$ENDIF}

  function GetWidth(Pos, Length: LongInt): LongInt;
  var
    i : LongInt;
  {$IFDEF WIN32}
    Size : TPoint;
  {$ENDIF}
  {$IFDEF DARWIN}
    b, e, d : ATSUTextMeasurement;
  {$ENDIF}
  begin
    Result := 0;
    for i := Pos to Pos + Length - 1 do
    begin
      if Font.CharInfo[Text[i]].Width = -1 then
      begin
      {$IFDEF WIN32}
        GetTextExtentPoint32W(DC, @Text[i], 1, Size);
        Font.CharInfo[Text[i]].Width := Size.X;
      {$ENDIF}
      {$IFDEF LINUX}
        Font.CharInfo[Text[i]].Width := 8;
      {$ENDIF}
      {$IFDEF DARWIN}
        if not SetupFlag then
        begin
          ATSUSetTextPointerLocation(Layout, Pointer(Text), 0, Count, Count);
          ATSUSetRunStyle(Layout, Font.Style, 0, kATSUToTextEnd);
          ATSUSetTransientFontMatching(Layout, True);
          SetupFlag := True;
        end;
        ATSUGetUnjustifiedBounds(Layout, i, 1, b, e, Font.Ascent, d);
        Font.CharInfo[Text[i]].Width := Round(Fix2X(e - b));
      {$ENDIF}
      end;
      Inc(Result, Font.CharInfo[Text[i]].Width);
    end;
  end;

var
  i, b : LongInt;
begin
{$IFDEF DARWIN}
  SetupFlag := False;
{$ENDIF}
  Result := 0;
  b := 0;
  for i := 0 to Count - 1 do
    if Text[i] = #13 then
    begin
      Inc(Result, GetWidth(b, i - b));
      b := i + 1;
    end;

  if b < Count then
    Inc(Result, GetWidth(b, Count - b));
end;

procedure TCanvas.TextWrap(Text: PWideChar; Count, X, Width: LongInt; out Lines: TStringPartArray);
type
  TCS = set of AnsiChar;
const
  c1 : TCS = [#13, ' ', '!', '%', ')', '-', '>', '?', ']', '}', #$A1, #$A2, {'°', '·', '»',} #$BF]; // post break
  c2 : TCS = ['$', '(', '<', '[', '\', '{', #$A3, #$A5{, '¤', '«'}];  // pre break
var
  TextLine, CurLine : TStringPart;

  procedure AddLine(NewLine: TStringPart);
  begin
    if (NewLine.Length > 0) and (Text[NewLine.Start + NewLine.Length - 1] = #13) then
      Dec(NewLine.Length);
    SetLength(Lines, Length(Lines) + 1);
    Lines[Length(Lines) - 1] := NewLine;
    CurLine.Left := 0;
  end;

  procedure ParseLine;
  var
    i, b, t, w : LongInt;
  begin
    if TextLine.Length <= 0 then
      Exit;
  // check line length
    w := TextWidth(@Text[TextLine.Start], TextLine.Length);
  // width of sum line parts greater than max width
    if CurLine.Right + w > Width then
    begin
      if CurLine.Length > 0 then
        AddLine(CurLine);
      CurLine.Start  := TextLine.Start;
      CurLine.Length := TextLine.Length;
      CurLine.Right  := CurLine.Left + TextWidth(@Text[CurLine.Start], CurLine.Length);
    // text part width is greater than max width
      if CurLine.Right > Width then
      begin
        t := CurLine.Left;
        b := CurLine.Start;
        for i := CurLine.Start to CurLine.Start + CurLine.Length - 1 do
        begin
          w := TextWidth(@Text[i], 1);
          if (t + w > Width) and (t > 0) then
          begin
            TextLine.Start  := b;
            TextLine.Length := i - b;
            TextLine.Left   := CurLine.Left;
            TextLine.Right  := t;
            Dec(CurLine.Right, t);
            AddLine(TextLine);
            b := i;
            t := w;
          end else
            Inc(t, w);
        end;
        if (b > CurLine.Start) or (w > 0) then
        begin
          CurLine.Length := CurLine.Start + CurLine.Length - b;
          CurLine.Start  := b;
        end;
      end;
    end else
    begin
      Inc(CurLine.Right, w);
      Inc(CurLine.Length, TextLine.Length);
    end;

    with CurLine do
      if (Length > 0) and (Text[Start + Length - 1] = #13) then
      begin
        AddLine(CurLine);
        CurLine.Right := CurLine.Left;
        Start  := Start + Length;
        Length := 0;
      end;
  end;

var
  i, b : LongInt;
begin
  Lines := nil;
  b := 0;
  CurLine.Start   := 0;
  CurLine.Length  := 0;
  CurLine.Left    := X;
  CurLine.Right   := X;
  for i := 0 to Count - 1 do
  begin
  // copy text fragment
    if (Ord(Text[i]) < 256) and (AnsiChar(Text[i]) in c1) then // post break
    begin
      TextLine.Start  := b;
      TextLine.Length := i - b + 1;
      b := i + 1;
    end else
      if (Ord(Text[i]) < 256) and (AnsiChar(Text[i]) in c2) then // pre break
      begin
        TextLine.Start  := b;
        TextLine.Length := i - b;
        b := i;
      end else
        continue;
    ParseLine;
  end;

  TextLine.Start  := b;
  TextLine.Length := Count - b;
  ParseLine;
  AddLine(CurLine);
end;

procedure TCanvas.TextOut(X, Y: LongInt; Text: PWideChar; Length: LongInt);
{$IFDEF WIN32}
begin
  TextOutW(DC, X, Y, Text, Length);
{$ENDIF}
{$IFDEF LINUX}
var
  Color : TXftColor;
begin
  with PRGBA(@FTextColor)^, Color do
  begin
    color.R := R shl 8 or R;
    color.G := G shl 8 or G;
    color.B := B shl 8 or B;
    color.A := $FFFF;
  end;
  XftDrawString16(XftDraw, @Color, Font.ID, X, Y, Text, Length);
{$ENDIF}
{$IFDEF DARWIN}
var
  TempBrush : TColor;
begin
  if Font <> nil then
  begin
    TempBrush := BrushColor;
    BrushColor := TextColor;
    ATSUSetTextPointerLocation(Layout, Pointer(Text), 0, Length, Length);
    ATSUSetRunStyle(Layout, Font.Style, 0, kATSUToTextEnd);
    ATSUSetTransientFontMatching(Layout, True);
    ATSUDrawText(Layout, 0, Length, X shl 16, (Y - 1) shl 16 - Font.Ascent);
    BrushColor := TempBrush;
  end;
{$ENDIF}
end;

function TCanvas.TextOut(X, Y, LineHeight: LongInt; Text: PWideChar; const Lines: TStringPartArray): LongInt;
var
  i : LongInt;
begin
  Result := X;
  for i := 0 to Length(Lines) - 1 do
  begin
    TextOut(X + Lines[i].Left, Y + i * LineHeight, @Text[Lines[i].Start], Lines[i].Length);
    Result := Lines[i].Right;
  end;
end;

procedure TCanvas.TextOut(X, Y: LongInt; const Text: WideString);
begin
  TextOut(X, Y, PWideChar(Text), Length(Text));
end;

function TCanvas.TextPosToCaret(X, Y: LongInt; Text: PWideChar; const Lines: TStringPartArray): LongInt;
var
  i, cx, px : LongInt;
begin
  if y < 0 then
    Result := 0
  else
    if y < Length(Lines) then
    begin
      px := 0;
      for i := Lines[y].Start to Lines[y].Start + Lines[y].Length - 1 do
      begin
        cx := TextWidth(@Text[i], 1);
        Inc(px, cx);
        if px > X then
        begin
          if px - X > cx div 2 then
            Result := i
          else
            Result := i + 1;
          Exit;
        end;
      end;
      Result := Lines[y].Start + Lines[y].Length;
    end else
      Result := Length(Text);
end;

function TCanvas.TextCaretToPos(Caret: LongInt; Text: PWideChar; const Lines: TStringPartArray): TPoint;
var
  i : LongInt;
begin
  for i := 0 to Length(Lines) - 1 do
    with Lines[i] do
      if Caret > 0 then
      begin
        if (Start > 0) and (Text[Start - 1] = #13) then
          Dec(Caret);
        if Caret <= Length then
        begin
          Result.X := TextWidth(@Text[Start], Caret);
          Result.Y := i;
          Exit;
        end else
          Dec(Caret, Length);
      end;
  Result.X := 0;
  Result.Y := 0;
end;

procedure TCanvas.Draw(Canvas: TCanvas; const SrcRect, DstRect: TRect; Alpha: Byte);
{$IFDEF WIN32}
var
  BlendMode : TBlendFunction;
begin
  if not RectIntersect(Canvas.PaintRect, DstRect) then
    Exit;

  with BlendMode do
  begin
    BlendOp             := 0;
    BlendFlags          := 0;
    SourceConstantAlpha := Alpha;
    AlphaFormat         := 1;
  end;
  AlphaBlend(Canvas.DC, DstRect.Left, DstRect.Top, DstRect.Right - DstRect.Left, DstRect.Bottom - DstRect.Top,
                    DC, SrcRect.Left, SrcRect.Top, SrcRect.Right - SrcRect.Left, SrcRect.Bottom - SrcRect.Top, BlendMode);
{$ENDIF}
{$IFDEF LINUX}
begin
  //
{$ENDIF}
{$IFDEF DARWIN}
var
  img : CGImageRef;
  r : CGRect;
begin
  r := CGRectMake(SrcRect, False);
  r.origin.y := ImgHeight - r.origin.y - r.size.height;
  img := CGImageCreateWithImageInRect(Image, r);
  CGContextSetAlpha(Canvas.Context, Alpha * IBYTE);
  r := CGRectMake(DstRect, False);
  r.origin.y := r.origin.y - 1;
  CGContextDrawImage(Canvas.Context, r, img);
  CGContextSetAlpha(Canvas.Context, 1);
  CGImageRelease(img);
{$ENDIF}
end;
{$ENDREGION}

{$REGION 'TImage'}
{ TImage }
constructor TImage.Create(ImgData: Pointer; Width, Height: LongInt);
begin
  FCanvas := TCanvas.Create(ImgData, Width, Height);
  Self.Width  := Width;
  Self.Height := Height;
  Valid := True;
end;

constructor TImage.Create(Data: Pointer; Size: LongInt; KeepData: Boolean);
var
  Stream : TStream;
  IWidth, IHeight : LongInt;
begin
  Stream := TMemoryStream.Create(Data, Size);
  Valid := LoadIMG(Stream, ImgData, IWidth, IHeight);
  if Valid then
  begin
    Create(ImgData, IWidth, IHeight);
    if not KeepData then
      FreeData;
  end;
  Stream.Free;
end;

destructor TImage.Destroy;
begin
  FreeData;
  FCanvas.Free;
  inherited;
end;

class function TImage.Load(const FileName: WideString): TImage;
var
  Stream : TFileStream;
  Data   : Pointer;
begin
  Stream := TFileStream.Create(FileName);
  if Stream.Valid then
  begin
    Data := GetMemory(Stream.Size);
    Stream.Read(Data^, Stream.Size);
    Result := TImage.Create(Data, Stream.Size);
    FreeMemory(Data);
  end else
    Result := nil;
  Stream.Free;
end;

procedure TImage.FreeData;
begin
  if ImgData <> nil then
  begin
    FreeMemory(ImgData);
    ImgData := nil;
  end;
end;

function TImage.GetPixel(x, y: LongInt): LongWord;
begin
  Result := PLongArray(ImgData)[(Height - y - 1) * Width + x] and $FFFFFF;
end;

procedure TImage.Draw(Canvas: TCanvas; const SrcRect, DstRect: TRect; Alpha: Byte);
begin
  if FCanvas <> nil then
    FCanvas.Draw(Canvas, SrcRect, DstRect, Alpha);
end;

procedure TImage.Draw(Canvas: TCanvas; sX, sY, sW, sH, dX, dY, dW, dH: LongInt; Alpha: Byte);
begin
  Draw(Canvas, SetRect(sX, sY, sX + sW, sY + sH), SetRect(dX, dY, dX + dW, dY + dH), Alpha);
end;

procedure TImage.Draw(Canvas: TCanvas; X, Y, AreaWidth, AreaHeight: LongInt; Alpha: Byte);
begin
  Draw(Canvas, 0, 0, Width, Height,
       X + (AreaWidth - Width) div 2, Y + (AreaHeight - Height) div 2, Width, Height, Alpha);
end;

procedure TImage.DrawFrame(Canvas: TCanvas; X, Y, Index, Size: LongInt; Alpha: Byte);
begin
  Draw(Canvas,
       Index mod (Width div Size) * Size, Index div (Width div Size) * Size,
       Size, Size, X, Y, Size, Size, Alpha);
end;

procedure TImage.DrawWindow(Canvas: TCanvas; Rect: TRect; sX, sY, Size: LongInt; Alpha: Byte);
var
  sR, sB, dR, dB, dL, dT : LongInt;
begin
  if (Rect.Right - Rect.Left < Size * 2) or (Rect.Bottom - Rect.Top < Size * 2) then
    Exit;

  with Rect do
  begin
    sR := sX + Size;
    sB := sY + Size;
    dL := Left + Size;
    dT := Top + Size;
    dR := Right - Size;
    dB := Bottom - Size;
    Draw(Canvas, sX, sY, Size, Size, Left, Top, Size, Size, Alpha);    // LT
    Draw(Canvas, sX, sB, Size, Size, Left, dB, Size, Size, Alpha);     // LB
    Draw(Canvas, sR, sY, Size, Size, dR, Top, Size, Size, Alpha);      // RT
    Draw(Canvas, sR, sB, Size, Size, dR, dB, Size, Size, Alpha);       // RB
    Draw(Canvas, sR, sY, 1, Size, dL, Top, dR - Left - Size, Size, Alpha);  // T
    Draw(Canvas, sR, sB, 1, Size, dL, dB, dR - Left - Size, Size, Alpha);   // B
    Draw(Canvas, sX, sB, Size, 1, Left, dT, Size, dB - Top - Size, Alpha);  // L
    Draw(Canvas, sR, sB, Size, 1, dR, dT, Size, dB - Top - Size, Alpha);    // R
    Draw(Canvas, sR, sB, 1, 1, dL, dT, dR - Left - Size, dB - Top - Size, Alpha);
  end;
end;

procedure TImage.DrawWindowH(Canvas: TCanvas; sX, sY, dX, dY, Width, Size: LongInt; Alpha: Byte);
var
  sR, dR, dL : LongInt;
begin
  sR := sX + Size;
  dR := dX + Width - Size;
  dL := dX + Size;
  Draw(Canvas, sX, sY, Size, Size, dX, dY, Size, Size, Alpha);    // L
  Draw(Canvas, sR, sY, Size, Size, dR, dY, Size, Size, Alpha);    // R
  Draw(Canvas, sR, sY, 1, Size, dL, dY, Width - Size - Size, Size, Alpha);  // C
end;
{$ENDREGION}

{$REGION 'TImageAtlas'}
constructor TImageAtlas.Create(MapSize, ItemSize: LongInt);
begin
  Self.MapSize  := MapSize;
  Self.ItemSize := ItemSize;
  SetLength(Items, MapSize * MapSize);
  FillChar(Items[0], Length(Items) * SizeOf(Items[0]), 0);
  Atlas := TCanvas.Create(nil, MapSize * ItemSize, MapSize * ItemSize);
  Atlas.BrushColor := $FF00FF;
  Atlas.FillRect(SetRect(0, 0, MapSize * ItemSize, MapSize * ItemSize));
  Atlas.CS.Init;
end;

destructor TImageAtlas.Destroy;
begin
  Atlas.CS.Free;
  Atlas.Free;
  inherited;
end;

procedure TImageAtlas.Push(ImgData: PByteArray; var Item: TAtlasItem);
var
  i, p, d, minTime : LongInt;
begin
  Atlas.CS.Lock;
  Item.Index := -1;
// search free slot
  for i := 0 to Length(Items) - 1 do
    if Items[i] = nil then
    begin
      Item.Index := i;
      break;
    end;
// or old
  if Item.Index < 0 then
  begin
    minTime := Items[0].Time;
    Item.Index := 0;
    for i := 1 to Length(Items) - 1 do
      if Items[i].Time < minTime then
        Item.Index := i;
    Items[Item.Index].Index := -1;
  end;
  Items[Item.Index] := @Item;
// fill slot
  p := ((Item.Index mod MapSize) + (MapSize - Item.Index div MapSize - 1) * MapSize * ItemSize) * ItemSize * 4;
  d := MapSize * ItemSize * 4;
  for i := 0 to ItemSize - 1 do
  begin
    Move(ImgData[i * ItemSize * 4], Atlas.DataPtr[p], ItemSize * 4);
    Inc(p, d);
  end;
  Atlas.CS.Unlock;
end;

procedure TImageAtlas.Pop(var Item: TAtlasItem);
begin
  Atlas.CS.Lock;
  if Item.Index > -1 then
  begin
    Items[Item.Index] := nil;
    Item.Index := -1;
  end;
  Atlas.CS.Unlock;
end;

procedure TImageAtlas.Draw(Canvas: TCanvas; X, Y: LongInt; var Item: TAtlasItem; Alpha: Byte);
var
  sX, sY : LongInt;
begin
  Atlas.CS.Lock;
  if Item.Index > -1 then
  begin
    Item.Time := GetTime;
    sX := (Item.Index mod MapSize) * ItemSize;
    sY := (Item.Index div MapSize) * ItemSize;
    Atlas.Draw(Canvas,
                SetRect(sX, sY, sX + ItemSize, sY + ItemSize),
                SetRect(X, Y, X + ItemSize, Y + ItemSize), Alpha);
  end;
  Atlas.CS.Unlock;
end;
{$ENDREGION}

{$REGION 'TIcon'}
constructor TIcon.Create(ImgData: PByteArray; X, Y, Size: LongInt);
const
  IMG_WIDTH = 32;
  BPP = 4;
var
  Img : PByteArray;
  i : LongInt;
begin
// icon image has size 32xN
  Img := GetMemory(Size * Size * BPP);
  for i := 0 to Size - 1 do
    System.Move(ImgData^[((Y + i) * IMG_WIDTH + X) * BPP], Img^[i * Size * BPP], Size * BPP);
  inherited Create(Img, Size, Size);
  for i := 0 to Size - 1 do
    System.Move(ImgData^[((Y + i) * IMG_WIDTH + X) * BPP], Img^[(Size - i - 1) * Size * BPP], Size * BPP);
{$IFDEF WIN32}
  Icon := CreateIcon(HInstance, Size, Size, 1, BPP * 8, nil, Img);
{$ENDIF}
  FreeMemory(Img);
end;

destructor TIcon.Destroy;
begin
{$IFDEF WIN32}
  DestroyIcon(Icon);
{$ENDIF}
  if Small <> nil then
    Small.Free;
  inherited;
end;

procedure TIcon.Draw(Canvas: TCanvas; X, Y: LongInt; Alpha: Byte = 255);
begin
  inherited Draw(Canvas, X, Y, 16, 16, Alpha);
end;
{$ENDREGION}

{$REGION 'Common'}
function GetDateTime: TMsgDateTime;
{$IFDEF WIN32}
var
  t : TSystemTime;
begin
  GetLocalTime(t);
  Result.Time.Minute := t.wMinute;
  Result.Time.Hour   := t.wHour;
  Result.Date.Day    := t.wDay;
  Result.Date.Month  := t.wMonth;
  Result.Date.Year   := t.wYear;
end;
{$ENDIF}
{$IFDEF LINUX}
{$ENDIF}
{$IFDEF DARWIN}
var
  gt : CFGregorianDate;
begin
  gt := CFAbsoluteTimeGetGregorianDate(CFAbsoluteTimeGetCurrent, CFTimeZoneCopySystem);
  Result.Time.Minute := gt.minute;
  Result.Time.Hour   := gt.hour;
  Result.Date.Day    := gt.day;
  Result.Date.Month  := gt.month;
  Result.Date.Year   := gt.year;
end;
{$ENDIF}

procedure Wait(ms: LongWord);
begin
{$IFDEF WIN32}
  Sleep(ms);
{$ENDIF}
end;

function UnixTimeDecode(UnixTime: TUnixTime): TUTime;
{$IFDEF WIN32}
var
  t  : Int64;
  ft : TFileTime;
  st : TSystemTime;
  ti : TTimeZoneInformation;
begin
  GetTimeZoneInformation(ti);
  t := UnixTime;
  t := (t - (ti.Bias {+ ti.DaylightBias}) * 60) * 10000000 + 116444736000000000;
  ft.dwLowDateTime  := LongWord(t);
  ft.dwHighDateTime := t shr 32;
  FileTimeToSystemTime(ft, st);
  with Result do
  begin
    Second := st.wSecond;
    Minute := st.wMinute;
    Hour   := st.wHour;
    Day    := st.wDay;
    Month  := st.wMonth;
    Year   := st.wYear;
  end;
end;
{$ENDIF}
{$IFDEF LINUX}
{$ENDIF}
{$IFDEF DARWIN}
var
  at : CFAbsoluteTime;
  gt : CFGregorianDate;
begin
  with Result do
  begin
    UCConvertUTCDateTimeToCFAbsoluteTime(UnixTime, at);
    gt := CFAbsoluteTimeGetGregorianDate(at, CFTimeZoneCopySystem);
    Second := Round(gt.second);
    Minute := gt.minute;
    Hour   := gt.hour;
    Day    := gt.day;
    Month  := gt.month;
    Year   := gt.year;
  end;
end;
{$ENDIF}

function ConvZ(x: LongInt): WideString;
begin
  if x < 10 then
    Result := '0'
  else
    Result := '';
  Result := Result + Conv(x);
end;

function MsgConvDate(Date: TMsgDate): WideString;
begin
  Result := Conv(LongWord(Date.Day)) + ' ' + LangMsg[TLangMsg(Ord(lmMJan) + Date.Month - 1)] + ' ' + ConvZ(Date.Year);
end;

function MsgConvTime(Time: TMsgTime): WideString;
begin
  Result := ConvZ(Time.Hour) + ':' + ConvZ(Time.Minute);
end;

function MsgDateTime(UnixTime: TUnixTime): TMsgDateTime;
var
  UTime: TUTime;
begin
  UTime := UnixTimeDecode(UnixTime);
  Result.Date.Day    := UTime.Day;
  Result.Date.Month  := UTime.Month;
  Result.Date.Year   := UTime.Year;
  Result.Time.Hour   := UTime.Hour;
  Result.Time.Minute := UTime.Minute;
end;

function MsgDateCompare(const Date1, Date2: TMsgDate): Boolean;
begin
  Result := (Date1.Day = Date2.Day) and (Date1.Month = Date2.Month) and (Date1.Year = Date2.Year);
end;
{$ENDREGION}

procedure NetInit;
{$IFDEF WIN32}
var
  wData : TWSAData;
begin
  WSAStartup($0101, wData);
{$ELSE}
begin
{$ENDIF}
end;

procedure NetFree;
begin
{$IFDEF WIN32}
  WSACleanup;
{$ENDIF}
end;

procedure PlaySound(const Data: Pointer);
begin
{$IFDEF WIN32}
  sndPlaySoundW(Data, SND_ASYNC or SND_MEMORY);
{$ENDIF}
end;

function MakeDir(const Path: WideString): Boolean;
begin
{$I-}
  MkDir(Path);
{$I+}
  Result := IOResult = 0;
end;

function GetAppDir: WideString;
begin
  Result := ParamStr(0);
end;

function GetRootVIK: WideString;
var
  s : WideString;
begin
  SetLength(s, 255);
  if not SHGetSpecialFolderPathW(0, PWideChar(s), $1C{CSIDL_LOCAL_APPDATA}, True) then
    Result := ''
  else
    Result := PWideChar(s) + '\ViK\';
end;

function GetRootDir: WideString;
{$IFDEF WIN32}
const
  CLIENT_DIR : WideString = 'joim\';
  CSIDL_PERSONAL = $0005;
var
  Buf : array [0..255] of WideChar;
  F : File;
begin
{$I-}
  FileMode := 2;
  AssignFile(F, CLIENT_DIR + 'logon.dat');
  Reset(F, 1);
  if IOResult = 0 then
  begin
    CloseFile(F);
    Result := CLIENT_DIR;
    Exit;
  end;
{$I+}
  SHGetFolderPathW(0, CSIDL_PERSONAL, 0, 0, PWideChar(@Buf));
  Result := WideString(Buf) + '\' + CLIENT_DIR;
{$ELSE}
begin
  {$IFDEF LINUX}
    Result := '/usr/share/joim/';  //fpGetenv('HOME')/.config
  {$ENDIF}
  {$IFDEF DARWIN}
    Result := '/Library/Application Support/joim/';
  {$ENDIF}
{$ENDIF}
end;

function GetCursorPos: TPoint;
begin
{$IFDEF WIN32}
  GetCursorPosEx(Result);
{$ENDIF}
{$IFDEF LINUX}
  Result.X := 0;
  Result.Y := 0;
{$ENDIF}
{$IFDEF DARWIN}
  Result.X := 0;
  Result.Y := 0;
{$ENDIF}
end;

procedure UpdateScreen;
{$IFDEF WIN32}
var
  Rect : TRect;
begin
  SystemParametersInfoW(SPI_GETWORKAREA, 0, @Rect, 0);
  Screen.Left   := Rect.Left;
  Screen.Top    := Rect.Top;
  Screen.Width  := Rect.Right - Rect.Left;
  Screen.Height := Rect.Bottom - Rect.Top;
{$ELSE}
begin
  Screen.Left   := 0;
  Screen.Top    := 0;
  Screen.Width  := 1024;
  Screen.Height := 768;
{$ENDIF}
end;

procedure RegisterHotKeys;
const
  DB = Ord(High(THotKey)) + 1;
begin
{$IFDEF WIN32}
  RegisterHotKey(Window.Handle, Integer(hkPlayNext),  0, VK_MEDIA_NEXT_TRACK);
  RegisterHotKey(Window.Handle, Integer(hkPlayPrev),  0, VK_MEDIA_PREV_TRACK);
  RegisterHotKey(Window.Handle, Integer(hkStop),      0, VK_MEDIA_STOP);
  RegisterHotKey(Window.Handle, Integer(hkPlayPause), 0, VK_MEDIA_PLAY_PAUSE);

  RegisterHotKey(Window.Handle, Integer(hkPlayNext)  + DB, MOD_ALT or MOD_CONTROL, VK_DOWN);
  RegisterHotKey(Window.Handle, Integer(hkPlayPrev)  + DB, MOD_ALT or MOD_CONTROL, VK_UP);
  RegisterHotKey(Window.Handle, Integer(hkStop)      + DB, MOD_ALT or MOD_CONTROL, VK_LEFT);
  RegisterHotKey(Window.Handle, Integer(hkPlayPause) + DB, MOD_ALT or MOD_CONTROL, VK_RIGHT);
{$ENDIF}
end;

function GetTime: LongWord;
{$IFDEF WIN32}
begin
  Result := GetTickCount;
{$ENDIF}
{$IFDEF DARWIN}
var
  T : UnsignedWide;
begin
  Microseconds(T);
  Result := T.int div 1000;
{$ENDIF}
end;

function MoveFile(const Path1, Path2: WideString): Boolean;
begin
{$IFDEF WIN32}
  Result := MoveFileExW(PWideChar(Path1), PWideChar(Path2), 1);
{$ENDIF}
{$IFDEF DARWIN}
  Result := False;
{$ENDIF}
end;

function DeleteFile(const Path: WideString): Boolean;
begin
{$IFDEF WIN32}
  Result := DeleteFileW(PWideChar(Path));
{$ENDIF}
{$IFDEF DARWIN}
  Result := False;
{$ENDIF}
end;

procedure BrowseURL(const URL: WideString);
begin
{$IFDEF WIN32}
  ShellExecuteW(Window.Handle, 'open', PWideChar(URL), nil, nil, SW_SHOW);
{$ENDIF}
end;

procedure RestartApp;
begin
{$IFDEF WIN32}
  ShellExecuteW(0, 'open', PWideChar(AppPath), nil, nil, SW_SHOW);
{$ENDIF}
end;

procedure CheckFolders;
begin
  MakeDir(RootDir);
  MakeDir(RootDir + 'avatar/');
  MakeDir(RootDir + 'img/');
end;

procedure FlushMemory;
{$IFDEF WIN32}
var
  MainHandle: THandle;
begin
  MainHandle := OpenProcess(PROCESS_ALL_ACCESS, False, GetCurrentProcessID);
  SetProcessWorkingSetSize(MainHandle, DWORD(-1), DWORD(-1));
  CloseHandle(MainHandle);
end;
{$ELSE}
begin
end;
{$ENDIF}

function CheckAutorun(Autorun: TAutorun): Boolean;
{$IFDEF WIN32}
const
  PATH : PWideChar = 'Software\Microsoft\Windows\CurrentVersion\Run';
var
  Key: HKEY;
  dt, ds : LongInt;
begin
  Result := False;
  if RegOpenKeyW(HKEY_CURRENT_USER, PATH, Key) = 0 then
  begin
    case Autorun of
      arCheck :
        Result := RegQueryValueExW(Key, PWideChar(CLIENT_NAME), nil, @dt, nil, @ds) = 0;
      arEnable :
        Result := True;
      arDisable :
        RegDeleteValueW(Key, PWideChar(CLIENT_NAME));
    end;
    if Result then
      Result := RegSetValueExW(Key, PWideChar(CLIENT_NAME), 0, 1, PWideChar(WideString(ParamStr(0))), Length(ParamStr(0)) * SizeOf(WideChar)) = 0;
    RegCloseKey(Key);
  end;
end;
{$ELSE}
begin
  Result := False;
end;
{$ENDIF}

function ClipboardGet: WideString;
{$IFDEF WIN32}
var
  mem : LongWord;
  blk : Pointer;
begin
  if not IsClipboardFormatAvailable(CF_UNICODETEXT) then
    Exit;
  if not OpenClipboard(Window.Handle) then
    Exit;
  mem := GetClipboardData(CF_UNICODETEXT);
  blk := GlobalLock(mem);
  if blk <> nil then
  begin
    SetLength(Result, Length(PWideChar(blk)));
    Move(blk^, Result[1], Length(Result) * SizeOf(WideChar));
    GlobalUnlock(mem);
  end else
    Result := '';
  CloseClipboard;
end;
{$ELSE}
begin
  Result := '';
end;
{$ENDIF}

procedure ClipboardSet(const Text: WideString);
{$IFDEF WIN32}
var
  mem : LongWord;
  blk : Pointer;
begin
  if not OpenClipboard(Window.Handle) then
    Exit;
  mem := GlobalAlloc(GMEM_MOVEABLE, (Length(Text) + 1) * SizeOf(WideChar));
  if mem = 0 then
  begin
    CloseClipboard;
    Exit;
  end;
  blk := GlobalLock(mem);
  if blk <> nil then
  begin
    EmptyClipboard;
    Move(Text[1], blk^, Length(Text) * SizeOf(WideChar));
    PWideChar(blk)[Length(Text)] := #0; // null terminated
    GlobalUnlock(mem);
    SetClipboardData(CF_UNICODETEXT, mem);
  end else
    GlobalFree(mem);
  CloseClipboard;
end;
{$ELSE}
begin
end;
{$ENDIF}

{$IFDEF DARWIN}
procedure ProxyTimerProc(inTimer: EventLoopTimerRef; TimerProc: TTimerProc); cdecl;
begin
  TimerProc;
end;
{$ENDIF}

function InitTimer(Interval: LongWord; TimerProc: TTimerProc): LongWord;
begin
{$IFDEF WIN32}
  Result := SetTimer(AppWindow.Handle, LongWord(@TimerProc), Interval, nil);
  //Result := SetTimer(Window.Handle, LongWord(@TimerProc), Interval, nil);
{$ENDIF}
{$IFDEF LINUX}
  Result := 0;
{$ENDIF}
{$IFDEF DARWIN}
  InstallEventLoopTimer(GetMainEventLoop, kEventDurationNoWait, Interval / 1000, NewEventLoopTimerUPP(@ProxyTimerProc), @TimerProc, EventLoopTimerRef(Result));
{$ENDIF}
end;

procedure FreeTimer(ID: LongWord);
begin
{$IFDEF WIN32}
  KillTimer(Window.Handle, ID);
{$ENDIF}
{$IFDEF DARWIN}
  RemoveEventLoopTimer(EventLoopTimerRef(ID));
{$ENDIF}
end;

// try except handler
function GetExceptionObject(P: Pointer): TObject;
begin
  Result := TObject.Create;
end;

{$IFNDEF FPC}
procedure ErrorHandler(ErrorCode: Byte; ErrorAddr: Pointer);
begin
  raise TObject.Create at ErrorAddr;
end;
{$ELSE}
procedure ErrorHandler(ErrorCode: LongInt; p1, p2: Pointer);
begin
  //raise TObject.Create at ErrorAddr;
end;
{$ENDIF}

procedure ExceptHandler(ExceptObject: TObject; ExceptAddr: Pointer);
begin
end;

{$IFNDEF WIN32}
var
  MM : TMemoryManager;
{$ENDIF}
initialization
{$IFNDEF WIN32}
  GetMemoryManager(MM);
  MM.NeedLock := True;
  SetMemoryManager(MM);
{$ELSE}
  Set8087CW($133F);
  WM_TASKBARCREATED := RegisterWindowMessageW('TaskbarCreated');
//  WM_TASKBARBUTTONCREATED := RegisterWindowMessageW('TaskbarButtonCreated');
{$ENDIF}
{$IFDEF LINUX}
  XDisplay := XOpenDisplay(nil);
  XScreen  := XDefaultScreen(XDisplay);
{$ENDIF}
  ErrorProc      := ErrorHandler;
  ExceptProc     := @ExceptHandler;
  ExceptionClass := TObject;
  ExceptObjProc  := @GetExceptionObject;

end.
