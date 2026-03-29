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
    vst: TLazVirtualStringTree;
    procedure btnCancelClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FInputTreeArray: TRecArr;
    FOutputText: String;
    procedure SetInputTreeArray(AValue: TRecArr);
    procedure vstLocationAddToSelection(Sender: TBaseVirtualTree;
      Node: PVirtualNode);
    procedure vstLocationCollapsing(Sender: TBaseVirtualTree;
      Node: PVirtualNode; var Allowed: Boolean);
    procedure vstLocationFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure vstLocationGetNodeDataSize(Sender: TBaseVirtualTree;
      var NodeDataSize: Integer);
    procedure vstLocationGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
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
    HintMode := hmTooltip;
    ShowHint := True;
    DefaultNodeHeight := Canvas.TextHeight('W') * 3 div 2;
    LineStyle:= lsSolid;

    with Header do
    begin
      Columns.Clear;
      Columns.Add;
      Columns[0].Text := '';

      AutoSizeIndex := 0;
      Height := Canvas.TextHeight('W') * 3 div 2;
      Options := Options + [hoAutoResize,
                            hoOwnerDraw,
                            hoShowHint,
                            hoShowImages
                            //, hoVisible
                            ];
      Height := Canvas.TextHeight('W') * 3 div 2;
    end;

    with TreeOptions do
    begin
      AutoOptions := AutoOptions
                    + [toAutoScroll
                      , toAutoSpanColumns]
                    - [];

      MiscOptions := MiscOptions
                    + [toCheckSupport]
                    - [toAcceptOLEDrop
                      , toEditOnClick];

      PaintOptions := PaintOptions
                    //+ [toShowButtons]
                    - [toShowDropmark, toShowButtons ];

      SelectionOptions := SelectionOptions
                     + [toExtendedFocus
                      , toFullRowSelect
                      , toCenterScrollIntoView
                      , toRestoreSelection
                      , toAlwaysSelectNode]
                    - [toMultiSelect];
    end;

    OnDblClick := @btnOKClick;
    OnAddToSelection:= @vstLocationAddToSelection;
    OnCollapsing:= @vstLocationCollapsing;
    OnGetText:= @vstLocationGetText;
    OnGetNodeDataSize:= @vstLocationGetNodeDataSize;
    OnFreeNode:= @vstLocationFreeNode;
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

procedure TfrmChildTree.vstLocationAddToSelection(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
var
  Data: PMyRecord = nil;
begin
  Data:= vst.GetNodeData(Node);
  if not Assigned(Data)
    then OutputText:= 'no data'
    else OutputText:= Data^.ValueProtocol;
end;

procedure TfrmChildTree.vstLocationCollapsing(Sender: TBaseVirtualTree;
  Node: PVirtualNode; var Allowed: Boolean);
begin
  Allowed:= False;
end;

procedure TfrmChildTree.vstLocationFreeNode(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
begin
  if Assigned(Sender.GetNodeData(Node)) then
    Finalize(PMyRecord(Sender.GetNodeData(Node))^);
end;

procedure TfrmChildTree.vstLocationGetNodeDataSize(Sender: TBaseVirtualTree;
  var NodeDataSize: Integer);
begin
  NodeDataSize:= SizeOf(TMyRecord);
end;

procedure TfrmChildTree.vstLocationGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: String);
var
  Data: PMyRecord = nil;
begin
  Data := vst.GetNodeData(Node);
  if not Assigned(Data) then Exit;

  case Column of
    0: CellText := Data^.ValueCaption;
    else;
  end;
end;

end.

