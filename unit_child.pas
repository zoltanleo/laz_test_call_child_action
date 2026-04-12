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
    FTestStr: String;
    FCurrentActionIdx: SizeInt; // индекс действия, вызвавшего заполнение vstChildTree

    // Отдельные обработчики для каждого Action
    procedure OnExecute_act1(Sender: TObject);
    procedure OnExecute_act11(Sender: TObject);
    procedure OnExecute_act12(Sender: TObject);
    procedure OnExecute_act13(Sender: TObject);
    procedure OnExecute_act3(Sender: TObject);
    procedure OnExecute_act4(Sender: TObject);
  public
    property TestStr: String read FTestStr write FTestStr;
    property CurrentActionIdx: SizeInt read FCurrentActionIdx;
    procedure GetPseudoTreeData; override;
    procedure InstanceInit;override;
    procedure ActionExecute(Sender: TObject); // Обработчик выполнения действия
    procedure ActCallHintForm(Sender: TObject);//вызов дочерней формы
    function GetTestString(const ANodeArr: TRecArr): String;
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
  //=== общие свойства ===
  with tmpMDS do
  begin
    AppendRecord([AutoID,1,-1,'расположение','','']);

    AppendRecord([AutoID,2,1,'в грудной клетке','','', PtrInt(ctRadioButton), PtrInt(csUncheckedNormal)]);
    AppendRecord([AutoID,3,1,'в поддиафрагмальной области','','', PtrInt(ctRadioButton), PtrInt(csCheckedNormal), True, True]);
    AppendRecord([AutoID,4,1,'в поясничной области','','', PtrInt(ctRadioButton), PtrInt(csUncheckedNormal)]);
    AppendRecord([AutoID,5,1,'в мезогастрии','','', PtrInt(ctRadioButton), PtrInt(csUncheckedNormal)]);
    AppendRecord([AutoID,6,1,'в области подвздошной ямки','','', PtrInt(ctRadioButton), PtrInt(csUncheckedNormal)]);
    AppendRecord([AutoID,7,1,'в малом тазу','','', PtrInt(ctRadioButton), PtrInt(csUncheckedNormal)]);

    AppendRecord([AutoID,8,-1,'смещаемость','','']);
    AppendRecord([AutoID,9,8,'физиологическая','','', PtrInt(ctRadioButton), PtrInt(csCheckedNormal), True, True]);
    AppendRecord([AutoID,10,8,'до 2 см','','', PtrInt(ctRadioButton), PtrInt(csUncheckedNormal)]);
    AppendRecord([AutoID,11,8,'до 3 см','','', PtrInt(ctRadioButton), PtrInt(csUncheckedNormal)]);
    AppendRecord([AutoID,12,8,'более 3 см','','', PtrInt(ctRadioButton), PtrInt(csUncheckedNormal)]);


    AppendRecord([AutoID,13,-1,'форма среза','','']);
    AppendRecord([AutoID,14,13,'бобовидная','','', PtrInt(ctRadioButton), PtrInt(csCheckedNormal), True, True]);
    AppendRecord([AutoID,15,13,'фетальная дольчатость','','', PtrInt(ctRadioButton), PtrInt(csUncheckedNormal)]);
    AppendRecord([AutoID,16,13,'"горбатая" почка','','', PtrInt(ctRadioButton), PtrInt(csUncheckedNormal)]);
    AppendRecord([AutoID,17,13,'"подковообразная" почка','','', PtrInt(ctRadioButton), PtrInt(csUncheckedNormal)]);
    AppendRecord([AutoID,18,13,'"галетообразная" почка','','', PtrInt(ctRadioButton), PtrInt(csUncheckedNormal)]);
    AppendRecord([AutoID,19,13,'L-образная почка','','', PtrInt(ctRadioButton), PtrInt(csUncheckedNormal)]);
    AppendRecord([AutoID,20,13,'S-образная почка','','', PtrInt(ctRadioButton), PtrInt(csUncheckedNormal)]);
    AppendRecord([AutoID,21,13,'I-образная почка','','', PtrInt(ctRadioButton), PtrInt(csUncheckedNormal)]);

    AppendRecord([AutoID,22,-1,'ровность контура','','']);
    AppendRecord([AutoID,23,22,'ровные','','', PtrInt(ctRadioButton), PtrInt(csCheckedNormal), True, True]);
    AppendRecord([AutoID,24,22,'волнистые','','', PtrInt(ctRadioButton), PtrInt(csUncheckedNormal)]);

    AppendRecord([AutoID,25,-1,'четкость контура','','']);
    AppendRecord([AutoID,26,25,'четкие','','', PtrInt(ctRadioButton), PtrInt(csCheckedNormal), True, True]);
    AppendRecord([AutoID,27,25,'нечеткие','','', PtrInt(ctRadioButton), PtrInt(csUncheckedNormal)]);

    AppendRecord([AutoID,28,-1,'размеры','','', PtrInt(ctCheckBox), PtrInt(csUncheckedNormal)]);
  end;
