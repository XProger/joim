unit jctrl;

interface

{$Q-}
{$R-}

uses
  {$IFDEF DARWIN}MacOSAll,{$ENDIF}
  jsys, jutils;

{$REGION 'Class interface'}
const
  TRACK_TIME_LEFT  = 28;
  TRACK_TIME_RIGHT = 28;

type
  TControl = class;

  TWndProc = function (Hwnd, Msg: LongWord; WParam, LParam: LongInt): LongInt; stdcall;

  TCursorType = (ctNone, ctArrow, ctHand, ctIBeam, ctSizeWE, ctSizeNS);

  TShiftState = set of (ssShift, ssAlt, ssCtrl);
  TMouseButton = (mbLeft, mbRight, mbMiddle);

  THotKey = (hkPlayNext, hkPlayPrev, hkStop, hkPlayPause);

  TEventType = (etMouseWheel, etMouseDown, etMouseUp, etMouseMove,
                etChar, etKeyDown, etKeyUp, etHotKey,
                etSize, etDraw, etFocus, etHit, etFold, etChange, etClick);

  TMouseEvent = record
    Button : TMouseButton;
    BState : set of TMouseButton;
    Shift  : TShiftState;
    Pos    : record
        x, y, w : SmallInt;
      end;
  end;

  TKeyEvent = record
    Shift : TShiftState;
    case Integer of
      0 : (Value  : Word);
      1 : (Char   : System.WideChar);
      2 : (HotKey : THotKey);
  end;

  TDrawEvent = record
    Canvas : TCanvas;
    Rect   : TRect;
  end;

  TFoldEvent = record
    Fold : Boolean;
    Size : PSize;
  end;

  TControlEvent = record
    case ID: TEventType of
    // mouse
      etMouseWheel,
      etMouseDown,
      etMouseUp,
      etMouseMove  : (Mouse: TMouseEvent);
    // keyboard
      etChar,
      etKeyDown,
      etKeyUp      : (Key: TKeyEvent);
    // paint
      etDraw       : (Draw: TDrawEvent);
    // focus
      etFocus      : (Focus: Boolean);
    // fold
      etFold       : (Fold: TFoldEvent);
  end;

  TEventProc = function (Control: TControl; const Event: TControlEvent): Boolean;

  TControl = class
    constructor Create(Parent: TControl);
    destructor Destroy; override;
  protected
    FParent  : TControl;
    FVisible : Boolean;
    FFont    : TFont;
    FText    : WideString;
    FMouseFocus : TControl;
    FUpdate  : Boolean;
    function CalcASize(const RSize: TSize): TSize;
    procedure SetVisible(const Value: Boolean); virtual;
    procedure SetText(const Value: WideString); virtual;
    procedure SetFont(const Value: TFont);
    procedure SetMouseFocus(const Value: TControl);
    function GetMouseFocus: Boolean;
  public
    ASize     : TSize;
    ARect     : TRect;
    Hint      : WideString;
    Size      : TSize;
    Controls  : array of TControl;
    ID        : LongInt;
    Cursor    : TCursorType;
    EventProc : TEventProc;
    HoldFocus : Boolean;
    function GetCtrl(X, Y: LongInt): TControl;
    procedure UpdateRect;
    procedure Resize;
    procedure BeginUpdate; virtual;
    procedure EndUpdate; virtual;
    function Perform(const Event: TControlEvent): Boolean; virtual;
    function OnEvent(const Event: TControlEvent): Boolean; virtual;
    procedure Move(Left, Top, Width, Height: LongInt); virtual;
    function AddCtrl(const Ctrl: TControl): TControl;
    function DelCtrl(const Ctrl: TControl): Boolean;
    procedure Repaint(Rect: PRect = nil; Force: Boolean = False);
    property Visible: Boolean read FVisible write SetVisible;
    property Font: TFont read FFont write SetFont;
    property Text: WideString read FText write SetText;
    property CParent: TControl read FParent;
    property Rect: TRect read ARect;
    property Left: SmallInt read ASize.Left;
    property Top: SmallInt read ASize.Top;
    property Width: SmallInt read ASize.Width;
    property Height: SmallInt read ASize.Height;
    property MouseFocus: Boolean read GetMouseFocus;
  end;

  TFrame = class(TControl)
    constructor Create(Parent: TControl);
  public
    Clip : Boolean;
    Color, Border : TColor;
    function Perform(const Event: TControlEvent): Boolean; override;
    function OnEvent(const Event: TControlEvent): Boolean; override;
  end;

  THint = class;

  TWindow = class(TControl)
    constructor Create(ParentWindow: TWindow; Popup: Boolean = False; App: Boolean = False);
    destructor Destroy; override;
  protected
    DefProc : TWndProc;
    FCanvas : TCanvas;
    FActive : Boolean;
    FMinimized : Boolean;
    FFocus   : TControl;
    MouseFocus : TControl;
    FFolded : Boolean;
    FBorderColor : TColor;
    FResizing : Boolean;
    FMinSize : TSize;
    function GetWndRect: TRect;
    procedure SetVisible(const Value: Boolean); override;
    procedure SetText(const Value: WideString); override;
    procedure SetFocus(const Value: TControl);
    procedure SetFolded(const Value: Boolean);
    procedure SetActive(const Value: Boolean); virtual;
    procedure SetBorderColor(const Value: TColor);
    procedure SetShadow(const Value: Boolean);
    procedure SetResizing(const Value: Boolean);
    procedure SetMinSize(const Value: TSize);
  public
    Modal    : Boolean; // for closing MessageBox
    SepFocus : Boolean;
    Popup    : Boolean;
    Frame   : TFrame;
    HintWnd : THint;
    Handle  : {$IFDEF WIN32}LongWord{$ENDIF}{$IFDEF LINUX}LongWord{$ENDIF}{$IFDEF DARWIN}WindowRef{$ENDIF};
    ClientRect : TRect;
    ScreenRect : TRect;
    procedure Move(SLeft, STop, SWidth, SHeight: LongInt); override;
    procedure Fore;
    procedure Close;
    procedure Minimize;
    function IsFore: Boolean;
    property Canvas: TCanvas read FCanvas;
    property Focus: TControl read FFocus write SetFocus;
    property Folded: Boolean read FFolded write SetFolded;
    property Active: Boolean read FActive write SetActive;
    property BorderColor: TColor read FBorderColor write SetBorderColor;
    property Shadow: Boolean write SetShadow;
    property Resizing: Boolean read FResizing write SetResizing;
    property MinSize: TSize read FMinSize write SetMinSize;
  end;

  TAppWindow = class(TWindow)
    constructor Create;
    destructor Destroy; override;
  private
    TimerBlink : LongWord;
    FIcon      : TIcon;
    FTrayIcon  : TIcon;
    FFlashing  : Boolean;
    FTrayBlink : Boolean;
    Blink : Boolean;
    procedure SetIcon(const Value: TIcon);
    procedure SetTrayIcon(const Value: TIcon);
    procedure SetTrayBlink(const Value: Boolean);
    procedure SetFlashing(const Value: Boolean);
  public
    procedure Flash(Value: Boolean);
    procedure UpdateTray(Flag: LongWord);
    property Icon: TIcon read FIcon write SetIcon;
    property TrayIcon: TIcon read FTrayIcon write SetTrayIcon;
    property TrayBlink: Boolean read FTrayBlink write SetTrayBlink;
    property Flashing: Boolean read FFlashing write SetFlashing;
  end;

  TPopupMenu = class(TWindow)
    constructor Create(ParentWindow: TWindow);
  protected
    procedure SetVisible(const Value: Boolean); override;
    procedure SetActive(const Value: Boolean); override;
  end;

  TButton = class(TControl)
    constructor Create(Parent: TControl; Image: TImage; ImageIdx: LongInt; ImageCom: LongInt = -1);
  private
    FAlpha : Byte;
    FImageIdx : LongInt;
    FImageCom : LongInt;
    procedure SetAlpha(const Value: Byte);
    procedure SetImageIdx(const Value: LongInt);
    procedure SetImageCom(const Value: LongInt);
  public
    MinAlpha : Byte;
    Active   : Boolean;
    Image    : TImage;
    function OnEvent(const Event: TControlEvent): Boolean; override;
    property Alpha: Byte read FAlpha write SetAlpha;
    property ImageIdx: LongInt read FImageIdx write SetImageIdx;
    property ImageCom: LongInt read FImageCom write SetImageCom;
  end;

  TLabel = class(TControl)
    Color    : TColor;
    WordWrap : Boolean;
    LineHeight : LongInt;
    LineCount  : LongInt;
    Center     : Boolean;
    function OnEvent(const Event: TControlEvent): Boolean; override;
  end;

  THint = class(TWindow)
    constructor Create(ParentWindow: TWindow; Clear: Boolean = False);
  protected
    procedure SetText(const Value: WideString); override;
    procedure SetVisible(const Value: Boolean); override;
  public
    LFrame : TLabel;
    MPos   : TPoint;
    Idle   : LongInt;
    Tick   : LongInt;
    Target : TControl;
    function OnEvent(const Event: TControlEvent): Boolean; override;
  end;

  TProgress = class(TControl)
  private
    FProgress : LongInt;
    procedure SetProgress(const Value: LongInt);
  public
    function OnEvent(const Event: TControlEvent): Boolean; override;
    property Progress: LongInt read FProgress write SetProgress;
  end;

  TPicture = class(TControl)
    destructor Destroy; override;
  public
    Image : TImage;
    function OnEvent(const Event: TControlEvent): Boolean; override;
  end;

  TCheck = class(TControl)
    constructor Create(Parent: TControl);
  protected
    FOver    : Boolean;
    FChecked : Boolean;
    procedure SetText(const Value: WideString); override;
    procedure SetOver(const Value: Boolean);
    procedure SetChecked(const Value: Boolean);
  public
    function OnEvent(const Event: TControlEvent): Boolean; override;
    property Over: Boolean read FOver write SetOver;
    property Checked: Boolean read FChecked write SetChecked;
  end;

  TScroll = class(TControl)
    constructor Create(Parent: TControl);
  private
    MOffset : LongInt;
    FOffset : LongInt;
    Hover   : Boolean;
    procedure SetOffset(Value: LongInt);
  public
    Invert : Boolean;
    MDrag  : Boolean;
    Step   : LongInt;
    Range  : LongInt;
    function OnEvent(const Event: TControlEvent): Boolean; override;
    property Offset: LongInt read FOffset write SetOffset;
  end;

  TScrollBox = class(TControl)
    constructor Create(Parent: TControl);
  public
    VScroll : TScroll;
    procedure EndUpdate; override;
    procedure UpdateRange; virtual;
    function OnEvent(const Event: TControlEvent): Boolean; override;
  end;

  TSelection = record
    Left, Right : LongInt;
  end;

  TEdit = class(TScrollBox)
    constructor Create(Parent: TControl);
  protected
    FCaretOffset : LongInt;
    CaretPos     : TPoint;
    Lines : TStringPartArray;
    VText : WideString;
    MDrag : Boolean;
    FSelection : TSelection;
    procedure Change;
    procedure SetText(const Value: WideString); override;
    procedure SetCaretOffset(Value: LongInt);
    function GetSelection: TSelection;
  public
    Disable     : Boolean;
    Dereturn    : Boolean;
    InFocus     : Boolean;
    Highlight   : Boolean;
    Password    : Boolean;
    WordWrap    : Boolean;
    Tabulate    : Boolean;
    CaretState  : Boolean;
    ReadOnly    : Boolean;
    procedure Clear;
    procedure ScrollToCaret;
    procedure UpdateRange; override;
    function SelectionDelete: Boolean;
    function SelectionText: WideString;
    procedure SwitchLayout;
    procedure TextCut;
    procedure TextCopy;
    procedure TextPaste;
    function OnEvent(const Event: TControlEvent): Boolean; override;
    property CaretOffset: LongInt read FCaretOffset write SetCaretOffset;
    property Selection: TSelection read GetSelection;
  end;

  TSplitter = class(TControl)
  protected
    MDrag : Boolean;
    MPos  : TPoint;
    FVertical : Boolean;
    procedure SetVertical(const Value: Boolean);
  public
    Ctrl     : array [0..1] of TControl;
    MinSize  : array [0..1] of LongInt;
    function OnEvent(const Event: TControlEvent): Boolean; override;
    property Vertical: Boolean read FVertical write SetVertical;
  end;

  TLoader = class(TControl)
    function OnEvent(const Event: TControlEvent): Boolean; override;
  end;

  TTrack = class(TControl)
    constructor Create(Parent: TControl);
  private
    TempPos   : LongInt;
    FPosition : LongInt;
    FComplete : Single;
    function GetPosition: LongInt;
    procedure SetPosition(const Value: LongInt);
    procedure SetComplete(const Value: Single);
  public
    MDrag    : Boolean;
    Time     : Boolean;
    BarWidth : LongInt;
    MaxValue : LongInt;
    function OnEvent(const Event: TControlEvent): Boolean; override;
    function TrackLeft: LongInt;
    function TrackWidth: LongInt;
    property Position: LongInt read GetPosition write SetPosition;
    property Complete: Single read FComplete write SetComplete;
  end;

  TVolume = class(TControl)
    constructor Create(Parent: TControl);
  private
    FValue : LongInt;
    procedure SetValue(const Value: LongInt);
  public
    MDrag    : Boolean;
    function OnEvent(const Event: TControlEvent): Boolean; override;
    property Value: LongInt read FValue write SetValue;
  end;

  TImageList = class(TControl)
  private
    FIndex : LongInt;
    FOver  : LongInt;
    procedure SetOver(const Value: LongInt);
    procedure SetIndex(const Value: LongInt);
  public
    Image : TImage;
    Cols  : LongInt;
    Count : LongInt;
    ImageText : function (Index: LongInt): WideString;
    function OnEvent(const Event: TControlEvent): Boolean; override;
    property Over: LongInt read FOver write SetOver;
    property Index: LongInt read FIndex write SetIndex;
  end;
{$ENDREGION}

  procedure MessageLoop;

