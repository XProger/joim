unit jimg;
// ---------------------------
// Image loader
// ---------------------------
// Date   : 31/03/2010
// Author : XProger (xproger@list.ru)
// Description :
//   Support PNG, JPG, GIF image formats
// TODO :
//   - Progressive JPG
//   - Interlaced PNG
//   - GIF animation
//   - PNG animation
// ---------------------------
interface

{$R-}

uses
  jsys, jutils, jzip;

  function LoadIMG(const Stream: TStream; out Data: PByteArray; out Width, Height: LongInt): Boolean;
  procedure ResampleIMG(const Data: PByteArray; const Width, Height: LongInt; out OutData: PByteArray; const OutWidth, OutHeight: LongInt);

{$IFDEF DEBUG}
  procedure TestImg(const FileName: string);
{$ENDIF}

function LoadJPG(const Stream: TStream; out Data: PByteArray; out Width, Height: LongInt): Boolean;


implementation

uses
  jglobal; // Log

{$REGION 'Common'}
procedure ClampByte(out Value: Byte; x: LongInt);
begin
  if x < 0 then
    Value := 0
  else
    if x > 255 then
      Value := 255
    else
      Value := x;
end;

// RGBA to BGRA
procedure RGBA2BGRA(Width: LongInt; Data: PByteArray);
var
  i : LongInt;
  t : Byte;
begin
  for i := 0 to Width - 1 do
  begin
    t := Data^[i * 4];
    Data^[i * 4]     := Data^[i * 4 + 2];
    Data^[i * 4 + 2] := t;
  end;
end;

// YCbCr to BGRA
procedure YCbCr2BGRA(Width: LongInt; Data: PByteArray);
var
  i, Y, Cb, Cr : LongInt;
  p : PByteArray;

  function Clamp(x: LongInt): Byte; inline;
  const
    MAX_SAMPLE = 255 * 1024;
  begin
    if x < 0 then x := 0;
    if x > MAX_SAMPLE then x := MAX_SAMPLE;
    Result := x shr 10;
  end;

begin
  for i := 0 to Width - 1 do
  begin
    p := @Data^[i * 4];
    Y  := p^[0] * 1024;
    Cb := p^[1] - 128;
    Cr := p^[2] - 128;
    p^[0] := Clamp(Y + 1815 * Cb + 512);
    p^[1] := Clamp(Y - 352 * Cb - 731 * Cr + 512);
    p^[2] := Clamp(Y + 1436 * Cr + 512);
    p^[3] := 255;
  end;
end;

// Grayscale to BGRA
procedure Gray2BGRA(Width: LongInt; Data: PByteArray);
var
  i : LongInt;
  p : PByteArray;
begin
  p := Data;
  for i := 0 to Width - 1 do
  begin
    p^[1] := p^[0];
    p^[2] := p^[0];
    p^[3] := 255;
    p := @Data^[i * 4 + 4];
  end;
end;
{$ENDREGION}

{$REGION 'PNG'}
function LoadPNG(const Stream: TStream; out Data: PByteArray; out Width, Height: LongInt): Boolean;
const
  IHDR = $52444849;
  IDAT = $54414449;
  IEND = $444E4549;
  PLTE = $45544C50;
  tRNS = $534E5274;
var
  i, j : LongInt;
  Bits : Byte;
  BPP  : Byte;
  BPL  : LongInt;
  ColorType : Byte;
  Interlace : Byte;
  ChunkSize : LongInt;
  ChunkName : LongWord;
  Size    : LongInt;
  Pos     : LongInt;
  Prev    : PByteArray;
  Buffer  : PByteArray;
  CData   : PByteArray;
  Palette : array [0..256 * 3 - 1] of Byte;
  Trans   : array [0..255] of Byte;
  DStream : TDecompressor;
  CurBit   : Byte;
  PalWord  : Word;
  CurByte  : LongInt;
  PalIdx   : Byte;

  function Paeth(A, B, C: LongInt): LongInt;
  var
    P, PA, PB, PC : LongInt;
  begin
    P := A + B - C;
    PA := Abs(P - A);
    PB := Abs(P - B);
    PC := Abs(P - C);
    if (PA <= PB) and (PA <= PC) then
      Result := A
    else
      if PB <= PC then
        Result := B
      else
        Result := C;
  end;

  procedure Filter(ID: LongInt; Source, Dest, Prev: PByteArray);
  var
    i : LongInt;
  begin
    case ID of
      0 : // no filter
        Move(Source^, Dest^, BPL);
      1 : // sub filter
        begin
          Move(Source^, Dest^, BPP);
          for i := BPP to BPL - 1 do
            Dest^[i] := (Source^[i] + Dest^[i - BPP]);
        end;
      2 : // up filter
        for i := 0 to BPL - 1 do
          Dest^[i] := (Source^[i] + Prev^[i]);
      3 : // average filter
        begin
          for i := 0 to BPP - 1 do
            Dest^[i] := (Source^[i] + Prev^[i] shr 1);
          for i := BPP to BPL - 1 do
            Dest^[i] := (Source^[i] + (Dest^[i - BPP] + Prev^[i]) shr 1);
        end;
      4 : // paeth filter
        begin
          for i := 0 to BPP - 1 do
            Dest^[i] := (Source^[i] + Paeth(0, Prev^[i], 0));
          for i := BPP to BPL - 1 do
            Dest^[i] := Source^[i] + Paeth(Dest^[i - BPP], Prev^[i], Prev^[i - BPP]);
        end;
    end;
  end;

