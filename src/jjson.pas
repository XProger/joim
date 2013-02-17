unit jjson;

interface

type
  TJSON = class
    constructor Create(const Text: WideString);
    destructor Destroy; override;
  private
    FCount : LongInt;
    FValue : WideString;
    FNode  : array of TJSON;
    function GetNode(const Value: WideString): TJSON;
    function GetNodeI(Idx: LongInt): TJSON;
  public
    property Count: LongInt read FCount;
    property Value: WideString read FValue;
    property Node[const Value: WideString]: TJSON read GetNode; default;
    property NodeI[Idx: LongInt]: TJSON read GetNodeI;
  end;

implementation

constructor TJSON.Create(const Text: WideString);
begin
  //
end;

destructor TJSON.Destroy;
var
  i : LongInt;
begin
  for i := 0 to Count - 1 do
    FNode[i].Free;
  inherited;
end;

function TJSON.GetNode(const Value: WideString): TJSON;
//var
//  i : LongInt;
begin
{
  for i := 0 to Count - 1 do
    if FNode[i].Name = Name then
    begin
      Result := FNode[i];
      Exit;
    end;
}
  Result := nil;
end;

function TJSON.GetNodeI(Idx: Integer): TJSON;
begin
  Result := FNode[Idx];
end;

end.
