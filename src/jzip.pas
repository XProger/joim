unit jzip;
// based on C++ core "tiny inflate" by Joergen Ibsen / Jibz
// http://www.ibsensoftware.com/
interface

{$R-}

uses
  jsys, jutils;

const
  TINF_OK         =  0;
  TINF_DATA_ERROR = -3;

type
  TINF_TREE = record
    table : array [0..15] of Word;
    trans : array [0..288] of Word;
  end;

  TINF_DATA = record
    source   : PByteArray;
    tag      : LongWord;
    bitcount : LongWord;
    dest     : PByteArray;
    destLen  : LongWord;
    ltree    : TINF_TREE;
    dtree    : TINF_TREE;
  end;

  TDecompressor = class
    constructor Create;
  private
    sltree : TINF_TREE;
    sdtree : TINF_TREE;
  public
    function ReadBlock(Source, Dest: PByteArray): LongInt;
    function ReadZLIB(Source, Dest: PByteArray): LongInt;
    function ReadGZIP(Source, Dest: PByteArray): LongInt;
    function SizeGZIP(Source: PByteArray; CSize: LongWord): LongWord;
  end;

implementation

var
  gsltree : TINF_TREE;
  gsdtree : TINF_TREE;
  length_bits : array [0..29] of Byte;
  length_base : array [0..29] of Word;
  dist_bits   : array [0..29] of Byte;
  dist_base   : array [0..29] of Word;

procedure tinf_build_bits_base(bits: PByteArray; base: PWordArray; delta, first: LongInt);
var
  i, sum : LongInt;
begin
  FillChar(bits[0], delta, 0);
  for i := 0 to 30 - delta - 1 do
    bits[i + delta] := i div delta;
  sum := first;
  for i := 0 to 29 do
  begin
    base[i] := sum;
    sum := sum + 1 shl bits[i];
  end;
end;

procedure tinf_build_fixed_trees(var lt, dt: TINF_TREE);
var
  i : LongInt;
begin
  FillChar(lt.table[0], 7 * SizeOf(lt.table[0]), 0);
  lt.table[7] := 24;
  lt.table[8] := 152;
  lt.table[9] := 112;
  for i := 0 to 23  do lt.trans[i]       := 256 + i;
  for i := 0 to 143 do lt.trans[i + 24]  := i;
  for i := 0 to 7   do lt.trans[i + 168] := 280 + i;
  for i := 0 to 111 do lt.trans[i + 176] := 144 + i;
  FillChar(dt.table[0], 5 * SizeOf(dt.table[0]), 0);
  dt.table[5] := 32;
  for i := 0 to 31 do dt.trans[i] := i;
end;

procedure tinf_build_tree(var t: TINF_TREE; lengths: PByteArray; num: LongInt);
var
  offs   : array [0..15] of Word;
  i, sum : LongWord;
begin
  FillChar(t.table[0], 16 * SizeOf(t.table[0]), 0);
  for i := 0 to num - 1 do Inc(t.table[lengths[i]]);
  t.table[0] := 0;
  sum := 0;
  for i := 0 to 15 do
  begin
    offs[i] := sum;
    Inc(sum, t.table[i]);
  end;
  for i := 0 to num - 1 do
    if lengths[i] <> 0 then
    begin
      t.trans[offs[lengths[i]]] := i;
      Inc(offs[lengths[i]]);
    end;
end;

function tinf_getbit(var d: TINF_DATA): LongInt;
var
  bit : LongWord;
begin
  if d.bitcount = 0 then
  begin
    d.tag := d.source[0];
    d.source := @d.source[1];
    d.bitcount := 8;
  end;
  Dec(d.bitcount);
  bit := d.tag and 1;
  d.tag := d.tag shr 1;
  Result := bit;
end;

function tinf_read_bits(var d: TINF_DATA; num, base: LongInt): LongWord;
var
  val, limit, mask : LongWord;
begin
  val := 0;
  if num <> 0 then
  begin
    limit := 1 shl num;
    mask := 1;
    while mask < limit do
    begin
      if tinf_getbit(d) <> 0 then
        Inc(val, mask);
      mask := mask * 2;
    end;
  end;
  Result := val + LongWord(base);
end;

function tinf_decode_symbol(var d: TINF_DATA; const t: TINF_TREE): LongInt;
var
  sum, cur, len : LongInt;
begin
  sum := 0; cur := 0; len := 0;
  repeat
    cur := 2 * cur + tinf_getbit(d);
    Inc(len);
    Inc(sum, t.table[len]);
    Dec(cur, t.table[len]);
  until (cur < 0);
  Result := t.trans[sum + cur];
end;

procedure tinf_decode_trees(var d: TINF_DATA; var lt, dt: TINF_TREE);
const
  clcidx : array [0..18] of Byte = (16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15);
var
  code_tree : TINF_TREE;
  lengths   : array [0..288+32 - 1] of Byte;
  hlit, hdist, hclen, clen, i, num, length : LongWord;
  sym : LongInt;
  prev : Byte;
