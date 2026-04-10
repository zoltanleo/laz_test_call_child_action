unit unit_child;

{$mode ObjFPC}{$H+}

interface

uses
  Classes
  , SysUtils
  , ActnList
  , unit_virtstringtree
  , unit_child_tree
  , Controls
  , laz.VirtualTrees
  ;

type
  { TChildPseudoClass - наследник TPseudoTreeClass }
  TChildPseudoClass = class(TPseudoTreeClass)
  private
    // Отдельные обработчики для каждого Action
    procedure OnExecute_act1(Sender: TObject);
    procedure OnExecute_act11(Sender: TObject);
    procedure OnExecute_act12(Sender: TObject);
    procedure OnExecute_act13(Sender: TObject);
    procedure OnExecute_act3(Sender: TObject);
    procedure OnExecute_act4(Sender: TObject);
  public
    procedure GetPseudoTreeData; override;
    procedure InstanceInit;override;
    procedure ActionExecute(Sender: TObject); // Обработчик выполнения действия
    procedure ActCallHintForm(Sender: TObject);//вызов дочерней формы
  end;

implementation

const
  ActListArr: array[0..5] of String = (
                                      'Action_1',
                                      'Action_11',
                                      'Action_12',
                                      'Action_13',
                                      'Action_3',
                                      'Action_4'
                                                );

{ TChildPseudoClass }

procedure TChildPseudoClass.OnExecute_act1(Sender: TObject);
begin
  if Assigned(FOnDisplayMessage) then
    FOnDisplayMessage('Выполнено: ' + TAction(Sender).Caption + ' (корневой узел)');

  Exit;
end;

procedure TChildPseudoClass.OnExecute_act11(Sender: TObject);
begin
  with tmpMDS do
  begin
    AppendRecord([AutoID,1,-1,'расположение','','', PtrInt(csUncheckedNormal), PtrInt(ctNone)]);

    AppendRecord([AutoID,2,1,'в грудной клетке','','', PtrInt(csUncheckedNormal), PtrInt(ctRadioButton)]);
    AppendRecord([AutoID,3,1,'в поддиафрагмальной области','','', PtrInt(csCheckedNormal), PtrInt(ctRadioButton), True, True]);
    AppendRecord([AutoID,4,1,'в поясничной области','','', PtrInt(csUncheckedNormal), PtrInt(ctRadioButton)]);
    AppendRecord([AutoID,5,1,'в мезогастрии','','', PtrInt(csUncheckedNormal), PtrInt(ctRadioButton)]);
    AppendRecord([AutoID,6,1,'в области подвздошной ямки','','', PtrInt(csUncheckedNormal), PtrInt(ctRadioButton)]);
    AppendRecord([AutoID,7,1,'в малом тазу','','', PtrInt(csUncheckedNormal), PtrInt(ctRadioButton)]);

    AppendRecord([AutoID,8,-1,'смещаемость','','']);
    AppendRecord([AutoID,9,-1,'форма среза','','']);
    AppendRecord([AutoID,10,-1,'ровность контура','','']);
    AppendRecord([AutoID,11,-1,'четкость контура','','']);
    AppendRecord([AutoID,12,-1,'размеры','','', PtrInt(csUncheckedNormal), PtrInt(ctCheckBox)]);
  end;
end;

procedure TChildPseudoClass.OnExecute_act12(Sender: TObject);
begin
  if Assigned(FOnDisplayMessage) then
    FOnDisplayMessage('Выполнено: ' + TAction(Sender).Caption + ' (дочерний узел act1)');
end;

procedure TChildPseudoClass.OnExecute_act13(Sender: TObject);
begin
  if Assigned(FOnDisplayMessage) then
    FOnDisplayMessage('Выполнено: ' + TAction(Sender).Caption + ' (корневой узел)');
end;

procedure TChildPseudoClass.OnExecute_act3(Sender: TObject);
begin
  if Assigned(FOnDisplayMessage) then
    FOnDisplayMessage('Выполнено: ' + TAction(Sender).Caption + ' (корневой узел)');
end;

procedure TChildPseudoClass.OnExecute_act4(Sender: TObject);
begin
  if Assigned(FOnDisplayMessage) then
    FOnDisplayMessage('Выполнено: ' + TAction(Sender).Caption + ' (корневой узел)');
end;

procedure TChildPseudoClass.GetPseudoTreeData;
var
  i: SizeInt = 0;
begin
  // строим псевдодерево (версия Child);
  // ActionName берётся последовательно из ActListArr
  SetLength(FParentNodeArr, 0);
  AddPseudoNode(FParentNodeArr, 1, -1, ActListArr[0], 'Почка', ctCheckBox, csCheckedNormal, False, True, True);
  AddPseudoNode(FParentNodeArr, 2,  1, ActListArr[1], 'общие свойства', ctCheckBox, csUncheckedNormal, False, False, False);
  AddPseudoNode(FParentNodeArr, 3,  1, ActListArr[2], 'капсула почки', ctCheckBox, csUncheckedNormal, False, False, False);
  AddPseudoNode(FParentNodeArr, 4,  1, ActListArr[3], 'паренхима', ctCheckBox, csUncheckedNormal, False, False, False);
  AddPseudoNode(FParentNodeArr, 7, -1, ActListArr[4], 'act3');   // act3
  AddPseudoNode(FParentNodeArr, 8, -1, ActListArr[5], 'act4');   // act4

  // Регистрируем Actions; Caption берём из уже заполненного PseudoNodeArr
  for i := 0 to High(ActListArr) do
    AddAction(ParentNodeArr[i].ActionName, ParentNodeArr[i].ValueCaption, @ActionExecute);
end;

procedure TChildPseudoClass.InstanceInit;
begin
//
end;

procedure TChildPseudoClass.ActionExecute(Sender: TObject);
var
  Act: TAction = nil;
  idx: SizeInt = -1;
begin
  if not Sender.InheritsFrom(TAction) then Exit;
  Act := TAction(Sender);

  for idx := 0 to High(ActListArr) do
    if ActListArr[idx] = Act.Name then Break;

  if tmpMDS.Active then tmpMDS.Active:= False;
  tmpMDS.CreateTable;//очищаем датасет от данных
  tmpMDS.Active:= True;
  FAutoID:= 0;

  case idx of
    //0: OnExecute_act1(Sender);
    1: OnExecute_act11(Sender);
    2: OnExecute_act12(Sender);
    3: OnExecute_act13(Sender);
    4: OnExecute_act3(Sender);
    5: OnExecute_act4(Sender);
  else
    if Assigned(FOnDisplayMessage) then
      FOnDisplayMessage('Неизвестное действие: ' + Act.Name);
    Exit;
  end;

  ConvertDataToChildNodeArr(FChildNodeArr);
  ActCallHintForm(Sender);
end;

procedure TChildPseudoClass.ActCallHintForm(Sender: TObject);
var
  tmpFrm: TfrmChildTree = nil;
begin
  tmpFrm:= TfrmChildTree.Create(nil);
  try
    tmpFrm.InputTreeArray:= ChildNodeArr;
    tmpFrm.ShowModal;

    if (tmpFrm.ModalResult = mrOK) then
    begin

    end;

    if Assigned(FOnDisplayMessage) then FOnDisplayMessage(tmpFrm.OutputText);
  finally
    FreeAndNil(tmpFrm);
  end;
end;

end.