end;

procedure TChildPseudoClass.OnExecute_act12(Sender: TObject);
begin
  //=== капсула почки ===
  with tmpMDS do
  begin
    AppendRecord([AutoID,1,-1,'толщина контура','','']);
    AppendRecord([AutoID,2, 1,'равномерная','','', PtrInt(ctRadioButton), PtrInt(csCheckedNormal), True, True]);
    AppendRecord([AutoID,3, 1,'неравномерная','','', PtrInt(ctRadioButton), PtrInt(csUnCheckedNormal)]);

    AppendRecord([AutoID,4,-1,'эхогенность','','']);
    AppendRecord([AutoID,5, 4,'гиперэхогенная','','', PtrInt(ctRadioButton), PtrInt(csCheckedNormal), True, True]);
    AppendRecord([AutoID,6, 4,'изоэхогенная','','', PtrInt(ctRadioButton), PtrInt(csUnCheckedNormal)]);
    AppendRecord([AutoID,7, 4,'гипоэхогенная','','', PtrInt(ctRadioButton), PtrInt(csUnCheckedNormal)]);


    AppendRecord([AutoID,8,-1,'целостность','','']);
    AppendRecord([AutoID,9, 8,'прослеживается на всем протяжении контура','','', PtrInt(ctRadioButton), PtrInt(csCheckedNormal), True, True]);
    AppendRecord([AutoID,10,8,'не прослеживается в области верхнего полюса','','', PtrInt(ctRadioButton), PtrInt(csUnCheckedNormal)]);
    AppendRecord([AutoID,11,8,'не прослеживается в области средней трети','','', PtrInt(ctRadioButton), PtrInt(csUnCheckedNormal)]);
    AppendRecord([AutoID,12,8,'не прослеживается в области нижней трети','','', PtrInt(ctRadioButton), PtrInt(csUnCheckedNormal)]);
    AppendRecord([AutoID,13,8,'не прослеживается на всем протяжении','','', PtrInt(ctRadioButton), PtrInt(csUnCheckedNormal)]);

    AppendRecord([AutoID,14,-1,'толщина (мм)','','', PtrInt(ctCheckBox), PtrInt(csUncheckedNormal)]);

  end;
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

  FCurrentActionIdx := idx; // запоминаем вызвавшее действие для GetTestString
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
    tmpFrm.OnTestNodeArrReady := @GetTestString; // передаём callback для обработки TestNodeArr
    tmpFrm.ShowModal;

    if (tmpFrm.ModalResult = mrOK) then
    begin

    end;

    if Assigned(FOnDisplayMessage) then FOnDisplayMessage(tmpFrm.OutputText);
  finally
    FreeAndNil(tmpFrm);
  end;
end;

function TChildPseudoClass.GetTestString(const ANodeArr: TRecArr): String;
var
  i: SizeInt = 0;
begin
  FTestStr := '';

  case FCurrentActionIdx of
    1: // OnExecute_act11 — конкатенация через '~'
      begin
        for i := 0 to High(ANodeArr) do
        begin
          if (i > 0) then FTestStr := FTestStr + '~ ';
          FTestStr := FTestStr + ANodeArr[i].ValueCaption;
        end;
      end;

    2: // OnExecute_act12 — фиксированный результат
      begin
        FTestStr := 'OnExecute_act12(Sender)';
      end;

  else
    // Поведение по умолчанию для остальных действий — конкатенация через пробел
    for i := 0 to High(ANodeArr) do
    begin
      if (i > 0) then FTestStr := FTestStr + ' ';
      FTestStr := FTestStr + ANodeArr[i].ValueCaption;
    end;
  end;

  Result := FTestStr;
end;

end.