begin
  Result := False;
  if Stream.Size < 8 then
    Exit;
  Pos  := 0;
  Buffer := nil;
  Bits := 0;
  ColorType := 0;
  Interlace := 0;
  Stream.Position := Stream.Position + 8;
  DStream := TDecompressor.Create;
// read chunks
  while Stream.Position < Stream.Size do
  begin
    ChunkSize := SwapInt32(Stream.ReadUInt32);
    Stream.Read(ChunkName, SizeOf(ChunkName));
    case ChunkName of
      IHDR : // Image Header
        begin
          Width     := SwapInt32(Stream.ReadUInt32);
          Height    := SwapInt32(Stream.ReadUInt32);
          Bits      := Stream.ReadUInt8;
          ColorType := Stream.ReadUInt8;
          Stream.Position := Stream.Position + 2;
          Interlace := Stream.ReadUInt8;

        // unsupported formats
          if (Bits > 8) then
          begin
            DStream.Free;
            Exit;
          end;

          case ColorType of
            2 : i := 3;
            4 : i := 2;
            6 : i := 4;
          else
            i := 1;
          end;

          BPP := (Bits + 7) div 8 * i;
          BPL := (Width * Bits + 7) div 8 * i;
          Size := BPL * Height;
          Data   := GetMemory(Size);
          Buffer := GetMemory(Size + Height);
          FillChar(Trans, SizeOf(Trans), $FF);
        end;
      PLTE : // Palette
        Stream.Read(Palette, ChunkSize);
      tRNS : // Transparency info
        Stream.Read(Trans, ChunkSize);
      IDAT : // Compressed image data part
        begin
          CData := GetMemory(ChunkSize);
          Stream.Read(CData^, ChunkSize);
          Inc(Pos, DStream.ReadBlock(@CData[2], @Buffer[Pos]));
          FreeMemory(CData);
        end;
    else
      Stream.Position := Stream.Position + ChunkSize;
    end;
    Stream.Position := Stream.Position + 4; // Chunk CRC
    if ChunkName = IEND then
      break;
  end;
  DStream.Free;

  if Buffer <> nil then
  begin
  // decode image lines
    if Interlace = 0 then
    begin
      Prev := GetMemory(BPL);
      FillChar(Prev^, BPL, 0);
      for i := 0 to Height - 1 do
      begin
        Filter(Buffer^[i * (BPL + 1)], @Buffer^[i * (BPL + 1) + 1], @Data^[(Height - i - 1) * BPL], Prev);
        if i = 0 then
          FreeMemory(Prev);
        Prev := @Data^[(Height - i - 1) * BPL];
      end;
      Result := True;
    end else
    begin
      FreeMemory(Buffer);
      FreeMemory(Data);
      Exit;
    end;
    FreeMemory(Buffer);

  // convert to RGBA
    if ColorType <> 6 then
    begin
      Buffer := GetMemory(Width * Height * 4);
      case ColorType of
        0 : // Grayscale
          for i := 0 to Width * Height - 1 do
          begin
            Buffer^[i * 4 + 0] := Data^[i];
            Buffer^[i * 4 + 1] := Data^[i];
            Buffer^[i * 4 + 2] := Data^[i];
            Buffer^[i * 4 + 3] := Trans[0];
          end;
        2 : // Truecolor RGB
          for i := 0 to Width * Height - 1 do
          begin
            Buffer^[i * 4 + 0] := Data^[i * 3 + 2];
            Buffer^[i * 4 + 1] := Data^[i * 3 + 1];
            Buffer^[i * 4 + 2] := Data^[i * 3 + 0];
            Buffer^[i * 4 + 3] := Trans[0];
          end;
        3 : // Indexed color
          begin
            CurByte := 0;
            PalWord := 0;
            for j := 0 to Height - 1 do
            begin
              CurBit := 8;
              for i := 0 to Width - 1 do
              begin
                if CurBit > 7 then
                begin
                  CurBit := CurBit - 8;
                  if i < Width - 1 then
                    PalWord := Data^[CurByte] or (Data^[CurByte + 1] shl 8)
                  else
                    PalWord := Data^[CurByte];
                  Inc(CurByte);
                end;
                PalIdx := (PalWord shr (8 - Bits - CurBit)) and not ($FFFF shl Bits);
                CurBit := CurBit + Bits;

                Buffer^[(j * Width + i) * 4 + 0] := Palette[PalIdx * 3 + 2];
                Buffer^[(j * Width + i) * 4 + 1] := Palette[PalIdx * 3 + 1];
                Buffer^[(j * Width + i) * 4 + 2] := Palette[PalIdx * 3 + 0];
                Buffer^[(j * Width + i) * 4 + 3] := Trans[PalIdx];
              end;
            end;
          end;
        4 : // Grayscale with Alpha
          for i := 0 to Width * Height - 1 do
          begin
            Buffer^[i * 4 + 0] := Data^[i * 2 + 0];
            Buffer^[i * 4 + 1] := Data^[i * 2 + 0];
            Buffer^[i * 4 + 2] := Data^[i * 2 + 0];
            Buffer^[i * 4 + 3] := Data^[i * 2 + 1];
          end;
      end;
      FreeMemory(Data);
      Data := Buffer;
    end;
  // Swap RGBA -> BGRA (if image is Truecolor with Alpha)
    if ColorType = 6 then
      for i := 0 to Height - 1 do
        RGBA2BGRA(Width, @Data^[i * Width * 4]);
  end;
