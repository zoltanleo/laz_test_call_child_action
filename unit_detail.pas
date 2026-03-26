unit unit_detail;

{$mode ObjFPC}{$H+}

interface

uses
  Classes
  , SysUtils
  , ActnList
  , unit_virtstringtree
  ;

type
  { TDetailPseudoClass - наследник TPseudoTreeClass }
  TDetailPseudoClass = class(TPseudoTreeClass)
  public
    procedure GetPseudoTreeData; override;
  end;

implementation

{ TDetailPseudoClass }

procedure TDetailPseudoClass.GetPseudoTreeData;
begin
  // строим псевдодерево (версия Detail)
  SetLength(FPseudoNodeArr, 0);
  AddPseudoNode(FPseudoNodeArr, 1, -1, 'act1', 'Action 1 D');
  AddPseudoNode(FPseudoNodeArr, 2, 1, 'act11', 'Action 11 D');
  AddPseudoNode(FPseudoNodeArr, 3, 1, 'act12', 'Action 12 D');
  AddPseudoNode(FPseudoNodeArr, 4, -1, 'act2', 'Action 2 D');
  AddPseudoNode(FPseudoNodeArr, 5, 4, 'act21', 'Action 21 D');
  AddPseudoNode(FPseudoNodeArr, 6, 4, 'act22', 'Action 22 D');
  AddPseudoNode(FPseudoNodeArr, 7, -1, 'act3', 'Action 3 D');
  AddPseudoNode(FPseudoNodeArr, 8, -1, 'act4', 'Action 4 D');
end;

end.

