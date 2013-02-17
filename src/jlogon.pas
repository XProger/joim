unit jlogon;

interface

uses
  jsys, jutils, jctrl, jnet, jvk, jhash;

const
  LOGON_VERSION = 6;

type
  TLogon = class(TControl)
    constructor Create(Parent: TControl);
    destructor Destroy; override;
  public
    TimerUpdate : LongWord;
    CLogin   : TControl;
    CCaptcha : TControl;
    CSetup   : TControl;
    CLoading : TControl;

    EMail    : TEdit;
    EPass    : TEdit;
    HExpire  : TCheck;
    HAuto    : TCheck;
    BProxy   : TButton;
    BLogin   : TButton;
    BSetup   : TButton;
    BAbout   : TButton;
    EHost    : TEdit;
    EPort    : TEdit;
    PIdle    : TProgress;
    LError   : TLabel;
    LAccept  : TLabel;

    ICaptcha : TPicture;
    ECaptcha : TEdit;
    BCancel  : TButton;
    BCaptcha : TButton;

    LLoader  : TLoader;

    Auto : Boolean;

    CaptchaSID  : AnsiString;

    procedure Load;
    procedure Save;
    procedure Login;
    procedure ShowLogon;
    procedure ShowCaptcha;
    procedure ShowLoading;
    procedure ShowError(const EText: WideString);
    procedure ShowSetup(ShowPanel: Boolean);
    procedure ShowIdle(Show: Boolean);
  end;

  procedure LogonResProc(VKResult: TVKResult; const Param: WideString);

implementation

uses
  jglobal;

const
  BTN_LOGIN    = 1;
  BTN_SETUP    = 2;
  BTN_ABOUT    = 3;
  BTN_CAPTCHA  = 4;
  BTN_CANCEL   = 5;
  IMG_CAPTCHA  = 6;
  CHECK_AUTO   = 7;
  EDIT_MAIL    = 8;
  EDIT_PASS    = 9;
  EDIT_HOST    = 10;
  EDIT_PORT    = 11;
  EDIT_CAPTCHA = 12;

procedure UpdateIdle;
begin
  if Logon <> nil then
  begin
    if Logon.Visible and Logon.CLogin.Visible and Logon.PIdle.Visible then
    begin
      Logon.PIdle.Progress := Logon.PIdle.Progress + 1;
      if Logon.PIdle.Progress = 100 then
      begin
        Logon.ShowIdle(False);
        Logon.Login;
        Logon.Auto := True;
      end;
    end;

    if Logon.Visible and Logon.CLoading.Visible and Logon.LLoader.Visible then
      Logon.LLoader.Repaint;
  end;
end;

procedure OnCaptcha(CallID: Integer; const Header: AnsiString; const Content: WideString; Data, RawData: Pointer; RawSize: LongInt);
begin
  if RawData <> nil then
  begin
    if Logon.ICaptcha.Image <> nil then
      Logon.ICaptcha.Image.Free;
    Logon.ICaptcha.Image := TImage.Create(RawData, RawSize);
    Logon.ShowCaptcha;
    Exit;
  end;
  Logon.ShowLogon; // unknown errors 8)
end;

function LogonProc(Control: TControl; const Event: TControlEvent): Boolean;

  procedure GoCaptcha;
  var
    Str : AnsiString;
  begin
    if Control.ID = IMG_CAPTCHA then
      Str := ''
    else
      Str := AnsiString(Logon.ECaptcha.Text);

    vk.ResProc := TVKResProc(@LogonResProc);
    vk.TryLogin(Logon.CaptchaSID, Str);

    Logon.ShowLoading;
  end;

  procedure EditPass;
  begin
    if (Logon <> nil) and Logon.EPass.Disable then
    begin
      Logon.PIdle.Visible := False;
      Logon.EPass.Disable := False;
      Logon.EPass.Text := '';
    end;
  end;

