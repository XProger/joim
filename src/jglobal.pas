unit jglobal;

interface

uses
  jsys, jnet, jutils, jimg, jctrl, jlogon, jinfo, jdata, jhttp, jroster, jhistory,
  jmedia, jvk, jupdate, jstatus, jflash, jplayer, jvchat, jpopup, jlastfm;

const
  CONFIG_VERSION = 5;

  CLIENT_NAME : WideString = 'joim';
  CLIENT_VER  : WideString = '0.09k';
  APP_ID      = '1911946';
  APP_SECRET  = 'IgKaQ2FrsNghfyCv9J6l';

  COLOR_0 = $FFFFFF;
  COLOR_1 = $9F764B;
  COLOR_2 = $B38F6D;
  COLOR_3 = $8E6845;
  COLOR_4 = $E8E2DA;
  COLOR_5 = $CABBAB;
  COLOR_6 = $D5CAC0;
  COLOR_7 = $F0E4D9;
  COLOR_8 = $553400;
  COLOR_9 = $B38860;
  COLOR_A = $946E46;
  COLOR_B = $EAEAEA;
  COLOR_C = $666666;
  COLOR_D = $DDDDDD;
  COLOR_E = $E6DFD8;
  COLOR_F = $D8D2CB;
  COLOR_G = $98673B;
  COLOR_H = $AB825C;
  COLOR_I = $D1D1D1;

  COLOR_T0 = $FFFFFF;
  COLOR_T1 = $7A582B;
  COLOR_T2 = $666666;

  COLOR_B0 = $FFFFFF;
  COLOR_B1 = $E6DFD8;
  COLOR_B2 = $B38F6D;
  COLOR_B3 = $98673B;
  COLOR_B4 = $D5CAC0;

  COLOR_G1 = $DFF6D8;
  COLOR_G2 = $8FB36D;
  COLOR_G3 = $67983B;

  COLOR_WINDOW = $FAF3EE;

// default control
  CONTROL_WINDOW    = COLOR_0;
  CONTROL_BORDER    = COLOR_6;
// border
  BORDER_DEFAULT    = COLOR_B4;
  BORDER_ACTIVE     = $BEEDF5;
// caption
  CAPTION_ACTIVE    = COLOR_1;
  CAPTION_INACTIVE  = $C2B6AA;//COLOR_2;
  CAPTION_BORDER    = COLOR_3;
  CAPTION_TEXT      = COLOR_0;
  CAPTION_SHADOW    = COLOR_8;
  CAPTION_TOP       = COLOR_9;
  CAPTION_BOTTOM    = COLOR_A;
// button
  BUTTON_WINDOW     = COLOR_1;
  BUTTON_HOVER      = $8E6336;
  BUTTON_BORDER     = $C6B19A;
// edit
  EDIT_WINDOW       = COLOR_0;
  EDIT_BORDER       = COLOR_6;
  EDIT_ACTIVE       = $1898FF;
  EDIT_SELECT       = $FFCF9C;
// scroll
  SCROLL_BAR        = BUTTON_WINDOW;
  SCROLL_BAR_HOVER  = BUTTON_HOVER;
  SCROLL_BAR_BORDER = BUTTON_BORDER;
// info
  INFO_AVATAR_SIZE  = 50;
  INFO_BORDER       = COLOR_6;
  INFO_AVATAR       = COLOR_0;
// popup
  POPUP_WINDOW        = $F7F7F7;
  POPUP_BORDER        = $8E6336;
  POPUP_TEXT          = $7A582B;
  POPUP_OVER          = $E8E2DA;
  POPUP_OVER_BORDER   = POPUP_OVER;
  POPUP_OVER_TEXT     = POPUP_TEXT;
  POPUP_SELECT        = $B38F6D;
  POPUP_SELECT_BORDER = $98673B;
  POPUP_SELECT_TEXT   = $FFFFFF;
  POPUP_SEPARATOR     = $E8E2DA;

  POPUP_SIZE_ITEM     = 20;

  MEDIA_OVER          = $D2F5FF;

// roster
  ROSTER_SIZE_GROUP     = 20;
  ROSTER_SIZE_CONTACT   = 26;
  ROSTER_SIZE_SEPARATOR = 4;

  ROSTER_WINDOW                  = COLOR_0;
  ROSTER_BORDER                  = COLOR_6;

  ROSTER_GROUP                   = $E2D6C7;
  ROSTER_GROUP_BORDER            = $D6BDB1;
  ROSTER_GROUP_TEXT              = $8E6845;

  ROSTER_GROUP_FOLD              = $EEEEEE;
  ROSTER_GROUP_FOLD_BORDER       = $CCCCCC;
  ROSTER_GROUP_FOLD_TEXT         = $888888;

  ROSTER_CONTACT_TEXT            = $7A582B;

  ROSTER_CONTACT_ACTIVE          = $C3F5FF;
  ROSTER_CONTACT_ACTIVE_TEXT     = $000000;

  ROSTER_CONTACT_SELECT          = $8E6336;
  ROSTER_CONTACT_SELECT_TEXT     = $FFFFFF;

  ROSTER_CONTACT_OVER            = $D2F5FF;
  ROSTER_CONTACT_OVER_TEXT       = $34474C;

  ROSTER_CONTACT_AVATAR          = $FAFAFA;
  ROSTER_CONTACT_AVATAR_BORDER   = $D5CAC0;

  ROSTER_ICON_SIZE  = 20;
  WINDOW_MIN_WIDTH  = 480;
  WINDOW_MIN_HEIGHT = 320;
