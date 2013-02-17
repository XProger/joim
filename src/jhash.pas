unit jhash;

interface

uses
  jutils;

// MD5
type
  TMD5Digest = array [0..3] of LongWord;
  TMD5Block  = array [0..63] of Byte;
  TMD5Context = record
    State : TMD5Digest;
    Block : TMD5Block;
    Len   : Int64;
    Pos   : LongInt;
  end;

procedure MD5Init(out Context: TMD5Context);
procedure MD5Update(var Context: TMD5Context; const Data; Size: LongWord); overload;
procedure MD5Update(var Context: TMD5Context; const Str: WideString); overload;
procedure MD5Final(var Context: TMD5Context; out Digest: TMD5Digest);
function MD5Match(D1, D2: TMD5Digest): Boolean;
function MD5String(const Str: WideString): TMD5Digest;

// SHA1
type
  TSHA1Digest = array [0..4] of LongWord;
  TSHA1Block  = array [0..63] of Byte;
  TSHA1Context = record
    State : TSHA1Digest;
    Block : TSHA1Block;
    Len   : Int64;
    Pos   : LongInt;
  end;

procedure SHA1Init(out Context: TSHA1Context);
procedure SHA1Update(var Context: TSHA1Context; const Data; Size: LongWord);
procedure SHA1Final(var Context: TSHA1Context; out Digest: TSHA1Digest);

implementation

{$REGION 'MD5'}
var
  MD5Table : array [0..63] of LongWord;

procedure MD5Calc(const MD5Block: TMD5Block; var State: TMD5Digest);
const
  r : array [0..63] of Byte = (
    7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,
    5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,
    4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,
    6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21);
var
  i : LongInt;
  a, b, c, d, e, f, g : LongWord;
  w : array [0..15] of LongWord absolute MD5Block;
begin
{$Q-}
{$R-}
  a := State[0];
  b := State[1];
  c := State[2];
  d := State[3];

  for i := 0 to 63 do
  begin
    if i > 47 then
    begin
      f := c xor (b or (not d));
      g := (7 * i) mod 16;
    end else
      if i > 31 then
      begin
        f := b xor c xor d;
        g := (3 * i + 5) mod 16;
      end else
        if i > 15 then
        begin
          f := c xor (d and (b xor c));
          g := (5 * i + 1) mod 16;
        end else
        begin
          f := d xor (b and (c xor d));
          g := i;
        end;

    e := d;
    d := c;
    c := b;
    b := b + LeftRotate(a + f + MD5Table[i] + w[g], r[i]);
    a := e;
  end;

  Inc(State[0], a);
  Inc(State[1], b);
  Inc(State[2], c);
  Inc(State[3], d);
{$Q+}
end;

procedure MD5Init(out Context: TMD5Context);
begin
  Context.State[0] := $67452301;
  Context.State[1] := $EFCDAB89;
  Context.State[2] := $98BADCFE;
  Context.State[3] := $10325476;
  Context.Len := 0;
  Context.Pos := 0;
end;

procedure MD5Update(var Context: TMD5Context; const Data; Size: LongWord);
var
  Count : LongWord;
  ptr   : Pointer;
begin
  with Context do
  begin
    Len := Len + Size * 8;
    ptr := @Data;
    while Size > 0 do
    begin
      Count := SizeOf(Block) - Pos;
      if Size < Count then
        Count := Size;
      Move(ptr^, Block[Pos], Count);
      Inc(Pos, Count);
      Dec(Size, Count);
      ptr := Pointer(LongWord(ptr) + Count);
      if Pos = SizeOf(Block) then
      begin
        MD5Calc(Block, State);
        Pos := 0;
      end;
    end;
  end;
end;

procedure MD5Update(var Context: TMD5Context; const Str: WideString);
var
  UTF8 : UTF8String;
begin
  UTF8 := UTF8Encode(Str);
  MD5Update(Context, UTF8[1], Length(UTF8));
end;
                                    
procedure MD5Final(var Context: TMD5Context; out Digest: TMD5Digest);
begin
  with Context do
  begin
    Block[Pos] := $80;
    if Pos > SizeOf(Block) - 9 then
    begin
      FillChar(Block[Pos + 1], SizeOf(Block) - Pos - 1, 0);
      MD5Calc(Block, State);
      FillChar(Block, SizeOf(Block), 0);
    end else
      FillChar(Block[Pos + 1], SizeOf(Block) - Pos - 9, 0);
    Move(Len, Block[SizeOf(Block) - 8], 8);
    MD5Calc(Block, State);
    Digest := State;
  end;
