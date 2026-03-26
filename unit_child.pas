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
begin
  // строим псевдодерево (версия Child)
  SetLength(FPseudoNodeArr, 0);
  AddPseudoNode(FPseudoNodeArr, 1, -1, 'act1', 'Action 1');
  AddPseudoNode(FPseudoNodeArr, 2, 1, 'act11', 'Action 11');
  AddPseudoNode(FPseudoNodeArr, 3, 1, 'act12', 'Action 12');
  AddPseudoNode(FPseudoNodeArr, 4, -1, 'act2', 'Action 2');
  AddPseudoNode(FPseudoNodeArr, 5, 4, 'act21', 'Action 21');
  AddPseudoNode(FPseudoNodeArr, 6, 4, 'act22', 'Action 22');
  AddPseudoNode(FPseudoNodeArr, 7, -1, 'act3', 'Action 3');
  AddPseudoNode(FPseudoNodeArr, 8, -1, 'act4', 'Action 4');
end;

end.