//  WINDOW_MIN_FOLDED =

  ITEM_AUDIO_HEIGHT = 22;
  ITEM_AUDIO_TRACK  = 16;

var
  VK_CLUB : WideString = '19132165';
  VK_HOST : AnsiString = 'vk.com';
  VK_URL  : WideString;// = 'http://' + VK_HOST + '/';
  VKAPI_HOST  : AnsiString;// = 'api.' + VK_HOST;

  TOKEN_HTTP  : WideString;
  TOKEN_FTP   : WideString;
  TOKEN_HTTPS : WideString;

  AppPath : WideString;
  RootDir : WideString;

  Font_Tahoma_10  : TFont;
  Font_Tahoma_11  : TFont;
  Font_Tahoma_11b : TFont;
  Font_Tahoma_13  : TFont;
  Font_Tahoma_13b : TFont;

  Cursors : array [TCursorType] of TCursor;

  AppWindow : TAppWindow;
  Window  : TWindow;
  Logon   : TLogon;
  DCanvas : TCanvas;
  Roster  : TRoster;
  RFrame  : TControl;
  RTools  : TRosterTools;
  Frame   : TControl;
  Info      : TInfo;
  InfoThumb : TInfoThumb;
  History : THistory;
  Edit    : TEdit;
  Tools   : TControl;
  Media   : TMedia;
  MFrame  : TMediaFrame;
  Status  : TStatusFrame;
  Player  : TPlayer;
//  VChat   : TVideoChat;
  InfoHint : TInfoHint;
  Hint     : THint;
  Flash    : TFlash;
  PopupMan : TPopupMan;

  LastFM   : TLastFM;

  BtnCfgSend, BtnCfgSound, BtnCfgPopup : TButton;

  RSplitter : TSplitter;
  HSplitter : TSplitter;

//  Net  : TNet;
  HTTP : THTTP;
  vk : TVK;

  UnixTimeStart  : LongWord;
  UnixTimeOffset : LongWord;

  Screen : TSize;
  TimerUpdate : LongWord;
  TimerAlive  : LongWord;

// Icons
type
  TIconType = (itOnline, itOffline, itTyping, itMessage);

  TConfig = class
  private
    Param : record
        Sound       : Boolean;
        Popup       : Boolean;
        SimpleSend  : Boolean;
        PlayMode    : TPlayerMode;
        PlayVolume  : LongInt;
        FrameWidth  : LongInt;
        EditTop     : LongInt;
        EditHeight  : LongInt;
        RosterLeft  : LongInt;
        RosterWidth : LongInt;
        WindowSize  : TSize;
      end;
    procedure SetSound(const Value: Boolean);
    procedure SetPopup(const Value: Boolean);
    procedure SetSimpleSend(const Value: Boolean);
  public
    procedure Load;
    procedure Save;
    property Sound: Boolean read Param.Sound write SetSound;
    property Popup: Boolean read Param.Popup write SetPopup;
    property SimpleSend: Boolean read Param.SimpleSend write SetSimpleSend;
  end;

var
  ImgBase   : TImage;
  ImgMood   : TImage;
  ImgSmile  : TImage;
  ImgFilter : TImage;

  Icon : array [TIconType] of TIcon;

  Config : TConfig;

  KeepAliveTick : LongInt = 0;

// Language specific
type
  TLangMsg = (lmNone,
              lmErrorFlash, lmQuestClose,
              lmLogonWnd, lmLoginBtn, lmGroupActive, lmGroupDefault, lmGroupSearch, lmSend,
              lmMultiMsg,
            // quest
              lmOK,
              lmYes,
              lmNo,
              lmCancel,
              lmContinue,
            // update
              lmUpdateHead, lmUpdateQuest, lmUpdateProcess, lmUpdateReady, lmUpdateError, lmUpdateCheck,
            // logon
              lmAcceptNote, lmAboutLastFM, lmName, lmMail, lmPass, lmProxy,
              lmCaptcha, lmExpire, lmAutoStart,
            // errors
              lmErrorLogin, lmErrorConnect, lmErrorAttempts, lmErrorProxy,
            // date
              lmMJan, lmMFeb, lmMMar, lmMApr, lmMMay, lmMJun, lmMJul, lmMAug, lmMSep, lmMOct, lmMNov, lmMDec,
            // media
              lmAudio, lmMyPhoto, lmMyAudio, lmMyVideo, lmMyRecs,
              lmPlayPrev,
              lmPlayNext,
              lmModeNormal,
              lmModeRepeat,
              lmModeShuffle,
              lmMediaRefresh,
              lmMediaSearch,
              lmMediaClose,
            // main hints
              lmHintClose, lmHintMinimize, lmHintSoundOn, lmHintSoundOff, lmHintPopupOn, lmHintPopupOff,
              lmHintDialogClose, lmHintDialogInvite,
            // logon hints
              lmHintExpire, lmHintAutoStart, lmHintSetup, lmHintAbout,
            // roster hints
              lmHintMyPage, lmHintMyPhoto, lmHintMyAudio, lmHintMyVideo, lmHintMyNotes, lmHintMyStatus,
            // info hints
              lmHintUserPage, lmHintUserPhoto, lmHintUserAudio, lmHintUserVideo, lmHintUserNotes,
            // tool hints
              lmHintSendPhoto, lmHintSendAudio, lmHintSendVideo,
              lmHintSendEnter, lmHintSendCtrlEnter,
              lmHintKeySwitch,
            // media hints
              lmHintMedia,
              lmHintMediaModeNormal, lmHintMediaModeRepeat, lmHintMediaModeShuffle,
              lmHintMediaPrev, lmHintMediaNext,
              lmHintMediaAdd, lmHintMediaDel, lmHintMediaSend, lmHintMediaSite,
            // popup window
              lmPopupReply, lmPopupSend
            );
