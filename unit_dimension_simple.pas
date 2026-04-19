unit unit_dimension_simple;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, unit_virtstringtree;

type

  { TfrmDimensionSimple }

  TfrmDimensionSimple = class(TForm)
    btnClose: TButton;
    edtSingDimH: TEdit;
    edtSingDimTh: TEdit;
    edtSingDimW: TEdit;
    lblDescription: TLabel;
    lblSingDimWUnit: TLabel;
    lblSingDimWUnit1: TLabel;
    lblSingDimWUnit2: TLabel;
    Panel1: TPanel;
    pnlBottom: TPanel;
    pnlMiddle: TPanel;
    pnlTop: TPanel;
    ScrollBox1: TScrollBox;
    trbSingDimH: TTrackBar;
    trbSingDimTh: TTrackBar;
    trbSingDimW: TTrackBar;
    procedure btnCloseClick(Sender: TObject);
    procedure edtSingDimWEditingDone(Sender: TObject);
    procedure edtSingDimWKeyPress(Sender: TObject; var Key: char);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure trbSingDimWChange(Sender: TObject);
  private
    FNodeDimensionType: TNodeDimensionType;
    FOnClosed: TNotifyEvent;
    FReadyText: String;
  public
    property OnClosed: TNotifyEvent read FOnClosed write FOnClosed;
    property ReadyText: String read FReadyText;
    property NodeDimensionType: TNodeDimensionType read FNodeDimensionType write FNodeDimensionType;
  end;

var
  frmDimensionSimple: TfrmDimensionSimple;

implementation

{$R *.lfm}

{ TfrmDimensionSimple }


procedure TfrmDimensionSimple.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  FReadyText:= FormatDateTime('hh:nn:ss.zzz',Now);

  if Assigned(FOnClosed) then FOnClosed(Self);
  CloseAction:= caFree;
end;

procedure TfrmDimensionSimple.edtSingDimWKeyPress(Sender: TObject; var Key: char
  );
begin
  if not (Key in ['0'..'9']) then Key:= #0;
end;

procedure TfrmDimensionSimple.edtSingDimWEditingDone(Sender: TObject);
var
  Value: LongInt = 0;
  tmpTrBar: TTrackBar = nil;

  function FindTrackBarByTag(aCtrl: TWinControl; aTag: Integer): TTrackBar;
  var
    cnt: SizeInt = -1;
    ChildCtrl: TControl = nil;
  begin
    Result:= nil;

    if TWinControl(aCtrl).InheritsFrom(TTrackBar) then
      if (TTrackBar(aCtrl).Tag = aTag) then
      begin
        Result:= TTrackBar(aCtrl);
        Exit;
      end;

    if (csAcceptsControls in aCtrl.ControlStyle) then
      for cnt := 0 to Pred(aCtrl.ControlCount) do
      begin
        ChildCtrl:= aCtrl.Controls[cnt];

        if (ChildCtrl is TWinControl) then
        begin
          Result := FindTrackBarByTag(TWinControl(ChildCtrl), ATag);
          if Assigned(Result) then Exit; // Нашли во вложенном контейнере, выходим
        end;
      end;
  end;
begin
  if not TObject(Sender).InheritsFrom(TEdit) then Exit;

  tmpTrBar:= FindTrackBarByTag(Self,TEdit(Sender).Tag);

  if not Assigned(tmpTrBar) then Exit;
  if not tmpTrBar.Enabled then Exit;//отключенных не обслуживаем

  if not TryStrToInt(TEdit(Sender).Text,Value) then Value:= 0;

  if (Value > tmpTrBar.Max)
    then Value:= tmpTrBar.Max
    else if (Value < tmpTrBar.Min)
          then  Value:= tmpTrBar.Min;

  tmpTrBar.OnChange:= nil;
  tmpTrBar.Position:= Value;
  tmpTrBar.OnChange:= @trbSingDimWChange;

  TEdit(Sender).Text:= IntToStr(Value);
end;

procedure TfrmDimensionSimple.btnCloseClick(Sender: TObject);
begin
  Self.Close;
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
    end;

    if aCtrl.InheritsFrom(TEdit) then
    begin
      TEdit(aCtrl).MaxLength:= 3;
      TEdit(aCtrl).Text:= '0';
      TEdit(aCtrl).Width:= ChrWdt * 3;
      TEdit(aCtrl).OnKeyPress:= @edtSingDimWKeyPress;
      TEdit(aCtrl).OnEditingDone:= @edtSingDimWEditingDone;
    end;

    if aCtrl.InheritsFrom(TTrackBar) then
    begin
      begin
        TTrackBar(aCtrl).Max:= 100;
        TTrackBar(aCtrl).Frequency:= 5;
      end;

      TTrackBar(aCtrl).Height:= lblDescription.Height * 3 div 2;

      TTrackBar(aCtrl).Position:= 0;
      TTrackBar(aCtrl).OnChange:= @trbSingDimWChange;
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
  Self.AutoScroll:= True;
  Self.AutoSize:= True;

  ChrWdt:= Canvas.TextWidth('W');//ширина большого символа
  FNodeDimensionType:= ndtNone;

  trbSingDimW.Tag:= 1;
  trbSingDimH.Tag:= 2;
  trbSingDimTh.Tag:= 3;

  edtSingDimW.Tag:= trbSingDimW.Tag;
  edtSingDimH.Tag:= trbSingDimH.Tag;
  edtSingDimTh.Tag:= trbSingDimTh.Tag;


  for i:= 0 to Pred(Self.ControlCount) do RecursiveInitControls(Self.Controls[i]);

  Self.Constraints.MinWidth:= edtSingDimW.Width * 10;

end;

procedure TfrmDimensionSimple.FormDeactivate(Sender: TObject);
begin
  //btnCloseClick(Sender);
end;

procedure TfrmDimensionSimple.FormShow(Sender: TObject);
begin
  pnlMiddle.Visible:= (PtrInt(NodeDimensionType) >= PtrInt(ndtDouble));
  pnlBottom.Visible:= (PtrInt(NodeDimensionType) >= PtrInt(ndtTriple));
end;

procedure TfrmDimensionSimple.trbSingDimWChange(Sender: TObject);
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

