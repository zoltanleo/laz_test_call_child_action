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
  ;

type
  { TChildPseudoClass - наследник TPseudoTreeClass }
  TChildPseudoClass = class(TPseudoTreeClass)
  private
    // Отдельные обработчики для каждого Action
    procedure OnExecute_act1(Sender: TObject);
    procedure OnExecute_act11(Sender: TObject);
    procedure OnExecute_act12(Sender: TObject);
    procedure OnExecute_act2(Sender: TObject);
    procedure OnExecute_act3(Sender: TObject);
    procedure OnExecute_act4(Sender: TObject);
  public
    procedure GetPseudoTreeData; override;
    procedure ActionExecute(Sender: TObject); // Обработчик выполнения действия
    procedure ActCallHintForm(Sender: TObject);//вызов дочерней формы
  end;

implementation

const
  ActListArr: array[0..5] of String = (
    'act1',
    'act11',
    'act12',
    'act2',
    'act3',
    'act4'
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
  //if Assigned(FOnDisplayMessage) then
  //  FOnDisplayMessage('Выполнено: ' + TAction(Sender).Caption + ' (дочерний узел act1)');
  with tmpMDS do
  begin
    AppendRecord([AutoID,1,-1,'Почка','','']);
    AppendRecord([AutoID,2,1,'паренхима почки','','']);

    AppendRecord([AutoID,3,2,'верхняя треть','верхней трети паренхимы почки','']);
    AppendRecord([AutoID,4,2,'верхний сегмент (1й сегмент)','верхнего сегмента почки (1й сегмент)','']);
    AppendRecord([AutoID,5,2,'верхний передний сегмент (2й сегмент)','верхнего переднего сегмента почки (2й сегмент)','']);

    AppendRecord([AutoID,6,2,'средняя треть','средней трети паренхимы почки','']);
    AppendRecord([AutoID,7,2,'нижний передний сегмент (3й сегмент)','нижнего переднего сегмента почки (3й сегмент)','']);
    AppendRecord([AutoID,8,2,'задний сегмент (5й сегмент)','заднего сегмента почки (5й сегмент)','']);

    AppendRecord([AutoID,9,2,'нижняя треть','нижней трети паренхимы почки','']);
    AppendRecord([AutoID,10,2,'нижний сегмент (4й сегмент)','нижнего сегмента почки (4й сегмент)','']);
  end;
end;

procedure TChildPseudoClass.OnExecute_act12(Sender: TObject);
begin
  if Assigned(FOnDisplayMessage) then
    FOnDisplayMessage('Выполнено: ' + TAction(Sender).Caption + ' (дочерний узел act1)');
end;

procedure TChildPseudoClass.OnExecute_act2(Sender: TObject);
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
  AddPseudoNode(FParentNodeArr, 1, -1, ActListArr[0], 'Action 1');   // act1
  AddPseudoNode(FParentNodeArr, 2,  1, ActListArr[1], 'Action 11');  // act11
  AddPseudoNode(FParentNodeArr, 3,  1, ActListArr[2], 'Action 12');  // act12
  AddPseudoNode(FParentNodeArr, 4, -1, ActListArr[3], 'Action 2');   // act2
  AddPseudoNode(FParentNodeArr, 7, -1, ActListArr[4], 'Action 3');   // act3
  AddPseudoNode(FParentNodeArr, 8, -1, ActListArr[5], 'Action 4');   // act4

  // Регистрируем Actions; Caption берём из уже заполненного PseudoNodeArr
  for i := 0 to High(ActListArr) do
    AddAction(ActListArr[i], ParentNodeArr[i].ValueCaption, @ActionExecute);
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
    0: OnExecute_act1(Sender);
    1: OnExecute_act11(Sender);
    2: OnExecute_act12(Sender);
    3: OnExecute_act2(Sender);
    4: OnExecute_act3(Sender);
    5: OnExecute_act4(Sender);
  else
    if Assigned(FOnDisplayMessage) then
      FOnDisplayMessage('Неизвестное действие: ' + Act.Name);
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
    if Assigned(FOnDisplayMessage) then FOnDisplayMessage(tmpFrm.OutputText);
  finally
    FreeAndNil(tmpFrm);
  end;
end;

end.

