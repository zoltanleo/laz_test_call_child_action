unit unit_virtstringtree;

{$mode ObjFPC}{$H+}

interface

uses
  Classes
  , SysUtils
  , laz.VirtualTrees
  , LCLIntf
  , LCLType
  , ActnList
  ;

type

  PMyRecord = ^TMyRecord;
  TMyRecord = record
    ID: SizeInt;          //  tree node ID
    ParentID: SizeInt;    // contains the root node ID for the child node (-1 for the root node)
    ActionName: String;   // link-name of an Action in a custom ActList
    Caption: String;      // node header
  end;

  TRecArr = array of TMyRecord;
  TActArray = array of TAction;

  // Тип callback-процедуры для отображения сообщений из обработчиков действий
  TDisplayMessageProc = procedure(const AMessage: String) of object;

  { TPseudoTreeClass - базовый класс для работы с псевдодеревом }
  TPseudoTreeClass = class
  protected
    FPseudoNodeArr: TRecArr;
    FActList: TActionList;
    FActArray: TActArray;
    FOnDisplayMessage: TDisplayMessageProc;
  public
    constructor Create(aOwner: TComponent);
    destructor Destroy; override;
    property ActList: TActionList read FActList write FActList;
    property ActArray: TActArray read FActArray write FActArray;
    property PseudoNodeArr: TRecArr read FPseudoNodeArr write FPseudoNodeArr;
    property OnDisplayMessage: TDisplayMessageProc read FOnDisplayMessage write FOnDisplayMessage; // Callback для отображения результата выполнения действия во внешнем контроле

    function GetActionByIndex(Index: SizeInt): TAction;
    function GetActionByName(const AName: String): TAction;
    function ActionCount: SizeInt;
    procedure GetPseudoTreeData; virtual; abstract; // абстрактный метод для переопределения
    class procedure AddPseudoNode(var aRecArr: TRecArr; const aID, aParentID: SizeInt;
      const aActionName, aCaption: String);
  end;

  // Auxiliary classes for accessing protected fields
  TBaseVirtualTreeAccess = class(TBaseVirtualTree)
  end;

  TLazVirtualStringTreeAccess = class(TLazVirtualStringTree)
  end;

  { TVirtStringTreeHelper }

  TVirtStringTreeHelper = class
  private
  public
    class function GetNodeDataSizeHelper: LongInt;
    class function GetRootNodeCountHelper(aTree: TBaseVirtualTree): LongWord;
    class function AddNode(aTree: TBaseVirtualTree; aNode: PVirtualNode; const AActionName, ACaption: String): PVirtualNode;
    class procedure InitializeTree(aTree: TBaseVirtualTree); // устанавливает NodeDataSize
    class procedure SerializeTree(aTree: TBaseVirtualTree; out aRecArr: TRecArr);
    class procedure DeserializeTree(aTree: TBaseVirtualTree; aRecArr: TRecArr);
  end;


implementation

{ TPseudoTreeClass }

constructor TPseudoTreeClass.Create(aOwner: TComponent);
begin
  inherited Create;
  FActList := TActionList.Create(aOwner);
end;

destructor TPseudoTreeClass.Destroy;
begin
  FActList.Free;
  inherited Destroy;
end;

function TPseudoTreeClass.GetActionByIndex(Index: SizeInt): TAction;
begin
  Result := nil;
  if (Index >= 0) and (Index < Length(FActArray)) then
    Result := FActArray[Index];
end;

function TPseudoTreeClass.GetActionByName(const AName: String): TAction;
var
  i: SizeInt;
begin
  Result := nil;
  for i := 0 to High(FActArray) do
    if Assigned(FActArray[i]) and (FActArray[i].Name = AName) then
    begin
      Result := FActArray[i];
      Break;
    end;
end;

function TPseudoTreeClass.ActionCount: SizeInt;
begin
  Result := Length(FActArray);
end;

class procedure TPseudoTreeClass.AddPseudoNode(var aRecArr: TRecArr; const aID,
  aParentID: SizeInt; const aActionName, aCaption: String);
var
  tmpArr: TMyRecord;
begin
  with tmpArr do
  begin
    ID := aID;
    ParentID := aParentID;
    ActionName := aActionName;
    Caption := aCaption;
  end;
  SetLength(aRecArr, Length(aRecArr) + 1);
  aRecArr[High(aRecArr)] := tmpArr;
end;

class function TVirtStringTreeHelper.GetNodeDataSizeHelper: LongInt;
begin
  Result := SizeOf(TMyRecord);
end;

class function TVirtStringTreeHelper.GetRootNodeCountHelper(aTree: TBaseVirtualTree): LongWord;
var
  Node: PVirtualNode = nil;
begin
  Result:= 0;

  Node:= aTree.GetFirst;
  while Assigned(Node) do
  begin
    Inc(Result);
    Node:= Node^.NextSibling;
  end;
end;

{ TVirtStringTreeHelper }
class function TVirtStringTreeHelper.AddNode(aTree: TBaseVirtualTree;
  aNode: PVirtualNode; const AActionName, ACaption: String): PVirtualNode;
var
  Data: PMyRecord = nil;
  ParentID: SizeInt = 0;