var
  LangMsg : array [TLangMsg] of WideString = ('',
     'Для корректной работы приложения, необходима установка Flash Player for Internet Explorer 32-bit!'#13'Скачать?',
     'Вы действительно хотите закрыть приложение?',
     'Авторизация',
     'Вход',
     'активные',
     'общая',
     'поиск',
     'Отправить',
     'Рассылка',
   // quest
     'OK',
     'Да',
     'Нет',
     'Отмена',
     'Продолжить',
   // update
     'Обновление',
     'Доступна новая версия, обновить?',
     'Идёт обновление программы...',
     'Обновление завершено!',
     'Не удалось обновить программу, узнать почему?',
     'Проверка обновлений',
   // logon
     '* Приложение получит доступ к личным данным и сообщениям.',
     'Информация о прослушиваемом музыкальном треке будет передаваться на специальный сервер, который формирует список рекомендуемых исполнителей согласно Вашим музыкальным предпочтениям.' + ' Данная возможность является абсолютно бесплатной, но требует регистрации на сайте Last.fm',
     'Имя:',
     'E-mail:',
     'Пароль:',
     'Прокси:',
     'Введите код с картинки:',
     'Чужой компьютер',
     'Автозагрузка',
   // errors
     'Неверный e-mail или пароль',
     'Ошибка подключения',
     'Попробуйте через минуту',
     'Ошибка подключения к прокси',
   // date
     'января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
   // media
     'Аудиозаписи',
     'Мои Фотографии', 'Мои Аудиозаписи', 'Мои Видеозаписи', 'Рекомендуемые',
     'Предыдущая',
     'Следующая',
     'Последовательно',
     'Повторять',
     'Случайно',
     'Обновить список',
     'Поиск',
     'Закрыть список',
   // main hints
     'Закрыть',
     'Свернуть',
     'Звук включен',
     'Звук выключен',
     'Показывать всплывающие окна',
     'Всплывающие окна отключены',
     'Закрыть диалог',
     'Отправить приглашение',
   // logon hints
     'Не сохранять пароль на этом компьютере',
     'Запуск программы при старте компьютера',
     'Настройки подключения',
     'Группа техподдержки',
   // roster hints
     'Моя Страница',
     'Мои Фотографии',
     'Мои Аудиозаписи',
     'Мои Видеозаписи',
     'Мои Заметки',
     'Мой Статус',
   // info hints
     'Страница пользователя',
     'Фотографии пользователя',
     'Аудиозаписи пользователя',
     'Видеозаписи пользователя',
     'Заметки пользователя',
   // tool hints
     'Передать фотографию',
     'Передать аудиозапись',
     'Передать видеозапись',
     'Отправка по Enter',
     'Отправка по Ctrl + Enter',
     'Исправить раскладку (Ctrl + R)',
   // media hint
     'Текущий плейлист',
     'Поочерёдно',
     'Повторять',
     'Случайно',
     'Предыдущая (Ctrl + Alt + Вверх)',
     'Следующая (Ctrl + Alt + Вниз)',
     'Добавить себе',
     'Удалить',
     'Отправить',
     'Перейти на страницу',
   // popup window
     'Ответить',
     'Отправить'
   );

  StatusText : array [0..92] of WideString = (
    '[нет]', 'дома', 'глажу', 'в магазине', 'уборка', 'готовлю', 'ремонтирую',
    'мою посуду', 'стираю', 'выгуливаю собаку', 'киска', 'белочка', 'зайка',
    'напитки', 'пиво', 'кофе', 'газировка', 'гамбургер', 'обед', 'фастфуд',
    'качаюсь', 'кручу педали', 'танцую', 'гуляю', 'бильярд', 'баскетбол',
    'футбол', 'рыбалка', 'тону', 'химичу', 'уход за собой', 'стрижка',
    'макияж', 'купаюсь', 'шоппинг', 'День рождения!', 'Новый Год!', 'веселюсь',
    'рисую', 'квадрат Малевича', 'играю на клавишах', 'играю на гитаре',
    'крутой', 'играю', 'кино', 'аниме', 'ня!', 'удача', 'сплю', 'ночь',
    'радуга', 'работаю', 'перекур', 'работаю', 'на встрече', 'кодинг', 'деньги',
    'сотовый', 'звоню', 'читаю', 'учусь', 'думаю', 'жопа', 'молюсь', 'бомба',
    'пришельцы', 'в туалете', 'нирвана', 'радиация', 'умер', 'напуган', 'музыка',
    'хитрый', 'флирт', 'псих', 'влюблён', 'любовь', 'клубничка', 'секс',
    'несчастная любовь', 'грустный', 'болею', 'злой', 'вышел', 'коммандировка',
    'путешествие', 'уехал', 'улетел', 'отдыхаю', 'дразнюсь', 'устал', 'насторожен', 'бес');
  SmileTag : array [0..31] of WideString = (
    ':-)', ';-)', ':-D', ':-[', ':-P', '^_^', ':-]', '%-)',
    ':-(', ':''(', '<-(', '<:-(', ':-\', '-_-', '8-)', ':-X',
    ':-@', ':-o', '8-]', ':-O', ':-S', '<_<', ':-|', ':->',
    '<3', ':-?', ':~[', ':-!', '<:-[', ':-=', 'x_o', '[:-]'
  );

  function ReplaceMediaTags(const Text: WideString): WideString;
  procedure InitGlobal;
  procedure FreeGlobal;
  function SendMessage(const Text: WideString; User: TUser; const Attach: WideString = ''): Boolean;
  procedure MediaUpdate;
  procedure MediaSwitch(MediaType: TMediaType; const UID: WideString);
  procedure MediaClose;
  procedure Activate_Logon;
  procedure Activate_Roster;
  function CreateButton(Parent: TControl; ImageIdx, Left, Top, ID: LongInt; EventProc: TEventProc; Hint: TLangMsg = lmNone): TButton;