begin
  Result := False;
  case Event.ID of
    etFocus :
      if (Control.ID = EDIT_PASS) and Event.Focus then
        EditPass;
    etChange :
      if Control.ID = EDIT_MAIL then
        EditPass;
    etClick :
      begin
        case Control.ID of
          BTN_LOGIN   : Logon.Login;
          BTN_ABOUT   : BrowseURL(VK_URL + 'club' + VK_CLUB);
          BTN_SETUP   : Logon.ShowSetup(not Logon.CSetup.Visible);
          BTN_CANCEL  : Logon.ShowLogon;
          BTN_CAPTCHA, IMG_CAPTCHA : GoCaptcha;
          CHECK_AUTO  :
            with TCheck(Control) do
              if Checked then
                Checked := CheckAutorun(arEnable)
              else
                Checked := CheckAutorun(arDisable);
        end;
        if Logon.PIdle.Visible then
          Logon.PIdle.Visible := False;
      end;
    etKeyDown :
      case Control.ID of
        EDIT_MAIL, EDIT_PASS, EDIT_HOST, EDIT_PORT, EDIT_CAPTCHA :
          case Event.Key.Value of
            9  : // TabStop
              case Control.ID of
                EDIT_MAIL : Window.Focus := Logon.EPass;
                EDIT_PASS : Window.Focus := Logon.EMail;
                EDIT_HOST : Window.Focus := Logon.EPort;
                EDIT_PORT : Window.Focus := Logon.EHost;
              end;
            13 : // Logon
              if Control.ID = EDIT_CAPTCHA then
                GoCaptcha
              else
                Logon.Login;
          end
      end;
  end;
end;

procedure LogonResProc(VKResult: TVKResult; const Param: WideString);
begin
  with Logon do
    case VKResult of
      vrLogin :
        begin
          vk.pass := '';
          Save;
        end;
      vrError :
        begin
          ShowLogon;
          ShowError(LangMsg[lmErrorConnect]);
          ShowIdle(Auto);
        end;
      vrErrorProxy :
        begin
          ShowLogon;
          ShowSetup(True);
          Window.Focus := Logon.EHost;
          ShowError(LangMsg[lmErrorProxy]);
          ShowIdle(Auto and (vk.token <> ''));
        end;
      vrErrorLogin :
        begin
          ShowLogon;
          Window.Focus := Logon.EPass;
          ShowError(LangMsg[lmErrorLogin]);
        end;
      vrErrorAttempts :
        begin
          ShowLogon;
          ShowError(LangMsg[lmErrorAttempts]);
          ShowIdle(False);
        end;
      vrErrorCaptcha :
        begin
          vk.ResProc := @VKDummyProc;
          CaptchaSID  := AnsiString(Param);
          vk.GetCaptcha(CaptchaSID, 0, @OnCaptcha);
        end;
    end;
end;

constructor TLogon.Create(Parent: TControl);
var
  LCtrl : TLabel;
begin
  inherited;
// login frame
  CLogin := TControl.Create(Self);
  CLogin.Move(16, 8, -33, -17);
  CLogin.EventProc := @LogonProc;

  LCtrl := TLabel.Create(CLogin);
  LCtrl.Font  := Font_Tahoma_11b;
  LCtrl.Color := $666666;
  LCtrl.Text := LangMsg[lmMail];
  LCtrl.Move(0, 0, -1, 12);
  LCtrl.EventProc := @LogonProc;

  EMail := TEdit.Create(CLogin);
  EMail.Move(8, 16, -17 + EMail.VScroll.Width, 20);
  EMail.WordWrap := False;
  EMail.ID        := EDIT_MAIL;
  EMail.EventProc := @LogonProc;

  LCtrl := TLabel.Create(CLogin);
  LCtrl.Font  := Font_Tahoma_11b;
  LCtrl.Color := $666666;
  LCtrl.Text := LangMsg[lmPass];
  LCtrl.Move(0, 40, -1, 12);
  LCtrl.EventProc := @LogonProc;

  EPass := TEdit.Create(CLogin);
  EPass.Move(8, 56, -17 + EPass.VScroll.Width, 20);
  EPass.WordWrap := False;
  EPass.Password := True;
  EPass.ID        := EDIT_PASS;
  EPass.EventProc := @LogonProc;

  HExpire := TCheck.Create(CLogin);
  HExpire.Move(8, 84, 1, 1);
  HExpire.Text := LangMsg[lmExpire];
  HExpire.Hint := LangMsg[lmHintExpire];

  HAuto := TCheck.Create(CLogin);
  HAuto.Move(8, 104, 1, 1);
  HAuto.Text := LangMsg[lmAutoStart];
  HAuto.Hint := LangMsg[lmHintAutoStart];
  HAuto.Checked := CheckAutorun(arCheck);
  HAuto.ID := CHECK_AUTO;
  HAuto.EventProc := @LogonProc;

  BLogin := TButton.Create(CLogin, nil, 0);
  BLogin.Move(8, 128, 64, 24);
  BLogin.ID := BTN_LOGIN;
  BLogin.EventProc := @LogonProc;
  BLogin.Text := LangMsg[lmLoginBtn];

  BSetup := CreateButton(CLogin, 16,  80, 132, BTN_SETUP, TEventProc(@LogonProc), lmHintSetup);
  BAbout := CreateButton(CLogin, 17, 104, 132, BTN_ABOUT, TEventProc(@LogonProc), lmHintAbout);

  PIdle := TProgress.Create(CLogin);
  PIdle.EventProc := @LogonProc;

  LError := TLabel.Create(CLogin);
  LError.Font  := Font_Tahoma_11;
  LError.Color := $000088;
  LError.Move(8, -46, -17, 12);

  LAccept := TLabel.Create(CLogin);
  LAccept.Font  := Font_Tahoma_10;
  LAccept.Color := $666666;
  LAccept.Text := LangMsg[lmAcceptNote];
  LAccept.WordWrap := True;
  LAccept.LineHeight := 12;
  LAccept.Move(0, -28, -1, 36);
  LAccept.EventProc := @LogonProc;

