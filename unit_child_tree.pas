unit unit_child_tree;

{$mode ObjFPC}{$H+}

interface

uses
  Classes
  , SysUtils
  , Forms
  , Controls
  , Graphics
  , Dialogs
  , StdCtrls
  , ExtCtrls
  , LazUTF8
  , laz.VirtualTrees
  , unit_virtstringtree
  ;

type

  { TfrmChildTree }

  TfrmChildTree = class(TForm)
    btnCancel: TButton;
    btnOK: TButton;
    LazVirtualStringTree1: TLazVirtualStringTree;
    mChildTree: TMemo;
    Splitter1: TSplitter;
    vstChildTree: TLazVirtualStringTree;
    procedure btnCancelClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FInputTreeArray: TRecArr;
    FOnTestNodeArrReady: TTestNodeArrReadyFunc;
    FOutputText: String;
    FTestNodeArr: TRecArr;
    procedure SetInputTreeArray(AValue: TRecArr);
    procedure TreeChecking(Sender: TBaseVirtualTree; Node: PVirtualNode; var NewState: TCheckState; var Allowed: Boolean);
    procedure TreeChecked(Sender: TBaseVirtualTree;  Node: PVirtualNode);
    procedure TreeCollapsing(Sender: TBaseVirtualTree; Node: PVirtualNode; var Allowed: Boolean);
    procedure TreeAddToSelection(Sender: TBaseVirtualTree;Node: PVirtualNode);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
    procedure TreeInitNode(Sender: TBaseVirtualTree; ParentNode,
      Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
    procedure TreeFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeGetNodeDataSize(Sender: TBaseVirtualTree; var NodeDataSize: Integer);
    procedure TreePaintText(Sender: TBaseVirtualTree;
      const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
      TextType: TVSTTextType);
    procedure TreeAfterCellPaint(Sender: TBaseVirtualTree; TargetCanvas: TCanvas;
      Node: PVirtualNode; Column: TColumnIndex; const CellRect: TRect);
    procedure CollectCheckedNodes(aNode: PVirtualNode);
  public
    property OutputText: String read FOutputText write FOutputText;
    property InputTreeArray: TRecArr read FInputTreeArray write SetInputTreeArray;
    property TestNodeArr: TRecArr read FTestNodeArr;
    property OnTestNodeArrReady: TTestNodeArrReadyFunc read FOnTestNodeArrReady write FOnTestNodeArrReady;
  end;

var
  frmChildTree: TfrmChildTree;

implementation

{$R *.lfm}

{ TfrmChildTree }

procedure TfrmChildTree.btnOKClick(Sender: TObject);
begin
  Self.ModalResult:= mrOK;
end;

procedure TfrmChildTree.btnCancelClick(Sender: TObject);
begin
  FOutputText:= Format('A ChildTree form closed at %s',[FormatDateTime('hh:mm:ss.zzz', Now)]);
  Self.ModalResult:= mrCancel;
end;

procedure TfrmChildTree.FormCreate(Sender: TObject);
begin
  Self.ModalResult:= mrCancel;
  SetLength(FInputTreeArray, 0);
  FOutputText:= 'no data';

  with vstChildTree do
  begin
    Header.AutoSizeIndex := 0;
    Header.MainColumn := 0;


    with TreeOptions do begin
      AutoOptions := AutoOptions + [toAutoScroll, toAutoSpanColumns, toAutoTristateTracking];
      MiscOptions := MiscOptions + [toCheckSupport] - [toAcceptOLEDrop, toEditOnClick];
      PaintOptions := PaintOptions - [toShowDropmark, toShowButtons];
      TreeOptions.SelectionOptions := TreeOptions.SelectionOptions
                                  + [toAlwaysSelectNode]
                                  - [toMultiSelect] // Отключаем множественное выделение
                                  ;
    end;

    // Важно: размер данных узла должен соответствовать TMyRecord;
    RootNodeCount := 0;

    OnGetText:= @TreeGetText;
    OnAddToSelection:= @TreeAddToSelection;
    OnInitNode:= @TreeInitNode;
    OnChecking:= @TreeChecking;
    OnChecked:= @TreeChecked;
    OnCollapsing:= @TreeCollapsing;
    OnFreeNode:= @TreeFreeNode;
    OnGetNodeDataSize:= @TreeGetNodeDataSize;
    OnPaintText:= @TreePaintText;
    OnAfterCellPaint:= @TreeAfterCellPaint;
  end;
end;

procedure TfrmChildTree.FormShow(Sender: TObject);
var
  Node: PVirtualNode = nil;
begin
  TVirtStringTreeHelper.DeserializeTree(vstChildTree, InputTreeArray);

  if (vstChildTree.RootNodeCount = 0) then Exit;

  vstChildTree.FullExpand;
  Node:= vstChildTree.GetFirst;
  while Assigned(Node) do
  begin
    vstChildTree.ReinitNode(Node,True);
    Node:= Node^.NextSibling;
  end;

  //vstChildTree.ClearSelection;
  //
  Node:= vstChildTree.GetFirst;
  if Assigned(Node) then
  begin
    vstChildTree.Selected[node]:= True;
  end;

  if vstChildTree.CanSetFocus then vstChildTree.SetFocus;
end;

procedure TfrmChildTree.SetInputTreeArray(AValue: TRecArr);
begin
  if (Length(AValue) > 0) then FInputTreeArray:= AValue;
end;

procedure TfrmChildTree.TreeChecking(Sender: TBaseVirtualTree;
  Node: PVirtualNode; var NewState: TCheckState; var Allowed: Boolean);
var
  Data: PMyRecord = nil;
begin
  Data := Sender.GetNodeData(Node);
  if not Assigned(Data) then Exit;

  case Node^.CheckType of
    ctCheckBox: Allowed:= Data^.ValueCheckedAccept;
  else
    Allowed:= True;
  end;

end;

procedure TfrmChildTree.TreeChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
var
  Data: PMyRecord = nil;
  SiblingNode: PVirtualNode = nil;
  aNode: PVirtualNode = nil;
begin
  // Обрабатываем только радиокнопки
  if (Node^.CheckType <> ctRadioButton) then Exit;

  // 1. Снимаем выделение и состояние checked со всех sibling-узлов того же родителя,
  //    оставляем выделенным только текущий узел
  if (Node^.Parent = Sender.RootNode) then
    SiblingNode := Sender.GetFirst        // узлы верхнего уровня
  else
    SiblingNode := Node^.Parent^.FirstChild; // дочерние узлы того же родителя

  while Assigned(SiblingNode) do
  begin
    if (SiblingNode <> Node) then
    begin
      Sender.Selected[SiblingNode] := False;
      // Снимаем галку у sibling-радиокнопок через данные + ReinitNode,
      // чтобы не вызывать OnChecked рекурсивно
      Data := Sender.GetNodeData(SiblingNode);
      if Assigned(Data) and (SiblingNode^.CheckType = ctRadioButton) then
      begin
        Data^.ValueCheckState := csUncheckedNormal;
        Sender.ReinitNode(SiblingNode, False);
      end;
    end;
    SiblingNode := SiblingNode^.NextSibling;
  end;

  // Выделяем текущий узел
  Sender.Selected[Node] := True;
  Sender.FocusedNode := Node;
  if Sender.CanSetFocus then Sender.SetFocus;

  // Фиксируем состояние текущего узла в данных и перерисовываем
  Data := Sender.GetNodeData(Node);
  if Assigned(Data) then
  begin
    Data^.ValueCheckState := csCheckedNormal;
    Sender.ReinitNode(Node, True);
  end;

  // 2. Логика из TreeAddToSelection: для листовых узлов собираем отмеченные
  //    и вызываем обратный вызов FOnTestNodeArrReady
  if (Node^.ChildCount = 0) then
  begin
    aNode := Sender.GetFirst;
    SetLength(FTestNodeArr, 0);
    if Assigned(aNode) then CollectCheckedNodes(aNode);

    if Assigned(FOnTestNodeArrReady) then
    begin
      mChildTree.Clear;
      mChildTree.Text := FOnTestNodeArrReady(FTestNodeArr);
    end;
  end;
end;

procedure TfrmChildTree.TreeCollapsing(Sender: TBaseVirtualTree;
  Node: PVirtualNode; var Allowed: Boolean);
begin
  Allowed:= False;
end;

procedure TfrmChildTree.TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
var
  Data: PMyRecord = nil;
  aNode: PVirtualNode = nil;
begin
  Data:= vstChildTree.GetNodeData(Node);

  if not Assigned(Data) then Exit;

  case Node^.CheckType of
    ctRadioButton:
      begin
        Data^.ValueCheckState:= csCheckedNormal;
        Sender.ReinitNode(Node,True);
      end
  else ;
  end;

  if (Node^.ChildCount = 0) then
  begin
    aNode := Sender.GetFirst;
    SetLength(FTestNodeArr, 0);
    if Assigned(aNode) then CollectCheckedNodes(aNode);

    if Assigned(FOnTestNodeArrReady) then
    begin
      mChildTree.Clear;
      mChildTree.Text := FOnTestNodeArrReady(FTestNodeArr);
    end;
  end;
end;

procedure TfrmChildTree.TreeGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: String);
var
  Data: PMyRecord = nil;