end;
{$ENDREGION}

{$REGION 'JPG'}
function LoadJPG(const Stream: TStream; out Data: PByteArray; out Width, Height: LongInt): Boolean;
type
  THuffmanTable = record
    Bits : array [0..15] of Byte;
    HVal : array [Byte] of Byte;
    Size : array [Byte] of Byte;
    Code : array [Byte] of Word;
  end;

  TQTable = array [0..63] of Single;
  PQTable = ^TQTable;

  PHuffmanCode = ^THuffmanCode;
  THuffmanCode = record
    Node  : array [0..1] of PHuffmanCode;
    Value : Byte;
  end;

var
  ChunkName : Byte;
  ChunkSize : Word;
  BPP       : Byte;
  Component : array [0..2] of record
      id, h, v, t, td, ta : LongInt;
    end;
{
  Scan : record
      ss, se, ah, al : LongInt;
    end;
}
  i, j, k, l, m : LongInt;
  Interval      : LongInt;
//  Progressive : Boolean;
  CurByte  : Byte;
  CurBit   : LongInt;
  dc : array [0..2] of LongInt;

// huffman trees (AC, DC)
  HACode, HDCode : array [0..3] of PHuffmanCode;
// quantization table
  QTable : array [0..3] of TQTable;

  function ReadBit: LongInt;
  begin
    if CurBit = 0 then
    begin
      CurByte := Stream.ReadUInt8;
      if CurByte = $FF then
      begin
        while CurByte = $FF do
          CurByte := Stream.ReadUInt8;
        if (CurByte >= $D0) and (CurByte <= $D7) then
          FillChar(dc, SizeOf(dc), 0);
        if CurByte = 0 then
          CurByte := $FF
        else
          CurByte := Stream.ReadUInt8;
      end;
    end;
    Result := (CurByte shr (7 - CurBit)) and 1;
    CurBit := (CurBit + 1) mod 8;
  end;

  function ReadBits(num: LongInt): LongInt; { TODO : optimize (remove readbit) }
  var
    i : LongInt;
  begin
    Result := 0;
    for i := 0 to num - 1 do
      Result := (Result shl 1) or ReadBit;
  end;

  function Bit2Int(bit: Byte; i: LongInt): LongInt;
  begin
    if i shr (bit - 1) = 1 then
      Result := i
    else
      Result := -(i xor (1 shl bit - 1));
  end;

  function HuffmanInit: PHuffmanCode;
  begin
    New(Result);
    FillChar(Result^, SizeOf(THuffmanCode), 0);
  end;

  procedure HuffmanAdd(HCode: PHuffmanCode; Code: Word; Size, Value: Byte);
  var
    Bit : Byte;
  begin
    while Size > 0 do
    begin
      Bit := Code shr (Size - 1) and 1;
      if HCode^.Node[Bit] = nil then
        HCode^.Node[Bit] := HuffmanInit;
      HCode := HCode^.Node[Bit];
      Dec(Size);
    end;
    HCode^.Value := Value;
  end;

  function HuffmanGet(HCode: PHuffmanCode): Byte;
  begin
    while (HCode <> nil) and (HCode^.Node[0] <> HCode^.Node[1]) do // while nodes <> nil
      HCode := HCode^.Node[ReadBit];             // get next huffman node

    if HCode = nil then
      Result := 0
    else
      Result := HCode^.Value;
  end;

  procedure HuffmanFree(HCode: PHuffmanCode);
  begin
    if HCode <> nil then
    begin
      HuffmanFree(HCode^.Node[0]);
      HuffmanFree(HCode^.Node[1]);
      Dispose(HCode);
    end;
  end;

  procedure IDCT(Data: PFloatArray); // inverse DCT
  const
    c0 = 1.414213562;
    c1 = 1.847759065;
    c2 = 1.082392200;
    c3 = 2.613125930;
  var
    t0, t1, t2, t3, t4, t5, t6, t7, t10, t11, t12, t13, z5, z10, z11, z12, z13 : Single;
    p : PFloatArray;
    i : LongInt;
  begin
    for i := 0 to 7 do
    begin
      p := @Data[i];
      t0  := p^[8 * 0];
      t1  := p^[8 * 2];
      t2  := p^[8 * 4];
      t3  := p^[8 * 6];
      t10 := t0 + t2;
      t11 := t0 - t2;
      t13 := t1 + t3;
      t12 := -t13 + (t1 - t3) * c0;
      t0  := t10 + t13;
      t3  := t10 - t13;
      t1  := t11 + t12;
      t2  := t11 - t12;
      t4  := p^[8 * 1];
      t5  := p^[8 * 3];
      t6  := p^[8 * 5];
      t7  := p^[8 * 7];
      z13 := t6 + t5;
      z10 := t6 - t5;
      z11 := t4 + t7;
      z12 := t4 - t7;
      t7  := z11 + z13;
      t11 := (z11 - z13) * c0;
      z5  := (z10 + z12) * c1;
      t10 := -z5 + z12 * c2;
      t12 := z5 - z10 * c3;
      t6  := t12 - t7;
      t5  := t11 - t6;
      t4  := t10 + t5;
      p^[8 * 0] := t0 + t7;
      p^[8 * 7] := t0 - t7;
      p^[8 * 1] := t1 + t6;
      p^[8 * 6] := t1 - t6;
      p^[8 * 2] := t2 + t5;
      p^[8 * 5] := t2 - t5;
      p^[8 * 4] := t3 + t4;
      p^[8 * 3] := t3 - t4;
    end;
    for i := 0 to 7 do
    begin
      p := @Data^[i * 8];
      t10 := p^[0] + p^[4];
      t11 := p^[0] - p^[4];
      t13 := p^[2] + p^[6];
      t12 := -t13 + (p^[2] - p^[6]) * c0;
      t0  := t10 + t13;
      t3  := t10 - t13;
      t1  := t11 + t12;
      t2  := t11 - t12;
      z13 := p^[5] + p^[3];
      z10 := p^[5] - p^[3];
      z11 := p^[1] + p^[7];
      z12 := p^[1] - p^[7];
      t7  := z11 + z13;
      t11 := (z11 - z13) * c0;
      z5  := (z10 + z12) * c1;
      t10 := -z5 + z12 * c2;
      t12 := z5 - z10 * c3;
      t6  := t12 - t7;
      t5  := t11 - t6;
      t4  := t10 + t5;
      p^[0] := t0 + t7;
      p^[7] := t0 - t7;
      p^[1] := t1 + t6;
      p^[6] := t1 - t6;
      p^[2] := t2 + t5;
      p^[5] := t2 - t5;
      p^[4] := t3 + t4;
      p^[3] := t3 - t4;
    end;
  end;

  procedure Decompress; // baseline decompression
  const
    ZZI : array [0..63] of Byte = (
       0,  1,  8, 16,  9,  2,  3, 10,
      17, 24, 32, 25, 18, 11,  4,  5,
      12, 19, 26, 33, 40, 48, 41, 34,
      27, 20, 13,  6,  7, 14, 21, 28,
      35, 42, 49, 56, 57, 50, 43, 36,
      29, 22, 15, 23, 30, 37, 44, 51,
      58, 59, 52, 45, 38, 31, 39, 46,
      53, 60, 61, 54, 47, 55, 62, 63);
    aanscale : array [0..7] of Single = ( // 1.0, k = 0; cos(k * PI / 16) * sqrt(2), k = 1...7
      1.0, 1.387039845, 1.306562965, 1.175875602,
      1.0, 0.785694958, 0.541196100, 0.275899379);
  var
    DCT  : array [0..63] of Single;
    pDCT : PFloatArray;
    ScaleH, ScaleV : array [0..2] of LongInt;
    i, j, k, m, x, y, h, v, p : LongInt;
    dx, dy, mx, my : LongInt;
    Color : Byte;
    pData : PByteArray;
    q : PQTable;
  begin
    ScaleH[0] := 1;
    ScaleV[0] := 1;
    if BPP = 3 then
    begin
      ScaleH[1] := Component[0].h div Component[1].h;
      ScaleV[1] := Component[0].v div Component[1].v;
      ScaleH[2] := Component[0].h div Component[2].h;
      ScaleV[2] := Component[0].v div Component[2].v;
    end;

  // prepare QTables
    for k := 0 to BPP - 1 do
      for i := 0 to 63 do
      begin
        j := ZZI[i];
        QTable[k][i] := QTable[k][i] * aanscale[j mod 8] * aanscale[j div 8] * 0.125;
      end;

    FillChar(dc, SizeOf(dc), 0);
    CurBit := 0;
    y := 0;
    while y < Height do
    begin
      if Interval > 0 then
        CurBit := 0;
      x := 0;
      while x < Width do
      begin
        for p := 0 to BPP - 1 do
        begin
          q := @QTable[Component[p].t];
          for v := 0 to Component[p].v - 1 do
            for h := 0 to Component[p].h - 1 do
            begin
              i := HuffmanGet(HDCode[Component[p].td]) and $0F;
              Inc(dc[p], Bit2Int(i, ReadBits(i)));
              FillChar(DCT[1], SizeOf(DCT) - SizeOf(DCT[0]), 0);
              DCT[0] := dc[p] * q^[0];
              i := 1;
            // init dct
              while i < 64 do
              begin
                j := HuffmanGet(HACode[Component[p].ta]);
                if j <> 0 then
                begin
                  Inc(i, j shr 4);
                  j := j and $0F;
                  DCT[ZZI[i]] := Bit2Int(j, ReadBits(j)) * q^[i];
                  Inc(i);
                end else
                  break;
              end;

            // transform
              IDCT(@DCT);

            // fill data
              if (ScaleH[p] = 1) and (ScaleV[p] = 1) then
              begin
                dx := x + h * 8;
                dy := y + v * 8;
                mx := Min(7, Width - dx - 1);
                my := Min(7, Height - dy - 1);
                pData := @Data[((Height - dy - 1) * Width + dx) * 4 + p];
                pDCT  := @DCT[0];
                for dy := 0 to my do
                begin
                  for dx := 0 to mx do
                    ClampByte(pData^[dx * 4], Round(pDCT^[dx]) + 128);
                  pDCT  := @pDCT^[8];
                  pData := @pData^[-Width * 4];
                end;
              end else
                for k := 0 to 63 do
                begin
                  ClampByte(Color, Round(DCT[k]) + 128);
                  for m := 0 to ScaleH[p] * ScaleV[p] - 1 do
                  begin
                    i := x + (k mod 8 + h * 8) * ScaleH[p] + m mod ScaleH[p];
                    j := y + (k div 8 + v * 8) * ScaleV[p] + m div ScaleH[p];
                    if (i < Width) and (j < Height) then
                      Data^[((Height - j - 1) * Width + i) * 4 + p] := Color;
                  end;
                end;
            end;
        end;
        Inc(x, Component[0].h * 8);
      end;
      Inc(y, Component[0].v * 8);
    end;
  end;

