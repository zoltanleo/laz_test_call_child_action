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
    Memo1: TMemo;
    Splitter1: TSplitter;
    vst: TLazVirtualStringTree;
    procedure btnCancelClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FInputTreeArray: TRecArr;
    FOutputText: String;
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
  public
    property OutputText: String read FOutputText write FOutputText;
    property InputTreeArray: TRecArr read FInputTreeArray write SetInputTreeArray;
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
    RootNodeCount := 0;

    OnGetText:= @TreeGetText;
    OnAddToSelection:= @TreeAddToSelection;
    OnInitNode:= @TreeInitNode;
    OnChecking:= @TreeChecking;
    OnChecked:= @TreeChecked;
    OnCollapsing:= @TreeCollapsing;
    OnFreeNode:= @TreeFreeNode;
    OnGetNodeDataSize:= @TreeGetNodeDataSize;
  end;
end;

procedure TfrmChildTree.FormShow(Sender: TObject);
var
  Node: PVirtualNode = nil;
begin
  TVirtStringTreeHelper.DeserializeTree(vst, InputTreeArray);

  if (vst.RootNodeCount = 0) then Exit;

  vst.FullExpand;
  Node:= vst.GetFirst;
  while Assigned(Node) do
  begin
    vst.ReinitNode(Node,True);
    Node:= Node^.NextSibling;
  end;

  Node:= vst.GetFirst;
  if Assigned(Node) then
  begin
    vst.Selected[node]:= True;
    if vst.CanSetFocus then vst.SetFocus;
  end;
end;

procedure TfrmChildTree.SetInputTreeArray(AValue: TRecArr);
begin
  if (Length(AValue) > 0) then FInputTreeArray:= AValue;
end;

procedure TfrmChildTree.TreeChecking(Sender: TBaseVirtualTree;
  Node: PVirtualNode; var NewState: TCheckState; var Allowed: Boolean);
begin
//
end;

procedure TfrmChildTree.TreeChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  Sender.Selected[Node]:= True;
  Sender.FocusedNode:= Node;
end;

procedure TfrmChildTree.TreeCollapsing(Sender: TBaseVirtualTree;
  Node: PVirtualNode; var Allowed: Boolean);
begin
  Allowed:= False;
end;

procedure TfrmChildTree.TreeAddToSelection(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
var
  Data: PMyRecord = nil;
begin
  Data:= vst.GetNodeData(Node);

  if not Assigned(Data) then Exit;

  case Node^.CheckType of
    ctRadioButton:
      begin
        Data^.ValueCheckState:= csCheckedNormal;
        Sender.ReinitNode(Node,True);
      end
  else ;
  end;

    //then OutputText:= 'no data'
    //else OutputText:= Data^.ValueProtocol
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

end.