implementation

uses
  jglobal, jroster;

const
  TIMER_MOUSE   = 1;
  TIMER_EDIT    = 2;

{$REGION 'Common'}
procedure MessageLoop;
{$IFDEF WIN32}
var
  Msg : TMsg;
begin
  while GetMessageW(Msg, 0, 0, 0) do
  begin
    TranslateMessage(Msg);
    DispatchMessageW(Msg);
  end;
end;
{$ENDIF}
{$IFDEF DARWIN}
begin
  RunApplicationEventLoop;
end;
{$ENDIF}

{$IFDEF WIN32}
function WndProc(hWnd, Msg: LongWord; wParam, lParam: Integer): Integer; stdcall;
var
  Wnd  : TWindow;
  Ctrl : TControl;
  Event : TControlEvent;
  p : TPoint;
  Rect : TRect;

  DC   : HDC;
  MDC  : HDC;
  LDC  : HDC;
  MBMP : HBITMAP;
  LBMP : HBITMAP;
  PS   : TPaintStruct;
{
  DropIndex : LongInt;
  DropCount : LongInt;
  DropLen   : LongInt;
  DropName  : array [1..512] of WideChar;
}
  function GetCtrlScreen: TControl;
  var
    p : TPoint;
  begin
    p := GetCursorPos;
    ScreenToClient(hWnd, p);
    Result := Wnd.GetCtrl(p.X, p.Y);
    if not RectIntersect(Result.ARect, p.X, p.Y) then
      Result := nil;
  end;

begin
  Wnd := TWindow(GetWindowLongW(Hwnd, GWL_USERDATA));
  Result := 0;

  case Msg of
    WM_GETMINMAXINFO :
      begin
        UpdateScreen;
        with PMinMaxInfo(Pointer(LParam))^ do
        begin
          ptMinTrackSize.X := Wnd.MinSize.Width;
          ptMinTrackSize.Y := Wnd.MinSize.Height;
          ptMaxPosition.X  := Screen.Left;
          ptMaxPosition.Y  := Screen.Top;
          ptMaxSize.X      := Screen.Width;
          ptMaxSize.Y      := Screen.Height;
        end;
      end;
    WM_ACTIVATEAPP :
      begin
        Window.Active := Word(wParam) = 1;
        AppWindow.Flashing := False;
        if Window.Active and (Roster <> nil) and (not Window.FMinimized) then
          if Length(Roster.Selected) = 1 then
            Roster.GetSelected;
        Window.Repaint;
        FlushMemory;
      end;
    WM_ACTIVATE :
      if Wnd.Popup then
      begin
        Wnd.Active := Word(wParam) <> 0;
        Wnd.Repaint;
{
        if Window.Active and (not Wnd.SepFocus) then
          jsys.SendMessageW(Window.Handle, WM_NCACTIVATE, 1, 0);
}
      end;
    WM_SYSCOMMAND :
      if wParam = SC_CLOSE then
      begin
        Wnd.Minimize;
        Exit;
      end;
    WM_HOTKEY :
      begin
        Event.ID := etHotKey;
        Event.Key.HotKey := THotKey(wParam mod (Ord(High(THotKey)) + 1));
        Event.Key.Shift := [];
        Wnd.Perform(Event);
        Exit;
      end;
    WM_KEYDOWN, WM_KEYUP, WM_CHAR,
    WM_SYSKEYDOWN, WM_SYSKEYUP, WM_SYSCHAR :
      begin
        with Event, Key do
        begin
          Value := wParam; // = Char

          Shift := [];
          if GetAsyncKeyState(VK_SHIFT) <> 0 then Shift := Shift + [ssShift];
          if GetAsyncKeyState(VK_CONTROL) <> 0 then Shift := Shift + [ssCtrl];
          if GetAsyncKeyState(VK_MENU) <> 0 then Shift := Shift + [ssAlt];

          case Msg of
            WM_KEYDOWN, WM_SYSKEYDOWN : ID := etKeyDown;
            WM_KEYUP, WM_SYSKEYUP     : ID := etKeyUp;
            WM_CHAR, WM_SYSCHAR       :
              begin
                ID := etChar;
                if Value = 10 then // Ctrl + Enter = #10
                  Value := 13;
              end;
          end;
        end;

        Wnd.Focus.Perform(Event);

        if Wnd is THint then
          SendMessageW(Window.Handle, Msg, wParam, lParam);
        Exit;
      end;
    WM_MOUSEMOVE, WM_NCMOUSEMOVE, WM_MOUSEWHEEL,
    WM_LBUTTONDOWN, WM_RBUTTONDOWN, WM_MBUTTONDOWN,
    WM_LBUTTONUP, WM_RBUTTONUP, WM_MBUTTONUP,
    WM_LBUTTONDBLCLK, WM_RBUTTONDBLCLK, WM_MBUTTONDBLCLK :
      with Event, Mouse do
      begin
        p := GetCursorPos;
        ScreenToClient(Wnd.Handle, p);
        Pos.x := p.X;
        Pos.y := p.Y;
        Pos.w := 0;
        Button := mbLeft;
        BState := [];
        Shift  := [];
        case Msg of
          WM_LBUTTONDOWN, WM_RBUTTONDOWN, WM_MBUTTONDOWN :
          begin
            ID := etMouseDown;
            case Msg of
              WM_LBUTTONDOWN : Button := mbLeft;
              WM_RBUTTONDOWN : Button := mbRight;
              WM_MBUTTONDOWN : Button := mbMiddle;
            end;
            SetCapture(Wnd.Handle);
          end;
          WM_LBUTTONUP, WM_RBUTTONUP, WM_MBUTTONUP :
          begin
            ID := etMouseUp;
            case Msg of
              WM_LBUTTONUP : Button := mbLeft;
              WM_RBUTTONUP : Button := mbRight;
              WM_MBUTTONUP : Button := mbMiddle;
            end;
            if wParam and (MK_LBUTTON or MK_RBUTTON or MK_MBUTTON) = 0 then
              ReleaseCapture;
          end;
          WM_LBUTTONDBLCLK, WM_RBUTTONDBLCLK, WM_MBUTTONDBLCLK :
          begin
            ID := etMouseDown;
            case Msg of
              WM_LBUTTONDBLCLK : Button := mbLeft;
              WM_RBUTTONDBLCLK : Button := mbRight;
              WM_MBUTTONDBLCLK : Button := mbMiddle;
            end;
          end;
          WM_MOUSEWHEEL :
            begin
              ID := etMouseWheel;
              Pos.w := SmallInt(wParam  shr 16) div 120;
            end;
        else
          ID := etMouseMove;
        end;

        if wParam and MK_LBUTTON > 0 then BState := BState + [mbLeft];
        if wParam and MK_RBUTTON > 0 then BState := BState + [mbRight];
        if wParam and MK_MBUTTON > 0 then BState := BState + [mbMiddle];

        if wParam and MK_SHIFT > 0   then Shift := Shift + [ssShift];
        if wParam and MK_CONTROL > 0 then Shift := Shift + [ssCtrl];

        Ctrl := Wnd.GetCtrl(Pos.x, Pos.y);
        if (ID = etMouseDown) and (not Wnd.Focus.HoldFocus) then
          Wnd.Focus := Ctrl;

        if (ID = etMouseDown) and (BState - [Button] = []) then
          Wnd.SetMouseFocus(Ctrl);

        Wnd.Perform(Event);

        if ID = etMouseUp then
        begin
          if (Button = mbLeft) and (Ctrl <> nil) and (Ctrl = Wnd.FMouseFocus) then
          begin
            Event.ID := etClick;
            Ctrl.Perform(Event);
          end;

          if BState = [] then
            Wnd.SetMouseFocus(nil);
        end;

      // hide hint
        if (Ctrl <> nil) and (Ctrl.Hint = '') then
          Ctrl := nil;

        if Wnd.HintWnd <> nil then
          with Wnd.HintWnd do
          begin
            if Visible then
              if (Ctrl <> Target) or
                 (Event.ID <> etMouseMove) or
                 ((Event.ID = etMouseMove) and ((Abs(Pos.x - MPos.X) > 4) or (Abs(Pos.y - MPos.Y) > 4))) then
                Visible := False;

            if Ctrl <> Target then
            begin
              Tick   := Idle;
              Target := Ctrl;
            end;
          end;
      end;
    WM_ERASEBKGND :
      begin
        Result := 1;
        Exit;
      end;
    WM_PAINT :
      begin
      // double buffered
        Wnd.Canvas.Lock;
        DC := BeginPaint(Wnd.Handle, PS);
        Wnd.Canvas.PaintRect := PS.rcPaint;
        with PS.rcPaint do
        begin
          MBMP := CreateCompatibleBitmap(DC, Right - Left, Bottom - Top);
          MDC  := CreateCompatibleDC(DC);
          LBMP := SelectObject(MDC, MBMP);
          LDC := Wnd.Canvas.DC;
          SetWindowOrgEx(MDC, Left, Top, nil);
          Wnd.Canvas.DC := MDC;
          Event.ID := etDraw;
          Event.Draw.Canvas := Wnd.Canvas;
          Event.Draw.Rect   := Wnd.Canvas.PaintRect;
          Wnd.Perform(Event);
          Wnd.Canvas.DC := LDC;
          BitBlt(DC, Left, Top, Right - Left, Bottom - Top, MDC, Left, Top, SRCCOPY);
          SelectObject(MDC, LBMP);
          DeleteObject(MBMP);
          DeleteDC(MDC);
        end;
        EndPaint(Wnd.Handle, PS);
        Wnd.Canvas.Unlock;
        Exit;
      end;
    {
    WM_MOVE :
      if (SmallInt(lParam) > 0) or (SmallInt(lParam shr 16) > 0) then
        with Wnd.ScreenRect do
        begin
          Left   := SmallInt(lParam);
          Top    := SmallInt(lParam shr 16);
          Right  := Left + Wnd.Size.Width;
          Bottom := Top + Wnd.Size.Height;
//        GetWindowRect(Wnd.Handle, Wnd.ScreenRect);
       end;
    WM_SIZE :
      if wParam <> SIZE_MINIMIZED then
      begin
        GetWindowRect(Wnd.Handle, Wnd.ScreenRect);
        Wnd.Size := SetSize(0, 0, Word(lParam), Word(lParam shr 16));
        Event.ID := etSize;
        Wnd.Perform(Event);
        // if Size <> OldSize then
        Wnd.Repaint(nil);
      end;
    }
    WM_SIZING :
      InvalidateRect(Wnd.Handle, nil, False);
    WM_MOVE :
      GetWindowRect(Wnd.Handle, Wnd.ScreenRect);
    WM_SIZE :
      begin
        GetWindowRect(Wnd.Handle, Wnd.ScreenRect);
        if not Wnd.FMinimized then
        begin
          Wnd.Size := SetSize(0, 0, Word(lParam), Word(lParam shr 16));
          Event.ID := etSize;
          Wnd.Perform(Event);
        end;
      end;

    WM_SETCURSOR :
      begin
        Ctrl := GetCtrlScreen;
        if (Ctrl <> nil) and (Ctrl.Cursor <> ctNone) then
        begin
          SetCursor(Cursors[Ctrl.Cursor].Cursor);
          Result := 1;
          Exit;
        end;
      end;
{
    WM_DROPFILES :
      begin
      // some experiments, not used yet... 8)
        DropCount := DragQueryFileW(wParam, $FFFFFFFF, nil, 0);
        for DropIndex := 0 to DropCount - 1 do
        begin
          DropLen := DragQueryFileW(wParam, DropIndex, @DropName[1], Length(DropName));
          Writeln(Copy(DropName, 1, DropLen));
        end;
        Exit;
      end;
}
    WM_TRAYICON :
      case lParam of
        WM_RBUTTONUP :
          if not Window.Modal then
          begin
            if not Window.FMinimized then
              Window.Fore;
            Window.Modal := True;
            if MessageBoxW(Window.Handle, PWideChar(LangMsg[lmQuestClose]), PWideChar(CLIENT_NAME), MB_YESNO or MB_ICONQUESTION) = IDYES then
              Window.Close
            else
              Window.Modal := False;
          end;

        WM_LBUTTONDOWN :
          begin
            Window.Fore;
            Roster.NextActive;
{
            if not Window.FMinimized then
              if (Length(Info.Contacts) <> 1) or (not Info.Contacts[0].Select) then
              begin
                Roster.UnSelect;
                Roster.NextActive;
              end;
}
          end;
        WM_LBUTTONDBLCLK :
          if not Window.FMinimized then
            Window.Minimize;
      end;

    WM_TIMER :
      case wParam of
        TIMER_MOUSE :
          begin
            p := GetCursorPos;
            GetWindowRect(Wnd.Handle, Rect);
            if RectIntersect(Rect, p.X, p.Y) then
            begin
            // show hint
              if Wnd.Active and (Wnd.HintWnd <> nil) then
                with Wnd.HintWnd do
                  if Target <> nil then
                  begin
                    if Tick > 0 then
                      Dec(Tick);
                    if (Tick = 0) and (not Visible) then
                    begin
                      MPos := GetCursorPos;
                      ScreenToClient(Wnd.Handle, MPos);
                      Tick := -1;
                      Text := Target.Hint;

                      if p.X + 10 + Width < jglobal.Screen.Width then
                        Inc(p.X, 10)
                      else
                        Dec(p.X, 10 + Width);
                      if p.Y + 10 + Height < jglobal.Screen.Height then
                        Inc(p.Y, 10)
                      else
                        Dec(p.Y, 10 + Height);
                      Move(p.X, p.Y, Width, Height);

                      Visible := True;
                    end;
                  end;
            end else
              if GetCapture <> Wnd.Handle then
              begin
                Event.ID := etMouseMove;
                Event.Mouse.Pos.x := -1;
                Event.Mouse.Pos.y := -1;
                Wnd.Perform(Event);
              end;
          end;
        TIMER_EDIT :
          if Wnd.Focus is TEdit then
            with TEdit(Wnd.Focus) do
              if Wnd.Active or CaretState then
              begin
                CaretState := not CaretState;
                Repaint;
              end;
      else
        TTimerProc(wParam)();
      end;
  else
    if (Msg = WM_TASKBARCREATED) and (not Wnd.Popup) then
      AppWindow.UpdateTray(NIM_ADD);
  end;
  Result := Wnd.DefProc(Hwnd, Msg, wParam, lParam);