var
  HC    : PHuffmanCode;
  Code  : LongWord;
  Bits  : array [0..15] of Byte;
begin
  Result := False;
  Stream.Position := Stream.Position + 2;
  BPP := 1;
  Interval := 0;
//  Progressive := False;
  for i := 0 to 3 do
  begin
    HACode[i] := HuffmanInit;
    HDCode[i] := HuffmanInit;
  end;

  while Stream.Position < Stream.Size do
  begin
    Stream.Position := Stream.Position + 1; // skip $FF chunk start
    ChunkName := Stream.ReadUInt8;
    ChunkSize := SwapInt16(Stream.ReadUInt16) - 2;
    case ChunkName of
      $C0{, $C2} : // baseline/progressive (huffman)
        begin
        //  Progressive := ChunkName = $C2;
          Stream.Position := Stream.Position + 1; // skip precision
          Height := SwapInt16(Stream.ReadUInt16);
          Width  := SwapInt16(Stream.ReadUInt16);
          BPP    := Stream.ReadUInt8;
          if BPP * 3 <> ChunkSize - 6 then
            break;
          for i := 0 to BPP - 1 do
            with Component[i] do
            begin
              id := Stream.ReadUInt8;
              j  := Stream.ReadUInt8;
              h := j shr 4 and $0F;
              v := j and $0F;
              t := Stream.ReadUInt8;
            end;
        end;
      $C4 : // huffman table
        while ChunkSize > 0 do
        begin
          k := Stream.ReadUInt8;
          if k and $10 > 0 then
            HC := HACode[k and $0F]
          else
            HC := HDCode[k and $0F];

          Dec(ChunkSize, 17);
          Code := 0;
          Stream.Read(Bits, 16);
          for i := 0 to 15 do
          begin
            Dec(ChunkSize, Bits[i]);
            for j := 0 to Bits[i] - 1 do
            begin
              HuffmanAdd(HC, Code, i + 1, Stream.ReadUInt8);
              Inc(Code);
            end;
            Code := Code shl 1;
          end;
        end;
      $DB : // quantization table
        while ChunkSize > 0 do
        begin
          j := Stream.ReadUInt8;
          if j shr 4 and $0F > 0 then
          begin
            for i := 0 to 63 do
              QTable[j][i] := SwapInt16(Stream.ReadUInt16);
            Dec(ChunkSize, 129);
          end else
          begin
            for i := 0 to 63 do
              QTable[j][i] := Stream.ReadUInt8;
            Dec(ChunkSize, 65);
          end;
        end;
      $D9 : // end of image
        break;
      $DA : // start of scan
        begin
          j := Stream.ReadUInt8;
          for i := 0 to j - 1 do
          begin
            k := Stream.ReadUInt8;
            m := Stream.ReadUInt8;
            for l := 0 to BPP - 1 do
              if Component[l].id = k then
              begin
                Component[l].td := m shr 4 and $0F;
                Component[l].ta := m and $0F;
              end;
          end;
          {Scan.ss :=} Stream.ReadUInt8;
          {Scan.se :=} Stream.ReadUInt8;
          {k := }Stream.ReadUInt8;
