unit unit_main;

{$mode objfpc}{$H+}

interface

uses
  Classes
  , SysUtils
  , Forms
  , Controls
  , Graphics
  , Dialogs
  , StdCtrls
  , laz.VirtualTrees
  , ActnList
  , ExtCtrls
  , unit_virtstringtree
  ;

type
  { TfrmMain }

  TfrmMain = class(TForm)
    lblExecName: TLabel;
    RadioGroup1: TRadioGroup;
    vst: TLazVirtualStringTree;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure RadioGroup1Click(Sender: TObject);
  private
    FTreeEntryCounter: SizeInt;//счетчик вхождения в дерево
    FPseudoClass: TPseudoTreeClass;
    procedure ExecuteActionForNode(Node: PVirtualNode);
    procedure TreeAddToSelection(Sender: TBaseVirtualTree;Node: PVirtualNode);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
    procedure TreeInitNode(Sender: TBaseVirtualTree; ParentNode,
      Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
    procedure DisplayActionMessage(const AMessage: String); // Отображает текст результата выполнения действия в lblExecName
    procedure TreeChecking(Sender: TBaseVirtualTree; Node: PVirtualNode; var NewState: TCheckState; var Allowed: Boolean);
    procedure TreeChecked(Sender: TBaseVirtualTree;  Node: PVirtualNode);
    procedure TreeCollapsing(Sender: TBaseVirtualTree; Node: PVirtualNode; var Allowed: Boolean);
  public
    property PseudoClass: TPseudoTreeClass read FPseudoClass write FPseudoClass;
  end;

var
  frmMain: TfrmMain;

implementation

uses
  unit_child
  , unit_detail
  ;

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FTreeEntryCounter:= 0;

  with vst do
  begin
    Header.AutoSizeIndex := 0;
    Header.MainColumn := 0;


    with TreeOptions do begin
      AutoOptions := AutoOptions + [toAutoScroll, toAutoSpanColumns, toAutoTristateTracking];
      MiscOptions := MiscOptions + [toCheckSupport] - [toAcceptOLEDrop, toEditOnClick];
      PaintOptions := PaintOptions - [toShowDropmark, toShowButtons];
      TreeOptions.SelectionOptions := TreeOptions.SelectionOptions - [toMultiSelect];// Отключаем множественное выделение
    end;

    // Важно: размер данных узла должен соответствовать TMyRecord;
    NodeDataSize := SizeOf(TMyRecord);
    RootNodeCount := 0;

    OnGetText:= @TreeGetText;
    OnAddToSelection:= @TreeAddToSelection;
    OnInitNode:= @TreeInitNode;
    OnChecking:= @TreeChecking;
    OnChecked:= @TreeChecked;
    OnCollapsing:= @TreeCollapsing;
  end;

  RadioGroup1.AutoSize:= True;
  RadioGroup1.Columns:= RadioGroup1.Items.Count;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if Assigned(FPseudoClass) then FPseudoClass.Free;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  RadioGroup1.ItemIndex:= 0;
  RadioGroup1Click(Sender);
end;

procedure TfrmMain.RadioGroup1Click(Sender: TObject);
var
  Node: PVirtualNode = nil;
begin
  if Assigned(FPseudoClass) then FreeAndNil(FPseudoClass);

  case RadioGroup1.ItemIndex of
    0: PseudoClass := TChildPseudoClass.Create(Self);
    else
      PseudoClass := TDetailPseudoClass.Create(Self);
  end;

  // Назначаем callback для отображения результата выполнения действия
  PseudoClass.OnDisplayMessage := @DisplayActionMessage;

  //PseudoClass.GetPseudoTreeData;//получаем данные
  TVirtStringTreeHelper.DeserializeTree(vst, PseudoClass.ParentNodeArr);//десериализуем дерево

  if vst.RootNodeCount = 0 then Exit;

  vst.FullExpand;
  Node := vst.GetFirst;
  while Assigned(Node) do
  begin
    vst.ReinitNode(Node,True);
    Node:= Node^.NextSibling;
  end;

  Node := vst.GetFirst;
  FTreeEntryCounter:= 0;


  if Assigned(Node) then
  begin
    vst.Selected[Node] := True;
    TreeChecked(vst,Node);
  end;
  if vst.CanSetFocus then vst.SetFocus;
end;

procedure TfrmMain.ExecuteActionForNode(Node: PVirtualNode);
var
  Data: PMyRecord = nil;
  Act: TAction = nil;
begin
  if not Assigned(Node) then Exit;
  if (FTreeEntryCounter = 0) then Exit;

  Data := vst.GetNodeData(Node);

  // Ищем действие по имени из записи узла в массиве действий текущего класса
  Act := PseudoClass.GetActionByName(Data^.ActionName);
  if Assigned(Act) and Assigned(Act.OnExecute)
    then Act.Execute
    else lblExecName.Caption := 'обработчик не назначен';
end;

procedure TfrmMain.TreeAddToSelection(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
begin
  ExecuteActionForNode(Node);
  Inc(FTreeEntryCounter);
end;

procedure TfrmMain.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
var
  Data: PMyRecord = nil;
begin
  Data := Sender.GetNodeData(Node);
  if Assigned(Data) then
    CellText := Data^.ValueCaption;
end;

procedure TfrmMain.TreeInitNode(Sender: TBaseVirtualTree; ParentNode,
  Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
var
  Data: PMyRecord = nil;
begin
  Data := Sender.GetNodeData(Node);
  if Assigned(Data) then
  begin
    // Устанавливаем тип (чекбокс, радиокнопка или ничего)
    Node^.CheckType:= Data^.ValueCheckType;

    // Устанавливаем текущее состояние (отмечен/не отмечен)
    Sender.CheckState[Node] := Data^.ValueCheckState;
  end;
end;

procedure TfrmMain.DisplayActionMessage(const AMessage: String);
begin
  lblExecName.Caption := AMessage;
end;

procedure TfrmMain.TreeChecking(Sender: TBaseVirtualTree; Node: PVirtualNode;
  var NewState: TCheckState; var Allowed: Boolean);
var
  Data: PMyRecord = nil;
begin
  Data:= Sender.GetNodeData(Node);
  if Assigned(Data) then Allowed:= Data^.ValueSiblingIsDepend;
end;

procedure TfrmMain.TreeChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
var
  Data: PMyRecord = nil;
  IsChecked: Boolean;
  SiblingNode: PVirtualNode = nil;

  // Локальная процедура для обхода дочерних узлов
  procedure SetChildrenDisabledState(ParentNode: PVirtualNode; Disable: Boolean);
  var
    ChildNode: PVirtualNode;
  begin
    // Получаем первого ребенка
    ChildNode := Sender.GetFirstChild(ParentNode);
    while Assigned(ChildNode) do
    begin
      // Включаем или выключаем узел
      Sender.IsDisabled[ChildNode] := Disable;
      //дизейблим всю иерархию рекурсивно (детей детей),
       SetChildrenDisabledState(ChildNode, Disable);
      // Переходим к следующему узлу на этом же уровне
      ChildNode := ChildNode^.NextSibling;
    end;
  end;
begin
  Data := Sender.GetNodeData(Node);
  if not Assigned(Data) then Exit;

  //Синхронизируем данные с новым состоянием в дереве
  Data^.ValueCheckState := Sender.CheckState[Node];

  //Если дети зависят от состояния родителя
  if Data^.ValueChildIsDepend then
  begin
    //Проверяем, отмечен ли чекбокс (учитываем обычное и "нажатое" состояние)
    IsChecked := (Data^.ValueCheckState = csCheckedNormal) or (Data^.ValueCheckState = csCheckedPressed);

    //Если отмечен, то Disable = False (энейблим). Иначе Disable = True (дизейблим).
    SetChildrenDisabledState(Node, not IsChecked);
  end;

  //Если узлы того же уровня зависят от состояния данного узла
  if Data^.ValueSiblingIsDepend then
  begin
    // Узлы активны если текущий узел отмечен или в смешанном состоянии
    IsChecked := (Data^.ValueCheckState = csCheckedNormal)
              or (Data^.ValueCheckState = csCheckedPressed)
              or (Data^.ValueCheckState = csMixedNormal)
              or (Data^.ValueCheckState = csMixedPressed);

    // Обходим всех братьев (sibling) текущего узла
    // Первый брат — первый ребёнок родителя
    if Assigned(Node^.Parent) then
      SiblingNode := (Node^.Parent)^.FirstChild
    else
      SiblingNode := Sender.GetFirst;

    while Assigned(SiblingNode) do
    begin
      // Пропускаем сам текущий узел
      if (SiblingNode <> Node) then Sender.IsDisabled[SiblingNode] := not IsChecked;
      if (SiblingNode^.ChildCount > 0) then SetChildrenDisabledState(SiblingNode, not IsChecked);
      SiblingNode := SiblingNode^.NextSibling;
    end;
  end;
end;

procedure TfrmMain.TreeCollapsing(Sender: TBaseVirtualTree; Node: PVirtualNode;
  var Allowed: Boolean);
begin
  Allowed:= False;
end;

end.