// setup settings frame
  CSetup := TControl.Create(CLogin);
  CSetup.Move(0, 158, -1, 40);

  LCtrl := TLabel.Create(CSetup);
  LCtrl.Font  := Font_Tahoma_11b;
  LCtrl.Color := $666666;
  LCtrl.Text := LangMsg[lmProxy];
  LCtrl.Move(0, 0, -1, 12);

  EHost := TEdit.Create(CSetup);
  EHost.Move(8, 16, 127, 20);
  EHost.WordWrap  := False;
  EHost.ID        := EDIT_HOST;
  EHost.EventProc := @LogonProc;

  LCtrl := TLabel.Create(CSetup);
  LCtrl.Font  := Font_Tahoma_13b;
  LCtrl.Color := $666666;
  LCtrl.Text := ':';
  LCtrl.Move(131, 17, 52, 20);

  EPort := TEdit.Create(CSetup);
  EPort.Move(136, 16, 52, 20);
  EPort.WordWrap  := False;
  EPort.ID        := EDIT_PORT;
  EPort.EventProc := @LogonProc;

// captcha frame
  CCaptcha := TControl.Create(Self);
  CCaptcha.Move(8, 8, -17, -17);

  LCtrl := TLabel.Create(CCaptcha);
  LCtrl.Font  := Font_Tahoma_11b;
  LCtrl.Color := $666666;
  LCtrl.Text := LangMsg[lmCaptcha];
  LCtrl.Move(8, 0, -1, 12);

  ICaptcha := TPicture.Create(CCaptcha);
  ICaptcha.Image := nil;
  ICaptcha.Move(36, 16, 132, 52);
  ICaptcha.Cursor    := ctHand;
  ICaptcha.ID        := IMG_CAPTCHA;
  ICaptcha.EventProc := @LogonProc;

  ECaptcha := TEdit.Create(CCaptcha);
  ECaptcha.Move(64, 75, -1 - 128 + ECaptcha.VScroll.Width, 20);
  ECaptcha.Font := Font_Tahoma_13;
  ECaptcha.WordWrap := False;
  ECaptcha.ID := EDIT_CAPTCHA;
  ECaptcha.EventProc := @LogonProc;

  BCancel := TButton.Create(CCaptcha, nil, 0);
  BCancel.Move(28, 102, 68, 20);
  BCancel.ID := BTN_CANCEL;
  BCancel.EventProc := @LogonProc;
  BCancel.Text := LangMsg[lmCancel];

  BCaptcha := TButton.Create(CCaptcha, nil, 0);
  BCaptcha.Move(108, 102, 68, 20);
  BCaptcha.ID := BTN_CAPTCHA;
  BCaptcha.EventProc := @LogonProc;
  BCaptcha.Text := LangMsg[lmSend];

// Loading
  CLoading := TControl.Create(Self);
  CLoading.Move(0, 0, -1, -1);

  LLoader := TLoader.Create(CLoading);

  Load;

  ShowIdle(vk.token <> '');
  TimerUpdate := InitTimer(40, @UpdateIdle);
end;

destructor TLogon.Destroy;
begin
  FreeTimer(TimerUpdate);
  inherited;
end;

procedure TLogon.Load;
var
  Stream : TFileStream;
