unit jutils;

interface

uses
  jsys;

const
  HexDigits : PWideChar = '0123456789abcdef';

type
  TCompareFunc = function (Item1, Item2: Pointer): LongInt;

  TParam = record
    Name  : WideString;
    Value : WideString;
  end;

  TStream = class
  protected
    FPosition : LongInt;
    FSize     : LongInt;
    procedure SetPosition(const Value: LongInt); virtual;
  public
    function ReadUInt8: Byte;
    function ReadUInt16: Word;
    function ReadUInt32: LongWord;
    function ReadInt8: ShortInt;
    function ReadInt16: SmallInt;
    function ReadInt32: LongInt;
    function ReadFloat: Single;
    function ReadStr: WideString;
    function Read(out Data; Size: LongInt): LongInt; virtual;
    function WriteInt32(Value: LongInt): LongInt;
    function WriteStr(const Value: WideString): LongInt;
    function Write(const Data; Size: LongInt): LongInt; virtual;
    property Position: LongInt read FPosition write SetPosition;
    property Size: LongInt read FSize;
  end;

  TMemoryStream = class(TStream)
    constructor Create(Data: Pointer; DSize: LongInt; FreeMem: Boolean = False);
    destructor Destroy; override;
  protected
    FData    : PByteArray;
    FFreeMem : Boolean;
  public
    function Read(out Data; DSize: LongInt): LongInt; override;
    function Write(const Data; DSize: LongInt): LongInt; override;
  end;

  TFileMode = (fmRead, fmWrite, fmReadWrite);

  TFileStream = class(TStream)
    class function CreateInMemory(const FileName: WideString): TMemoryStream;
    constructor Create(const FileName: WideString; FileMode: TFileMode = fmRead);
    destructor Destroy; override;
  protected
    F : File;
    FValid : Boolean;
    procedure SetPosition(const Value: LongInt); override;
  public
    function Read(out Data; DSize: LongInt): LongInt; override;
    function Write(const Data; DSize: LongInt): LongInt; override;
    property Valid: Boolean read FValid;
  end;

  function SetRect(Left, Top, Right, Bottom: LongInt): TRect;
  function SetSize(Left, Top, Width, Height: SmallInt): TSize;
  function SetRectSize(Left, Top, Width, Height: SmallInt): TRect;
  function RectCompare(const Rect1, Rect2: TRect): Boolean;
  function RectMerge(const Rect1, Rect2: TRect): TRect;
  function RectIntersect(const Rect1, Rect2: TRect): Boolean; overload;
  function RectIntersect(const Rect: TRect; X, Y: LongInt): Boolean; overload;

  function Min(x, y: LongInt): LongInt;
  function Max(x, y: LongInt): LongInt;
  function SwapInt16(const Value: Word): Word;
  function SwapInt32(const Value: LongWord): LongWord;
  function LeftRotate(x, c: LongWord): LongWord;

  function BGR2RGB(Value: TColor): TColor;
  function Conv(const Str: WideString; Def: LongInt = 0): LongInt; overload;
  function Conv(const Str: WideString; Def: Single = 0): Single; overload;
  function Conv(const Str: WideString; Def: Boolean = False): Boolean; overload;
  function Conv(Value: LongInt): WideString; overload;
  function Conv(Value: LongWord): WideString; overload;
  function Conv(Value: Single; Digits: LongInt = 6): WideString; overload;
  function Conv(Value: Boolean): WideString; overload;
  function ConvBase64(const Data: PByteArray; Size: LongInt): WideString; overload;
  function ConvBase64(const Code: WideString; out Data: PByteArray): LongInt; overload;
  function ConvHex(const Buf; Count: LongInt; Invert: Boolean = False): WideString;
  function ConvSURL(const URL: WideString): WideString;

  function EncodeHTML(const Str: WideString): WideString;
  function DecodeURL(const URL: AnsiString): AnsiString;
  function EncodeURL(const URL: AnsiString): WideString;
{$IFDEF WIN32}
  function UTF8Decode(const S: UTF8String): WideString;
{$ENDIF}

  function LowerCase(const Str: WideString): WideString;
  function UpperCase(const Str: WideString): WideString;
  function TrimChars(const Str: WideString; Chars: TCharSet): WideString;
  function Trim(const Str: WideString): WideString;
  function PosBuf(Start, Count: LongInt; const SubStr, Str: WideString): LongInt;
  function PosEx(Start: LongInt; const SubStr, Str: WideString): LongInt;
  function DeleteChars(const Str: WideString; Chars: TCharSet): WideString;
  function ReplaceStr(const Str, Source, Dest: WideString): WideString;
  function CharToSpec(const Str: WideString): WideString;
  function SpecToChar(const Str: WideString): WideString;
  function RandomHex(Bytes: LongInt): WideString;
  function Tag(const TagName: WideString; const Params: WideString = ''; const Content: WideString = ''): WideString;
  function BinToPas(const FileName, OutFileName: WideString): Boolean;
  procedure QSort(Items: PPointerArray; L, R: LongInt; CompareFunc: TCompareFunc);

  procedure URLtoHostReq(const URL: WideString; out Host, Req: WideString);