end;
{$ENDIF}
{$IFDEF LINUX}
procedure WndProc(var Event: TXEvent);
begin
  if Event._type = Expose then
  begin
    //
  end;
end;
{$ENDIF}
{$IFDEF DARWIN}
function WndProc(inHandlerCallRef, inEvent, UserData: Pointer): LongInt; cdecl;
var
  Wnd : TWindow;
  Ctrl : TControl;
  EventKind : LongWord;
  Event : TControlEvent;
  r : Rect;
  k : LongWord;
  d : LongInt;
  p : CGPoint;
  b : EventMouseButton;

  procedure Paint;
  var
    Context : CGContextRef;
  begin
  //  Writeln('paint');
    Wnd.Canvas.Lock;
    SetPortWindowPort(Wnd.Handle);
    QDBeginCGContext(GetWindowPort(Wnd.Handle), Context);
    CGContextSaveGState(Context);
    CGContextTranslateCTM(Context, 0, Wnd.ARect.Bottom - 1);
    CGContextScaleCTM(Context, 1, -1);
    CGContextSetLineWidth(Context, 1);
    CGContextSetAllowsAntiAliasing(Context, 0);
    Wnd.Canvas.SetContext(Context);
    Event.ID := etDraw;
    Event.Draw.Canvas           := Wnd.Canvas;
    Event.Draw.Rect             := Wnd.ARect;
    Event.Draw.Canvas.PaintRect := Wnd.ARect;
    Wnd.Perform(Event);
    CGContextRestoreGState(Context);
    QDEndCGContext(GetWindowPort(Wnd.Handle), Context);
    Wnd.Canvas.Unlock;
  end;

  function RemapKey(const Key: LongWord): Word;
  begin
    case Key of
      $24 : Result := VK_RETURN;
      $30 : Result := VK_TAB;
      $31 : Result := VK_SPACE;
      $33 : Result := VK_BACK;
      $35 : Result := VK_ESCAPE;
      $7B : Result := VK_LEFT;
      $7C : Result := VK_RIGHT;
      $7D : Result := VK_DOWN;
      $7E : Result := VK_UP;
      $72 : Result := VK_INSERT;
      $75 : Result := VK_DELETE;
      $73 : Result := VK_HOME;
      $77 : Result := VK_END;
      $74 : Result := VK_PRIOR;
      $79 : Result := VK_NEXT;
      $3B : Result := VK_CONTROL;
      $3A : Result := VK_MENU;
      $38 : Result := VK_SHIFT;
      $00 : Result := Ord('A');
      $0B : Result := Ord('B');
      $08 : Result := Ord('C');
      $02 : Result := Ord('D');
      $0E : Result := Ord('E');
      $03 : Result := Ord('F');
      $05 : Result := Ord('G');
      $04 : Result := Ord('H');
      $22 : Result := Ord('I');
      $26 : Result := Ord('J');
      $28 : Result := Ord('K');
      $25 : Result := Ord('L');
      $2E : Result := Ord('M');
      $2D : Result := Ord('N');
      $1F : Result := Ord('O');
      $23 : Result := Ord('P');
      $0C : Result := Ord('Q');
      $0F : Result := Ord('R');
      $01 : Result := Ord('S');
      $11 : Result := Ord('T');
      $20 : Result := Ord('U');
      $09 : Result := Ord('V');
      $0D : Result := Ord('W');
      $07 : Result := Ord('X');
      $10 : Result := Ord('Y');
      $06 : Result := Ord('Z');
    else
      Result := 0;
    end;
  end;

begin
  Wnd := TWindow(UserData);

  Result := noErr;
  EventKind := GetEventKind(inEvent);
  case GetEventClass(inEvent) of
    kEventClassWindow :
      case EventKind of
        kEventWindowClosed :
          QuitApplicationEventLoop;
        kEventWindowActivated, kEventWindowDeactivated :
          begin
            Wnd.Active := EventKind = kEventWindowActivated;
          //  Writeln('active: ', Wnd.Active);
            Wnd.Repaint;
          end;
        kEventWindowUpdate :
          begin
          //  Writeln('update');
            BeginUpdate(Wnd.Handle);
            Paint;
            EndUpdate(Wnd.Handle);
          end;
        kEventWindowBoundsChanged :
          begin
          //  Writeln('resize');
            Wnd.ScreenRect := Wnd.GetWndRect;
            GetWindowBounds(Wnd.Handle, kWindowContentRgn, r);
            with r do
              Wnd.Size := SetSize(0, 0, Right - Left, Bottom - Top);
            Event.ID := etSize;
            Wnd.Perform(Event);
            Wnd.Repaint;
          end;
      end;
  // keyboard
    kEventClassKeyboard :
      with Event, Key do
      begin
        Shift := [];
        GetEventParameter(inEvent, kEventParamKeyCode, typeUInt32, nil, SizeOf(k), nil, @k);
        Value := RemapKey(k);
        case EventKind of
          kEventRawKeyDown : ID := etKeyDown;
          kEventRawKeyUp   : ID := etKeyUp;
        end;
        Wnd.Focus.Perform(Event);
        if ID = etKeyDown then
        begin
          GetEventParameter(inEvent, kEventParamKeyUnicodes, typeUnicodeText, 0, SizeOf(Value), 0, @Value);
          ID := etChar;
          Wnd.Focus.Perform(Event);
        end;
      end;
  // mouse
    kEventClassMouse :
      with Event, Mouse do
      begin
        GetEventParameter(inEvent, kEventParamMouseLocation, typeHIPoint, nil, SizeOf(p), nil, @p);
        GetWindowBounds(Wnd.Handle, kWindowContentRgn, r);
        //kEventParamKeyModifiers
        Button := mbLeft;
        BState := [];
        Shift  := [];
        Pos.x := Round(p.x) - r.Left;
        Pos.y := Round(p.y) - r.Top;
        Pos.w := 0;

        if (EventKind = kEventMouseDown) or (EventKind = kEventMouseUp) then
        begin
          GetEventParameter(inEvent, kEventParamMouseButton, typeMouseButton, nil, SizeOf(b), nil, @b);
          case b of
            1 : Button := mbLeft;
            2 : Button := mbRight;
            3 : Button := mbMiddle;
          end;
        end;

        case EventKind of
          kEventMouseDown       : ID := etMouseDown;
          kEventMouseUp         : ID := etMouseUp;
          kEventMouseMoved      : ID := etMouseMove;
          kEventMouseWheelMoved :
            begin
              ID := etMouseWheel;
              GetEventParameter(inEvent, kEventParamMouseWheelDelta, typeLongInteger, nil, SizeOf(d), nil, @d);
              Mouse.Pos.w := d;
            end;
        end;

        Ctrl := Wnd.GetCtrl(Pos.x, Pos.y);
        if (ID = etMouseDown) and (not Wnd.Focus.HoldFocus) then
          Wnd.Focus := Ctrl;
        if (ID = etMouseDown) and (BState - [Button] = []) then
          Wnd.SetMouseFocus(Ctrl);

        Wnd.Perform(Event);

        if ID = etMouseUp then
        begin
          if (Button = mbLeft) and (Ctrl <> nil) and (Ctrl = Wnd.FMouseFocus) then
          begin
            ID := etClick;
            Ctrl.Perform(Event);
          end;
          if BState = [] then
            Wnd.SetMouseFocus(nil);
        end;
        Result := eventNotHandledErr;
      end;
  end;
end;
{$ENDIF}
{$ENDREGION}

{$REGION 'TControl'}
{ TControl }
constructor TControl.Create(Parent: TControl);
begin
  FVisible := True;
  if Parent <> nil then
    Parent.AddCtrl(Self);
  FMouseFocus := nil;
  Cursor := ctArrow;
  EventProc := nil;
end;

destructor TControl.Destroy;
begin
  while Length(Controls) > 0 do
    DelCtrl(Controls[0]);
  inherited;
end;

function TControl.CalcASize(const RSize: TSize): TSize;

  function ClampValue(Value, Clamp: SmallInt): SmallInt;
  begin
    if Value >= 0 then
      Result := Value
    else
      Result := Clamp + Value;
  end;

begin
  if FParent = nil then
  begin
    Result.Left   := RSize.Left;
    Result.Top    := RSize.Top;
    Result.Width  := RSize.Width;
    Result.Height := RSize.Height;
  end else
  begin
    Result.Left   := ClampValue(RSize.Left,   FParent.Width);
    Result.Top    := ClampValue(RSize.Top,    FParent.Height);
    Result.Width  := ClampValue(RSize.Width,  FParent.Width + 1);
    Result.Height := ClampValue(RSize.Height, FParent.Height + 1);
  end;
end;

procedure TControl.SetVisible(const Value: Boolean);
begin
  if FVisible <> Value then
  begin
    FVisible := Value;
    UpdateRect;
    if FParent <> nil then
      FParent.Repaint;
  end;
end;

procedure TControl.SetText(const Value: WideString);
var
  Event : TControlEvent;
begin
  FText := Value;
  Event.ID := etChange;
  Perform(Event);
  Repaint;
end;

procedure TControl.SetFont(const Value: TFont);
begin
  FFont := Value;
end;

procedure TControl.SetMouseFocus(const Value: TControl);
var
  i : LongInt;
begin
  FMouseFocus := Value;
  for i := 0 to Length(Controls) - 1 do
    Controls[i].SetMouseFocus(Value);
end;

function TControl.GetMouseFocus: Boolean;
begin
  Result := (FMouseFocus = nil) or (FMouseFocus = Self);
end;

function TControl.GetCtrl(X, Y: LongInt): TControl;
var
  i : LongInt;