begin
  Data := Sender.GetNodeData(Node);
  if Assigned(Data) then
    CellText := Data^.ValueCaption;
end;

procedure TfrmChildTree.TreeInitNode(Sender: TBaseVirtualTree; ParentNode,
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

procedure TfrmChildTree.TreeFreeNode(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
begin
  if Assigned(Sender.GetNodeData(Node)) then Finalize(PMyRecord(Sender.GetNodeData(Node))^);
end;

procedure TfrmChildTree.TreeGetNodeDataSize(Sender: TBaseVirtualTree;
  var NodeDataSize: Integer);
begin
  NodeDataSize:= SizeOf(TMyRecord);
end;

procedure TfrmChildTree.TreePaintText(Sender: TBaseVirtualTree;
  const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  TextType: TVSTTextType);
var
  Data: PMyRecord = nil;
begin
  Data:= Sender.GetNodeData(Node);
  if not Assigned(Data) then Exit;

  if Data^.ValueIsDefault then TargetCanvas.Font.Style:= [fsItalic];
end;

procedure TfrmChildTree.TreeAfterCellPaint(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  const CellRect: TRect);
var
  CheckRect: TRect;
  Triangle: array[0..2] of TPoint;
  ButtonWidth: SizeInt = 16;
  BaseOffset: SizeInt = 0;
begin
  // 1. Проверяем, что это главная колонка и тип узла — ctButton
    if (Column = TLazVirtualStringTree(Sender).Header.MainColumn) and (Node^.CheckType = ctButton) then
    begin
      ButtonWidth := 14;

          // 2. РАСЧЕТ ГОРИЗОНТАЛЬНОЙ ПОЗИЦИИ (X)
          // Начальный отступ равен уровню вложенности, помноженному на Indent
          BaseOffset := (TLazVirtualStringTree(Sender).GetNodeLevel(Node) + 1) * TLazVirtualStringTree(Sender).Indent;

          // Если кнопки развертывания (+/-) ВКЛЮЧЕНЫ, добавляем еще один Indent,
          // так как чекбокс/кнопка идет СЛЕДУЮЩИМ элементом после кнопки +/-.
          // Если кнопки +/- ВЫКЛЮЧЕНЫ (как в вашем случае), этот отступ не добавляем.
          if toShowButtons in TLazVirtualStringTree(Sender).TreeOptions.PaintOptions then
            BaseOffset := BaseOffset + TLazVirtualStringTree(Sender).Indent;

          // Добавляем небольшой внутренний отступ (TextMargin), чтобы кнопка не касалась линий
          // В VTV это обычно 2-4 пикселя.
          CheckRect.Left := CellRect.Left + BaseOffset + 6;
          CheckRect.Right := CheckRect.Left + ButtonWidth;

          // 3. РАСЧЕТ ВЕРТИКАЛЬНОЙ ПОЗИЦИИ (Y) - Центрирование
          CheckRect.Top := CellRect.Top + ((CellRect.Bottom - CellRect.Top - ButtonWidth) div 2) + 1;
          CheckRect.Bottom := CheckRect.Top + ButtonWidth;

          // 4. ОТРИСОВКА
          // Очищаем фон (важно для корректного отображения при выделении)
          //TargetCanvas.Brush.Color := TLazVirtualStringTree(Sender).Colors.BackGroundColor;
          //TargetCanvas.FillRect(CheckRect);

          // Настраиваем цвета для треугольника
          TargetCanvas.Brush.Color := clWindowText;
          TargetCanvas.Pen.Color := clWindowText;

          // Рисуем треугольник вершиной вниз
          // Координаты относительно вычисленного CheckRect
          Triangle[0] := Point(CheckRect.Left + 2, CheckRect.Top + 4);
          Triangle[1] := Point(CheckRect.Right - 2, CheckRect.Top + 4);
          Triangle[2] := Point((CheckRect.Left + CheckRect.Right) div 2, CheckRect.Bottom - 5);

          TargetCanvas.Polygon(Triangle);
    end;
end;

procedure TfrmChildTree.CollectCheckedNodes(aNode: PVirtualNode);
var
  Data: PMyRecord = nil;
begin
  while Assigned(aNode) do
    begin
      if (aNode^.ChildCount > 0) then //для узлов с детками
        CollectCheckedNodes(vstChildTree.GetFirstChild(aNode)) else
      begin
        Data := vstChildTree.GetNodeData(aNode);
        if Assigned(Data) then
        begin
          case Data^.ValueCheckType of
            ctRadioButton, ctCheckBox:
              if (Data^.ValueCheckState = csCheckedNormal) then
              begin
                SetLength(FTestNodeArr, Length(FTestNodeArr) + 1);
                FTestNodeArr[High(FTestNodeArr)] := Data^;
              end;
          end;
        end;
      end;
      aNode := aNode^.NextSibling;
    end;
end;

end.