// API
  function Param(const Name, Value: WideString): TParam;
  function ParamSigURL(const DefParam, Param: array of TParam; const FToken, DToken, LToken: WideString; var URL: WideString): WideString;

implementation

uses
  jhash;

{$REGION 'TStream'}
{ TStream }
function TStream.ReadUInt8: Byte;
begin
  Read(Result, SizeOf(Result));
end;

function TStream.ReadUInt16: Word;
begin
  Read(Result, SizeOf(Result));
end;

function TStream.ReadUInt32: LongWord;
begin
  Read(Result, SizeOf(Result));
end;

function TStream.ReadInt8: ShortInt;
begin
  Read(Result, SizeOf(Result));
end;

function TStream.ReadInt16: SmallInt;
begin
  Read(Result, SizeOf(Result));
end;

function TStream.ReadInt32: LongInt;
begin
  Read(Result, SizeOf(Result));
end;

function TStream.ReadFloat: Single;
begin
  Read(Result, SizeOf(Result));
end;

procedure TStream.SetPosition(const Value: LongInt);
begin
  FPosition := Value;
end;

function TStream.ReadStr: WideString;
var
  L : Word;
  S : UTF8String;
begin
  Read(L, SizeOf(L));
  if L > 0 then
  begin
    SetLength(S, L);
    Read(S[1], L);
    Result := UTF8Decode(S);
  end else
    Result := '';
end;

function TStream.Read(out Data; Size: LongInt): LongInt;
begin
  Result := 0;
end;

function TStream.WriteInt32(Value: Integer): LongInt;
begin
  Result := Write(Value, SizeOf(Value));
end;

function TStream.WriteStr(const Value: WideString): LongInt;
var
  L : Word;
  S : UTF8String;
begin
  S := UTF8Encode(Value);
  L := Length(S);
  Write(L, SizeOf(L));
  if L > 0 then
    Result := Write(S[1], L)
  else
    Result := 0;
end;

function TStream.Write(const Data; Size: LongInt): LongInt;
begin
  Result := 0;
end;
{$ENDREGION}

{$REGION 'TMemoryStream'}
{ TMemoryStream }
constructor TMemoryStream.Create(Data: Pointer; DSize: LongInt; FreeMem: Boolean = False);
begin
  FData    := Data;
  FSize    := DSize;
  FFreeMem := FreeMem;
end;

destructor TMemoryStream.Destroy;
begin
  if FFreeMem then
    FreeMemory(FData);
  inherited;
end;

function TMemoryStream.Read(out Data; DSize: LongInt): LongInt;
begin
  Result := Min(FPosition + DSize, FSize) - FPosition;
  Move(FData^[FPosition], Data, Result);
  Inc(FPosition, Result);
end;