implementation
uses
  jxml;

const
  EDIT_SEND  = 0;
  BTN_SEND   = 1;
  BTN_PHOTO  = 4;
  BTN_AUDIO  = 5;
  BTN_VIDEO  = 6;
  BTN_ENTER  = 7;
  BTN_SWITCH = 8;
  BTN_SOUND  = 9;
  BTN_POPUP  = 10;

{$REGION 'Common'}
function ReplaceMediaTag(const Text: WideString; Pos: LongInt): WideString;
var
  Tag, Link : WideString;
  i, j : LongInt;
begin
  Result := Text;
  i := PosEx(Pos + 5, ']]', Result);
  if i = 0 then
    Exit;
  Tag := Copy(Result, Pos + 5, 5);
  if (Tag = 'photo') or (Tag = 'video') or (Tag = 'audio') then
    Link := Copy(Text, Pos + 5, i - Pos - 5)
  else
    Exit;

  if Tag = 'audio' then
  begin
    j := System.Pos(WideString('_'), Link); // ^___^
    if j = 0 then
      Exit;
  // fast govnocode
    Link[1] := 'A';
    Tag[1]  := 'A';
    Link[j] := '^';
  // :D
    Link := ReplaceStr(Link, Tag, 'audio.php?id=');
    Link := ReplaceStr(Link, '^', '&audio_id=');
  end;
  Delete(Result, Pos, i + 2 - Pos);
  if Pos = 1 then
    Insert(VK_URL + Link, Result, Pos)
  else
    Insert(' ' + VK_URL + Link, Result, Pos);
end;

function ReplaceMediaTags(const Text: WideString): WideString;
const
  TAG : WideString = '<*>[[';
var
  i : LongInt;
begin
  Result := Text;
  i := Pos(TAG, Result);
  while i > 0 do
  begin
    Result := ReplaceMediaTag(Result, i);
    i := Pos(TAG, Result);
  end;
end;
{$ENDREGION}

{$REGION 'Timers'}
procedure UpdateInfo;
begin
  Roster.Update;
  Status.Update;
  LastFM.Update;
  if KeepAliveTick > 0 then
    Dec(KeepAliveTick)
  else
    if Roster.Online then
    begin
      vk.Query([], 'activity.online', 0, nil);
      KeepAliveTick := 10 * 60 - 5; // one send per 10 min (9:55)
    end;
//  Writeln(Length(Roster.Users));
end;
{$ENDREGION}

{$REGION 'TConfig'}
procedure TConfig.Load;
var
  Stream : TFileStream;
  i, g  : LongInt;
  Group : TGroup;
  Flag  : Byte;
begin
  Stream := TFileStream.Create(RootDir + vk.mid + '.cfg', fmRead);
  if (not Stream.Valid) or (Stream.ReadInt32 <> CONFIG_VERSION) then
  begin
    Param.Sound      := True;
    Param.Popup      := True;
    Param.SimpleSend := False;
  end else
  begin
    Stream.Read(Param, SizeOf(Param));
    g := Stream.ReadInt32;
    for i := 0 to g - 1 do
    begin
      Flag := Stream.ReadUInt8;
      Group := Roster.GetGroupByGID(Stream.ReadStr, False);
      if Group <> nil then
      begin
        Group.Folded := Flag and 1 > 0;
        Group.Filter := Flag and 2 > 0;
      end;
    end;
    Window.Folded := True;

    Player.Mode       := Param.PlayMode;
    Player.Volume     := Param.PlayVolume;
    Edit.Size.Top     := Param.EditTop;
    Edit.Size.Height  := Param.EditHeight;
    Frame.ASize.Width := Param.FrameWidth;
    RFrame.Size.Left  := Param.RosterLeft;
    RFrame.Size.Width := Param.RosterWidth;
    UpdateScreen;
    with Param.WindowSize do
    begin
      if Left + Width > Screen.Left + Screen.Width then
        Dec(Left, Left + Width - Screen.Left - Screen.Width);
      if Top + 320 > Screen.Top + Screen.Height then
        Dec(Top, Top + 320 - Screen.Top - Screen.Height);
      Window.Move(Left, Top, Width, Height);
      Window.Resize;
    end;
  end;
  Stream.Free;

  Sound      := Param.Sound;
  Popup      := Param.Popup;
  SimpleSend := Param.SimpleSend;
end;

procedure TConfig.Save;
var
  Stream : TFileStream;
  i : LongInt;
  Flag : Byte;