//          Scan.ah := k shr 4 and $0F;
//          Scan.al := k and $0F;
          Result := True;
          break;
        end;
      $DD :
        Interval := SwapInt16(Stream.ReadUInt16);
      $C1, $C2, $C3, $C5..$CF : // unsupported format
        break;
    else
      Stream.Position := Stream.Position + ChunkSize;
    end;
  end;

  if Result then
  begin
    Data := GetMemory(Width * Height * 4);
    Decompress;
    case BPP of
      1 : for i := 0 to Height - 1 do
            Gray2BGRA(Width, @Data[i * Width * 4]);
      3 : for i := 0 to Height - 1 do
            YCbCr2BGRA(Width, @Data[i * Width * 4]);
    end;
  end;

// free huffman tables
  for i := 0 to 3 do
  begin
    HuffmanFree(HACode[i]);
    HuffmanFree(HDCode[i]);
  end;
end;
{$ENDREGION}

{$REGION 'GIF'}
function LoadGIF(const Stream: TStream; out Data: PByteArray; out Width, Height: LongInt): Boolean;

  procedure DecompressLZW(InitCodeSize: Byte; Source, Dest: Pointer; PackedSize, UnpackedSize: LongInt);
  const
    NoLZWCode = 4096;
  var
    I: LongInt;
    Data, Bits, Code : LongWord;
    SourcePtr : ^Byte;
    InCode : LongWord;
    CodeSize, CodeMask, FreeCode, OldCode : LongWord;
    Prefix : array [0..4095] of LongWord;
    Suffix, Stack : array [0..4095] of Byte;
    StackPointer,Target : ^Byte;
    FirstChar : Byte;
    ClearCode, EOICode : Word;
  begin
    Target    := Dest;
    SourcePtr := Source;
    CodeSize  := InitCodeSize + 1;
    ClearCode := 1 shl InitCodeSize;
    EOICode   := ClearCode+1;
    FreeCode  := ClearCode+2;
    OldCode   := NoLZWCode;
    CodeMask  := (1 shl CodeSize) - 1;
    for i := 0 to ClearCode - 1 do
    begin
      Prefix[i] := NoLZWCode;
      Suffix[i] := i;
    end;
    StackPointer := @Stack;
    FirstChar := 0;
    Data := 0;
    Bits := 0;
    while (UnpackedSize > 0) and (PackedSize > 0) do
    begin
    // read code from bit stream
      Inc(Data, SourcePtr^ shl Bits);
      Inc(Bits, 8);
      while Bits >= CodeSize do
      begin
      // current code
        Code := Data and CodeMask;
      // prepare next run
        Data := Data shr CodeSize;
        Dec(Bits, CodeSize);
      // decoding finished?
        if Code = EOICode then
          break;
      // handling of clear codes
        if Code = ClearCode then
        begin
        // reset of all variables
          CodeSize := InitCodeSize + 1;
          CodeMask:=(1 shl CodeSize)-1;
          FreeCode:=ClearCode+2;
          OldCode:=NoLZWCode;
          continue;
        end;
      // check whether it is a valid, already registered code
        if Code > FreeCode then
          break;
      // handling for the first LZW code: print and keep it
        if OldCode = NoLZWCode then
        begin
          FirstChar := Suffix[Code];
          Target^    := FirstChar;
          Inc(Target);
          Dec(UnpackedSize);
          OldCode := Code;
          continue;
        end;
      // keep the passed LZW code
        InCode := Code;
      // the first LZW code is always smaller than FFirstCode
        if Code = FreeCode then
        begin
          StackPointer^ := FirstChar;
          Inc(StackPointer);
          Code := OldCode;
        end;
      // loop to put decoded bytes onto the stack
        while Code > ClearCode do
        begin
          StackPointer^ := Suffix[Code];
          Inc(StackPointer);
          Code := Prefix[Code];
        end;
      // place new code into code table
        FirstChar     := Suffix[Code];
        Stackpointer^ := FirstChar;
        Inc(Stackpointer);
        Prefix[FreeCode] := OldCode;
        Suffix[FreeCode] := FirstChar;
      // increase code size if necessary
        if (FreeCode = CodeMask) and (CodeSize < 12) then
        begin
          Inc(CodeSize);
          CodeMask := 1 shl CodeSize - 1;
        end;
        if FreeCode < 4095 then
          Inc(FreeCode);
      // put decoded bytes (from the stack) into the target Buffer
        OldCode := InCode;
        repeat
          Dec(StackPointer);
          Target^ := StackPointer^;
          Inc(Target);
          Dec(UnpackedSize);
        until StackPointer = @Stack;
      end;
      Inc(SourcePtr);
      Dec(PackedSize);
    end;
  end;