function TMemoryStream.Write(const Data; DSize: LongInt): LongInt;
begin
  Result := Min(FPosition + DSize, FSize) - FPosition;
  Move(Data, FData^[FPosition], Result);
  Inc(FPosition, Result);
  Inc(FSize, Max(0, FPosition - FSize));
end;
{$ENDREGION}

{$REGION 'TFileStream'}
{ TFileStream }
class function TFileStream.CreateInMemory(const FileName: WideString): TMemoryStream;
var
  Data : Pointer;
  Stream : TFileStream;
begin
  Stream := TFileStream.Create(FileName);
  if Stream.Valid then
  begin
    Data := GetMemory(Stream.Size);
    Stream.Read(Data^, Stream.Size);
    Result := TMemoryStream.Create(Data, Stream.Size, True);
  end else
    Result := TMemoryStream.Create(nil, 0, False);
  Stream.Free;
end;

constructor TFileStream.Create(const FileName: WideString; FileMode: TFileMode);
begin
{$I-}
  System.FileMode := 2;
  AssignFile(F, FileName);
  case FileMode of
    fmRead      :
      begin
        System.FileMode := 0;
        Reset(F, 1);
      end;
    fmWrite     :
      begin
        System.FileMode := 1;
        Rewrite(F, 1)
      end;
    fmReadWrite :
      begin
        System.FileMode := 2;
        Reset(F, 1);
      end;
  end;

  if IOResult = 0 then
  begin
    FSize  := FileSize(F);
    FValid := True;
  end else
    FValid := False;
{$I+}
end;

destructor TFileStream.Destroy;
begin
  if FValid then
    CloseFile(F);
end;

procedure TFileStream.SetPosition(const Value: LongInt);
begin
  inherited;
  Seek(F, FPosition);
end;

function TFileStream.Read(out Data; DSize: LongInt): LongInt;
begin
  BlockRead(F, Data, DSize, Result);
  Inc(FPosition, Result);
end;

function TFileStream.Write(const Data; DSize: LongInt): LongInt;
begin
  BlockWrite(F, Data, DSize, Result);
  Inc(FPosition, Result);
  FSize := FileSize(F);
end;
{$ENDREGION}

{$REGION 'Common'}
{ Common }
function SetRect(Left, Top, Right, Bottom: LongInt): TRect;
begin
  Result.Left   := Left;
  Result.Top    := Top;
  Result.Right  := Right;
  Result.Bottom := Bottom;
end;

function SetSize(Left, Top, Width, Height: SmallInt): TSize;
begin
  Result.Left   := Left;
  Result.Top    := Top;
  Result.Width  := Width;
  Result.Height := Height;
end;

function SetRectSize(Left, Top, Width, Height: SmallInt): TRect;
begin
  Result.Left   := Left;
  Result.Top    := Top;
  Result.Right  := Left + Width;
  Result.Bottom := Top + Height;
end;

function RectCompare(const Rect1, Rect2: TRect): Boolean;
begin
  Result := (Rect1.Left   = Rect2.Left)  and
            (Rect1.Top    = Rect2.Top)   and
            (Rect1.Right  = Rect2.Right) and
            (Rect1.Bottom = Rect2.Bottom);
end;

function RectMerge(const Rect1, Rect2: TRect): TRect;
begin
  Result.Left   := Min(Rect1.Left, Rect2.Left);
  Result.Right  := Max(Rect1.Right, Rect2.Right);
  Result.Top    := Min(Rect1.Top, Rect2.Top);
  Result.Bottom := Max(Rect1.Bottom, Rect2.Bottom);
end;

function RectIntersect(const Rect1, Rect2: TRect): Boolean; overload;
begin
  Result := not ((Rect1.Left   >= Rect2.Right)  or
                 (Rect1.Right  <= Rect2.Left)   or
                 (Rect1.Top    >= Rect2.Bottom) or
                 (Rect1.Bottom <= Rect2.Top));
end;