begin
  vk.token := '';
  Stream := TFileStream.Create(RootDir + 'logon.dat', fmRead);
  if Stream.Valid and (Stream.ReadInt32 = LOGON_VERSION) then
  begin
    HExpire.Checked := Stream.ReadInt32 = 1;
    if not HExpire.Checked then
    begin
      EMail.Text    := Stream.ReadStr;
      EPass.Text    := '( . Y . )';
      EPass.Disable := True;
      vk.mid    := WideString(Stream.ReadStr());
      vk.token  := AnsiString(Stream.ReadStr());
      vk.secret := WideString(Stream.ReadStr());
    end;
    EHost.Text := Stream.ReadStr;
    EPort.Text := Stream.ReadStr;
  end else
    HAuto.Checked := CheckAutorun(arEnable);
  Stream.Free;
end;

procedure TLogon.Save;
var
  Stream : TFileStream;
begin
  Stream := TFileStream.Create(RootDir + 'logon.dat', fmWrite);
  if Stream.Valid then
  begin
    Stream.WriteInt32(LOGON_VERSION);
    Stream.WriteInt32(Ord(HExpire.Checked));
    if not HExpire.Checked then
    begin
      Stream.WriteStr(EMail.Text);
    //  Stream.WriteStr(WideString(vk.Cookie));
      Stream.WriteStr(WideString(vk.mid));
      Stream.WriteStr(WideString(vk.token));
      Stream.WriteStr(WideString(vk.secret));
    end;
    Stream.WriteStr(EHost.Text);
    Stream.WriteStr(EPort.Text);
  end;
  Stream.Free;
end;

procedure TLogon.Login;
var
  ProxyHost : WideString;
  ProxyPort : LongInt;
begin
  Auto := False;
  if Trim(EMail.Text) = '' then
    Window.Focus := Logon.EMail
  else
    if Trim(EPass.Text) = '' then
      Window.Focus := EPass
    else
    begin
      ProxyHost := Trim(EHost.Text);
      ProxyPort := Conv(Trim(EPort.Text), 0);
      if (ProxyHost <> '') and (ProxyPort = 0) then
        Window.Focus := EPort
      else
        if (ProxyHost = '') and (ProxyPort <> 0) then
          Window.Focus := EHost
        else
        begin
          if ProxyPort <> 0 then
            Proxy.Family := pfUnknown
          else
            Proxy.Family := pfNone;
          Proxy.Host := AnsiString(ProxyHost);
          Proxy.Port := ProxyPort;
          vk.ResProc := TVKResProc(@LogonResProc);
          vk.mail := EMail.Text;
          if not EPass.Disable then
          begin
            //vk.Digest := MD5String(EMail.Text + ':vk.com:' + EPass.Text);
            vk.pass  := EPass.Text;
            vk.token := '';
          end;
          vk.TryLogin('', '');
          ShowLoading;
        end;
    end;
end;

procedure TLogon.ShowLogon;
begin
  CLogin.Visible   := True;
  CSetup.Visible   := False;
  CCaptcha.Visible := False;
  CLoading.Visible := False;
  LError.Visible   := False;
  with Window, ScreenRect do
    Move(Left, Top, Right - Left, 270);
  Window.Focus := EMail;
end;

procedure TLogon.ShowCaptcha;
begin
  CLogin.Visible   := False;
  CCaptcha.Visible := True;
  CLoading.Visible := False;
  ECaptcha.Text    := '';
  with Window, ScreenRect do
    Move(Left, Top, Right - Left, 184);
  Window.Focus := ECaptcha;
end;

procedure TLogon.ShowLoading;
begin
  CLogin.Visible   := False;
  CCaptcha.Visible := False;
  CLoading.Visible := True;
  LLoader.Move(16, 24, -33, 8);
  with Window, ScreenRect do
    Move(Left, Top, Right - Left, 96);
  Window.Focus := Window;
end;

procedure TLogon.ShowError(const EText: WideString);
begin
  LError.Text    := EText;
  LError.Visible := True;
  LError.Move(8, -46, -17, 12);
end;

procedure TLogon.ShowSetup(ShowPanel: Boolean);
begin
  if CSetup.Visible <> ShowPanel then
  begin
    CSetup.Visible := ShowPanel;
    with Window, ScreenRect do
      if ShowPanel then
      begin
        Move(Left, Top, Right - Left, Bottom - Top + CSetup.Height);
        Focus := Logon.EHost;
      end else
      begin
        Move(Left, Top, Right - Left, Bottom - Top - CSetup.Height);
        Focus := Logon.EMail;
      end;
  end;
end;

procedure TLogon.ShowIdle(Show: Boolean);
begin
  PIdle.Progress := 0;
  PIdle.Visible  := Show;
  PIdle.Move(8, -56, -17, 8);
end;

end.
