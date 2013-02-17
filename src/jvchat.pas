unit jvchat;

interface

uses
  jctrl;

type
  TVideoChat = class(TFrame)
    constructor Create(Parent: TControl);
  public
    procedure Init;
    function OnEvent(const Event: TControlEvent): Boolean; override;
  end;

implementation

uses
  jglobal;

constructor TVideoChat.Create(Parent: TControl);
begin
  inherited;
//  Flash := TFlash.Create(Self);
//  Flash.Move(4, 4, -8, -8);
  Border := COLOR_B4;
  Color  := COLOR_B4;
end;

procedure TVideoChat.Init;
begin
//  Flash.Load('H:\Projects\joim\src\swf\bin\joim.swf');
//  Flash.Call('test', ['joim test']);
end;

function TVideoChat.OnEvent(const Event: TControlEvent): Boolean;
begin
  Result := inherited OnEvent(Event);
  if Event.ID = etMouseUp then
    Init;
end;

end.