begin
  Stream := TFileStream.Create(RootDir + vk.mid + '.cfg', fmWrite);
  if Stream.Valid then
  begin
    MediaClose;
    Window.Folded := True;
    Param.PlayMode    := Player.Mode;
    Param.PlayVolume  := Player.Volume;
    Param.EditTop     := Edit.Size.Top;
    Param.EditHeight  := Edit.Size.Height;
    Param.FrameWidth  := Frame.ASize.Width;
    Param.RosterLeft  := RFrame.Size.Left;
    Param.RosterWidth := RFrame.Size.Width;
    with Window.ScreenRect do
      Param.WindowSize := SetSize(Left, Top, Right - Left, Bottom - Top);
    Stream.WriteInt32(CONFIG_VERSION);
    Stream.Write(Param, SizeOf(Param));
    Stream.WriteInt32(Length(Roster.Groups));
    for i := 0 to Length(Roster.Groups) - 1 do
    begin
      Flag := 0;
      if Roster.Groups[i].Folded then Flag := Flag or 1;
      if Roster.Groups[i].Filter then Flag := Flag or 2;
      Stream.Write(Flag, SizeOf(Flag));
      Stream.WriteStr(Roster.Groups[i].GID);
    end;
  end;
  Stream.Free;
end;

procedure TConfig.SetSound(const Value: Boolean);
begin
  Param.Sound := Value;
  with BtnCfgSound do
    if Sound then
    begin
      ImageIdx := 0;
      Hint := LangMsg[lmHintSoundOn];
    end else
    begin
      ImageIdx := 1;
      Hint := LangMsg[lmHintSoundOff];
    end;
end;

procedure TConfig.SetPopup(const Value: Boolean);
begin
  Param.Popup := Value;
  with BtnCfgPopup do
    if Popup then
    begin
      ImageIdx := 4;
      Hint := LangMsg[lmHintPopupOn];
    end else
    begin
      ImageIdx := 5;
      Hint := LangMsg[lmHintPopupOff];
    end;
end;

procedure TConfig.SetSimpleSend(const Value: Boolean);
begin
  Param.SimpleSend := Value;
  with BtnCfgSend do
    if SimpleSend then
    begin
      ImageCom := -1;
      Hint := LangMsg[lmHintSendEnter];
    end else
    begin
      ImageCom := 22;
      Hint := LangMsg[lmHintSendCtrlEnter];
    end;
end;
{$ENDREGION}

{$REGION 'Events'}
(*
procedure KeepAlive;
begin
  if not Net.Connected then
  begin
    if vk.ResReady then
    begin
      vk.ResProc  := TVKResProc(@VKDefProc);
      vk.ResReady := False;
      vk.TryLogin('', '');
    end;
  end else
    XMPP.Write(' ');
end;

procedure OnNetStatus(Net: TNet; NetStatus: TNetStatus; const Msg: WideString = '');
begin
  case NetStatus of
    nsConnect    :
      begin
      {$IFDEF DEBUG}
        Writeln('Connected');
      {$ENDIF}
        XMPP.Hello;
      end;
    nsDisconnect, nsError, nsErrorProxy :
      begin
      {$IFDEF DEBUG}
        if NetStatus in [nsError, nsErrorProxy] then
          Writeln('Error: ', Ord(NetStatus))
        else
          Writeln('Disconnected');
      {$ENDIF}
        XMPP.QueryFreeAll;
        vk.QueryFreeAll;
        Roster.Online := False;
        vk.ResReady := True;
      end;
  end;
end;

procedure OnNetReceive(Net: TNet);
begin
  XMPP.Process;
end;
*)

procedure MediaUpdate;
var
  i : LongInt;
begin
  if MFrame.Visible then
    if Length(Info.Users) = 1 then
      MFrame.Move(8, 65, -14, -1 - 8 - 65 - 28)
    else
      MFrame.Move(8,  8, -14, -1 - 8 -  8 - 28);
  Window.Folded := (not MFrame.Visible) and (Length(Info.Users) <> 1);
  Info.Visible  := (not MFrame.Visible) or (Length(Info.Users) = 1);
// hide/show tool panel buttons
  with Tools do
    for i := 0 to Length(Controls) - 1 do
      Controls[i].Visible := (not MFrame.Visible) or (Controls[i].ID in [BTN_PHOTO, BTN_AUDIO, BTN_VIDEO]);

  History.Visible   := not MFrame.Visible;
  Edit.Visible      := not MFrame.Visible;
  HSplitter.Visible := not MFrame.Visible;

  if not Window.Folded then
    Frame.Resize;
end;

procedure MediaSwitch(MediaType: TMediaType; const UID: WideString);
var
  usr : TUser;
begin
// second clock to close media
  if MFrame.Visible and (Media.CurMedia = MediaType) then
    if (MediaType <> mtAudio) or (Media.PlayList.Name = UID) then
    begin
      MediaClose;
      Exit;
    end;

// ... or open media
  if MediaType = mtAudio then
    Media.PlayList := Player.PlayList[UID];

  MFrame.SearchBar(False);//MediaType in [mtAudio, mtVideo]);

  MFrame.Resize;
  Media.CurMedia := MediaType;
  if (MediaType = mtAudio) and (UID <> Roster.OwnerUser.UID) then
  begin
    usr := Roster.GetUserByUID(UID, False);
    if usr <> nil then
      MFrame.Text := LangMsg[lmAudio] + ' (' + usr.Name + ')'
    else
      MFrame.Text := LangMsg[lmAudio] + ' (' + UID + ')'
  end else
    MFrame.Text := LangMsg[TLangMsg(Ord(lmMyPhoto) + Ord(Media.CurMedia))];

  MFrame.Visible := True;
  MediaUpdate;