begin
  hlit  := tinf_read_bits(d, 5, 257);
  hdist := tinf_read_bits(d, 5, 1);
  hclen := tinf_read_bits(d, 4, 4);
  FillChar(lengths[0], 19, 0);
  for i := 0 to hclen - 1 do
  begin
    clen := tinf_read_bits(d, 3, 0);
    lengths[clcidx[i]] := clen;
  end;
  tinf_build_tree(code_tree, @lengths, 19);

  num := 0;
  while num < hlit + hdist do
  begin
    sym := tinf_decode_symbol(d, code_tree);
    case sym of
      16 :
        begin
          prev := lengths[num - 1];
          length := tinf_read_bits(d, 2, 3);
          FillChar(lengths[num], length, prev);
          Inc(num, length);
        end;
      17 :
        begin
          length := tinf_read_bits(d, 3, 3);
          FillChar(lengths[num], length, 0);
          Inc(num, length);
        end;
      18 :
        begin
          length := tinf_read_bits(d, 7, 11);
          FillChar(lengths[num], length, 0);
          Inc(num, length);
        end;
      else
        lengths[num] := sym;
        Inc(num);
    end;
  end;

  tinf_build_tree(lt, @lengths, hlit);
  tinf_build_tree(dt, @lengths[hlit], hdist);
end;

function tinf_inflate_block_data(var d: TINF_DATA; var lt, dt: TINF_TREE): LongInt;
var
  Start : PByteArray;
  i, length, dist, offs, sym : LongInt;
begin
   start := d.dest;
   while true do
   begin
     sym := tinf_decode_symbol(d, lt);

     if sym = 256 then
     begin
       Inc(d.destLen, LongWord(d.dest) - LongWord(start));
       break;
     end;

     if sym < 256 then
     begin
       d.dest[0] := sym;
       d.dest := @d.dest[1];
     end else
     begin
       Dec(sym, 257);
       length := tinf_read_bits(d, length_bits[sym], length_base[sym]);
       dist := tinf_decode_symbol(d, dt);
       offs := tinf_read_bits(d, dist_bits[dist], dist_base[dist]);
       for i := 0 to length - 1 do
         d.dest[i] := d.dest[i - offs];
       d.dest := @d.dest[length];
    end;
  end;
  Result := TINF_OK;
end;

function tinf_inflate_uncompressed_block(var d: TINF_DATA): LongInt;
var
  length, invlength : LongWord;
begin
  length    := d.source[0] + 256 * d.source[1];
  invlength := d.source[2] + 256 * d.source[3];

  if (length <> (not invlength) and $FFFF) then
  begin
    Result := TINF_DATA_ERROR;
    Exit;
  end;

  d.source := @d.source[4];
  Move(d.source[0], d.dest[0], length);
  d.dest   := @d.dest[length];
  d.source := @d.source[length];

  d.bitcount := 0;
  Inc(d.destLen, length);

  Result := TINF_OK;
end;

function tinf_inflate_dynamic_block(var d: TINF_DATA): LongInt;
begin
  tinf_decode_trees(d, d.ltree, d.dtree);
  Result := tinf_inflate_block_data(d, d.ltree, d.dtree);
end;

constructor TDecompressor.Create;
begin
  inherited Create;
  Move(gsltree, sltree, SizeOf(TINF_TREE));
  Move(gsdtree, sdtree, SizeOf(TINF_TREE));
end;

function TDecompressor.ReadBlock(Source, Dest: PByteArray): LongInt;
var
  d : TINF_DATA;
  btype : LongWord;
  bfinal, res : LongInt;
begin
  d.source   := Source;
  d.bitcount := 0;
  d.dest     := Dest;
  d.destLen  := 0;

  repeat
    bfinal := tinf_getbit(d);
    btype  := tinf_read_bits(d, 2, 0);
    case btype of
      0 : res := tinf_inflate_uncompressed_block(d);
      1 : res := tinf_inflate_block_data(d, sltree, sdtree);
      2 : res := tinf_inflate_dynamic_block(d);
    else
      res := TINF_DATA_ERROR;
    end;
  until (bfinal <> 0) or (res <> TINF_OK);
  Result := d.destLen;
end;

function TDecompressor.ReadZLIB(Source, Dest: PByteArray): LongInt;
begin
  Result := ReadBlock(@Source[2], Dest);
end;

function TDecompressor.ReadGZIP(Source, Dest: PByteArray): LongInt;
const
  FTEXT    = 1;
  FHCRC    = 2;
  FEXTRA   = 4;
  FNAME    = 8;
  FCOMMENT = 16;
var
  Flag  : Byte;
  Start : PByteArray;
begin
  Result := 0; // not inflate
  if Source[2] <> 8 then
    Exit;
  Flag := Source[3];
  if Flag and $E0 > 0 then
    Exit;
  Start := @Source[10];
// skip extra info
  if Flag and FEXTRA > 0 then
    Start := @Start[Start[0] + Start[1] * 256 + 2];
// skip file name
  if Flag and FNAME > 0 then
  begin
    while Start[0] <> 0 do
      Start := @Start[1];
    Start := @Start[1];
  end;
// skip file comment
  if Flag and FCOMMENT > 0 then
  begin
    while Start[0] <> 0 do
      Start := @Start[1];
    Start := @Start[1];
  end;
// skip crc
  if Flag and FHCRC > 0 then
    Start := @Start[Start[0] + Start[1] * 256 + 2];
  Result := ReadBlock(Start, Dest);
end;

function TDecompressor.SizeGZIP(Source: PByteArray; CSize: LongWord): LongWord;
begin
  Result := Source[CSize - 1];
  Result := 256 * Result + Source[CSize - 2];
  Result := 256 * Result + Source[CSize - 3];
  Result := 256 * Result + Source[CSize - 4];
end;

initialization
  tinf_build_fixed_trees(gsltree, gsdtree);
  tinf_build_bits_base(@length_bits, @length_base, 4, 3);
  tinf_build_bits_base(@dist_bits, @dist_base, 2, 1);
  length_bits[28] := 0;
  length_base[28] := 258;

end.