begin
  Result := Self;
  for i := Length(Controls) - 1 downto 0 do
    with Controls[i] do
      if Visible then
        if RectIntersect(ARect, X, Y) then
        begin
          Result := Self.Controls[i].GetCtrl(X, Y);
          break;
        end;
end;

procedure TControl.UpdateRect;
begin
  ASize := CalcASize(Size);

  ARect.Left   := Left;
  ARect.Top    := Top;
  ARect.Right  := Left + Width;
  ARect.Bottom := Top + Height;

  if FParent <> nil then
    with FParent.Rect do
    begin
      ARect.Left   := ARect.Left + Left;
      ARect.Top    := ARect.Top + Top;
      ARect.Right  := ARect.Right + Left;
      ARect.Bottom := ARect.Bottom + Top;
    end;
end;

procedure TControl.Resize;
var
  Event : TControlEvent;
  r : TRect;
begin
  // Repaint(@ARect);
  Event.ID := etSize;
  r := ARect;
  Perform(Event);
  r := RectMerge(r, ARect);
  Repaint(@r);
end;
{
procedure TControl.Resize;
var
  Event : TControlEvent;
begin
  Event.ID := etSize;
  Perform(Event);
  Repaint(@ARect);
end;
}
procedure TControl.BeginUpdate;
begin
  FUpdate := True;
end;

procedure TControl.EndUpdate;
begin
  FUpdate := False;
  Repaint;
end;

function TControl.Perform(const Event: TControlEvent): Boolean;
var
  i : LongInt;
  Flag : Boolean;
begin
  Result := False;

  Flag := True;
  case Event.ID of
    etSize :
      UpdateRect;
    etDraw :
      if not RectIntersect(ARect, Event.Draw.Canvas.PaintRect) then
        Exit;
    etMouseWheel :
      if FMouseFocus <> nil then
      begin
        if FMouseFocus <> Self then
          Flag := False;
      end else
        if not RectIntersect(ARect, Event.Mouse.Pos.x, Event.Mouse.Pos.y) then
          Flag := False;
    etMouseDown, etMouseUp, etMouseMove :
      Flag := MouseFocus;
  end;

  if Flag then
  begin
    Result := True;
    if @EventProc <> nil then
      if EventProc(Self, Event) then
        Exit;
    if OnEvent(Event) then
      Exit;
    Result := False;
  end;

  if Event.ID in [etChar, etKeyDown, etKeyUp, etFocus, etFold, etChange, etClick] then
  begin
    Result := True;
    Exit;
  end;

  for i := 0 to Length(Controls) - 1 do
    if Controls[i].Visible then
    begin
      Result := Controls[i].Perform(Event);
      if Result then
        Exit;
    end;
end;

function TControl.OnEvent(const Event: TControlEvent): Boolean;
begin
  Result := False;
end;

procedure TControl.Move(Left, Top, Width, Height: LongInt);
begin
  Size := SetSize(Left, Top, Width, Height);
  Resize;
end;

function TControl.AddCtrl(const Ctrl: TControl): TControl;
begin
  Result := Ctrl;
  SetLength(Controls, Length(Controls) + 1);
  Controls[Length(Controls) - 1] := Ctrl;
  Ctrl.FParent := Self;
  Ctrl.UpdateRect;
end;

function TControl.DelCtrl(const Ctrl: TControl): Boolean;
var
  i, j : LongInt;
begin
  for i := 0 to Length(Controls) - 1 do
    if Controls[i] = Ctrl then
    begin
      Controls[i].Free;
      for j := i to Length(Controls) - 2 do
        Controls[j] := Controls[j + 1];
      SetLength(Controls, Length(Controls) - 1);
      Result := True;
      Exit;
    end;
  Result := False;
end;

procedure TControl.Repaint(Rect: PRect; Force: Boolean);
{$IFDEF DARWIN}
var
  r : MacOSAll.Rect;
{$ENDIF}
begin
  if not Visible then
    Exit;
  if Rect = nil then
    Rect := @ARect;
  if Self is TWindow then
  begin
  {$IFDEF WIN32}
    InvalidateRect(TWindow(Self).Handle, Rect, False);
    if Force then
      UpdateWindow(TWindow(Self).Handle);
  {$ENDIF}
  {$IFDEF DARWIN}
    r.Left   := Rect^.Left;
    r.Top    := Rect^.Top;
    r.Right  := Rect^.Right;
    r.Bottom := Rect^.Bottom;
    InvalWindowRect(TWindow(Self).Handle, r);
  {$ENDIF}
  end else
    FParent.Repaint(Rect, Force);
end;
{$ENDREGION}

{$REGION 'TFrame'}
constructor TFrame.Create(Parent: TControl);
begin
  inherited;
  Color  := COLOR_0;
  Border := COLOR_5;
end;

function TFrame.Perform(const Event: TControlEvent): Boolean;
begin
  if (Event.ID = etDraw) and Clip then Event.Draw.Canvas.ClipInit(ARect);
  Result := inherited Perform(Event);
  if (Event.ID = etDraw) and Clip then Event.Draw.Canvas.ClipFree;
end;

function TFrame.OnEvent(const Event: TControlEvent): Boolean;
begin
  case Event.ID of
    etDraw :
      with Event.Draw do
      begin
      // background
        if Color <> 0 then
        begin
          Canvas.BrushColor := Color;
          Canvas.FillRect(ARect);
        end;
      // border
        if Border <> 0 then
        begin
          Canvas.PenColor   := Border;
          Canvas.FrameRect(ARect);
        end;
      end;
  end;
  Result := inherited OnEvent(Event);
end;
{$ENDREGION}

{$REGION 'TWindow'}
{ TWindow }
constructor TWindow.Create(ParentWindow: TWindow; Popup, App: Boolean);
{$IFDEF WIN32}
const
  WndClass : array [Boolean] of PWideChar = ('STATIC', 'EDIT');
var
  Style, StyleEx : LongWord;
  PHandle : LongWord;
{$ENDIF}
{$IFDEF DARWIN}
const
  Events : array [0..10, 0..1] of LongWord = (
    (kEventClassWindow, kEventWindowUpdate),
    (kEventClassWindow, kEventWindowBoundsChanged),
    (kEventClassWindow, kEventWindowClosed),
    (kEventClassWindow, kEventWindowActivated),
    (kEventClassWindow, kEventWindowDeactivated),
    (kEventClassKeyboard, kEventRawKeyDown),
    (kEventClassKeyboard, kEventRawKeyUp),
    (kEventClassMouse, kEventMouseDown),
    (kEventClassMouse, kEventMouseUp),
    (kEventClassMouse, kEventMouseMoved),
    (kEventClassMouse, kEventMouseWheelMoved)
  );
var
  Size : MacOSAll.Rect;
{$ENDIF}
begin
  inherited Create(nil);
  Self.Popup := Popup;
  FVisible := False;
  MinSize := SetSize(0, 0, 32, 32);

{$IFDEF WIN32}
  Style   := WS_POPUP;
  StyleEx := 0;

  if not Popup then
  begin
    if App then
      StyleEx := WS_EX_APPWINDOW
    else
      Style := WS_THICKFRAME or WS_CAPTION or WS_SYSMENU;// or WS_MINIMIZEBOX;
  end else
    StyleEx := WS_EX_TOOLWINDOW or WS_EX_TOPMOST;

  if ParentWindow <> nil then
    PHandle := ParentWindow.Handle
  else
    PHandle := 0;

  Handle := CreateWindowExW(StyleEx, WndClass[Popup], nil, Style, 0, 0, 0, 0, PHandle, 0, HInstance, nil);
  SetWindowLongW(Handle, GWL_USERDATA, LongInt(Self));
  SetWindowLongW(Handle, GWL_WNDPROC, LongInt(@WndProc));
  DefProc := @DefWindowProcW;
{$ENDIF}
{$IFDEF DARWIN}
  Size.Left   := 100;
  Size.Top    := 100;
  Size.Right  := 320;
  Size.Bottom := 240;
  CreateNewWindow(kDocumentWindowClass,
    kWindowCloseBoxAttribute or
    kWindowResizableAttribute or
    kWindowStandardHandlerAttribute or
    kWindowLiveResizeAttribute, Size, Handle);
  InstallEventHandler(GetWindowEventTarget(Handle), NewEventHandlerUPP(@WndProc), Length(Events), @Events, Self, nil);
{$ENDIF}

  if App then
    Popup := True;
{$IFDEF WIN32}
  SetTimer(Handle, TIMER_MOUSE, 100, nil);
  SetTimer(Handle, TIMER_EDIT, 500, nil);
{$ENDIF}
  FCanvas := TCanvas.Create(LongWord(Handle));
  FFocus := Self;

  FBorderColor := BORDER_DEFAULT;

  if not Popup then
  begin
  // frame
    Frame := TFrame.Create(Self);
    Frame.Color := COLOR_0;
    Frame.Move(0, 0, -1, -1);
  // hint
    HintWnd := THint.Create(Self);
    HintWnd.Size := SetSize(0, 0, 0, 20);
  end;
end;

destructor TWindow.Destroy;
begin
  if HintWnd <> nil then
    HintWnd.Free;
  Canvas.Free;
{$IFDEF WIN32}
  DestroyWindow(Handle);
{$ENDIF}
{$IFDEF DARWIN}
  ReleaseWindow(Handle);
{$ENDIF}
  inherited;
end;

function TWindow.GetWndRect: TRect;
{$IFDEF WIN32}
begin
  GetWindowRect(Handle, Result);
{$ENDIF}
{$IFDEF DARWIN}
var
  r : MacOSAll.Rect;
begin
  GetWindowBounds(Handle, kWindowStructureRgn, r);
  Result.Left   := r.Left;
  Result.Top    := r.Top;
  Result.Right  := r.Right;
  Result.Bottom := r.Bottom;
{$ENDIF}
end;

procedure TWindow.SetVisible(const Value: Boolean);
{$IFDEF WIN32}
var
  Flag : LongWord;
{$ENDIF}
begin
  if Value = FVisible then
    Exit;
  inherited;
{$IFDEF WIN32}
  Flag := SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE;
  if FVisible then
    SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_SHOWWINDOW or Flag)
  else
    SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_HIDEWINDOW or Flag);
{$ENDIF}
{$IFDEF DARWIN}
//  SelectWindow(Handle);
  ShowHide(Handle, FVisible);
{$ENDIF}
end;

procedure TWindow.SetText(const Value: WideString);

  procedure SetWindowText;
  {$IFDEF WIN32}
  begin
    SetWindowTextW(Handle, PWideChar(Value));
  {$ENDIF}
  {$IFDEF DARWIN}
  var
    StrRef : CFStringRef;
  begin
    StrRef := CFStringCreateWithCharacters(nil, @Value[1], Length(Value));
    SetWindowTitleWithCFString(Handle, StrRef);
    CFRelease(StrRef);
  {$ENDIF}
  end;

begin
  inherited;
  if Self = AppWindow then
  begin
    SetWindowText;
  {$IFDEF WIN32}
    AppWindow.UpdateTray(NIM_MODIFY);
  {$ENDIF}
  end else
    if not Popup then
    begin
      AppWindow.Text := Value;
      SetWindowText;
    end;
end;

procedure TWindow.SetFocus(const Value: TControl);
var
  e : TControlEvent;
begin
  if Value = Focus then
    Exit;
  e.ID := etFocus;
  e.Focus := False;
  if Focus <> nil then
    Focus.Perform(e);
  e.Focus := True;
  Value.Perform(e);
  FFocus := Value;
end;

procedure TWindow.SetFolded(const Value: Boolean);
var
  Event : TControlEvent;
  WSize : TSize;
  WRect : TRect;
begin
  if FFolded <> Value then
  begin
    FFolded := Value;
    if not Popup then
    begin
      AppWindow.Visible := not Value;
      AppWindow.Repaint(nil);
    {$IFDEF WIN32}
      SetWindowPos(Handle, LongWord(-1 - Ord(Value = False)), 0, 0, 0, 0, SWP_NOSIZE or SWP_NOMOVE or SWP_NOREDRAW);
    {$ENDIF}
    end;
    WRect := GetWndRect;
    with WRect do
      WSize := SetSize(Left, Top, Right - Left, Bottom - Top);
    Event.ID := etFold;
    Event.Fold.Fold := Value;
    Event.Fold.Size := @WSize;
    Perform(Event);
    with WSize do
      Move(Left, Top, Width, Height);
  end;
end;

procedure TWindow.SetActive(const Value: Boolean);
begin
  FActive := Value;
end;

procedure TWindow.SetBorderColor(const Value: TColor);
begin
  FBorderColor := Value;
//  Repaint;
end;