const
  GIF_TABLE_FLAG  = $80;
  GIF_TABLE_SIZE  = $07;
  GIF_BLOCK_IMAGE = $2C;
  GIF_BLOCK_EXT   = $21;
  GIF_BLOCK_END   = $3B;
  GIF_INTERLACED  = $40;

  PASS_S : array [0..4] of Byte = (0, 0, 4, 2, 1);
  PASS_I : array [0..4] of Byte = (1, 8, 8, 4, 2);

var
  Header : packed record
    Magic   : array [0..2] of Byte;
    Version : array [0..2] of Byte;
    Width   : Word;
    Height  : Word;
    Flags   : Byte;
    BgColor : Byte;
    Aspect  : Byte;
  end;

  Image : packed record
    Left, Top     : Word;
    Width, Height : Word;
    Flags         : Byte;
  end;

  Pallete : array [Byte, 0..4] of Byte;
  ChunkName, Size, Ext, Flag, b, InitCodeSize : Byte;
  Buffer : PByteArray;
  BufSize : LongInt;
  IndexBuffer : PByteArray;
  i, x, y : LongInt;
begin
  Result := False;
  Stream.Read(Header, SizeOf(Header));
  if Header.Flags and GIF_TABLE_FLAG > 0 then
    for i := 0 to (1 shl (Header.Flags and GIF_TABLE_SIZE + 1)) - 1 do
    begin
      Pallete[i][2] := Stream.ReadUInt8;
      Pallete[i][1] := Stream.ReadUInt8;
      Pallete[i][0] := Stream.ReadUInt8;
      Pallete[i][3] := 255;
    end;