end;

procedure MediaClose;
begin
  if MFrame.Visible then
  begin
    MFrame.Visible := False;
    MediaUpdate;
    Roster.GetSelected;
  end;
end;

function WndEvent(Control: TEdit; const Event: TControlEvent): Boolean;
begin
  Result := False;
  case Event.ID of
    etFold :
      with Event.Fold do
      begin
        if Fold then
        begin
          MediaClose;
          with Size^ do
          begin
            Window.MinSize := SetSize(0, 0, 211, 320);
            Size^ := SetSize(Left + Frame.Width - 3, Top, Width - Frame.Width + 3, Height);
          end;
          RFrame.Move(8, 0, -12, -1);
          Window.Focus := Window;
        end else
        begin
          with Size^ do
          begin
            Window.MinSize := SetSize(0, 0, 640, 320);
            Size^ := SetSize(Left - Frame.Width + 3, Top, Width + Frame.Width - 3, Height);
          end;
          Frame.Move(0, 0, -RFrame.Width - 9, -1);
          RFrame.Move(-RFrame.Width - 3, 0, RFrame.Width, -1);
        end;

        if not Fold then
        begin
        // history splitter
          with Edit.Size do
            HSplitter.Size := SetSize(Left + 8, Top - 4, Width - 20, 4);
          with History.Size do
            History.Move(Left, Top, Width, -170 + 64 - Edit.Height);
          HSplitter.UpdateRect;
        // roster splitter
          with RFrame.Size do
            RSplitter.Move(Left - 8, Top + 16, 4, Height - 60);
          RSplitter.UpdateRect;
        end;

        RSplitter.Visible := not Fold;
        HSplitter.Visible := not Fold;
        Frame.Visible     := not Fold;
      end;
  end;
end;

function SendMessage(const Text: WideString; User: TUser; const Attach: WideString): Boolean;
var
  Str : WideString;
  DT  : TMsgDateTime;
  Msg : PMessage;