function RectIntersect(const Rect: TRect; X, Y: LongInt): Boolean; overload;
begin
  Result := (X >= Rect.Left) and (X < Rect.Right) and
            (Y >= Rect.Top) and (Y < Rect.Bottom);
end;


function Min(x, y: LongInt): LongInt;
begin
  if x < y then
    Result := x
  else
    Result := y;
end;

function Max(x, y: LongInt): LongInt;
begin
  if x > y then
    Result := x
  else
    Result := y;
end;

function SwapInt16(const Value: Word): Word;
begin
  Result := ((Value shl 8) and $FF00) or ((Value shr 8) and $00FF);
end;

function SwapInt32(const Value: LongWord): LongWord; assembler;
asm
  bswap eax
end;

function LeftRotate(x, c: LongWord): LongWord;
begin
  Result := (x shl c) or (x shr (32 - c));
end;

function BGR2RGB(Value: TColor): TColor;
begin
  Result := (Value and $FF shl 16) or (Value and $FF00) or (Value shr 16 and $FF);
end;

function Conv(const Str: WideString; Def: LongInt): LongInt;
var
  Code : LongInt;
begin
  Val(Str, Result, Code);
  if Code <> 0 then
    Result := Def;
end;

function Conv(const Str: WideString; Def: Single): Single;
var
  Code : LongInt;
begin
  Val(Str, Result, Code);
  if Code <> 0 then
    Result := Def;
end;

function Conv(const Str: WideString; Def: Boolean = False): Boolean;
var
  LStr : WideString;
begin
  LStr := LowerCase(Str);
  if LStr = 'true' then
    Result := True
  else
    if LStr = 'false' then
      Result := False
    else
      Result := Def;
end;

function Conv(Value: LongInt): WideString;
var
  Res : string[32];
begin
  Str(Value, Res);
  Result := WideString(Res);
end;

function Conv(Value: LongWord): WideString;
begin
  Result := Conv(LongInt(Value));
end;

function Conv(Value: Single; Digits: LongInt = 6): WideString;
var
  Res : string[32];
begin
  Str(Value:0:Digits, Res);
  Result := WideString(Res);
end;

function Conv(Value: Boolean): WideString;
begin
  if Value then
    Result := 'true'
  else
    Result := 'false';
end;

function ConvBase64(const Data: PByteArray; Size: LongInt): WideString;
const
  Base64Table : PWideChar = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
var
  i : LongInt;
  v : LongWord;
  s : PByteArray;
  d : PWideChar;
begin
  SetLength(Result, (Size + 2) div 3 * 4);
  s := Data;
  d := @Result[1];
  for i := 0 to Size div 3 - 1 do
  begin
    v := (s^[0] shl 24) or (s^[1] shl 16) or (s^[2] shl 8);
    d[0] := Base64Table[v shr 26];
    d[1] := Base64Table[v shl  6 shr 26];
    d[2] := Base64Table[v shl 12 shr 26];
    d[3] := Base64Table[v shl 18 shr 26];
    s := Pointer(Cardinal(s) + 3);
    d := Pointer(Cardinal(d) + 4 * SizeOf(WideChar));
  end;

  if Size mod 3 > 0 then
  begin
    v := 0;
    for i := Size div 3 * 3 to Size - 1 do
      v := v or (Data^[i] shl (24 - 8 * (i mod 3)));
    for i := 0 to 3 do
      if i * 6 < Size mod 3 * 8 then
        d[i] := Base64Table[v shl (6 * i) shr 26]
      else
        d[i] := '=';
  end;
end;

function ConvBase64(const Code: WideString; out Data: PByteArray): LongInt;
var
  i : LongInt;
  v : LongInt;
  d : PByteArray;