//  Log('gPallete: ', 1 shl (Header.Flags and GIF_TABLE_SIZE + 1));
  while Stream.Position < Stream.Size do
  begin
    Stream.Read(ChunkName, SizeOf(ChunkName));
  //  Log(ConvHex(ChunkName, 1));
    case ChunkName of
      GIF_BLOCK_IMAGE :
        begin
          Stream.Read(Image, SizeOf(Image));
          if Image.Flags and GIF_TABLE_FLAG > 0 then
          begin
            Stream.Position := Stream.Position + (1 shl (Image.Flags and GIF_TABLE_SIZE + 1)) * 3;
//            Log('lPallete: ', 1 shl (Image.Flags and GIF_TABLE_SIZE + 1));
          end;
          Stream.Read(InitCodeSize, SizeOf(InitCodeSize));

          if not Result then
          begin
            Width  := Header.Width;
            Height := Header.Height;
            Data := GetMemory(Width * Height * 4);
            Result := True;
          end;
        // get compressed data size
          BufSize := 0;
          i := Stream.Position;
          repeat
            Stream.Read(Size, SizeOf(Size));
            Inc(BufSize, Size);
            Stream.Position := Stream.Position + Size;
          until (Size = 0);
          Stream.Position := i;
        // get compressed data
          i := 0;
          Buffer := GetMemory(BufSize);
          repeat
            Stream.Read(Size, SizeOf(Size));
            Stream.Read(Buffer[i], Size);
            Inc(i, Size);
          until (Size = 0);
        // decompress data
          IndexBuffer := GetMemory(Width * (Height + 1)); // with reserved
          FillChar(IndexBuffer^, Width * (Height + 1), 0); // temp
          DecompressLZW(InitCodeSize, Buffer, IndexBuffer, BufSize, Width * (Height + 1));
          FreeMemory(Buffer);
        // fill data from pallete indices
          Buffer := IndexBuffer;
          x := Byte(Image.Flags and GIF_INTERLACED > 0);
          y := x * 4;
          for i := x to y do
          begin
            y := PASS_S[i];
            while y < Height do
            begin
              for x := 0 to Width - 1 do
                Move(Pallete[Buffer^[x]], Data^[((Height - y - 1) * Width + x) * 4], 4);
              Buffer := @Buffer^[Width];
              Inc(y, PASS_I[i]);
            end;
          end;
          FreeMemory(IndexBuffer);
          Exit; // load only first frame
        end;
      GIF_BLOCK_EXT :
        begin
          Stream.Read(Ext, SizeOf(Ext));
          Stream.Read(Size, SizeOf(Size));
          Flag := Stream.ReadUInt8;
          case Ext of
            $F9 : // Frame information
              begin
                Stream.ReadUInt16; // delay...
                b := Stream.ReadUInt8;
                if Flag and 1 > 0 then
                  Pallete[b][3] := 0; // Transparent color
                Size := 0;
              end;
          end;
          while Size > 0 do
          begin
            Stream.Position := Stream.Position + Size;
            Stream.Read(Size, SizeOf(Size));
          end;
        end;
      GIF_BLOCK_END :
        break;
    end;
  end;
end;
{$ENDREGION}

{$REGION 'Image Functions'}
function LoadIMG(const Stream: TStream; out Data: PByteArray; out Width, Height: LongInt): Boolean;
const
  MAGIC_PNG = $474E5089;
  MAGIC_JPG = $E0FFD8FF;
  MAGIC_GIF = $38464947;
var
  Magic : LongWord;
{$IFDEF DEBUG}
  Str : WideString;
{$ENDIF}
begin
  Result := False;

  try
    Stream.Read(Magic, SizeOf(Magic));
    Stream.Position := Stream.Position - SizeOf(Magic);
    case Magic of
      MAGIC_JPG : Result := LoadJPG(Stream, Data, Width, Height);
      MAGIC_PNG : Result := LoadPNG(Stream, Data, Width, Height);
      MAGIC_GIF : Result := LoadGIF(Stream, Data, Width, Height);
    end;
  except
    if Data <> nil then
      FreeMemory(Data);
    Data := nil;
    Result := False;
  end;

{$IFDEF DEBUG}
  if not Result then
  begin
    Str := 'not supported image format: ';
    case Magic of
      MAGIC_PNG : Str := Str + 'png';
      MAGIC_JPG : Str := Str + 'jpg';
      MAGIC_GIF : Str := Str + 'gif';
    else
      Str := Str + 'unknown';
    end;
    Writeln(Str);
  end else
    Writeln('--- image: ', Width, ' x ', Height);
{$ENDIF}
end;

