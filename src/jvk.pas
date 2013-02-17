unit jvk;

{ TODO : check for <error_code>3</error_code> (change password) }
interface

uses
  jsys, jdata, jutils, jhash, jzip, jnet, jhttp, jroster, jhistory, jxml;

type
  TJSONArray = array of WideString;

  TQueryXMLProc = procedure (ID: Integer; XML: TXML);

  TVKQuery = record
    Method : AnsiString;
    Text   : AnsiString;
    ID     : LongInt;
    Proc   : TQueryXMLProc;
  end;

  TVKQueryArray = array of TVKQuery;

  TVKResult = (vrLogin, vrError, vrErrorProxy, vrErrorLogin, vrErrorAttempts, vrErrorCaptcha);

  TVKResProc = procedure (VKResult: TVKResult; const Param: WideString = '');

  TVK = class
    constructor Create;
    destructor Destroy; override;
  private
    CS : TCriticalSection;
    TimerQuery : LongWord;
    QueryTick : LongInt; // * 100 ms
    QueryBuf  : TVKQueryArray;
    SendTick  : LongWord;
    function QueryPush(const Method, Text: AnsiString; ID: Integer; Proc: TQueryXMLProc; First: Boolean = False): Boolean;
    function QueryPop: TVKQuery;
    function QueryFlush: Boolean;
    function GetServerTime: LongWord;
  public
    mid      : WideString;
    secret   : WideString;
    mail     : WideString;
    pass     : WideString;

    token    : AnsiString;

    ResProc  : TVKResProc;

    ListOffset : Integer;

    LongServer : AnsiString;
    LongKey    : AnsiString;
    LongTS     : AnsiString;

    procedure QueryFreeAll;
  // login / appreg / captcha / relogin etc.
    procedure OAuth(const CaptchaSID, CaptchaKey: AnsiString);
    procedure TryLogin(const CaptchaSID, CaptchaKey: AnsiString);
//    procedure TrySetup(const CaptchaSID, CaptchaKey: AnsiString);
    procedure Login;
  // vk api query
    procedure Query(const Params: array of TParam; const Method: WideString; ID: Integer; Proc: TQueryXMLProc; First: Boolean = False);
    procedure QueryHistory(const UID: WideString; Offset, Count: LongInt; ID: Integer; Proc: TQueryXMLProc; First: Boolean = False);
    procedure QueryValueGet(Key: WideString; User: TUser; Proc: TQueryXMLProc);
    procedure QueryValueSet(Value: LongInt; Key: WideString);
  // raw http query
    procedure GetCaptcha(const CSID: AnsiString; ID: Integer; Proc: TQueryProc);
    procedure GetImage(const Host, URL: AnsiString; ID: Integer; Proc: TQueryProc);
    procedure GetFile(const URL: AnsiString; ID: Integer; Proc: TQueryProc);
    procedure POST(const Host, URL, Content: AnsiString; ID: Integer; Proc: TQueryProc);
    procedure GET(const Host, URL, Content: AnsiString; ID: Integer; Proc: TQueryProc; SSL: Boolean = False);
    procedure QueryUsersInfo(const UIDs, Fields: WideString; ID: Integer; Proc: TQueryXMLProc);
    procedure QuerySelf;
    procedure QueryUsersGroup;
    procedure QueryUsersNext;
    procedure QueryUsersOnline;
    procedure QueryLongFirst;
    procedure QueryLongNext;
    procedure QueryTime;

    procedure MsgSetRead(const MIDs: WideString);
    procedure MsgGetOffline(Offset: LongInt = 0);
    procedure MsgSend(const UID: WideString; MsgLine: PMsgLine; Title: Boolean);

    property ServerTime: LongWord read GetServerTime;
  end;

  procedure VKDummyProc(VKResult: TVKResult; const Param: WideString);
  procedure VKDefProc(VKResult: TVKResult; const Param: WideString);

implementation

uses
  jglobal, jlogon;

