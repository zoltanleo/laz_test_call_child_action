unit unit_child;

{$mode ObjFPC}{$H+}

interface

uses
  Classes
  , SysUtils
  , ActnList
  , unit_virtstringtree
  ;

type
  { TChildPseudoClass - наследник TPseudoTreeClass }
  TChildPseudoClass = class(TPseudoTreeClass)
  public
    procedure GetPseudoTreeData; override;
  end;

implementation

{ TChildPseudoClass }

procedure TChildPseudoClass.GetPseudoTreeData;
var
  i: SizeInt = 0;

  procedure AddAction(const AName, aCaption: String);
  var Act: TAction = nil;
  begin
    Act := TAction.Create(ActList);
    Act.Name := AName;
    Act.Caption := aCaption;

    // ← Сохраняем ссылку на действие в массив базового класса
    SetLength(FActArray, Length(FActArray) + 1);
    FActArray[High(FActArray)] := Act;
  end;
begin
  // строим псевдодерево (версия Child)
  SetLength(FPseudoNodeArr, 0);
  AddPseudoNode(FPseudoNodeArr, 1, -1, 'act1', 'Action 1');
  AddPseudoNode(FPseudoNodeArr, 2, 1, 'act11', 'Action 11');
  AddPseudoNode(FPseudoNodeArr, 3, 1, 'act12', 'Action 12');
  AddPseudoNode(FPseudoNodeArr, 4, -1, 'act2', 'Action 2');
  AddPseudoNode(FPseudoNodeArr, 7, -1, 'act3', 'Action 3');
  AddPseudoNode(FPseudoNodeArr, 8, -1, 'act4', 'Action 4');

  for i:= 0 to Pred(Length(PseudoNodeArr)) do
  begin
    AddAction(PseudoNodeArr[i].ActionName, PseudoNodeArr[i].Caption);
  end;
end;

end.

