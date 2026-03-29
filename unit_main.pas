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
    procedure DisplayActionMessage(const AMessage: String); // Отображает текст результата выполнения действия в lblExecName
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

    // Отключаем множественное выделение
    TreeOptions.SelectionOptions := TreeOptions.SelectionOptions - [toMultiSelect];

    // Важно: размер данных узла должен соответствовать TMyRecord;
    NodeDataSize := SizeOf(TMyRecord);
    RootNodeCount := 0;

    OnGetText:= @TreeGetText;
    OnAddToSelection:= @TreeAddToSelection;
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

  PseudoClass.GetPseudoTreeData;//получаем данные
  TVirtStringTreeHelper.DeserializeTree(vst, PseudoClass.ParentNodeArr);//десериализуем дерево

  if vst.RootNodeCount = 0 then Exit;
  vst.FullExpand;
  Node := vst.GetFirst;
  FTreeEntryCounter:= 0;
  vst.Selected[Node] := True;
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

procedure TfrmMain.DisplayActionMessage(const AMessage: String);
begin
  lblExecName.Caption := AMessage;
end;

end.