begin
  Result := Length(Code) div 4 * 3;
  Data := GetMemory(Result);
  d := Data;
  v := 0;
  for i := 1 to Length(Code) do
  begin
    v := v shl 6;
    case Code[i] of
      'A'..'Z' : v := v or (Byte(Code[i]) - 65);
      'a'..'z' : v := v or (Byte(Code[i]) - 71);
      '0'..'9' : v := v or (Byte(Code[i]) + 4);
      '+'      : v := v or 62;
      '/'      : v := v or 63;
      '='      : Dec(Result);
    end;
    if i mod 4 = 0 then
    begin
      d^[0] := v and $FF0000 shr 16;
      d^[1] := v and $00FF00 shr 8;
      d^[2] := v and $0000FF;
      d := Pointer(Cardinal(d) + 3);
    end;
  end;
end;

function ConvHex(const Buf; Count: LongInt; Invert: Boolean): WideString;
var
  i, idx : LongInt;
  d : TByteArray absolute Buf;
begin
  SetLength(Result, Count * 2);
  for i := 0 to Count - 1 do
  begin
    if Invert then
      idx := Count - i - 1
    else
      idx := i;
    Result[i * 2 + 1] := HexDigits[d[idx] shr 4 and $0F];
    Result[i * 2 + 2] := HexDigits[d[idx] and $0F];
  end;
end;

function ConvSURL(const URL: WideString): WideString;
var
  i : LongInt;
begin
  Result := URL;
// remove xxx://
  i := Pos(WideString('//'), Result);
  if i > 0 then
    Delete(Result, 1, i + 1);
// remove host name
  i := Pos('/', Result);
  if i > 0 then
    Delete(Result, 1, i);
// replace other slashes
  i := Pos('/', Result);
  while i > 0 do
  begin
    Result[i] := '_';
    i := Pos('/', Result);
  end;
end;

function EncodeHTML(const Str: WideString): WideString;
var
  i : LongInt;
begin
  Result := '';
  for i := 1 to Length(Str) do
    if Str[i] > #255 then
      Result := Result + '&#' + Conv(LongWord(Ord(Str[i]))) + ';'
    else
      Result := Result + Str[i];
end;

function DecodeTriplet(const Value: AnsiString; Delimiter: AnsiChar): AnsiString;
var
  x, l, lv: Integer;
  c: AnsiChar;
  b: Byte;
  bad: Boolean;