const
  LOGIN_CAPTCHA = 0;
  LOGIN_USER    = 1;
  LOGIN_DESKTOP = 2;

  USER_SELF    = 0;
  USER_GROUP   = 1;
  USER_LIST    = 2;
  USER_ONLINE  = 3;
  LONG_START   = 4;
  LONG_NEXT    = 5;
  SERVER_TIME  = 6;

  MSG_OFFLINE  = 7;
  MSG_SEND     = 8;

  QUERY_MAX_TICK = 5;
  QUERY_MAX_USERS = 200;
  SEND_MAX_TICK  = 5000; // ms

{$REGION 'JSON'}
function JSON_Value(const Text, Param: WideString): WideString;
var
  b, i, br : LongInt;
  TextFlag, NextFlag : Boolean;
begin
  Result := '';
  b := Pos('"' + Param + '":', Text);
  if b > 0 then
  begin
    TextFlag := False;
    NextFlag := False;
    br := 0;
    b := b + Length(Param) + 3;
    for i := b to Length(Text) do
      if NextFlag then
        NextFlag := False
      else
        case Text[i] of
          '[' : if not TextFlag then Inc(br);
          ']' : if not TextFlag then Dec(br);
          '\' : NextFlag := True;
          '"' : TextFlag := not TextFlag;
        else
          if (not TextFlag) and (br = 0) and ((Text[i] = ',') or (Text[i] = '}')) then
          begin
            Result := TrimChars(Copy(Text, b, i - b), ['"', '''']);
            break;
          end;
        end;
  end;
end;

function JSON_NoSlash(const Text: WideString): WideString;
var
  i : LongInt;
begin
  Result := Text;
  if Result <> '' then
  begin
    i := 1;
    while i <= Length(Result) do
    begin
      if Result[i] = '\' then
        Delete(Result, i, 1);
      Inc(i);
    end;
  end;
end;

function JSON_Array(const Text: WideString): TJSONArray;
var
  i, b, br : LongInt;
  TextFlag, NextFlag : Boolean;
begin
  Result := nil;
  if (Text = '') or (Text = '[]') then
    Exit;
  TextFlag := False;
  NextFlag := False;
  br := 0;
  b  := 1;
  for i := b to Length(Text) do
    if NextFlag then
      NextFlag := False
    else
      case Text[i] of
        '"' : TextFlag := not TextFlag;
        '\' : NextFlag := True;
        else
          if not TextFlag then
            case Text[i] of
              '[', ']', ',' :
                begin
                  if br <= 1 then
                  begin
                    if (i - b > 0) then
                    begin
                      SetLength(Result, Length(Result) + 1);
                      Result[Length(Result) - 1] := Copy(Text, b, i - b);
                    end;
                    b := i + Ord((Text[i] = ',') or (br = 0));
                  end;
                  if Text[i] = '[' then Inc(br);
                  if Text[i] = ']' then Dec(br);
                end;
            end;
      end;
end;
{$ENDREGION}

{$REGION 'Proc'}
procedure VKProc(ID: Integer; const Header: AnsiString; const Content: WideString; XMLProc: TQueryXMLProc; RawData: Pointer; RawSize: LongInt);
var
  XML, x : TXML;
begin
  x := nil;
  XML := nil;
  if Content <> '' then
  begin
    XML := TXML.Create(Content, 1);
    if XML.DataLen > 0 then
      if XML.Tag = 'response' then
        x := XML
      else
        if XML.Tag = 'error' then
        begin
        {$IFDEF DEBUG}
          Writeln(Content);
        {$ENDIF}
          case Conv(XML.Value['error_code'], 0) of
          // Unknown method passed
            3  : Roster.Online := False;
          // User authorization failed
            5  : Roster.Online := False; // { TODO : relogin}
          // Captcha is needed
            14 : ; // captcha
          end;
        end;
  end;
  if @XMLProc <> nil then
    XMLProc(ID, x);
  if XML <> nil then
    XML.Free;
end;

procedure VKBaseProc(ID: Integer; XML: TXML);
var
  i : LongInt;
  usr : TUser;
  Flag : Boolean;
{
  MsgMID  : LongWord;
  MsgTime : TMsgDateTime;
  MsgLine : PMsgLine;
}
begin
  if XML = nil then // error query response
  begin
    Roster.Online := False;
    Wait(5000);
    case ID of
      USER_SELF  : vk.QuerySelf;
      USER_GROUP : vk.QueryUsersGroup;
      USER_LIST  : vk.QueryUsersNext;
    else
      vk.QueryUsersOnline;
    end;
    Exit;
  end;

  case ID of
    USER_SELF  :
      begin
        if XML['user'] <> nil then
          with XML['user'] do
            Roster.OwnerUser.Name := Value['first_name'] + ' ' + Value['last_name'];
        vk.QueryUsersGroup;
      end;
    USER_GROUP : // friends.getLists
      begin
        {$IFDEF DEBUG}Writeln('get groups');{$ENDIF}
        Roster.BeginUpdate;
        for i := 0 to XML.Count - 1 do
          with XML.NodeI[i] do
            Roster.AddGroup(Value['lid']).Name := SpecToChar(Value['name']);
        Roster.EndUpdate;
//        vk.ListOffset := 1285;
        vk.QueryUsersNext;
      end;
    USER_LIST : // friends.get
      begin
        Roster.BeginUpdate;
        for i := 0 to XML.Count - 1 do
          Roster.AddUser(XML.NodeI[i]);
        Roster.EndUpdate;

        Inc(vk.ListOffset, XML.Count);
        {$IFDEF DEBUG}Writeln('--------- ', XML.Count, #9, vk.ListOffset, #9, Length(Roster.Users));{$ENDIF}
        if XML.Count = 0 then
        begin
          Activate_Roster;
          vk.QueryUsersOnline;
        end else
          vk.QueryUsersNext;
      end;
    USER_ONLINE :
      begin
        Roster.BeginUpdate;
        for i := 0 to XML.Count - 1 do
          Roster.GetUserByUID(XML.NodeI[i].Content, True).Online := True;
        Roster.EndUpdate;
        Roster.LoadInfo;
        Roster.Online := True;
        Roster.Sort;
        vk.QueryLongFirst;
        vk.MsgGetOffline(0);
        vk.QueryTime;
        Player.List := Player.PlayList[Roster.OwnerUser.UID];
        Status.FirstCheck;
      end;
    LONG_START : // messages.getLongPollServer
      begin
        vk.LongServer := AnsiString(XML['server'].Content);
        vk.LongKey    := AnsiString(XML['key'].Content);
        vk.LongTS     := AnsiString(XML['ts'].Content);
        vk.QueryLongNext;
      end;
    SERVER_TIME :
      begin
        UnixTimeOffset := Conv(XML.Content, 0);
        UnixTimeStart  := GetTime div 1000;
      end;
    MSG_OFFLINE :
      begin
        Flag := False;
        for i := XML.Count - 1 downto 0 do
          with XML.NodeI[i] do
            if Tag = 'message' then
            begin
              usr := Roster.GetUserByUID(Value['uid'], True);
              if History.FindLog(usr.UID) <> nil then // no log - no add
              begin
                History.Log[usr.UID].MsgAdd(XML.NodeI[i]);
              {
                MsgMID  := Conv(Value['mid'], 0);
              // add new message?
                MsgLine := History.Log[usr.UID].MsgLine[MsgMID];
                if MsgLine = nil then
                begin
                  MsgTime := MsgDateTime(Conv(Value['date'], 0));
                  MsgLine := History.Log[usr.UID].MsgAdd(usr, ParseMsg(Node['body'], Node['attachments']), MsgTime, MsgMID);
                end;
              // set state
                if MsgLine <> nil then
                  if Value['read_state'] <> '1' then
                    MsgLine^.State := msUnread
                  else
                    MsgLine^.State := msRead;
              }
              end;
              Roster.Activate(usr);
              Flag := True;
            end;

        if Flag then
          PlaySound(@SND_IN_DATA);
      end;
  end;
end;

procedure LongProc(ID: Integer; const Header: AnsiString; const Content: WideString; Data, RawData: Pointer; RawSize: LongInt);
var
  MsgMID  : LongWord;
  MsgTime : TMsgDateTime;
  MsgLine : PMsgLine;

  procedure ProcessMsg(const Content: WideString);
  var
    i, j, p : LongInt;
    MsgType : LongInt;
    UserTo, UserFrom : TUser;
    UValue, CValue : TJSONArray;
    text, url : WideString;
  begin
    UValue := JSON_Array(JSON_Value(Content, 'updates'));
    for i := 0 to Length(UValue) - 1 do
    begin
      CValue := JSON_Array(UValue[i]);
      if CValue <> nil then
        MsgType := Conv(CValue[0], -1)
      else
        MsgType := -1;

      case MsgType of
      // delete message
        0 : ;
      // set message flag
        1 : ;
      // add/remove message flag
        2, 3 :
          if Length(CValue) = 4 then
          begin
            if Conv(CValue[2], 0) and 1 = 0 then
              continue;
            MsgMID := Conv(CValue[1], 0);
            UserTo := Roster.GetUserByUID(CValue[3], True);
            if History.FindLog(UserTo.UID) <> nil then
            begin
              MsgLine := History.Log[UserTo.UID].MsgLine[MsgMID];
              if MsgLine <> nil then
              begin
                if MsgType = 3 then
                  MsgLine^.State := msRead
                else
                  MsgLine^.State := msUnread;
                if History.CurLog = History.Log[UserTo.UID] then
                  History.Repaint;
              end;
            end;
          end;
      // new message
        4 :
          begin
            UserTo := Roster.GetUserByUID(CValue[3], True);
            if Conv(CValue[2], 0) and 2 > 0 then // outbox
            begin
              UserFrom := Roster.OwnerUser;
              if (GetTime - vk.SendTick < SEND_MAX_TICK) or (History.FindLog(CValue[3]) = nil) then // active / log not loaded
                Exit;
            end else
              UserFrom := UserTo;
            MsgMID  := Conv(CValue[1], 0);
            MsgTime := MsgDateTime(Conv(CValue[4], 0));
{
            MsgLine := History.Log[UserTo.UID].MsgLine[MsgMID];
            if MsgLine = nil then
}
            text := SpecToChar(TrimChars(JSON_NoSlash(CValue[6]), ['"']));

          // parse attachments
            for j := 1 to 100 do
            begin
              p := Pos('"attach' + Conv(j) + '"', Content);
              if p = 0 then
                break;
              p := PosEx(p, ':"', Content);
              url := Copy(Content, p + 2, PosEx(p + 2, '"', Content) - p - 2);
            //  Writeln(url);
              p := PosEx(Pos('"attach' + Conv(j) + '_type"', Content), ':"', Content);
            //  Writeln(Content[p + 2]);

              case Content[p + 2] of
                'p' : url := VK_URL + 'photo' + url;
                'v' : url := VK_URL + 'video' + url;
                'd' : url := VK_URL + 'doc' + url;
                'a' : url := VK_URL + 'audio.php?id=' + ReplaceStr(ReplaceStr(url, '_', '&audio^id='), '^', '_');
              else
                url := '';
              end;

              if url <> '' then
              begin
                if text <> '' then
                  text := text + #13;
                text := text + url;
              end;
            end;

            MsgLine := History.Log[UserTo.UID].MsgAdd(UserFrom, text, '', MsgTime, MsgMID);
            if MsgLine <> nil then
            begin
              MsgLine^.Time  := MsgTime.Time;
              MsgLine^.State := msUnread;
            end;
          end;
      // user online/offline
        8, 9 :
          begin
            UserFrom := Roster.GetUserByUID(Copy(CValue[1], 2, Length(CValue[1])), True);
            UserFrom.Online := MsgType = 8;
          end;
      else
        // incorrect type
      end;
    end;
  end;

begin
  if Content <> '' then // error query response
  begin
  {$IFDEF DEBUG}
    Writeln('LongPoll: ', Content);
  {$ENDIF}
    vk.LongTS := AnsiString(JSON_Value(Content, 'ts'));
    if (JSON_Value(Content, 'failed') = '2') or (vk.LongTS = '') then
    begin
      vk.QueryLongFirst;
      Exit;
    end;
    ProcessMsg(Content);
    vk.QueryLongNext;
  end else
    VKBaseProc(ID, nil);
end;

procedure MsgSendProc(MsgLine: PMsgLine; XML: TXML);
begin
  if XML <> nil then
    MsgLine^.MID := Conv(XML.Content, 0)
  else
    MsgLine^.State := msError;
  History.Repaint;
end;
{$ENDREGION}

procedure FlushQuery;
begin
  if (not vk.QueryFlush) and (vk.QueryTick < QUERY_MAX_TICK) then
    Inc(vk.QueryTick);
end;

{ TVK }
procedure VKDefProc(VKResult: TVKResult; const Param: WideString);
begin
  with vk do
    case VKResult of
      vrErrorLogin, vrErrorCaptcha :
        LogonResProc(VKResult, Param);
    end;
end;

procedure VKDummyProc(VKResult: TVKResult; const Param: WideString);
begin
  //
end;

constructor TVK.Create;
begin
  token := '';
  CS.Init;
  ResProc := @VKDummyProc;
  TimerQuery := InitTimer(100, @FlushQuery);
end;

destructor TVK.Destroy;
begin
  FreeTimer(TimerQuery);
  QueryFreeAll;
  CS.Free;
  inherited;
end;

function TVK.QueryPush(const Method, Text: AnsiString; ID: Integer; Proc: TQueryXMLProc; First: Boolean): Boolean;
var
  i : LongInt;
  VKQuery : TVKQuery;
begin
  CS.Lock;
  if Text <> '' then
  begin
    VKQuery.Method := Method;
    VKQuery.Text := Text;
    VKQuery.ID   := ID;
    VKQuery.Proc := Proc;
    SetLength(QueryBuf, Length(QueryBuf) + 1);
    if not First then
    begin
      for i := Length(QueryBuf) - 1 downto 1 do
        QueryBuf[i] := QueryBuf[i - 1];
      QueryBuf[0] := VKQuery;
    end else
      QueryBuf[Length(QueryBuf) - 1] := VKQuery;
  end;
  CS.Unlock;
  Result := QueryFlush;
//  MessageBox(0, PWideChar(WideString(Text)), nil, 0);
end;

function TVK.QueryPop: TVKQuery;
begin
  CS.Lock;
  if Length(QueryBuf) > 0 then
  begin
    Result := QueryBuf[Length(QueryBuf) - 1];
    SetLength(QueryBuf, Length(QueryBuf) - 1);
    QueryTick := 0;
  end else
    Result.Text := '';
  CS.Unlock;
end;

function TVK.QueryFlush: Boolean;
var
  VKQuery : TVKQuery;
begin
  if vk.QueryTick >= QUERY_MAX_TICK then
  begin
    VKQuery := QueryPop;
    Result := VKQuery.Text <> '';
    if Result then
      HTTP.Query(qmPOST, VKAPI_HOST, VKQuery.Method, '', VKQuery.Text, VKQuery.ID, @VKProc, @VKQuery.Proc);
//      POST(VKAPI_HOST, '/api.php', VKQuery.Text, VKQuery.ID, VKProc, VKQuery.Proc);
  end else
    Result := False;
end;

function TVK.GetServerTime: LongWord;
begin
  Result := UnixTimeOffset + (GetTime div 1000 - UnixTimeStart);
end;

procedure TVK.QueryFreeAll;
begin
  CS.Lock;
  QueryBuf := nil;
  CS.Unlock;
end;

procedure OnLoginDirect(CallID: Integer; const Header: AnsiString; const Content: WideString; Data, RawData: Pointer; RawSize: LongInt);
var
  error : WideString;
begin
{$IFDEF DEBUG}
  Writeln(Content);
{$ENDIF}
  case CallID of
    0 :
      begin
        error := JSON_Value(Content, 'error');
        if error = '' then
        begin
          vk.mid    := JSON_Value(Content, 'user_id');
          vk.token  := AnsiString(JSON_Value(Content, 'access_token'));
          vk.secret := WideString(JSON_Value(Content, 'secret'));

          if vk.token <> '' then
            vk.Login
          else
            vk.ResProc(vrError);
        end else
          if error = 'invalid_client' then
            vk.ResProc(vrErrorLogin)
          else
            if error = 'need_captcha' then
              vk.ResProc(vrErrorCaptcha, JSON_Value(Content, 'captcha_sid'))
            else
              vk.ResProc(vrError);
      end;
  end;
end;

{
procedure OnLoginDirect(CallID: Integer; const Header: AnsiString; const Content: WideString; Data, RawData: Pointer; RawSize: LongInt);
var
  XML : TXML;
  DigestStr : WideString;
  TokenDigest : TMD5Digest;
begin
  Writeln(Content);
  case CallID of
    0 :
      begin
        XML := TXML.Create(Content, 1);
        if XML.DataLen > 0 then
        begin
          if XML.Tag <> 'error' then
          begin
            vk.token := AnsiString(XML['token'].Content);

            DigestStr := APP_KEY + ':' +
                         WideString(vk.nonce) + ':' +
                         WideString(vk.token) + ':' +
                         ConvHex(vk.Digest, SizeOf(TMD5Digest));
            TokenDigest := MD5String(DigestStr);

            vk.POST(VK_HOST, '/api.php',
                'api_id=' + APP_ID +
                '&method=auth.getSessionSecure' +
                '&nonce=' + vk.nonce +
                '&login=' + AnsiString(EncodeURL(AnsiString(vk.mail))) +
                '&digest=' + AnsiString(ConvHex(TokenDigest, SizeOf(TMD5Digest))),
                1, @OnLoginDirect);
          end else
            vk.ResProc(vrError);
        end else
          vk.ResProc(vrError);
        XML.Free;
      end;
    1 :
      begin
        XML := TXML.Create(Content, 1);
        if XML.DataLen > 0 then
        begin
          if XML.Tag <> 'error' then
          begin
            vk.mid    := XML['id'].Content;
            vk.sid    := XML['sid'].Content;
            vk.secret := XML['secret'].Content;
            vk.Login;
          //  Updater.CheckUpdate;
          end else
            if Pos(WideString('many'), XML.Content) > 0 then
              vk.ResProc(vrErrorAttempts)
            else
              vk.ResProc(vrErrorLogin);
        end else
          vk.ResProc(vrError);
        XML.Free;
      end;
  end;
end;
}

procedure TVK.OAuth(const CaptchaSID, CaptchaKey: AnsiString);
var
  str : AnsiString;
begin
  str := '/token?grant_type=password' +
         '&client_id=' + APP_ID +
         '&client_secret=' + APP_SECRET +
         '&username=' + AnsiString(EncodeURL(AnsiString(vk.mail))) +
         '&password=' + AnsiString(EncodeURL(AnsiString(vk.pass))) +
         '&scope=nohttps,messages,notify,friends,photos,audio,video,status,wall,groups,notifications';
  if CaptchaSID <> '' then
    str := str + '&captcha_sid=' + CaptchaSID + '&captcha_key=' + CaptchaKey;
  vk.GET('oauth.vk.com', str, '', 0, @OnLoginDirect, True);
end;

procedure TVK.TryLogin(const CaptchaSID, CaptchaKey: AnsiString);
//var
//  i : Integer;
begin
(*
// generate nonce
  SetLength(nonce, 16);
  for i := 1 to 16 do
    nonce[i] := AnsiChar({random(10) + } 48);
// query authorization
  if token = '' then
    POST(VK_HOST, '/api.php', 'api_id=' + APP_ID + '&method=auth.getTokenSecure&nonce=' + nonce, 0, @OnLoginDirect)
  else
    OnLoginDirect(0, '', '<login><token>' + vk.token + '</token></login>', nil, nil, 0);
*)
  if (vk.mid <> '') and (vk.token <> '') and (vk.secret <> '') then
    Login
  else
    OAuth(CaptchaSID, CaptchaKey);
end;

{
procedure TVK.TrySetup(const CaptchaSID, CaptchaKey: AnsiString);
var
  Str : AnsiString;
begin
  Str := 'addMember=1&app_settings_2=1&app_settings_4=1&app_settings_8=1&app_settings_16=1&app_settings_1024=1&app_settings_4096=1&app_settings_8192=1&hash=' + AppHash + '&id=' + APP_ID;
  if CaptchaSID <> '' then
    Str := Str + '&captcha_sid=' + CaptchaSID + '&captcha_key=' + CaptchaKey;
  POST(VK_HOST, '/apps.php?act=a_save_settings', Str, LOGIN_DESKTOP, @OnLogin);
end;
}
procedure TVK.Login;
begin
  Roster.OwnerUser.UID := mid;

  ResProc(vrLogin);
  ResProc := TVKResProc(@VKDummyProc);

  vk.QuerySelf;
{$IFNDEF DEBUG}
// dummy query for release version statistics
{
  if FirstLogin then
  begin
    HTTP.Query(qmHEAD, VK_HOST, '/club' + VK_CLUB, GetFullCookie, '', 0, nil); // HEAD request
    FirstLogin := False;
  end;
}
{$ENDIF}
end;

procedure TVK.Query(const Params: array of TParam; const Method: WideString; ID: Integer; Proc: TQueryXMLProc; First: Boolean);
var
  sig, m, URL : WideString;
begin
  m := '/method/' + method + '.xml';
  sig := ParamSigURL([Param('access_token', WideString(token))], Params, m + '?', '=', secret, URL);
  URL := URL + '&sig=' + sig;
//  Writeln('token: ', token);

  QueryPush(AnsiString(m), AnsiString(URL), ID, Proc, First);
end;

procedure TVK.QueryHistory(const UID: WideString; Offset, Count: LongInt; ID: Integer; Proc: TQueryXMLProc; First: Boolean);
begin
  Query([Param('uid', UID),
         Param('offset', Conv(Offset)),
         Param('count', Conv(Count))],
        'messages.getHistory', ID, Proc, First);
end;

procedure TVK.QueryValueGet(Key: WideString; User: TUser; Proc: TQueryXMLProc);
begin
  Query([Param('key', Key),
         Param('user_id', User.UID)],
         'getVariable', Integer(User), Proc);
end;

procedure TVK.QueryValueSet(Value: LongInt; Key: WideString);
begin
  Query([Param('key', Key),
         Param('value', Conv(Value)),
         Param('user_id', Roster.OwnerUser.UID)],
         'putVariable', 0, nil, True);
end;

procedure TVK.GetCaptcha(const CSID: AnsiString; ID: Integer; Proc: TQueryProc);
begin
  GetImage('api.' + VK_HOST, '/captcha.php?s=1&sid=' + CSID, ID, Proc);
end;

procedure TVK.GetImage(const Host, URL: AnsiString; ID: Integer; Proc: TQueryProc);
begin
  GET(Host, URL, '', ID, Proc);
end;

procedure TVK.GetFile(const URL: AnsiString; ID: Integer; Proc: TQueryProc);
var
  Host, Req : AnsiString;
begin
  Host := Copy(URL, 8, Length(URL));
  Host := Copy(Host, 1, Pos(AnsiString('/'), Host) - 1);
  Req  := Copy(URL, Length(Host) + 8, Length(URL));
  GET(Host, Req, '', ID, Proc);
//  HTTP.Query(qmGET, Host, URL, '', '', ID, Proc, nil, False);
end;

procedure TVK.POST(const Host, URL, Content: AnsiString; ID: Integer; Proc: TQueryProc);
begin
  HTTP.Query(qmPOST, Host, URL, '', Content, ID, Proc);
end;

procedure TVK.GET(const Host, URL, Content: AnsiString; ID: Integer; Proc: TQueryProc; SSL: Boolean);
begin
  HTTP.Query(qmGET, Host, URL, '', Content, ID, Proc, nil, True, SSL);
end;

procedure TVK.QueryUsersInfo(const UIDs, Fields: WideString; ID: Integer; Proc: TQueryXMLProc);
begin
  Query([Param('fields', Fields),
         Param('uids', UIDs)], 'users.get', ID, Proc, True);
end;

procedure TVK.QuerySelf;
begin
  QueryUsersInfo(mid, 'first_name,last_name,photo_rec', USER_SELF, @VKBaseProc);
end;

procedure TVK.QueryUsersGroup;
begin
  Query([], 'friends.getLists', USER_GROUP, @VKBaseProc, True);
end;

procedure TVK.QueryUsersNext;
begin
        {$IFDEF DEBUG}Writeln('get list');{$ENDIF}
  Query([Param('fields', 'bdate,city,contacts,first_name,last_name,lists,photo_rec,home_phone,mobile_phone'),
         Param('count', Conv(QUERY_MAX_USERS)),
         Param('offset', Conv(ListOffset))], 'friends.get', USER_LIST, @VKBaseProc, True);
end;

procedure TVK.QueryUsersOnline;
begin
        {$IFDEF DEBUG}Writeln('get online');{$ENDIF}
  Query([], 'friends.getOnline', USER_ONLINE, @VKBaseProc, True);
end;

procedure TVK.QueryLongFirst;
begin
  Query([], 'messages.getLongPollServer', LONG_START, @VKBaseProc, True);
end;

procedure TVK.QueryLongNext;
var
  i : LongInt;
  Host, URL : AnsiString;
begin
  i := Pos(AnsiString('/'), vk.LongServer);
  if i = 0 then
  begin
    Host := vk.LongServer;
    URL  := '/';
  end else
  begin
    Host := Copy(vk.LongServer, 1, i - 1);
    URL  := Copy(vk.LongServer, i, Length(vk.LongServer));
  end;
  URL := URL + '?act=a_check&mode=2&wait=25&key=' + vk.LongKey + '&ts=' + vk.LongTS;
  HTTP.Query(qmGET, Host, URL, '', '', LONG_NEXT, @LongProc);
//  vk.GET(Host, URL + '?act=a_check&wait=25&key=' + vk.LongKey + '&ts=' + vk.LongTS, '', LONG_NEXT, @LongProc);
end;

procedure TVK.QueryTime;
begin
  Query([], 'getServerTime', SERVER_TIME, @VKBaseProc, True);
end;

procedure TVK.MsgSetRead(const MIDs: WideString);
begin
  Query([Param('mids', MIDs)], 'messages.markAsRead', 0, nil, True);
end;

procedure TVK.MsgGetOffline(Offset: LongInt);
const
  MAX_TIME = '2419200'; // 28 days
begin
  Query([Param('count', '100'),
         Param('filters', '1'),
         Param('preview_length', '0'),
         Param('time_offset', MAX_TIME)], 'messages.get', MSG_OFFLINE, @VKBaseProc, True);
end;

procedure TVK.MsgSend(const UID: WideString; MsgLine: PMsgLine; Title: Boolean);
var
  Str : WideString;
begin
  if MsgLine = nil then
    Exit;
  SendTick := GetTime;

  Str := ReplaceStr(MsgLine^.Text, #13, '<br>');

  if MsgLine^.Attach <> '' then  // TODO: GOVNOKOD!
  begin
    Query([Param('uid', UID),
           //Param('message', Str), //CharToSpec(MsgLine^.Text)),
           Param('attachment', MsgLine^.Attach),
           Param('type', '1')], 'messages.send', Integer(MsgLine), @MsgSendProc, True);
  end else
  begin
    Query([Param('uid', UID),
           Param('message', Str), //CharToSpec(MsgLine^.Text)),
           Param('type', '1')], 'messages.send', Integer(MsgLine), @MsgSendProc, True);
  end;

  MsgLine^.State := msUnread;
end;

end.