procedure TWindow.Move(SLeft, STop, SWidth, SHeight: LongInt);
{$IFDEF WIN32}
var
  WRect : TRect;
begin
  SetWindowPos(Handle, 0, SLeft, STop, SWidth, SHeight, SWP_NOZORDER or SWP_NOACTIVATE);
  GetWindowRect(Handle, ScreenRect);
  GetClientRect(Handle, WRect);
{$ENDIF}
{$IFDEF DARWIN}
var
  r : MacOSAll.Rect;
  WRect : TRect;
begin
  r.Left   := SLeft;
  r.Top    := STop;
  r.Right  := SLeft + SWidth;
  r.Bottom := STop + SHeight;
  SetWindowBounds(Handle, kWindowStructureRgn, r);
  ScreenRect.Left   := r.Left;
  ScreenRect.Top    := r.Top;
  ScreenRect.Right  := r.Right;
  ScreenRect.Bottom := r.Bottom;
  GetWindowBounds(Handle, kWindowContentRgn, r);
  WRect.Left   := 0;
  WRect.Top    := 0;
  WRect.Right  := r.Right - r.Left;
  WRect.Bottom := r.Bottom - r.Top;
{$ENDIF}
  with WRect do
    inherited Move(Left, Top, Right - Left, Bottom - Top);
end;

procedure TWindow.Fore;
begin
  if Self.FMinimized then
    Self.Minimize;
  if not Visible then
    Visible := True;
{$IFDEF WIN32}
  jsys.SetFocus(Handle);
  jsys.SetForegroundWindow(Handle);
{$ENDIF}
end;


procedure TWindow.Close;
begin
{$IFDEF WIN32}
//  PostQuitMessage(0);
  PostMessageW(AppWindow.Handle, $12, 0, 0);
{$ENDIF}
{$IFDEF DARWIN}
  QuitApplicationEventLoop;
{$ENDIF}
end;

procedure TWindow.Minimize;
{$IFDEF WIN32}
var
  r1, r2 : TRect;
  p, c : LongWord;
begin
  GetWindowRect(Handle, r1);

  FActive := False;
  p := FindWindowW('Shell_TrayWnd', nil);
  c := FindWindowExW(p, 0, 'TrayNotifyWnd', nil);
  GetWindowRect(c, r2);

  if FVisible then
    DrawAnimatedRects(Handle, IDANI_CAPTION, r1, r2)
  else
    DrawAnimatedRects(Handle, IDANI_CAPTION, r2, r1);
  Visible := not Visible;
  AppWindow.Visible := Visible and (not Folded);
{$ENDIF}
{$IFDEF DARWIN}
begin
{$ENDIF}
  FMinimized := not FMinimized;
{
  if not FMinimized then
    if AppWindow.Flashing then
    begin
      FActive := True;
      AppWindow.Flashing := False;
      Roster.GetSelected;
    end;
}
  FlushMemory;
end;

function TWindow.IsFore: Boolean;
begin
{$IFDEF WIN32}
  Result := Handle = GetForegroundWindow;
{$ENDIF}
{$IFDEF DARWIN}
  Result := Active;
{$ENDIF}
end;

procedure TWindow.SetShadow(const Value: Boolean);
begin
{$IFDEF WIN32}
  SetClassLongW(Handle, GCL_STYLE, CS_DROPSHADOW * Ord(Value));
{$ENDIF}
end;

procedure TWindow.SetResizing(const Value: Boolean);
var
  Style : LongInt;
begin
{$IFDEF WIN32}
  Style := GetWindowLongW(Handle, GWL_STYLE);
  if Value then
    Style := Style or WS_THICKFRAME
  else
    Style := Style and (not WS_THICKFRAME);
  SetWindowLongW(Handle, GWL_STYLE, Style);
{$ENDIF}
{$IFDEF DARWIN}
  Style := kWindowResizableAttribute or kWindowLiveResizeAttribute;
  if Value then
    ChangeWindowAttributes(Handle, Style, 0)
  else
    ChangeWindowAttributes(Handle, 0, Style);
{$ENDIF}
end;

procedure TWindow.SetMinSize(const Value: TSize);
{$IFDEF DARWIN}
var
  r : CGRect;
{$ENDIF}
begin
  FMinSize := Value;
{$IFDEF DARWIN}
  r := CGRectMake(SetRect(0, 0, Value.Width, Value.Height), False);
  SetWindowResizeLimits(Handle, @r, nil); // WTF?
{$ENDIF}
end;
{$ENDREGION}

{$REGION 'TAppWindow'}
procedure AppBlink;
var
  TmpIcon : TIcon;
begin
{$IFDEF WIN32}
  with AppWindow do
  begin
  // flashing
    if Flashing then
      Flash(Window.BorderColor = BORDER_DEFAULT);
  // tray icon blinking
    if TrayBlink then
    begin
      if Blink then
      begin
        TmpIcon := FTrayIcon;
        FTrayIcon := nil;
        UpdateTray(NIM_MODIFY);
        FTrayIcon := TmpIcon;
      end else
        UpdateTray(NIM_MODIFY);
      Blink := not Blink;
    end;
  end;
{$ENDIF}
end;

constructor TAppWindow.Create;
begin
  AppWindow := Self;
  inherited Create(nil, False, True);
{$IFDEF WIN32}
  UpdateTray(NIM_ADD);
  TimerBlink := InitTimer(500, TTimerProc(@AppBlink));
{$ENDIF}
end;

destructor TAppWindow.Destroy;
begin
{$IFDEF WIN32}
  FreeTimer(TimerBlink);
  UpdateTray(NIM_DELETE);
{$ENDIF}
  inherited;
end;

procedure TAppWindow.SetIcon(const Value: TIcon);
begin
  if FIcon = Value then
    Exit;
  FIcon := Value;
  FTrayIcon := Value.Small;
{$IFDEF WIN32}
  if Value <> nil then
  begin
    SendMessageW(Handle, WM_SETICON, 1, Value.Icon);
    SendMessageW(Handle, WM_SETICON, 0, Value.Small.Icon);
    SendMessageW(Window.Handle, WM_SETICON, 1, Value.Icon);
    SendMessageW(Window.Handle, WM_SETICON, 0, Value.Small.Icon);
  end else
  begin
    SendMessageW(Handle, WM_SETICON, 1, 0);
    SendMessageW(Handle, WM_SETICON, 0, 0);
    SendMessageW(Window.Handle, WM_SETICON, 1, 0);
    SendMessageW(Window.Handle, WM_SETICON, 0, 0);
  end;
  UpdateTray(NIM_MODIFY);
{$ENDIF}
end;

procedure TAppWindow.SetTrayIcon(const Value: TIcon);
begin
  if FTrayIcon = Value then
    Exit;
  FTrayIcon := Value;
{$IFDEF WIN32}
  UpdateTray(NIM_MODIFY);
{$ENDIF}
end;

procedure TAppWindow.SetTrayBlink(const Value: Boolean);
begin
  if Value <> FTrayBlink then
  begin
    FTrayBlink := Value;
    Blink := False;
  {$IFDEF WIN32}
    UpdateTray(NIM_MODIFY);
  {$ENDIF}
  end;
end;

procedure TAppWindow.SetFlashing(const Value: Boolean);
{$IFDEF WIN32}
var
  FlashInfo : TFlashInfo;
{$ENDIF}
begin
  if FFlashing <> Value then
  begin
    FFlashing := Value;
  {$IFDEF WIN32}
    Flash(FFlashing);

    FlashInfo.cbSize  := SizeOf(FlashInfo);
    FlashInfo.hwnd    := Handle;
    if FFlashing then
      FlashInfo.dwFlags := FLASHW_ALL or FLASHW_TIMERNOFG
    else
      FlashInfo.dwFlags := FLASHW_STOP;
    FlashInfo.uCount    := 999999;
    FlashInfo.dwTimeout := 500;
    FlashWindowEx(FlashInfo);
  {$ENDIF}
  end;
end;

procedure TAppWindow.Flash(Value: Boolean);
begin
  if Value then
    Window.BorderColor := BORDER_ACTIVE
  else
    Window.BorderColor := BORDER_DEFAULT;
end;

procedure TAppWindow.UpdateTray(Flag: LongWord);
{$IFDEF WIN32}
var
  TrayIconData : TNotifyIconDataW;
begin
  FillChar(TrayIconData, SizeOf(TrayIconData), 0);
  TrayIconData.cbSize := SizeOf(TrayIconData);
  TrayIconData.Wnd    := Handle;
  TrayIconData.uFlags := NIF_MESSAGE or NIF_ICON or NIF_TIP;
  TrayIconData.uCallbackMessage := WM_TRAYICON;
  if FText <> '' then
  begin
    System.Move(FText[1], TrayIconData.szTip, Length(FText) * SizeOf(WideChar));
    TrayIconData.szTip[Length(FText)] := #0;
  end;
  if TrayIcon <> nil then
    TrayIconData.hIcon := TrayIcon.Icon;
  Shell_NotifyIconW(Flag, @TrayIconData);
end;
{$ENDIF}
{$IFDEF DARWIN}
begin
end;
{$ENDIF}
{$ENDREGION}

{$REGION 'TPopupMenu'}
constructor TPopupMenu.Create(ParentWindow: TWindow);
begin
  inherited Create(ParentWindow, True);
  Shadow := True;
  Cursor := ctArrow;
end;

procedure TPopupMenu.SetVisible(const Value: Boolean);
var
  p : TPoint;
begin
  if Value then
  begin
    UpdateScreen;
    p := GetCursorPos;
    if p.X + Width > Screen.Left + Screen.Width then p.X := p.X - Width;
    if p.Y + Height > Screen.Top + Screen.Height then p.Y := p.Y - Height;
    Move(p.X, p.Y, Width, Height);
  // global govnocode
    if (Window.HintWnd <> nil) then
    begin
      if Window.HintWnd.Visible then
        Window.HintWnd.Visible := False;
      Window.HintWnd := nil;
    end;
  end else
  begin
    Window.HintWnd := jglobal.Hint;
    Window.Focus := Edit;
  end;
  inherited;
end;

procedure TPopupMenu.SetActive(const Value: Boolean);
begin
  inherited;
  if not Value then
    Visible := False;
end;
{$ENDREGION}

{$REGION 'TButton'}
{ TButton }
constructor TButton.Create(Parent: TControl; Image: TImage; ImageIdx, ImageCom: LongInt);
begin
  inherited Create(Parent);
  Self.Image  := Image;
  FImageIdx   := ImageIdx;
  FImageCom   := ImageCom;
  Self.Cursor := ctHand;
  MinAlpha := 160;
  FAlpha := MinAlpha;
  Font := Font_Tahoma_11;
end;

procedure TButton.SetAlpha(const Value: Byte);
begin
  if FAlpha <> Value then
  begin
    FAlpha := Value;
    Repaint;
  end;
end;

procedure TButton.SetImageIdx(const Value: LongInt);
begin
  if FImageIdx <> Value then
  begin
    FImageIdx := Value;
    Repaint;
  end;
end;

procedure TButton.SetImageCom(const Value: LongInt);
begin
  if FImageCom <> Value then
  begin
    FImageCom := Value;
    Repaint;
  end;
end;

function TButton.OnEvent(const Event: TControlEvent): Boolean;
var
  w  : LongInt;
begin
  case Event.ID of
    etMouseMove :
      if RectIntersect(ARect, Event.Mouse.Pos.x, Event.Mouse.Pos.y) or Active then
        Alpha := 255
      else
        Alpha := MinAlpha;
    etDraw :
      with Event.Draw do
        if (Image = nil) or (ImageIdx = -1) then
        begin
          with ARect do
          begin
            Canvas.PenColor := BUTTON_BORDER;
            Canvas.FrameRect(SetRect(Left + 1, Top, Right - 1, Bottom));
            Canvas.FrameRect(SetRect(Left, Top + 1, Right, Bottom - 1));
            if Alpha = 255 then
              Canvas.PenColor := BUTTON_HOVER
            else
              Canvas.PenColor := BUTTON_WINDOW;
            Canvas.FrameRect(SetRect(Left + 2, Top, Right - 2, Bottom));
            Canvas.FrameRect(SetRect(Left, Top + 2, Right, Bottom - 2));
            Canvas.BrushColor := Canvas.PenColor;
            Canvas.FillRect(SetRect(Left + 1, Top + 1, Right - 1, Bottom - 1));
          end;

          Canvas.TextColor := COLOR_0;
          Canvas.Font := Font;
          w := Canvas.TextWidth(PWideChar(Text), Length(Text));
          Canvas.TextOut(ARect.Left + (Width - w) div 2, ARect.Top + (Height - 16) div 2 + 1, Text);
        end else
        begin
          Image.DrawFrame(Canvas, ARect.Left, ARect.Top, ImageIdx, 16, Alpha);
          if ImageCom > -1 then
            Image.DrawFrame(Canvas, ARect.Left, ARect.Top, ImageCom, 16, Alpha);
        end;
  end;
  Result := inherited OnEvent(Event);