begin
  Result := False;

  Str := TrimChars(Text, [#13, #10]);
  Str := ReplaceStr(Str, #10, #13);
  Str := ReplaceStr(Str, #13#13, #13);

  if ((Str = '') or (Str = ' ')) and (Attach = '') then
    Exit;
{
  if Sound then
    sndPlaySound(@SND_IN_DATA, SND_ASYNC or SND_MEMORY);
}
  Roster.Activate(User, False);

  DT  := MsgDateTime(vk.ServerTime);
  Msg := History.Log[User.UID].GetLastMessage;
  vk.MsgSend(User.UID, History.Log[User.UID].MsgAdd(Roster.OwnerUser, Str, Attach, DT), (Msg <> nil) and (not MsgDateCompare(DT.Date, Msg^.Date)) );

  Result := True;
end;

procedure SendEditMessage;
begin
  if SendMessage(Edit.Text, History.CurLog.User) then
    Edit.Clear;
end;

function SendEvent(Control: TControl; const Event: TControlEvent): Boolean;
begin
  Result := False;
  case Event.ID of
    etKeyUp :
      if (((Event.Key.Value = Ord('W')) and (ssCtrl in Event.Key.Shift)) or (Event.Key.Value = 27)) and (Length(Roster.Selected) > 0) then
      begin
        Roster.UnSelect;
        Roster.GetSelected;
      end else
        if (Event.Key.Value = 9) and (ssCtrl in Event.Key.Shift) then // tab
          Roster.NextActive;
    etChar :
      if (Control.ID = EDIT_SEND) and (Event.Key.Value = 13) and (Config.SimpleSend xor (ssCtrl in Event.Key.Shift)) then
      begin
        SendEditMessage;
        Result := True;
      end;
    etMouseUp :
      with Event.Mouse.Pos do
        if RectIntersect(Control.Rect, x, y) then
          case Control.ID of
            BTN_SEND   : SendEditMessage;
            BTN_PHOTO  : MediaSwitch(mtPhoto, Roster.OwnerUser.UID);
            BTN_AUDIO  : MediaSwitch(mtAudio, Roster.OwnerUser.UID);
            BTN_VIDEO  : MediaSwitch(mtVideo, Roster.OwnerUser.UID);
            BTN_SWITCH : Edit.SwitchLayout;
            BTN_ENTER  : Config.SimpleSend := not Config.SimpleSend;
            BTN_SOUND  : Config.Sound := not Config.Sound;
            BTN_POPUP  : Config.Popup := not Config.Popup;
          end;
  end;
end;
{$ENDREGION}

procedure InitGlobal;
const
{$IFDEF WIN32}
  CursorNames : array [TCursorType] of PWideChar = (
    IDC_ARROW, IDC_ARROW, IDC_HAND, IDC_IBEAM, IDC_SIZEWE, IDC_SIZENS
  );
{$ENDIF}
{$IFDEF LINUX}
  CursorNames : array [TCursorType] of PWideChar = (
    '', '', '', '', '', ''
  );
{$ENDIF}
{$IFDEF DARWIN}
  CursorNames : array [TCursorType] of PWideChar = (
    '', '', '', '', '', ''
  );
{$ENDIF}
var
  ct : TCursorType;
  it : TIconType;
  Stream : TStream;
  ImgData : PByteArray;
  Width, Height : LongInt;
  Ctrl : TControl;
  i : LongInt;

  function GetSlash: WideString;
  begin
    Result := '://';
  end;

begin
  TOKEN_HTTP  := 'ht' + 'tp' + GetSlash;
  TOKEN_FTP   := 'fp' + 'tp' + GetSlash;
  TOKEN_HTTPS := 'ht' + 'tps' + GetSlash;

  VK_URL      := TOKEN_HTTP + WideString(VK_HOST) + '/';
  VKAPI_HOST  := 'api.' + VK_HOST;

  AppPath := GetAppDir;
  RootDir := GetRootDir;

  UpdateScreen;

// fonts
  Font_Tahoma_10  := TFont.Create('Tahoma', 10);
  Font_Tahoma_11  := TFont.Create('Tahoma', 11);
  Font_Tahoma_11b := TFont.Create('Tahoma', 11, True);
  Font_Tahoma_13  := TFont.Create('Tahoma', 13);
  Font_Tahoma_13b := TFont.Create('Tahoma', 13, True);
// images
  ImgBase  := TImage.Create(@IMG_BASE_DATA, IMG_BASE_SIZE);
  ImgMood  := TImage.Create(@IMG_MOOD_DATA, IMG_MOOD_SIZE);
  ImgSmile := TImage.Create(@IMG_SMILE_DATA, IMG_SMILE_SIZE);

  ImgData := GetMemory(20 * 20 * 4);
  for i := 0 to 20 * 20 - 1 do
    PLongArray(ImgData)^[i] := $FF800000;
  ImgFilter := TImage.Create(ImgData, 20, 20);
  FreeMemory(ImgData);
// icons
  Stream := TMemoryStream.Create(@IMG_ICON_DATA, IMG_ICON_SIZE);
  if LoadIMG(Stream, ImgData, Width, Height) then
  begin
    for it := Low(Icon) to High(Icon) do
    begin
      Icon[it] := TIcon.Create(ImgData, 0, (Ord(High(it)) - Ord(it) + 1) * 32, 32);
      Icon[it].Small := TIcon.Create(ImgData, Ord(it) div 2 * 16, (1 + Ord(it)) mod 2 * 16, 16);
    end;
    FreeMemory(ImgData);
  end;
  Stream.Free;

// cursors
  for ct := Low(ct) to High(ct) do
    Cursors[ct] := TCursor.Create(CursorNames[ct]);

// main window
  AppWindow := TAppWindow.Create;

  InfoThumb := TInfoThumb.Create(AppWindow);
  InfoThumb.Move(0, 0, -1, -1);

  Window := TWindow.Create(AppWindow);
  Window.EventProc := TEventProc(@WndEvent);
  Hint := Window.HintWnd;
  DCanvas := Window.Canvas;
  Window.Frame.Color := COLOR_WINDOW;

  AppWindow.Icon := Icon[itOnline];
  AppWindow.Move(100, -1000, 200, 100);
  Status := TStatusFrame.Create;
// network
  NetInit;
  HTTP := THTTP.Create;
  vk := TVK.Create;
{
  Net := TNet.Create;
  Net.OnStatus  := TOnNetStatus(@OnNetStatus);
  Net.OnReceive := TOnNetEvent(@OnNetReceive);
  XMPP := TXMPP.Create(Net);
  XMPP.Host := 'vkmessenger.com';
  Net.Data := XMPP;
  Net.Host := AnsiString(XMPP.Host);
  Net.Port := 5222;
}
// flash object
  Flash := TFlash.Create(Window.Frame);
  Flash.Load(@SWF_MAIN_DATA, SWF_MAIN_SIZE);
  Flash.Move(0, 0, 0, 0);
// logon
  Logon := TLogon.Create(Window.Frame);
  Logon.Move(0, 0, -1, -1);
// roster
  RFrame := TControl.Create(Window.Frame);
  RFrame.Move(-200, 0, 192, -1);

  Roster := TRoster.Create(RFrame);
  Roster.VScroll.Step := ROSTER_SIZE_CONTACT;
  Roster.Move(0, 8, -1, -45);

  RTools := TRosterTools.Create(RFrame);
  RTools.Move(0, -29, -1, 28);

  Player := TPlayer.Create(RTools);
  Player.Move(-105, -25, 99, 16);

// frame
  Frame := TControl.Create(Window.Frame);
  Frame.Move(0, 0, -200, -1);

  Info := TInfo.Create(Frame);
  Info.Move(8, 8, -10, 54);

  History := THistory.Create(Frame);
  History.Move(8, 65, -14, -1 - 8 - 99 - 57 - 5);
{
  VChat := TVideoChat.Create(History);
  VChat.Move(-History.VScroll.Width - 321, 1, 320, 240);
}
  Edit := TEdit.Create(Frame);
  Edit.Move(8, -100, -14, 64);
  Edit.EventProc := TEventProc(@SendEvent);
  Edit.ID        := EDIT_SEND;
  Edit.Highlight := False;
  Edit.Tabulate  := True;
//  Edit.HoldFocus := True;
  MFrame := TMediaFrame.Create(Frame);
  MFrame.Move(8, 65, -14, -1 - 8 - 65 - 28);
  MFrame.Visible := False;

  Media := MFrame.Media;

  Tools := TControl.Create(Frame);
  Tools.Move(12, -32, -22, 24);

  RSplitter := TSplitter.Create(Window.Frame);
  with RSplitter do
  begin
    Visible := False;
    Move(-204, 8 + 65, 4, -45 - 65 - 8);
    Ctrl[0] := Frame;
    Ctrl[1] := RFrame;
    MinSize[0] := 320;
    MinSize[1] := 192;
    Vertical := True;
  end;

  HSplitter := TSplitter.Create(Frame);
  with HSplitter do
  begin
    Visible  := False;
    Move(16, -104, -35, 4);
    Ctrl[0] := History;
    Ctrl[1] := Edit;
    MinSize[0] := 128;
    MinSize[1] := 20;
    Vertical := False;
  end;

// send content btn
  for i := 0 to 2 do
    CreateButton(Tools, 7 + i, 24 * i, 4, BTN_PHOTO + i, TEventProc(@SendEvent), TLangMsg(Ord(lmHintSendPhoto) + i)).ImageCom := 20;

// send btn
  Ctrl := TButton.Create(Tools, nil, 0);
  Ctrl.Text := LangMsg[lmSend];
  Ctrl.ID   := BTN_SEND;
  Ctrl.EventProc := TEventProc(@SendEvent);
  Ctrl.Move(-97, 0, 96, 24);

  CreateButton(Tools, 23, -98 - 48, 4, BTN_SWITCH, TEventProc(@SendEvent), lmHintKeySwitch);
  BtnCfgSend  := CreateButton(Tools, 21, -98 - 24, 4, BTN_ENTER,  TEventProc(@SendEvent), lmHintSendCtrlEnter);
  BtnCfgPopup := CreateButton(Tools,  4, -98 - 72, 4, BTN_POPUP,  TEventProc(@SendEvent), lmHintPopupOn);
  BtnCfgSound := CreateButton(Tools,  0, -98 - 96, 4, BTN_SOUND,  TEventProc(@SendEvent), lmHintSoundOn);

  BtnCfgSend.ImageCom := 22;

// Info hints
  InfoHint := TInfoHint.Create;
  InfoHint.Visible := True;
  InfoHint.Move(0, 0, 200, 100);

  PopupMan := TPopupMan.Create;

  LastFM := TLastFM.Create;

  Config := TConfig.Create;
  RegisterHotKeys;
  TimerUpdate := InitTimer(1000, @UpdateInfo);
//  TimerAlive  := InitTimer(10000, @KeepAlive);

{$IFNDEF FPC}
  if not Flash.Valid then
    if MessageBoxW(Window.Handle, PWideChar(LangMsg[lmErrorFlash]), nil, MB_YESNO or MB_ICONWARNING) = IDYES then
      BrowseURL('http://get.adobe.com/ru/flashplayer/otherversions/');
    //  http://aihdownload.adobe.com/bin/install_flashplayer11x32ax_aih.exe
{$ENDIF}
end;   

procedure FreeGlobal;
var
  ct : TCursorType;
  it : TIconType;
begin
  FreeTimer(TimerUpdate);
  FreeTimer(TimerAlive);
  LastFM.Free;
  PopupMan.Free;
  if RFrame.Visible then
    Config.Save;
  Config.Free;
// waiting
  Roster.Lock;
  Roster.Unlock;
  Player.CS.Lock;
  Player.CS.Unlock;
{
  if Net.Connected then
  begin
    XMPP.StatusSet(xsOffline);
    XMPP.Write('</stream:stream>');
  end;
}
  vk.Free;
  HTTP.Free;

  Window.HintWnd := Hint;
  Status.Free;
  Window.Free;
  InfoHint.Free;
  AppWindow.Free;
  for it := Low(Icon) to High(Icon) do
    Icon[it].Free;
  for ct := Low(ct) to High(ct) do
    Cursors[ct].Free;
  Font_Tahoma_10.Free;
  Font_Tahoma_11.Free;
  Font_Tahoma_11b.Free;
  Font_Tahoma_13.Free;
  Font_Tahoma_13b.Free;
  ImgBase.Free;
  ImgMood.Free;
  ImgSmile.Free;
  ImgFilter.Free;
end;

procedure Activate_Logon;
begin
  AppWindow.Visible := True;
  Logon.Visible     := True;
  Window.Visible    := False;
  RFrame.Visible    := False;
  Frame.Visible     := False;

  Window.Focus := Logon.EMail;

  Window.Move(Screen.Width div 2 - 120, Screen.Height div 2 - 130, 240, 1);
  Window.Text     := LangMsg[lmLogonWnd];
  Window.Resizing := False;
  Window.Visible  := True;
  Window.Repaint;
  Logon.ShowLogon;
  FlushMemory;
end;

procedure Activate_Roster;
begin
  AppWindow.Visible := True;
  RFrame.Visible    := True;
  Frame.Visible     := True;
  Window.Visible    := False;
  Logon.Visible     := False;
{
  Window.Folded := False;
  Window.Folded := True;
}
  Window.Move(Screen.Width div 2 - 320, Screen.Height div 2 - 240, 640, 480);
  Config.Load;
  Window.Text     := CLIENT_NAME;
  Window.Resizing := True;
  Window.Folded   := True;
  Window.Visible  := True;
  Window.Repaint;
  FlushMemory;
end;

function CreateButton(Parent: TControl; ImageIdx, Left, Top, ID: LongInt; EventProc: TEventProc; Hint: TLangMsg): TButton;
begin
  Result := TButton.Create(Parent, ImgBase, ImageIdx);
  Result.Move(Left, Top, 16, 16);
  if Hint <> lmNone then
    Result.Hint := LangMsg[Hint];
  Result.ID := ID;
  Result.EventProc := EventProc;
end;

end.
