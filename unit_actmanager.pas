unit unit_actmanager;

{$mode ObjFPC}{$H+}

interface

uses
  Classes
  , SysUtils
  , ActnList
  ;

type

  { TChildActionsManager }

  TChildActionsManager = class
  private
    FActionList: TActionList;
    FActions: array of TAction;

    function GetActionCount: Integer;
    function GetActionByIndex(Index: Integer): TAction;
    function GetActionByName(const Name: string): TAction;

  public
    constructor Create(AActionList: TActionList);
    destructor Destroy; override;

    property ActionCount: Integer read GetActionCount;
    property Actions[Index: Integer]: TAction read GetActionByIndex; default;
    function GetAction(const Name: string): TAction;
  end;

implementation

{ TChildActionsManager }

function TChildActionsManager.GetActionCount: Integer;
begin
  Result := Length(FActions);
end;

function TChildActionsManager.GetActionByIndex(Index: Integer): TAction;
begin
  if (Index >= 0) and (Index < Length(FActions)) then
    Result := FActions[Index]
  else
    Result := nil;
end;

function TChildActionsManager.GetActionByName(const Name: string): TAction;
var
  i: SizeInt = 0;
begin
  Result := nil;
  for i := 0 to Pred(Length(FActions)) do
  begin
    if Assigned(FActions[i]) and (FActions[i].Name = Name) then
    begin
      Result := FActions[i];
      Exit;
    end;
  end;
end;

constructor TChildActionsManager.Create(AActionList: TActionList);
var
  i: SizeInt = 0;
begin
  inherited Create;
  FActionList := AActionList;

  if Assigned(FActionList) then
  begin
    SetLength(FActions, FActionList.ActionCount);
    for i := 0 to Pred(FActionList.ActionCount) do
      FActions[i] := TAction(FActionList.Actions[i]);
  end;
end;

destructor TChildActionsManager.Destroy;
begin
  SetLength(FActions, 0);
  inherited Destroy;
end;

function TChildActionsManager.GetAction(const Name: string): TAction;
begin
  Result := GetActionByName(Name);
end;

end.