end;
{$ENDREGION}

{$REGION 'TLabel'}
function TLabel.OnEvent(const Event: TControlEvent): Boolean;
var
  i, cx : LongInt;
  Lines : TStringPartArray;
begin
  Result := inherited OnEvent(Event);
  if Event.ID = etDraw then
    with Event.Draw do
    begin
      Canvas.ClipInit(ARect);
      Canvas.Font := Font;
      if not WordWrap then
      begin
        SetLength(Lines, 1);
        Lines[0].Start  := 0;
        Lines[0].Length := Length(FText);
      end else
        Canvas.TextWrap(PWideChar(Text), Length(Text), 0, ARect.Right - ARect.Left, Lines);

      i := Length(Lines);
      if (LineCount > 0) and (Length(Lines) > LineCount) then
      begin
        Lines[LineCount - 1] := Lines[LineCount - 1];// + '...';
        i := LineCount;
      end;

      Canvas.TextColor := Color;
      for i := 0 to i - 1 do
      begin
        if Center then
          cx := (Width - Canvas.TextWidth(@FText[Lines[i].Start + 1], Lines[i].Length)) div 2
        else
          cx := 0;
        Canvas.TextOut(ARect.Left + cx, ARect.Top + i * LineHeight, @FText[Lines[i].Start + 1], Lines[i].Length);
      end;
      Canvas.ClipFree;
    end;
end;
{$ENDREGION}

{$REGION 'THint'}
constructor THint.Create(ParentWindow: TWindow; Clear: Boolean);
const
  HINT_IDLE = 5;
begin
  inherited Create(ParentWindow, True);
  Shadow := True;
  if not Clear then
  begin
    Frame := TFrame.Create(Self);
    Frame.Move(0, 0, -1, -1);
    Frame.Border := $BEAA96;
    Frame.Color  := COLOR_0;
    LFrame := TLabel.Create(Frame);
    LFrame.Move(4, 3, -5, -4);
    LFrame.Font  := Font_Tahoma_11;
    LFrame.Color := $7D582C;
    LFrame.LineHeight := 16;
    LFrame.LineCount  := 20;
    LFrame.WordWrap   := True;
  end;
  Idle   := HINT_IDLE;
  Tick   := Idle;
  Cursor := ctArrow;
end;

procedure THint.SetText(const Value: WideString);
var
  Lines : TStringPartArray;
begin
  inherited;
  if LFrame <> nil then
  begin
    DCanvas.Lock;
    DCanvas.Font := LFrame.Font;
    DCanvas.TextWrap(PWideChar(FText), Length(FText), 0, 480, Lines);
    DCanvas.Unlock;

    if Length(Lines) > 0 then
    begin
      ASize.Width  := Lines[0].Right + 8;
      ASize.Height := Length(Lines) * LFrame.LineHeight + 4;
      ARect.Right  := ARect.Left + ASize.Width;
      ARect.Bottom := ARect.Top + ASize.Height;
    end;
    LFrame.Text := FText;
//    DCanvas.TextWrap(PWideChar(FText), Length(FText), 0, 640, Lines);
//    ASize.Width  := DCanvas.TextWidth(PWideChar(FText), Length(FText)) + 8;
//    ASize.Height := 20;

  end;
end;

procedure THint.SetVisible(const Value: Boolean);
begin
  inherited;
{
  if Value then
    jsys.SetFocus(Handle)
  else
    jsys.SetFocus(Window.Handle);
}
end;

function THint.OnEvent(const Event: TControlEvent): Boolean;
begin
  Result := inherited OnEvent(Event);
  if Visible then
    case Event.ID of
      etChar..etKeyUp :
        Visible := False;
      etMouseWheel..etMouseMove :
        with Event.Mouse.Pos do
          if (x > -1) and (y <> -1) then
            Visible := False;
    end;
end;
{$ENDREGION}

{$REGION 'TProgress'}
procedure TProgress.SetProgress(const Value: LongInt);
begin
  FProgress := Value;
  if FProgress < 0 then FProgress := 0;
  if FProgress > 100 then FProgress := 100;
  Repaint;
end;

function TProgress.OnEvent(const Event: TControlEvent): Boolean;
var
  HRect : TRect;
begin
  Result := inherited OnEvent(Event);
  if Event.ID = etDraw then
    with Event.Draw do
    begin
      with ARect do
        HRect := SetRect(Left, Top, Left + (Right - Left) * Progress div 100, Bottom);
      Canvas.ClipInit(ARect);
      Canvas.BrushColor := COLOR_0;
      Canvas.FillRect(ARect);
      Canvas.PenColor := $CCCCCC;
      Canvas.FrameRect(ARect);
      Canvas.BrushColor := $93785C;
      Canvas.FillRect(HRect);
      Canvas.PenColor := $8E6336;
      Canvas.FrameRect(HRect);
      Canvas.ClipFree;
    end;
end;
{$ENDREGION}

{$REGION 'TPicture'}
destructor TPicture.Destroy;
begin
  if Image <> nil then
    Image.Free;
  inherited;
end;

function TPicture.OnEvent(const Event: TControlEvent): Boolean;
var
  HRect : TRect;
begin
  Result := inherited OnEvent(Event);
  if (Event.ID = etDraw) and (Image <> nil) then
    with Event.Draw do
    begin
      HRect.Left   := ARect.Left + (Width - Image.Width) div 2 - 1;
      HRect.Top    := ARect.Top + (Height - Image.Height) div 2 - 1;
      HRect.Right  := HRect.Left + Image.Width + 2;
      HRect.Bottom := HRect.Top + Image.Height + 2;
      Image.Draw(Canvas, ARect.Left, ARect.Top, Width, Height);
      Canvas.PenColor := COLOR_6;
      Canvas.FrameRect(HRect);
    end;
end;
{$ENDREGION}

{$REGION 'TCheck'}
constructor TCheck.Create(Parent: TControl);
begin
  inherited;
  Font := Font_Tahoma_11;
  Cursor := ctHand;
end;

procedure TCheck.SetText(const Value: WideString);
var
  w : LongInt;
begin
  inherited;
  DCanvas.Lock;
  DCanvas.Font := Font;
  w := DCanvas.TextWidth(PWideChar(Value), Length(Value));
  DCanvas.Unlock;
  Move(Size.Left, Size.Top, 24 + w, 16);
end;

procedure TCheck.SetOver(const Value: Boolean);
begin
  if FOver <> Value then
  begin
    FOver := Value;
    Repaint;
  end;
end;

procedure TCheck.SetChecked(const Value: Boolean);
begin
  if FChecked <> Value then
  begin
    FChecked := Value;
    Repaint;
  end;
end;

function TCheck.OnEvent(const Event: TControlEvent): Boolean;
var
  idx : LongInt;
  IRect, HRect : TRect;
begin
  case Event.ID of
    etMouseMove, etMouseUp :
      with Event.Mouse do
      begin
        Over := RectIntersect(ARect, Pos.x, Pos.y);
        if (Event.ID = etMouseUp) and FOver then
          Checked := not Checked;
      end;
    etDraw :
      with Event.Draw do
      begin
        idx := 12;
        if FChecked then
          Inc(Idx);
        if FOver then
          Inc(idx, 2);
        IRect := SetRect(idx * 16, 0, (idx + 1) * 16, 16);
        with ARect do
          HRect := SetRect(Left, Top, Left + 16, Top + 16);
        ImgBase.Draw(Canvas, IRect, HRect);
        Canvas.Font      := Font;
        Canvas.TextColor := $7A582B;
        Canvas.TextOut(ARect.Left + 24, ARect.Top + 2, FText);
      end;
  end;
  Result := inherited OnEvent(Event);
end;
{$ENDREGION}

{$REGION 'TScroll'}
constructor TScroll.Create(Parent: TControl);
begin
  inherited;
  Cursor := ctHand;
end;

function TScroll.OnEvent(const Event: TControlEvent): Boolean;
const
  SCROLL_HEIGHT = 24;
var
  HRect : TRect;
  HoverOld : Boolean;

  function GetScrollTop: LongInt;
  begin
    Result := ARect.Top;
    if Invert then
      Inc(Result, Round((Height - SCROLL_HEIGHT) * (Offset + Range) / Range))
    else
      Dec(Result, Round((Height - SCROLL_HEIGHT) * Offset / Range));
  end;

  function GetScrollOffset(Top: LongInt): LongInt;
  begin
    if Invert then
      Result := Round(((Top - ARect.Bottom + SCROLL_HEIGHT + MOffset) * Range) / (Height - SCROLL_HEIGHT))
    else
      Result := Round(((ARect.Top - Top - MOffset) * Range) / (Height - SCROLL_HEIGHT));
  end;

begin
  Result := inherited OnEvent(Event);
  case Event.ID of
    etMouseUp   :
      if (Event.Mouse.Button = mbLeft) and MDrag then
      begin
        MDrag := False;
        Result := True;
      end;
    etMouseDown :
      if Event.Mouse.Button = mbLeft then
      begin
        MDrag := True;
        MOffset := GetScrollTop - Event.Mouse.Pos.y;
        if (MOffset > 0) or (MOffset < -SCROLL_HEIGHT) then
          MOffset := -SCROLL_HEIGHT div 2;
      end;
    etMouseMove :
      with Event.Mouse.Pos do
        if Range > 0 then
        begin
          HoverOld := Hover;
          if MDrag then
          begin
            if Height > 0 then
              Offset := GetScrollOffset(y);
            if not Hover then
              Repaint;
            Hover := True;
          end else
            Hover := RectIntersect(ARect, x, y);
          if HoverOld <> Hover then
            Repaint;
          Cursor := ctHand;
        end else
          Cursor := ctArrow;
    etDraw :
      if Range > 0 then
        with Event.Draw do
        begin
          HRect.Left   := ARect.Left;
          HRect.Right  := ARect.Right;
          HRect.Top    := GetScrollTop;
          HRect.Bottom := HRect.Top + SCROLL_HEIGHT;

          Canvas.PenColor := SCROLL_BAR_BORDER;
          with ARect do
            Canvas.Line(Left + Width div 2, Top, Left + Width div 2, Bottom);

          if Hover then
            Canvas.BrushColor := SCROLL_BAR_HOVER
          else
            Canvas.BrushColor := SCROLL_BAR;
          Canvas.PenColor := Canvas.BrushColor;
          with HRect do
          begin
            Canvas.FillRect(SetRect(Left + 1, Top, Right - 1, Bottom));
            Canvas.FrameRect(SetRect(Left, Top + 1, Right, Bottom - 1));
          end;
        end;
  end;
end;

procedure TScroll.SetOffset(Value: LongInt);
begin
  Value := Min(0, Max(-Range, Value));
  if FOffset <> Value then
  begin
    FOffset := Value;
    if CParent <> nil then
      CParent.Repaint(@CParent.ARect);
  end;
end;
{$ENDREGION}

{$REGION 'TScrollBox'}
{ TScrollBox }
constructor TScrollBox.Create(Parent: TControl);
begin
  inherited;
  VScroll := TScroll.Create(Self);
  VScroll.Step := 16;
  VScroll.Move(-11, 0, 11, -1);
end;

procedure TScrollBox.EndUpdate;
begin
  inherited;
  UpdateRange;
end;

procedure TScrollBox.UpdateRange;
begin
  Dec(VScroll.Range, Height - 2);
  VScroll.Offset := VScroll.Offset; // call SetOffset & check range
  Repaint;
end;

function TScrollBox.OnEvent(const Event: TControlEvent): Boolean;
begin
  Result := inherited OnEvent(Event);
  if Result then Exit;

  case Event.ID of
    etSize :
      if not FUpdate then
        UpdateRange;
    etMouseWheel :
      if not VScroll.MDrag then
        if VScroll.Invert then
          VScroll.Offset := VScroll.Offset - Event.Mouse.Pos.w * VScroll.Step
        else
          VScroll.Offset := VScroll.Offset + Event.Mouse.Pos.w * VScroll.Step;
  end;
end;
{$ENDREGION}

{$REGION 'TEdit'}
constructor TEdit.Create(Parent: TControl);
begin
  inherited;
  Cursor := ctIBeam;
  Font   := Font_Tahoma_13;
  CaretOffset := 0;
  WordWrap    := True;
  Highlight   := True;
end;

procedure TEdit.Change;
var
  Event : TControlEvent;
  i : LongInt;