begin
  lv := Length(Value);
  SetLength(Result, lv);
  x := 1;
  l := 1;
  while x <= lv do
  begin
    c := Value[x];
    Inc(x);
    if c <> Delimiter then
    begin
      Result[l] := c;
      Inc(l);
    end
    else
      if x < lv then
      begin
        Case Value[x] Of
          #13:
            if (Value[x + 1] = #10) then
              Inc(x, 2)
            else
              Inc(x);
          #10:
            if (Value[x + 1] = #13) then
              Inc(x, 2)
            else
              Inc(x);
        else
          begin
            bad := False;
            Case Value[x] Of
              '0'..'9': b := (Byte(Value[x]) - 48) Shl 4;
              'a'..'f', 'A'..'F': b := ((Byte(Value[x]) And 7) + 9) shl 4;
            else
              begin
                b := 0;
                bad := True;
              end;
            end;
            Case Value[x + 1] Of
              '0'..'9': b := b Or (Byte(Value[x + 1]) - 48);
              'a'..'f', 'A'..'F': b := b Or ((Byte(Value[x + 1]) And 7) + 9);
            else
              bad := True;
            end;
            if bad then
            begin
              Result[l] := c;
              Inc(l);
            end
            else
            begin
              Inc(x, 2);
              Result[l] := AnsiChar(b);
              Inc(l);
            end;
          end;
        end;
      end
      else
        break;
  end;
  Dec(l);
  SetLength(Result, l);
end;

function EncodeTriplet(const Value: AnsiString; Delimiter: AnsiChar; Specials: TSpecials): AnsiString;
var
  n, l: Integer;
  c: AnsiChar;
begin
  SetLength(Result, Length(Value) * 3);
  l := 1;
  for n := 1 to Length(Value) do
  begin
    c := Value[n];
    if c in Specials then
    begin
      Result[l] := Delimiter;
      Inc(l);
      Result[l] := AnsiChar(HexDigits[Ord(c) div 16]);
      Inc(l);
      Result[l] := AnsiChar(HexDigits[Ord(c) mod 16]);
      Inc(l);
    end
    else
    begin
      Result[l] := c;
      Inc(l);
    end;
  end;
  Dec(l);
  SetLength(Result, l);
end;

function DecodeURL(const URL: AnsiString): AnsiString;
begin
  Result := DecodeTriplet(URL, '%');
end;
(*
function EncodeURL(const URL: WideString): AnsiString;
const
  URLSpecialChar: TSpecials = [#$00..#$20, '<', '>', '"', '%', '&', '#', ';', '{', '}', '|', '\', '/', '^', '~', '+', '@', '[', ']', '`', #$7F..#$FF];
begin
  Result := EncodeTriplet(AnsiString(EncodeHTML(URL)), '%', URLSpecialChar);
end;
*)
function EncodeURL(const URL: AnsiString): WideString;
var
  i : LongInt;
  c : LongWord;
begin
  Result := '';
  for i := 1 to Length(URL) do
  begin
    c := Ord(URL[i]);
    if not (c in [$21, $27, $2E, $30..$39, $41..$5A, $5F, $61..$7A]) then // ! ' . 0..9 A..Z _ a..z
      Result := Result + ('%' + HexDigits[c div 16] + HexDigits[c mod 16])
    else
      Result := Result + WideChar(URL[i]);
  end;
end;

{$IFDEF WIN32}
function UTF8ToUnicode(Dest: PWideChar; MaxDestChars: Cardinal; Source: PAnsiChar; SourceBytes: Cardinal): Cardinal;
begin
  Result := 0;
  if Source = nil then Exit;
  if (Dest <> nil) and (MaxDestChars > 0) then
  begin
    Result := Cardinal(MultibyteToWideChar(CP_UTF8, 0, Source, Integer(SourceBytes), Dest, Integer(MaxDestChars)));
    if (Result > 0) and (Result <= MaxDestChars) and (Dest[Result - 1] <> #0) then
    begin
      if Result = MaxDestChars then
      begin
        if (Result > 1) and (Word(Dest[Result - 1]) >= $DC00) and (Word(Dest[Result - 1]) <= $DFFF) then
          Dec(Result);
      end else
        Inc(Result);
      Dest[Result - 1] := #0;
    end;
  end else
    Result := Cardinal(MultibyteToWideChar(CP_UTF8, 0, Source, Integer(SourceBytes), nil, 0));
end;

function UTF8Decode(const S: UTF8String): WideString;
var
  L: Integer;
  Temp: WideString;
begin
  Result := '';
  if S = '' then Exit;
  L := Length(S);
  SetLength(Temp, L);

  L := UTF8ToUnicode(PWideChar(Temp), L + 1, PAnsiChar(S), L);
  if L > 0 then
    SetLength(Temp, L - 1)
  else
    Temp := '';
  Result := Temp;
end;
{$ENDIF}

function LowerCase(const Str: WideString): WideString;
var
  i : LongInt;
begin
  Result := Str;
  for i := 1 to Length(Str) do
    if ((Result[i] >= 'A') and (Result[i] <= 'Z')) or
       ((Result[i] >= 'А') and (Result[i] <= 'Я')) then
      Result[i] := WideChar(Ord(Result[i]) + 32);
end;

function UpperCase(const Str: WideString): WideString;
var
  i : LongInt;
begin
  Result := Str;
  for i := 1 to Length(Str) do
    if ((Result[i] >= 'a') and (Result[i] <= 'z')) or
       ((Result[i] >= 'а') and (Result[i] <= 'я')) then
      Result[i] := WideChar(Ord(Result[i]) - 32);
end;

function TrimChars(const Str: WideString; Chars: TCharSet): WideString;
var
  i, j : LongInt;
begin
  j := Length(Str);
  i := 1;
  while (i <= j) and (Ord(Str[i]) < $0100) and (AnsiChar(Str[i]) in Chars) do
    Inc(i);
  if i <= j then
  begin
    while (Ord(Str[j]) < $0100) and (AnsiChar(Str[j]) in Chars) do
      Dec(j);
    Result := Copy(Str, i, j - i + 1);
  end else
    Result := '';
end;

function Trim(const Str: WideString): WideString;
begin
  Result := TrimChars(Str, [#9, #10, #13, #32, #34, #39]);
end;

function DeleteChars(const Str: WideString; Chars: TCharSet): WideString;
var
  i, j : LongInt;
begin
  j := 0;
  SetLength(Result, Length(Str));
  for i := 1 to Length(Str) do
    if not (AnsiChar(Str[i]) in Chars) then
    begin
      Inc(j);
      Result[j] := Str[i];
    end;
  SetLength(Result, j);
end;

function PosBuf(Start, Count: LongInt; const SubStr, Str: WideString): LongInt;
var
  i, j, StrLen : LongInt;
begin
  Result := 0;
  StrLen := Length(SubStr);
  if StrLen = 0 then
    Exit;
  j := StrLen;
  for i := Max(0, Start) to Min(Start + Count - 1, Length(Str)) do
  begin
    if Str[i] = SubStr[StrLen - j + 1] then
      Dec(j)
    else
      j := StrLen;
    if j = 0 then
    begin
      Result := i - StrLen + 1;
      break;
    end;
  end;
end;

function PosEx(Start: LongInt; const SubStr, Str: WideString): LongInt;
begin
  Result := PosBuf(Start, Length(Str) - Start + 1, SubStr, Str);
end;

function ReplaceStr(const Str, Source, Dest: WideString): WideString;
var
  i : LongInt;
begin
  Result := Str;
  i := Pos(Source, Result);
  while i > 0 do
  begin
    Delete(Result, i, Length(Source));
    Insert(Dest, Result, i);
    i := Pos(Source, Result);
  end;
end;

function Replace(const Str, Source, Dest: WideString): WideString;
var
  i : LongInt;
begin
  Result := Str;
  i := Pos(Source, Result);
  while i > 0 do
  begin
    Delete(Result, i, Length(Source));
    Insert(Dest, Result, i);
    if Source = '&' then
      i := PosEx(i + 1, Source, Result)
    else
      i := Pos(Source, Result);
  end;
end;

function CharToSpec(const Str: WideString): WideString;
const
  SpecChar : array [0..9, 0..1] of WideString = (
     ('&amp;', '&'),
     ('&ndash;', '–'),
     ('&apos;', ''''),
     ('&#039;', ''''),
     ('&#39;', ''''),
//     ('&#62;', '>'),
     ('&quot;', '"'),
     (#13, #13#10),
     ('&lt;', '<'),
     ('&gt;', '>'),
     ('<br>', #13)
  );
var
  i : LongInt;
begin
  Result := Str;
  for i := 0 to Length(SpecChar) - 1 do
    Result := Replace(Result, SpecChar[i][1], SpecChar[i][0]);
end;

function SpecToChar(const Str: WideString): WideString;
const
  SpecChar : array [0..10, 0..1] of WideString = (
     ('&amp;', '&'),
     ('&ndash;', '–'),
     ('&apos;', ''''),
     ('&#039;', ''''),
     ('&#39;', ''''),
//     ('&#62;', '>'),
     ('&quot;', '"'),
     ('&lt;', '<'),
     ('&gt;', '>'),
     ('<br>', #13),
     (#13#10, #13),
     (#10, #13));
var
  i : LongInt;
begin
  Result := Str;
  for i := 0 to Length(SpecChar) - 1 do
    Result := Replace(Result, SpecChar[i][0], SpecChar[i][1])
end;

function RandomHex(Bytes: LongInt): WideString;
var
  i : LongInt;
begin
  SetLength(Result, Bytes * 2);
  for i := 1 to Bytes * 2 do
    Result[i] := HexDigits[random(16)];
end;

function Tag(const TagName: WideString; const Params: WideString; const Content: WideString): WideString;
begin
  Result := '<' + TagName;
  if Params <> '' then
    Result := Result + ' ' + Params;
  if Content = '' then
    Result := Result + '/>'
  else
    Result := Result + '>' + Content + '</' + TagName + '>';
end;

function BinToPas(const FileName, OutFileName: WideString): Boolean;
var
  Stream : TFileStream;
  Str : WideString;
  i : LongInt;
  d : LongWord;
begin
  Stream := TFileStream.Create(FileName);
  Str := '  Data : array [0..' + Conv((Stream.Size + 3) div 4 - 1) + '] of LongWord = (';
  for i := 0 to (Stream.Size + 3) div 4 - 1 do
  begin
    if i mod 7 = 0 then
      Str := Str + #13#10'    ';
    d := 0;
    Stream.Read(d, 4);
    Str := Str + '$' + UpperCase(ConvHex(d, 4, True));
    if i < (Stream.Size + 3) div 4 - 1 then
      Str := Str + ', ';
  end;
  Str := Str + ');'#13#10'DataSize = ' + Conv(Stream.Size) + ';';
  Stream.Free;

  Stream := TFileStream.Create(OutFileName, fmWrite);
  Stream.Write(AnsiString(Str)[1], Length(Str));
  Stream.Free;

  Result := True;
end;

procedure QSort(Items: PPointerArray; L, R: LongInt; CompareFunc: TCompareFunc);
var
  i, j : LongInt;
  P, T : Pointer;
begin
  repeat
    i := L;
    j := R;
    P := Items^[(L + R) div 2];
    repeat
      while CompareFunc(Items^[i], P) < 0 do
        Inc(i);
      while CompareFunc(Items^[j], P) > 0 do
        Dec(j);
      if i <= j then
      begin
        if i <> j then
        begin
          T := Items^[i];
          Items^[i] := Items^[j];
          Items^[j] := T;
        end;
        Inc(i);
        Dec(j);
      end;
    until i > j;
    if L < j then
      QSort(Items, L, j, CompareFunc);
    L := i;
  until i >= R;
end;

procedure URLtoHostReq(const URL: WideString; out Host, Req: WideString);
begin
  Host := Copy(URL, 8, Length(URL));
  Host := Copy(Host, 1, Pos('/', Host) - 1);
  Req  := Copy(URL, Length(Host) + 8, Length(URL));
end;

// API
function Param(const Name, Value: WideString): TParam;
begin
  Result.Name  := Name;
  Result.Value := Value;
end;

function ParamSigURL(const DefParam, Param: array of TParam; const FToken, DToken, LToken: WideString; var URL: WideString): WideString;
var
  i : LongInt;
  p : array of TParam;
  tp : TParam;
  Sort : Boolean;
  Digest : TMD5Digest;
begin
  SetLength(p, Length(DefParam) + Length(Param));
  for i := 0 to Length(DefParam) - 1 do
    p[i] := DefParam[i];
  for i := Length(DefParam) to Length(p) - 1 do
    p[i] := Param[i - Length(DefParam)];
// alphabetical bubble sort
  Sort := True;
  while Sort do
  begin
    Sort := False;
    for i := 0 to Length(p) - 2 do
      if p[i].Name > p[i + 1].Name then
      begin
        tp := p[i];
        p[i] := p[i + 1];
        p[i + 1] := tp;
        Sort := True;
      end;
  end;
// get sig
  Result := '';
  for i := 0 to Length(p) - 1 do
  begin
    if i > 0 then
      Result := Result + '&';
    Result := Result + p[i].Name + DToken + p[i].Value;
  end;
  Digest := MD5String(FToken + Result + LToken);
  Result := ConvHex(Digest, SizeOf(Digest));
// get url
  URL := '';
  for i := 0 to Length(p) - 1 do
  begin
    if i > 0 then
      URL := URL + '&';
    URL := URL + p[i].Name + '=' + EncodeURL(UTF8Encode(p[i].Value));
  end;
end;
{$ENDREGION}

end.
