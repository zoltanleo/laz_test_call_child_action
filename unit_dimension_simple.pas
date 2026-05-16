unit unit_dimension_simple;

{$mode ObjFPC}{$H+}

interface

uses
  Classes
  , SysUtils
  , Forms
  , Controls
  , Graphics
  , Dialogs
  , ExtCtrls
  , ComCtrls
  , StdCtrls
  , ActnList
  , LazUTF8
  , unit_virtstringtree
  ;

type

  { TfrmDimensionSimple }

  TfrmDimensionSimple = class(TForm)
    actCancel: TAction;
    actOK: TAction;
    actList: TActionList;
    btnRight: TButton;
    btnLeft: TButton;
    edtDimH: TEdit;
    edtDimTh: TEdit;
    edtDimW: TEdit;
    lblDescription: TLabel;
    lblDimW: TLabel;
    lblDimH: TLabel;
    lblDimTh: TLabel;
    pnlCommon: TPanel;
    pnlBottom: TPanel;
    pnlMiddle: TPanel;
    pnlTop: TPanel;
    scbDimension: TScrollBox;
    TrackBar1: TTrackBar;
    trbDimH: TTrackBar;
    trbDimTh: TTrackBar;
    trbDimW: TTrackBar;
    procedure actCancelExecute(Sender: TObject);
    procedure actOKExecute(Sender: TObject);
    procedure edtDimWEditingDone(Sender: TObject);
    procedure edtDimWKeyPress(Sender: TObject; var Key: char);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure trbDimWChange(Sender: TObject);
  private
    FGenText: TStringBuilder;
    FNodeDimensionType: TNodeDimensionType;
    FOnClosed: TNotifyEvent;
  public
    property OnClosed: TNotifyEvent read FOnClosed write FOnClosed;
    property NodeDimensionType: TNodeDimensionType read FNodeDimensionType write FNodeDimensionType;
    property GenText: TStringBuilder read FGenText;
  end;

var
  frmDimensionSimple: TfrmDimensionSimple;

implementation

{$R *.lfm}

{ TfrmDimensionSimple }


procedure TfrmDimensionSimple.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  GenText.Clear;

  if (StrToInt(edtDimW.Text) <> 0) then GenText.AppendFormat('%s',[edtDimW.Text]);

  if pnlMiddle.Visible then
    if (StrToInt(edtDimH.Text) <> 0) then
    begin
      if (StrToInt(edtDimW.Text) <> 0)
        then GenText.AppendFormat(' мм x %s',[edtDimH.Text])
        else GenText.AppendFormat('%s',[edtDimH.Text]);
    end;

  if pnlBottom.Visible then
    if (StrToInt(edtDimTh.Text) <> 0) then
    begin
      if (StrToInt(edtDimW.Text) <> 0) or (StrToInt(edtDimH.Text) <> 0)
        then GenText.AppendFormat(' мм x %s',[edtDimTh.Text])
        else GenText.AppendFormat('%s',[edtDimTh.Text]);
    end;

  GenText.Append(' мм');
end;

procedure TfrmDimensionSimple.edtDimWKeyPress(Sender: TObject; var Key: char
  );