begin
  Result := aTree.AddChild(aNode);

  if Assigned(aNode) then
  begin
    Data:= aTree.GetNodeData(aNode);
    ParentID := Data^.ID;
  end else ParentID := -1;

  Data:= aTree.GetNodeData(Result);

  Data^.ID := aTree.AbsoluteIndex(Result);
  Data^.ParentID := ParentID;
  Data^.ActionName := AActionName;
  Data^.Caption := ACaption;
end;

class procedure TVirtStringTreeHelper.InitializeTree(aTree: TBaseVirtualTree);
begin
  // Используем вспомогательный класс для доступа к защищенному свойству
  TBaseVirtualTreeAccess(aTree).NodeDataSize := SizeOf(TMyRecord);
end;

class procedure TVirtStringTreeHelper.SerializeTree(aTree: TBaseVirtualTree;
  out aRecArr: TRecArr);
var
  Node: PVirtualNode = nil;
  RecArr: TRecArr;
  i: SizeInt = 0;

  procedure AddNodeDataToRecArr(aTree: TBaseVirtualTree; aNode: PVirtualNode);
  var
    Data: PMyRecord = nil;
    ChildNode: PVirtualNode = nil;
  begin
    while Assigned(aNode) do
    begin
      Data:= nil;
      Data:= aTree.GetNodeData(aNode);

      SetLength(RecArr,Length(RecArr) + 1);
      RecArr[High(RecArr)]:= Data^;

      if (aNode^.ChildCount > 0) then
      begin
        ChildNode:= aNode^.FirstChild;
        AddNodeDataToRecArr(aTree,ChildNode);
      end;

      aNode:= aNode^.NextSibling;
    end;
  end;

begin
  //if the tree is empty
  //if (TLazVirtualStringTreeAccess(aTree).RootNodeCount = 0) then Exit;//--> sometimes it gives a type conversion error when called in a third-party module.
  if (GetRootNodeCountHelper(aTree) = 0) then Exit;

  SetLength(RecArr,0);
  Node:= aTree.GetFirst;
  AddNodeDataToRecArr(aTree, Node);

  //filling the output buffer (array) with data
  SetLength(aRecArr,0);

  for i := 0 to High(RecArr) do
  begin
    SetLength(aRecArr,Length(aRecArr) + 1);
    aRecArr[High(aRecArr)]:= RecArr[i];
  end;
end;

class procedure TVirtStringTreeHelper.DeserializeTree(aTree: TBaseVirtualTree;
  aRecArr: TRecArr);
var
  tmpParentID: SizeInt = 0;
  tmpRecArr: TRecArr;
  i: SizeInt = 0;

  //returns the number of elements with ParentID = childID in the InRecArr input array,
  //if available, fills the OutRecArr output array with them
  function GetChildRecords(ChildID: SizeInt; InRecArr: TRecArr; out OutRecArr: TRecArr):SizeInt;
  var
    idx: SizeInt  = 0;
  begin
    Result:= 0;

    for idx := 0 to High(InRecArr) do
      if (InRecArr[idx].ParentID = ChildID) then Inc(Result);

    if (Result = 0) then Exit;

    SetLength(OutRecArr,0);//инициализируем выходной буфер-массив

    for idx := 0 to High(InRecArr) do
      if (InRecArr[idx].ParentID = ChildID) then
      begin
        SetLength(OutRecArr,Length(OutRecArr) + 1);
        OutRecArr[High(OutRecArr)]:= InRecArr[idx];
      end;
  end;

  //adds nodes of the same aParentID to the aTree tree if parentNode is defined,
  //then the nodes will be child nodes, otherwise they will be root nodes
  procedure AddNodeFromArray(aParentID: SizeInt; ParentNode: PVirtualNode = nil);
  var
    Node: PVirtualNode = nil;
    Data: PMyRecord = nil;
    _RecArr: TRecArr;
    j: SizeInt = 0;
  begin
    if (GetChildRecords(aParentID,aRecArr,_RecArr) = 0) then Exit;

    for j := 0 to High(_RecArr) do
    begin
      Node:= aTree.AddChild(ParentNode);
      Data:= aTree.GetNodeData(Node);
      Data^:= _RecArr[j];
    end;

    if Assigned(ParentNode)
      then Node:= ParentNode^.FirstChild
      else Node:= aTree.GetFirst;

    while Assigned(Node) do
    begin
      Data:= aTree.GetNodeData(Node);
      AddNodeFromArray(Data^.ID, Node);//adding nested nodes
      Node:= Node^.NextSibling;
    end;
  end;
begin
  aTree.BeginUpdate;
  try
    aTree.Clear;

    //if the input buffer is empty, the array is empty
    if (Length(aRecArr) = 0) then Exit;

    tmpParentID:= 10000000;//setting the max.probable value

    //we are looking for the smallest ParentID (which root nodes have)
    for i:= 0 to High(aRecArr) do
      if (aRecArr[i].ParentID < tmpParentID) then tmpParentID:= aRecArr[i].ParentID;

    //looking for root nodes
    if (GetChildRecords(tmpParentID,aRecArr,tmpRecArr) = 0) then Exit;

    AddNodeFromArray(tmpParentID);//looking for child records
  finally
    aTree.EndUpdate;
  end;
end;

end.

