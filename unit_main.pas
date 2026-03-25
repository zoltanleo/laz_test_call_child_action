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
  , ActnList, ExtCtrls
  , unit_virtstringtree
  ;

type
  { TfrmMain }

  TfrmMain = class(TForm)
    lblExecName: TLabel;
    RadioGroup1: TRadioGroup;
    vst: TLazVirtualStringTree;
    procedure FormCreate(Sender: TObject);
    procedure RadioGroup1Click(Sender: TObject);
  private
    //FNodeDataArray: TNodeDataArray; // Храним экспортированные данные
    procedure ExecuteActionForNode(Node: PVirtualNode);
    procedure TreeAddToSelection(Sender: TBaseVirtualTree;Node: PVirtualNode);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
  public

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
var
  i: SizeInt = 0;
  Node: PVirtualNode = nil;
  Data: PMyRecord = nil;
begin
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

  RadioGroup1.ItemIndex:= 0;
  RadioGroup1Click(Sender);
end;

procedure TfrmMain.RadioGroup1Click(Sender: TObject);
var
  RecArr: TRecArr;
  Node: PVirtualNode = nil;
begin
  case RadioGroup1.ItemIndex of
    0:
      begin
        // Используем класс из unit_child
        with unit_child.TPseudoClass.Create(Self) do
        try
          GetPseudoTreeData;
          RecArr := PseudoNodeArr;
          TVirtStringTreeHelper.DeserializeTree(vst, RecArr);
        finally
          Free;
        end;
      end;
    else
      begin
        // Используем класс из unit_detail
        with unit_detail.TPseudoClass.Create(Self) do
        try
          GetPseudoTreeData;
          RecArr := PseudoNodeArr;
          TVirtStringTreeHelper.DeserializeTree(vst, RecArr);
        finally
          Free;
        end;
      end;
  end;

  if (vst.RootNodeCount = 0) then Exit;

  vst.FullExpand;
  Node:= vst.GetFirst;
  vst.Selected[Node]:= True;
  if vst.CanSetFocus then vst.SetFocus;
end;

procedure TfrmMain.ExecuteActionForNode(Node: PVirtualNode);
var
  Data: PMyRecord = nil;
begin
  if not Assigned(Node) then Exit;

  Data := vst.GetNodeData(Node);
  //if Assigned(Data) and Assigned(Data^.ActionRef) then
  //begin
  //  if Data^.ActionName.Enabled then
  //    Data^.ActionRef.Execute
  //  else
  //    ShowMessage('Действие "' + Data^.Caption + '" недоступно');
  //end;
end;

procedure TfrmMain.TreeAddToSelection(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
begin
  ExecuteActionForNode(Node);
end;

procedure TfrmMain.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
var
  Data: PMyRecord = nil;
begin
  Data := Sender.GetNodeData(Node);
  if Assigned(Data) then
    CellText := Data^.Caption;
end;

end.