begin
  if not (Key in ['0'..'9',#8]) then Key:= #0;
end;

procedure TfrmDimensionSimple.edtDimWEditingDone(Sender: TObject);
var
  Value: LongInt = 0;
  PnlPar: TPanel = nil;
  Trb: TTrackBar = nil;
  i: SizeInt = 0;
begin
  if not TObject(Sender).InheritsFrom(TEdit) then Exit;
  PnlPar:= TPanel(TEdit(Sender).Parent);
  if not Assigned(PnlPar) then Exit;

  for i := 0 to Pred(PnlPar.ControlCount) do
    if (PnlPar.Controls[i]).InheritsFrom(TTrackBar) then
    begin
      Trb:= TTrackBar(PnlPar.Controls[i]);
      Break;
    end;

  if not Assigned(Trb) then Exit;

  if not TryStrToInt(TEdit(Sender).Text,Value) then Value:= 0;

  if (Value > Trb.Max)
    then Value:= Trb.Max
    else
      if (Value < Trb.Min) then  Value:= Trb.Min;

  Trb.OnChange:= nil;
  Trb.Position:= Value;
  Trb.OnChange:= @trbDimWChange;

  TEdit(Sender).Text:= IntToStr(Value);
end;

procedure TfrmDimensionSimple.actCancelExecute(Sender: TObject);
begin
  Self.ModalResult:= mrCancel;
end;

procedure TfrmDimensionSimple.actOKExecute(Sender: TObject);
begin
  Self.ModalResult:= mrOK;
end;

procedure TfrmDimensionSimple.FormCreate(Sender: TObject);
var
  i: SizeInt = 0;
  ChrWdt: SizeInt = 0;

  procedure RecursiveInitControls(aCtrl: TControl);
  var
    cnt: SizeInt = 0;
    ChildCtrl: TControl = nil;
  begin
    if aCtrl.InheritsFrom(TPanel) then
    begin
      TPanel(aCtrl).Caption:= '';
      TPanel(aCtrl).Color:= clDefault;
      TPanel(aCtrl).BevelOuter:= bvNone;
      TPanel(aCtrl).AutoSize:= True;
    end;

    if aCtrl.InheritsFrom(TEdit) then
    begin
      TEdit(aCtrl).MaxLength:= 3;
      TEdit(aCtrl).Text:= '0';
      {$IFDEF MSWINDOWS}
      TEdit(aCtrl).Width:= ChrWdt;
      {$ENDIF}
      TEdit(aCtrl).OnKeyPress:= @edtDimWKeyPress;
      TEdit(aCtrl).OnEditingDone:= @edtDimWEditingDone;
    end;

    if aCtrl.InheritsFrom(TTrackBar) then
    begin
      begin
        TTrackBar(aCtrl).Max:= 100;
        TTrackBar(aCtrl).Frequency:= 5;
      end;

      TTrackBar(aCtrl).Position:= 0;
      TTrackBar(aCtrl).OnChange:= @trbDimWChange;
    end;

    if aCtrl.InheritsFrom(TScrollBox) then
    begin
      TScrollBox(aCtrl).BorderStyle:= bsNone;
      TScrollBox(aCtrl).HorzScrollBar.Smooth:= True;
      TScrollBox(aCtrl).HorzScrollBar.Tracking:= True;
      TScrollBox(aCtrl).VertScrollBar.Smooth:= True;
      TScrollBox(aCtrl).VertScrollBar.Tracking:= True;
    end;

    //является винконтролом и контейнером
    if ((aCtrl is TWinControl) and(csAcceptsControls in aCtrl.ControlStyle))  then
      for cnt := 0 to Pred(TWinControl(aCtrl).ControlCount) do
      begin
        ChildCtrl:= TWinControl(aCtrl).Controls[cnt];
        RecursiveInitControls(ChildCtrl);
      end;
  end;
begin
  Self.ShowHint:= True;
  Self.AutoSize:= True;
  Self.ModalResult:= mrNone;
  FGenText:= TStringBuilder.Create;

  ChrWdt:= Canvas.TextWidth('0000');//ширина большого символа
  FNodeDimensionType:= ndtNone;

  trbDimW.Tag:= 1;
  trbDimH.Tag:= 2;
  trbDimTh.Tag:= 3;

  edtDimW.Tag:= trbDimW.Tag;
  edtDimH.Tag:= trbDimH.Tag;
  edtDimTh.Tag:= trbDimTh.Tag;

  for i:= 0 to Pred(Self.ControlCount) do RecursiveInitControls(Self.Controls[i]);

  Self.Constraints.MinWidth:= edtDimW.Width * 10;

  btnLeft.OnClick:= @actOKExecute;
  btnRight.OnClick:= @actCancelExecute;

end;

procedure TfrmDimensionSimple.FormDeactivate(Sender: TObject);
begin
  //btnCloseClick(Sender);
end;

procedure TfrmDimensionSimple.FormDestroy(Sender: TObject);
begin
  FGenText.Free;
end;

procedure TfrmDimensionSimple.FormShow(Sender: TObject);
begin
  pnlMiddle.Visible:= (PtrInt(NodeDimensionType) >= PtrInt(ndtDouble));
  pnlBottom.Visible:= (PtrInt(NodeDimensionType) >= PtrInt(ndtTriple));
end;

procedure TfrmDimensionSimple.trbDimWChange(Sender: TObject);
var
  tmpEdt: TEdit = nil;

  function FindEditByTag(aCtrl: TWinControl; aTag: Integer): TEdit;
  var
    cnt: SizeInt = -1;
    ChildCtrl: TControl = nil;
  begin
    Result:= nil;

    if TWinControl(aCtrl).InheritsFrom(TEdit) then
      if (TEdit(aCtrl).Tag = aTag) then
      begin
        Result:= TEdit(aCtrl);
        Exit;
      end;

    if (csAcceptsControls in aCtrl.ControlStyle) then
      for cnt := 0 to Pred(aCtrl.ControlCount) do
      begin
        ChildCtrl:= aCtrl.Controls[cnt];

        if (ChildCtrl is TWinControl) then
        begin
          Result := FindEditByTag(TWinControl(ChildCtrl), ATag);
          if Assigned(Result) then Exit; // Нашли во вложенном контейнере, выходим
        end;
      end;
  end;
begin
  if not TObject(Sender).InheritsFrom(TTrackBar) then Exit;
  if not TTrackBar(Sender).Visible  then Exit;

  tmpEdt:= FindEditByTag(Self,TTrackBar(Sender).Tag);
  if not Assigned(tmpEdt) then Exit;

  tmpEdt.Text:= IntToStr(TTrackBar(Sender).Position);
  //actCalcVolumeExecute(Sender);
end;

end.

