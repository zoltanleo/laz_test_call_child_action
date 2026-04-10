unit unit_detail;

{$mode ObjFPC}{$H+}

interface

uses
  Classes
  , SysUtils
  , ActnList
  , unit_virtstringtree
  , laz.VirtualTrees
  ;

type
  { TDetailPseudoClass - наследник TPseudoTreeClass }
  TDetailPseudoClass = class(TPseudoTreeClass)
  public
    procedure GetPseudoTreeData; override;
    procedure InstanceInit;override;
  end;

implementation

{ TDetailPseudoClass }

procedure TDetailPseudoClass.GetPseudoTreeData;
begin
  // строим псевдодерево (версия Detail)
  SetLength(FParentNodeArr, 0);
  AddPseudoNode(FParentNodeArr, 1, -1, 'act1', 'Action 1 D');
  AddPseudoNode(FParentNodeArr, 4, -1, 'act2', 'Action 2 D');
  AddPseudoNode(FParentNodeArr, 7, -1, 'act3', 'Action 3 D');
  AddPseudoNode(FParentNodeArr, 8, -1, 'act4', 'Action 4 D');
end;

procedure TDetailPseudoClass.InstanceInit;
begin
//
end;

end.