end;

function MD5Match(D1, D2: TMD5Digest): Boolean;
var
  i : LongInt;
begin
  for i := 0 to SizeOf(TMD5Digest) - 1 do
    if D1[i] <> D2[i] then
    begin
      Result := False;
      Exit;
    end;
  Result := True;
end;

function MD5String(const Str: WideString): TMD5Digest;
var
  Context : TMD5Context;
begin
  MD5Init(Context);
  MD5Update(Context, Str);
  MD5Final(Context, Result);
end;
{$ENDREGION}

{$REGION 'SHA1'}
procedure SHA1Calc(const SHA1Block: TSHA1Block; var State: TSHA1Digest);
var
  i : LongInt;
  a, b, c, d, e, f, g, t : LongWord;
  w : array [0..79] of LongWord;
begin
{$Q-}
  a := State[0];
  b := State[1];
  c := State[2];
  d := State[3];
  e := State[4];

  Move(SHA1Block, w, SizeOf(SHA1Block));
  for i := 0 to 15 do
    w[i] := SwapInt32(w[i]);
  for i := 16 to 79 do
  begin
    w[i] := w[i - 3] xor w[i - 8] xor w[i - 14] xor w[i - 16];
    w[i] := (w[i] shl 1) or (w[i] shr 31);
  end;

  for i := 0 to 79 do
  begin
    if i > 59 then
    begin
      f := b xor c xor d;
      g := $CA62C1D6;
    end else
      if i > 39 then
      begin
        f := (b and c) or (b and d) or (c and d);
        g := $8F1BBCDC;
      end else
        if i > 19 then
        begin
          f := b xor c xor d;
          g := $6ED9EBA1;
        end else
        begin
          f := d xor (b and (c xor d));
          g := $5A827999;
        end;

    t := LeftRotate(a, 5) + f + e + g + w[i];
    e := d;
    d := c;
    c := LeftRotate(b, 30);
    b := a;
    a := t;
  end;

  Inc(State[0], a);
  Inc(State[1], b);
  Inc(State[2], c);
  Inc(State[3], d);
  Inc(State[4], e);
end;

procedure SHA1Init(out Context: TSHA1Context);
begin
  Context.State[0] := $67452301;
  Context.State[1] := $EFCDAB89;
  Context.State[2] := $98BADCFE;
  Context.State[3] := $10325476;
  Context.State[4] := $C3D2E1F0;
  Context.Len := 0;
  Context.Pos := 0;
end;

procedure SHA1Update(var Context: TSHA1Context; const Data; Size: LongWord);
var
  Count : LongWord;
  ptr   : Pointer;
begin
  with Context do
  begin
    Len := Len + Size * 8;
    ptr := @Data;
    while Size > 0 do
    begin
      Count := SizeOf(Block) - Pos;
      if Size < Count then
        Count := Size;
      Move(ptr^, Block[Pos], Count);
      Inc(Pos, Count);
      Dec(Size, Count);
      ptr := Pointer(LongWord(ptr) + Count);
      if Pos = SizeOf(Block) then
      begin
        SHA1Calc(Block, State);
        Pos := 0;
      end;
    end;
  end;
end;

procedure SHA1Final(var Context: TSHA1Context; out Digest: TSHA1Digest);
var
  i : LongWord;
begin
  with Context do
  begin
    Block[Pos] := $80;
    if Pos > SizeOf(Block) - 9 then
    begin
      FillChar(Block[Pos + 1], SizeOf(Block) - Pos - 1, 0);
      SHA1Calc(Block, State);
      FillChar(Block, SizeOf(Block), 0);
    end else
      FillChar(Block[Pos + 1], SizeOf(Block) - Pos - 9, 0);
    LongWord(Pointer(@Block[SizeOf(Block) - 8])^) := SwapInt32(Len shr 32 and $FFFFFFFF);
    LongWord(Pointer(@Block[SizeOf(Block) - 4])^) := SwapInt32(Len and $FFFFFFFF);
    SHA1Calc(Block, State);
    for i := 0 to 4 do
      Digest[i] := SwapInt32(State[i]);
  end;
end;
{$ENDREGION}

var
  i : LongInt;

initialization
  for i := 0 to 63 do
    MD5Table[i] := Trunc(abs(sin(i + 1)) * 4294967296);

end.