procedure ResampleIMG(const Data: PByteArray; const Width, Height: LongInt; out OutData: PByteArray; const OutWidth, OutHeight: LongInt);
var
  i, j : LongInt;
  f    : array [0..1] of LongWord;
  Row  : array [0..1] of PByteArray;
  Pix  : array [0..3] of PByteArray;
  p    : array [0..1] of PLongArray;
  Step : LongInt;
  Buf  : PByteArray;
begin
  Step := Width * $10000 div OutWidth;

  p[0] := GetMemory(OutWidth * 4);
  p[1] := GetMemory(OutWidth * 4);

  f[0] := Step shr 2;
  f[1] := Step shr 2 * 3;
  for i := 0 to OutWidth - 1 do
  begin
    p[0]^[i] := 4 * (f[0] shr 16);
    p[1]^[i] := 4 * (f[1] shr 16);
    Inc(f[0], Step);
    Inc(f[1], Step);
  end;

  OutData := GetMemory(OutWidth * OutHeight * 4);
  Buf := OutData;
  for i := 0 to OutHeight - 1 do
  begin
    Row[0] := @Data[4 * Width * Trunc((i + 0.25) * Height / OutHeight)];
    Row[1] := @Data[4 * Width * Trunc((i + 0.75) * Height / OutHeight)];
    for j := 0 to OutWidth - 1 do
    begin
      Pix[0] := @Row[0][p[0]^[j]];
      Pix[1] := @Row[0][p[1]^[j]];
      Pix[2] := @Row[1][p[0]^[j]];
      Pix[3] := @Row[1][p[1]^[j]];
      Buf^[j * 4 + 0] := (Pix[0]^[0] + Pix[1]^[0] + Pix[2]^[0] + Pix[3]^[0]) shr 2;
      Buf^[j * 4 + 1] := (Pix[0]^[1] + Pix[1]^[1] + Pix[2]^[1] + Pix[3]^[1]) shr 2;
      Buf^[j * 4 + 2] := (Pix[0]^[2] + Pix[1]^[2] + Pix[2]^[2] + Pix[3]^[2]) shr 2;
      Buf^[j * 4 + 3] := (Pix[0]^[3] + Pix[1]^[3] + Pix[2]^[3] + Pix[3]^[3]) shr 2;
    end;
    Buf := @Buf^[OutWidth * 4];
  end;

  FreeMemory(p[0]);
  FreeMemory(p[1]);
end;
{$ENDREGION}

{$REGION 'DEBUG'}
procedure TestImg(const FileName: string);
var
  TGA : packed record
    FileType       : Byte;
    ColorMapType   : Byte;
    ImageType      : Byte;
    ColorMapStart  : Word;
    ColorMapLength : Word;
    ColorMapDepth  : Byte;
    OrigX          : Word;
    OrigY          : Word;
    iWidth         : Word;
    iHeight        : Word;
    iBPP           : Byte;
    ImageInfo      : Byte;
  end;

  Stream : TStream;
  Data : PByteArray;
  Width, Height : LongInt;
  t : LongWord;
//  Freq, OldCount, NewCount : Int64;
begin
{
  QueryPerformanceFrequency(Freq);
  QueryPerformanceCounter(OldCount);
  inStream := Classes.TFileStream.Create(FileName, fmOpenReadWrite);
  outStream := Classes.TFileStream.Create('res_' + FileName, fmCreate);
  LoadJPEG(inStream, outStream, False, 0, @JPEG_ProgressMonitor);
  QueryPerformanceCounter(NewCount);
  Log(Conv(LongInt(Trunc((NewCount - OldCount) / Freq * 1000))));
  inStream.Free;
  outStream.Free;

  Exit;  }

  Data := nil;
  Stream := TFileStream.CreateInMemory(FileName);
//  QueryPerformanceFrequency(Freq);
//  QueryPerformanceCounter(OldCount);
  t := GetTime;
  if LoadIMG(Stream, Data, Width, Height) then
  begin
    Writeln(GetTime - t);
    Readln;
//    QueryPerformanceCounter(NewCount);
//    Log(Conv(LongInt(Trunc((NewCount - OldCount) / Freq * 1000))));
    Stream.Free;
{
    ResampleIMG(Data, Width, Height, p, Width * 5, Height * 5);
    Width := Width * 5;
    Height := Height * 5;
    FreeMemory(Data);
    Data := p;
}
    Stream := TFileStream.Create('result.tga', fmWrite);
    if Data <> nil then
    begin
      FillChar(TGA, SizeOf(TGA), 0);
      TGA.iWidth    := Width;
      TGA.iHeight   := Height;
      TGA.ImageType := 2;
      TGA.iBPP      := 32;
      Stream.Write(TGA, SizeOf(TGA));
      Stream.Write(Data^, Width * Height * 4);
      FreeMemory(Data);
    end;
  end;
  Stream.Free;
end;
{$ENDREGION}

end.