begin
  if Dereturn then
  begin
    i := Pos(#13, FText);
    while i > 0 do
    begin
      Delete(FText, i, 1);
      i := Pos(#13, FText);
    end;
  end;

  i := Pos(#10, FText);
  while i > 0 do
  begin
    Delete(FText, i, 1);
    i := Pos(#10, FText);
  end;;

  if Password then
  begin
    SetLength(VText, Length(FText));
    for i := 1 to Length(VText) do
      VText[i] := #$25CF; // password char
  end else
    VText := FText;
  Event.ID := etChange;
  Perform(Event);
end;

procedure TEdit.SetText(const Value: WideString);
begin
  if Value <> FText then
  begin
    inherited;
    Change;
    CaretOffset := Length(FText);
    UpdateRange;
  end;
end;

procedure TEdit.SetCaretOffset(Value: LongInt);
begin
  if Value > Length(FText) then
    Value := Length(FText);
  if Value < 0 then
    Value := 0;
  if InFocus then
    CaretState := True;
  if FCaretOffset <> Value then
  begin
    FCaretOffset := Value;
    DCanvas.Lock;
    DCanvas.Font := Font;
    CaretPos := DCanvas.TextCaretToPos(FCaretOffset, PWideChar(VText), Lines);
    DCanvas.Unlock;
    ScrollToCaret;
    Repaint;
  end;
end;

function TEdit.GetSelection: TSelection;
begin
  with FSelection do
    if Left > Right then
    begin
      Result.Left := Right;
      Result.Right := Left;
    end else
      Result := FSelection;
end;

procedure TEdit.Clear;
begin
  FSelection.Left  := 0;
  FSelection.Right := 0;
  Text := '';
end;

procedure TEdit.ScrollToCaret;
var
  p : LongInt;
begin
  p := (CaretPos.Y + 1) * 16 + 2;
  if p + VScroll.Offset - 18 < 0 then VScroll.Offset := 18 - p;
  if p + VScroll.Offset > Height then VScroll.Offset := Height - p;
end;

procedure TEdit.UpdateRange;
begin
  DCanvas.Lock;
  DCanvas.Font := Font;
  if not WordWrap then
    DCanvas.TextWrap(PWideChar(VText), Length(VText), 0, 10000, Lines)
  else
    DCanvas.TextWrap(PWideChar(VText), Length(VText), 0, ARect.Right - ARect.Left - 8 - VScroll.Width, Lines);
  CaretPos := DCanvas.TextCaretToPos(CaretOffset, PWideChar(VText), Lines);
  DCanvas.Unlock;
  VScroll.Range := Length(Lines) * 16;
  ScrollToCaret;
  inherited;
end;

function TEdit.SelectionDelete: Boolean;
begin
  Result := False;
  FSelection := Selection; // flip if Left > Right
  with FSelection do
    if Left - Right <> 0 then
    begin
    // remove substr
      MDrag  := False;
      Result := True;
      Delete(FText, Left + 1, Right - Left);
      Change;
      UpdateRange;
      CaretOffset := Left;
      Left  := 0;
      Right := Left;
    end;
end;

function TEdit.SelectionText: WideString;
begin
  Result := '';
  with Selection do
    if Left - Right <> 0 then
      Result := Copy(VText, Left + 1, Right - Left);
end;

procedure TEdit.SwitchLayout;
const
  LK : array [Boolean] of WideString = (
    '~`@#qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM[{]};:''",<.>@#&',
    'Ёё"№йцукенгшщзфывапролдячсмитьЙЦУКЕНГШЩЗФЫВАПРОЛДЯЧСМИТЬхХъЪжЖэЭбБюЮ"№?');
var
  s : TSelection;
  Str  : WideString;
  i, j : LongInt;
begin
  s := Selection;
  if s.Left = s.Right then
  begin
    s.Left  := 0;
    s.Right := Length(FText);
  end;
  Str := FText;
  for i := s.Left + 1 to s.Right do
    for j := 1 to Length(LK[False]) do
      if (Str[i] = LK[False, j]) or (Str[i] = LK[True, j]) then
      begin
        Str[i] := LK[Str[i] = LK[False][j]][j];
        break;
      end;
  Text := Str;
end;

procedure TEdit.TextCut;
var
  Str : WideString;
begin
  if ReadOnly then
    Exit;
  Str := SelectionText;
  if Str <> '' then
  begin
    ClipboardSet(Str);
    SelectionDelete;
  end;
  UpdateRange;
end;

procedure TEdit.TextCopy;
var
  Str : WideString;
begin
  Str := SelectionText;
  if Str <> '' then
    ClipboardSet(Str);
end;

procedure TEdit.TextPaste;
var
  Str : WideString;
begin
  if ReadOnly then
    Exit;
  SelectionDelete;
  Str := ClipboardGet;
  Str := ReplaceStr(Str, #9, '    ');
  Str := ReplaceStr(Str, #10, #13);
  Str := ReplaceStr(Str, #13#13, #13);
  Insert(Str, FText, CaretOffset + 1);
  Change;
  CaretOffset := CaretOffset + Length(Str);
  UpdateRange;
end;

function TEdit.OnEvent(const Event: TControlEvent): Boolean;
var
  HRect, SRect : TRect;
  i, L, R : LongInt;
  S : TSelection;

  procedure MouseToCaret;
  begin
    with Event.Mouse.Pos, ARect do
    begin
      DCanvas.Lock;
      DCanvas.Font := Font;
      CaretOffset := DCanvas.TextPosToCaret(x - Left - 5, (y - VScroll.Offset - Top - 1) div 16, PWideChar(VText), Lines);
      DCanvas.Unlock;
    end;
  end;

  procedure SkipWord(Dir: ShortInt);
  var
    i : LongInt;
  begin
    if Dir > 0 then
    begin
      for i := CaretOffset + 1 to Length(VText) do
        if VText[i] = ' ' then
        begin
          CaretOffset := i;
          Exit;
        end;
      CaretOffset := Length(VText);
    end else
    begin
      for i := CaretOffset - 1 downto 1 do
        if VText[i] = ' ' then
        begin
          CaretOffset := i;
          Exit;
        end;
      CaretOffset := 0;
    end;
  end;

begin
  case Event.ID of
    etFocus :
      begin
        InFocus := Event.Focus;
        if CaretState then
          CaretState := False;
        Repaint;
      end;
    etMouseDown :
      with Event.Mouse.Pos, ARect do
        if (FText <> '') and RectIntersect(SetRect(Left, Top, Right - VScroll.Width, Bottom), x, y) then
        begin
          MouseToCaret;
          if FSelection.Left <> FSelection.Right then
            Repaint;
          FSelection.Left  := CaretOffset;
          FSelection.Right := FSelection.Left;
          MDrag := True;
        end;
    etMouseUp :
      MDrag := False;
    etMouseMove :
      if MDrag then
        with Event.Mouse.Pos, ARect do
        begin
          MouseToCaret;
          FSelection.Right := CaretOffset;
        end;
    etKeyDown :
      if InFocus then
      begin
        case Event.Key.Value of
        // dir
          VK_LEFT, VK_RIGHT, VK_HOME, VK_END, VK_UP, VK_DOWN :
            begin
              with FSelection do
                if ssShift in Event.Key.Shift then
                begin
                  if Left = Right then
                    Left := FCaretOffset; // start selection
                end else
                  Left := Right; // remove selection

              case Event.Key.Value of
                VK_LEFT  :
                  if ssCtrl in Event.Key.Shift then
                    SkipWord(-1)
                  else
                    CaretOffset := CaretOffset - 1;
                VK_RIGHT :
                  if ssCtrl in Event.Key.Shift then
                    SkipWord(+1)
                  else
                    CaretOffset := CaretOffset + 1;
                VK_HOME  :
                  with Lines[CaretPos.Y] do
                    CaretOffset := CaretOffset - (CaretOffset - Start);
                VK_END   :
                  with Lines[CaretPos.Y] do
                    CaretOffset := CaretOffset + (Start + Length - CaretOffset);
                VK_UP    :
                  if CaretPos.Y > 0 then
                    with Lines[CaretPos.Y - 1] do
                      CaretOffset := Start + Min(CaretOffset - Lines[CaretPos.Y].Start + 1, Length + 1) - 1;
                VK_DOWN  :
                  if CaretPos.Y < Length(Lines) - 1 then
                    with Lines[CaretPos.Y + 1] do
                      CaretOffset := Start + Min(CaretOffset - Lines[CaretPos.Y].Start + 1, Length + 1) - 1;
              end;

              if ssShift in Event.Key.Shift then
                FSelection.Right := FCaretOffset;
              UpdateRange;
            end;
        // backspace
          VK_BACK :
            if not SelectionDelete then
            begin
              Delete(FText, CaretOffset, 1);
              Change;
              UpdateRange;
              CaretOffset := CaretOffset - 1;
            end;
          Ord('A') :
            if ssCtrl in Event.Key.Shift then
            begin
              FSelection.Left  := 0;
              FSelection.Right := Length(FText);
              if FSelection.Left <> FSelection.Right then
                Repaint;
            end;
          Ord('R') :
            if (not ReadOnly) and (ssCtrl in Event.Key.Shift) then
              SwitchLayout;
          Ord('V'), Ord('C'), Ord('X'), VK_INSERT, VK_DELETE :
            with Event.Key do
              if ((Value = Ord('V')) and (ssCtrl in Shift)) or
                 ((Value = VK_INSERT) and (ssShift in Shift)) then
                TextPaste
              else
                if ((Value = Ord('C')) and (ssCtrl in Shift)) or
                   ((Value = VK_INSERT) and (ssCtrl in Shift)) then
                  TextCopy
                else
                  if ((Value = Ord('X')) and (ssCtrl in Shift)) or
                     ((Value = VK_DELETE) and (ssShift in Shift)) then
                    TextCut
                  else
                    if (Value = VK_DELETE) and (Shift = []) and (not SelectionDelete) then
                    begin
                      Delete(FText, CaretOffset + 1, 1);
                      Change;
                      CaretOffset := CaretOffset;
                      UpdateRange;
                    end;
        end;
        Repaint;
      end;
    etChar :
      if (not ReadOnly) and (inFocus) and ((Tabulate and (Event.Key.Value = 9)) or (Event.Key.Value > 31) or (WordWrap and (Event.Key.Value = 13))) then
      begin
        SelectionDelete;
        if Event.Key.Value = 9 then
        begin
          Insert('    ', FText, CaretOffset + 1);
          Change;
          CaretOffset := CaretOffset + 4;
        end else
        begin
          Insert(System.WideChar(Event.Key.Char), FText, CaretOffset + 1);
          Change;
          CaretOffset := CaretOffset + 1;
        end;
        UpdateRange;
        Repaint;
      end;
    etDraw :
      with Event.Draw do
      begin
        Canvas.BrushColor := EDIT_WINDOW;
        if InFocus and Highlight then
          Canvas.PenColor := EDIT_ACTIVE
        else
          Canvas.PenColor := EDIT_BORDER;

        with ARect do
          HRect := SetRect(Left, Top, Right - VScroll.Width div 2, Bottom);
        Canvas.FillRect(HRect);
        Canvas.FrameRect(HRect);

        with ARect do
          HRect := SetRect(Left + 1, Top + 1, Right - VScroll.Width - 1, Bottom - 1);
        Canvas.ClipInit(HRect);

        HRect.Left  := HRect.Left + 4;
        HRect.Right := HRect.Right - 4;
        HRect.Top   := HRect.Top + VScroll.Offset;
        Canvas.Font := Font;

        if FSelection.Left - FSelection.Right <> 0 then
        begin
          S := Selection; // flip if left > right

          Canvas.BrushColor := EDIT_SELECT;
          Canvas.PenColor   := COLOR_B2;
          for i := 0 to Length(Lines) - 1 do
            with Lines[i] do
            begin
              L := Max(Start, S.Left);
              R := Min(Start + Length, S.Right);
              if R - L > 0 then
              begin
                SRect := SetRectSize(HRect.Left + Canvas.TextWidth(@VText[Start + 1], L - Start) - 1, HRect.Top + i * 16 + 1,
                                     Canvas.TextWidth(@VText[L + 1], R - L) + 1, 16);
                Canvas.FillRect(SRect);
                with SRect do
                  Canvas.Line(Left, Bottom - 1, Right, Bottom - 1);
              end;
            end;
        end;

        if Disable then
          Canvas.TextColor := $DDDDDD
        else
          Canvas.TextColor := COLOR_8;
        Canvas.TextOut(HRect.Left, HRect.Top, 16, PWideChar(VText), Lines);
        Inc(HRect.Top, Length(Lines) * 16);
      // draw caret
        if (not ReadOnly) and CaretState and (FSelection.Left = FSelection.Right) then
        begin
          Canvas.PenColor := 0;
          HRect.Left := CaretPos.X + ARect.Left + 4;
          HRect.Top  := CaretPos.Y * 16 + ARect.Top + 4 + VScroll.Offset;
          with HRect do
            Canvas.Line(Left, Top, Left, Top + 12);
        end;
        Canvas.ClipFree;
      end;
  end;
  Result := inherited OnEvent(Event);
end;
{$ENDREGION}

{$REGION 'TSplitter'}
procedure TSplitter.SetVertical(const Value: Boolean);
begin
  FVertical := Value;
  if FVertical then
    Cursor := ctSizeWE
  else
    Cursor := ctSizeNS;
end;

function TSplitter.OnEvent(const Event: TControlEvent): Boolean;

  function CheckResize(var Delta: LongInt; Min1, Max1, Min2, Max2: LongInt): Boolean;
  begin
    Delta := Min(Delta, Max1 - Min1 - MinSize[0]);
    Delta := Max(Delta, Min2 - Max2 + MinSize[1]);
    Result := Delta <> 0;
  end;

  function ResizeHoriz(Delta: LongInt): Boolean;
  begin
    Result := False;
    if (Ctrl[0] <> nil) and (Ctrl[1] <> nil) then
      if CheckResize(Delta, Ctrl[0].ARect.Left, Ctrl[0].ARect.Right, Ctrl[1].ARect.Left, Ctrl[1].ARect.Right) then
      begin
        with Ctrl[0], Size do Move(Left, Top, Width - Delta, Height);
        with Ctrl[1], Size do Move(Left - Delta, Top, Width + Delta, Height);
        Dec(Size.Left, Delta);
        Result := True;
      end;
  end;

  function ResizeVert(Delta: LongInt): Boolean;
  begin
    Result := False;
    if (Ctrl[0] <> nil) and (Ctrl[1] <> nil) then
      if CheckResize(Delta, Ctrl[0].ARect.Top, Ctrl[0].ARect.Bottom, Ctrl[1].ARect.Top, Ctrl[1].ARect.Bottom) then
      begin
        with Ctrl[0], Size do Move(Left, Top, Width, Height - Delta);
        with Ctrl[1], Size do Move(Left, Top - Delta, Width, Height + Delta);
        Dec(Size.Top, Delta);
        Result := True;
      end;
  end;

var
  HRect : TRect;
  Flag  : Boolean;
begin
  Result := inherited OnEvent(Event);
  case Event.ID of
    etSize :
      if Visible then
      begin
        if Vertical then
          Flag := ResizeHoriz(0)
        else
          Flag := ResizeVert(0);
        if Flag then
          UpdateRect;
      end;
    etMouseDown :
      if Event.Mouse.Button = mbLeft then
      begin
        MDrag  := True;
        MPos.X := Event.Mouse.Pos.x;
        MPos.Y := Event.Mouse.Pos.y;
      end;
    etMouseUp :
      MDrag := False;
    etMouseMove :
      with Event.Mouse.Pos do
        if MDrag then
        begin
          if Vertical then
            Flag := ResizeHoriz(MPos.X - x)
          else
            Flag := ResizeVert(MPos.Y - y);
          if not Flag then
            Exit;
          MPos.X := x;
          MPos.Y := y;
          UpdateRect;
          HRect := RectMerge(Ctrl[0].ARect, Ctrl[1].Rect);
          FParent.Repaint(@HRect, True);
        end;
  end;
end;
{$ENDREGION}

{$REGION 'TLoader'}
function TLoader.OnEvent(const Event: TControlEvent): Boolean;
var
  i, c, w : LongInt;
begin
  Result := inherited OnEvent(Event);
  if Event.ID = etDraw then
    with Event.Draw do
    begin
      c := GetTime div 100 mod 8;
      w := Width div 8;
      for i := 0 to 7 do
      begin
        case (7 - i + c) mod 8 of
          1 : Canvas.BrushColor := $B49C84;
          0 : Canvas.BrushColor := $8E6845;
        else
          Canvas.BrushColor := $D9CDD1;
        end;
        with ARect do
          Canvas.FillRect(SetRect(Left + w * i + 4, Top, Left + w * (i + 1), Bottom));
      end;
    end;
end;
{$ENDREGION}

{$REGION 'TTrack'}
constructor TTrack.Create(Parent: TControl);
begin
  inherited;
  Cursor := ctHand;
  Complete := 1;
end;

function TTrack.GetPosition: LongInt;
begin
  if MDrag then
    Result := TempPos
  else
    Result := FPosition;
end;

procedure TTrack.SetPosition(const Value: LongInt);
var
  OldP, NewP, OldT, NewT : LongInt;
begin
  if MaxValue > 0 then
  begin
    OldP := TrackWidth * Position div MaxValue;
    OldT := Position div 1000; // msec to sec
    FPosition := Min(MaxValue, Max(0, Value));
    NewP := TrackWidth * Position div MaxValue;
    NewT := Position div 1000;
    if (OldP <> NewP) or (Time and (OldT <> NewT)) then
      Repaint;
  end;
end;

procedure TTrack.SetComplete(const Value: Single);
var
  OldP, NewP : LongInt;
begin
  OldP := Round((TrackWidth + BarWidth) * Complete);
  FComplete := Value;
  NewP := Round((TrackWidth + BarWidth) * Complete);
  if OldP <> NewP then
    Repaint;
end;

function TTrack.TrackLeft: LongInt;
begin
  Result := ARect.Left;
  if Time then
    Inc(Result, TRACK_TIME_LEFT);
end;

function TTrack.TrackWidth: LongInt;
begin
  Result := Width - BarWidth;
  if Time then
    Dec(Result, TRACK_TIME_LEFT + TRACK_TIME_RIGHT);
end;

function TTrack.OnEvent(const Event: TControlEvent): Boolean;
var
  e : TControlEvent;
  p : LongInt;

  procedure DrawTime(X, Y, Value: LongInt);
  begin
    Value := Value div 1000;
    Event.Draw.Canvas.TextOut(X, Y, Conv(Value div 60) + ':' + ConvZ(Value mod 60));
  end;

begin
  case Event.ID of
    etMouseDown :
      MDrag := Event.Mouse.Button = mbLeft;
    etMouseUp   :
      if MDrag and (Event.Mouse.Button = mbLeft) then
      begin
        MDrag := False;
        Position := TempPos;
        e.ID := etChange;
        Perform(e);
      end;
    etMouseMove :
      if TrackWidth > 0 then
      begin
        p := Min(MaxValue, Max(0, (Event.Mouse.Pos.x - TrackLeft - BarWidth div 2) * MaxValue div TrackWidth));
        if p <> TempPos then
        begin
          TempPos := p;
          Repaint;
        end;
      end;
    etDraw :
      with Event.Draw, ARect do
      begin
        p := TrackLeft;
        if Time then
        begin
          Canvas.Font := Font_Tahoma_10;
          Canvas.TextColor := $666666;
          DrawTime(Left, Top, Position);
          DrawTime(Right - TRACK_TIME_LEFT + 4, Top, MaxValue);
        end;

        if Complete < 0.9999 then
        begin
          Canvas.PenColor := COLOR_B4;
          Canvas.Line(p, Top + 4, p + TrackWidth + BarWidth, Top + 4);
        end;
        Canvas.PenColor := $9D7D5F;
        Canvas.Line(p, Top + 4, p + Round((TrackWidth + BarWidth) * Complete), Top + 4);
        if MaxValue > 0 then
          Inc(p, TrackWidth * Position div MaxValue);
        Canvas.BrushColor := Canvas.PenColor;
        Canvas.FillRect(SetRect(p, Top + 5, p + BarWidth, Top + 9));
      end;
  end;
  Result := inherited OnEvent(Event);
end;
{$ENDREGION}

{$REGION 'TVolume'}
constructor TVolume.Create(Parent: TControl);
begin
  inherited;
  Cursor := ctHand;
end;

procedure TVolume.SetValue(const Value: LongInt);
var
  e : TControlEvent;
  v : LongInt;
begin
  v := Min(5, Max(0, Value));
  if FValue <> v then
  begin
    FValue := v;
    if MDrag then
    begin
      e.ID := etChange;
      Perform(e);
    end;
    Repaint;
  end;
end;

function TVolume.OnEvent(const Event: TControlEvent): Boolean;
const
  BAR_DIST  = 5;
  BAR_WIDTH = 3;
  BAR_DELTA = 2;
var
  i : LongInt;

  procedure UpdatePos;
  begin
    if MDrag and (Width > 0) then
      Value := (Event.Mouse.Pos.x - ARect.Left + BAR_DIST) * BAR_DIST div Width;
  end;

begin
  case Event.ID of
    etMouseDown :
      begin
        MDrag := Event.Mouse.Button = mbLeft;
        UpdatePos;
      end;
    etMouseUp   :
      if MDrag and (Event.Mouse.Button = mbLeft) then
        MDrag := False;
    etMouseMove :
      UpdatePos;
    etDraw :
      with Event.Draw do
        for i := 0 to 4 do
        begin
          if Value > i then
            Canvas.BrushColor := $8D632D
          else
            Canvas.BrushColor := $C5AF94;
          with ARect do
            Canvas.FillRect(SetRect(Left + i * BAR_DIST, Top + (4 - i) * BAR_DELTA, Left + i * BAR_DIST + BAR_WIDTH, Bottom));
        end;
  end;
  Result := inherited OnEvent(Event);
end;
{$ENDREGION}

{$REGION 'TImageList'}
procedure TImageList.SetOver(const Value: LongInt);
var
  e : TControlEvent;
begin
  if Value <> FOver then
  begin
    FOver := Value;
{
    if Value = -1 then
      Cursor := ctArrow
    else
      Cursor := ctHand;
}
    e.ID := etChange;
    Perform(e);
    Repaint;
  end;
end;

procedure TImageList.SetIndex(const Value: LongInt);
var
  e : TControlEvent;
begin
  if Value <> FIndex then
  begin
    FIndex := Value;
    e.ID := etChange;
    Perform(e);
    Repaint;
  end;
end;

function TImageList.OnEvent(const Event: TControlEvent): Boolean;
var
  i, a : LongInt;
  HRect : TRect;
begin
  case Event.ID of
    etClick :
      if Over > -1 then
        Index := Over;
    etMouseMove :
      with Event.Mouse.Pos do
      begin
        if RectIntersect(ARect, x, y) then
        begin
          i := (y - ARect.Top - 4) div 20 * Cols + (x - ARect.Left - 4) div 20;
          if i <= Count then
            Over := i
          else
            Over := -1;
        end else
          Over := -1;
      end;
    etDraw :
      with Event.Draw do
      begin
        Canvas.BrushColor := COLOR_0;
        Canvas.PenColor   := COLOR_5;
        HRect := ARect;
        Dec(HRect.Bottom, 24);
        Canvas.FillRect(HRect);
        Canvas.FrameRect(HRect);

        for i := 0 to Count do
        begin
          HRect.Left := ARect.Left + (i mod Cols) * 20 + 4;
          HRect.Top  := ARect.Top  + (i div Cols) * 20 + 4;
          if (i = Over) or (i = Index) then
          begin
            HRect.Right  := HRect.Left + 20;
            HRect.Bottom := HRect.Top  + 20;
            if i = Over then
            begin
              Canvas.PenColor := EDIT_ACTIVE;
              Canvas.BrushColor := ROSTER_CONTACT_OVER;
              Canvas.FillRect(HRect);
              Canvas.FrameRect(HRect);
            end;

            if i = Index then
            begin
              Canvas.PenColor := ROSTER_CONTACT_SELECT;
              Canvas.FrameRect(HRect)
            end;
          end;

          if i = 0 then
            Icon[itOnline].Small.Draw(Canvas, HRect.Left + 2, HRect.Top + 2)
          else
            Image.DrawFrame(Canvas, HRect.Left + 2, HRect.Top + 2, i - 1, 16);
        end;

      // status text
        if Over > -1 then
          i := Over
        else
          i := Index;

        if (Over = Index) or (Over = -1) then
          a := 255
        else
          a := 128;

        if i = 0 then
          Icon[itOnline].Small.Draw(Canvas, ARect.Left + 2, ARect.Bottom - 18, a)
        else
          Image.DrawFrame(Canvas, ARect.Left + 2, ARect.Bottom - 18, i - 1, 16, a);
        Canvas.Font := Font_Tahoma_11;
        if @ImageText <> nil then
          Canvas.TextOut(ARect.Left + 24, ARect.Bottom - 16, ImageText(i));
      end;
  end;
  Result := inherited OnEvent(Event);
end;
{$ENDREGION}

end.
