unit jmem;

interface

uses
  cmem, jsys;

implementation

var
  CS  : TCriticalSection;
  OldMan : TMemoryManager;

function JGetMem(Size: PtrInt): Pointer;
begin
  CS.Lock;
  Result := OldMan.GetMem(Size);
  CS.Unlock;
end;

function JFreeMem(p: Pointer): PtrInt;
begin
  CS.Lock;
  Result := OldMan.FreeMem(p);
  CS.Unlock;
end;

function JFreeMemSize(p: Pointer; Size: PtrInt): PtrInt;
begin
  CS.Lock;
  Result := OldMan.FreeMemSize(p, Size);
  CS.Unlock;
end;

function JAllocMem(Size: PtrInt): Pointer;
begin
  CS.Lock;
  Result := OldMan.AllocMem(Size);
  CS.Unlock;
end;

function JReAllocMem(var p: Pointer; Size: PtrInt): Pointer;
begin
  CS.Lock;
  Result := OldMan.ReallocMem(p, Size);
  CS.Unlock;
end;

function JMemSize(p: Pointer): PtrInt;
begin
  CS.Lock;
  Result := OldMan.MemSize(p);
  CS.Unlock;
end;

function JGetHeapStatus: THeapStatus;
begin
  CS.Lock;
  Result := OldMan.GetHeapStatus;
  CS.Unlock;
end;

function JGetFPCHeapStatus: TFPCHeapStatus;
begin
  CS.Lock;
  Result := OldMan.GetFPCHeapStatus;
  CS.Unlock;
end;

var
  MemManager : TMemoryManager = (
    NeedLock : False;
    GetMem : @JGetmem;
    FreeMem : @JFreeMem;
    FreememSize : @JFreememSize;
    AllocMem : @JAllocMem;
    ReallocMem : @JReAllocMem;
    MemSize : @JMemSize;
    InitThread : nil;
    DoneThread : nil;
    RelocateHeap : nil;
    GetHeapStatus : @JGetHeapStatus;
    GetFPCHeapStatus: @JGetFPCHeapStatus;
  );

initialization
  CS.Init;
  GetMemoryManager(OldMan);
  SetMemoryManager(MemManager);

finalization
  SetMemoryManager(OldMan);
  CS.Free;

end.
