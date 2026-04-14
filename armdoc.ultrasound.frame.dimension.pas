unit armdoc.ultrasound.frame.dimension;

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
  , Buttons
  , ComCtrls
  , ActnList
  , LCLProc
  , LazUTF8
  , armdoc.ultrasound.common
  , JsonTools
  ;

type

  { TfrmFrameDimension }

  TfrmFrameDimension = class(TForm)
    actCalcVolume: TAction;
    actChoice: TAction;
    actExit: TAction;
    actHelp: TAction;
    actResultMultiplicity: TAction;
    actResultSingleness: TAction;
    actSwitchBox: TAction;
    actList: TActionList;
    bvlSingleness: TBevel;
    btnHelp: TButton;
    btnLeft: TButton;
    btnRight: TButton;
    bvlChoice: TBevel;
    chbVolCalculation: TCheckBox;
    edtMultDimMin: TEdit;
    edtMultDimMax: TEdit;
    edtSingDimW: TEdit;
    edtSingDimH: TEdit;
    edtSingDimTh: TEdit;
    edtSingDimV: TEdit;
    gbSingleness: TGroupBox;
    gbMultiplicity: TGroupBox;
    lblMultDimMin: TLabel;
    lblMultDimMax: TLabel;
    lblMultDimMinUnit: TLabel;
    lblMultDimMaxUnit: TLabel;
    lblSingDimW: TLabel;
    lblSingDimH: TLabel;
    lblSingDimTh: TLabel;
    lblSingDimV: TLabel;
    lblSingDimWUnit: TLabel;
    lblSingDimHUnit: TLabel;
    lblSingDimThUnit: TLabel;
    lblSingDimVUnit: TLabel;
    pnlButtons: TPanel;
    sbtnSingleness: TSpeedButton;
    sbtnMultiplicity: TSpeedButton;
    trbSingDimV: TTrackBar;
    trbMultDimMin: TTrackBar;
    trbMultDimMax: TTrackBar;
    trbSingDimW: TTrackBar;
    trbSingDimH: TTrackBar;
    trbSingDimTh: TTrackBar;
    procedure actCalcVolumeExecute(Sender: TObject);
    procedure actChoiceExecute(Sender: TObject);
    procedure actExitExecute(Sender: TObject);
    procedure actHelpExecute(Sender: TObject);
    procedure actResultMultiplicityExecute(Sender: TObject);
    procedure actResultSinglenessExecute(Sender: TObject);
    procedure actSwitchBoxExecute(Sender: TObject);
    procedure chbVolCalculationChange(Sender: TObject);
    procedure edtSingDimWEditingDone(Sender: TObject);
    procedure edtSingDimWKeyPress(Sender: TObject; var Key: char);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure trbSingDimWChange(Sender: TObject);
  private
    FBtnHeight: SizeInt;
    FGenText: TStringBuilder;//итоговый текст
    FMainNode: TJsonNode;
    FSettingsFile: String;
    FVolume: LongInt;//объем образования
  public
    property Volume: LongInt read FVolume;
    property GenText: TStringBuilder read FGenText;
    property MainNode: TJsonNode read FMainNode write FMainNode;//узел с настройками формы
    property SettingsFile: String read FSettingsFile write FSettingsFile;//файл с настройками программы (полный путь)
    property BtnHeight: SizeInt read FBtnHeight write FBtnHeight;//абстрактная высота кнопки
  end;

var
  frmFrameDimension: TfrmFrameDimension;

implementation

{$R *.lfm}

{ TfrmFrameDimension }

procedure TfrmFrameDimension.FormCreate(Sender: TObject);
var
  i: SizeInt = -1;
  ChrWdt: SizeInt = 0;
  AnAction: TBasicAction = nil;
  len: SizeInt = 0;

  procedure RecursiveInitControls(aCtrl: TControl);
  var
    cnt: SizeInt = 0;
    ChildCtrl: TControl = nil;
  begin
    if aCtrl.InheritsFrom(TEdit) then
    begin
      if TEdit(aCtrl).Equals(edtSingDimV)
        then TEdit(aCtrl).MaxLength:= 4
        else TEdit(aCtrl).MaxLength:= 3;
      TEdit(aCtrl).Text:= '0';
      TEdit(aCtrl).Width:= ChrWdt * 3;
      TEdit(aCtrl).OnKeyPress:= @edtSingDimWKeyPress;
      TEdit(aCtrl).OnEditingDone:= @edtSingDimWEditingDone;
    end;

    if aCtrl.InheritsFrom(TTrackBar) then
    begin
      if TTrackBar(aCtrl).Equals(trbSingDimV) then
      begin
        TTrackBar(aCtrl).Max:= 1000;
        TTrackBar(aCtrl).Frequency:= 50;
      end else
      begin
        TTrackBar(aCtrl).Max:= 100;
        TTrackBar(aCtrl).Frequency:= 5;
      end;

      TTrackBar(aCtrl).Height:= lblSingDimH.Height * 3 div 2;

      TTrackBar(aCtrl).Position:= 0;
      TTrackBar(aCtrl).OnChange:= @trbSingDimWChange;
    end;

    if aCtrl.InheritsFrom(TButton) then
    begin
      {$IFDEF LINUX}
      TButton(aCtrl).Height:= BtnHeight;
      {$ENDIF}
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
  Self.ModalResult:= mrCancel;
  FGenText:= TStringBuilder.Create;
  FMainNode:= TJsonNode.Create;
  FBtnHeight:= DefaultBtnHeight;

  bvlChoice.Width:= 0;
  sbtnSingleness.GroupIndex:= 1;
  sbtnMultiplicity.GroupIndex:= sbtnSingleness.GroupIndex;

  sbtnSingleness.Down:= True;
  sbtnSingleness.OnClick:= @actSwitchBoxExecute;
  sbtnMultiplicity.OnClick:= @actSwitchBoxExecute;

  gbSingleness.Caption:= '';
  gbSingleness.Constraints.MinHeight:= edtSingDimH.Height * 11;
  gbSingleness.Constraints.MinWidth:= edtSingDimH.Height * 14;

  gbMultiplicity.Caption:= '';
  bvlSingleness.Height:= 2;

  ChrWdt:= Canvas.TextWidth('W');//ширина большого символа
  FVolume:= 0;

  for i:= 0 to Pred(Self.ControlCount) do RecursiveInitControls(Self.Controls[i]);

  with pnlButtons do
  begin
    Constraints.MinWidth:= edtSingDimH.Height * 31;
    Color:= clDefault;
    BevelOuter:= bvNone;
    Caption:= '';
  end;

  for i := 0 to Pred(pnlButtons.ControlCount) do
  if pnlButtons.Controls[i].InheritsFrom(TButton) then
    if (Canvas.TextWidth(TButton(pnlButtons.Controls[i]).Caption) > len)
      then len:= Canvas.TextWidth(TButton(pnlButtons.Controls[i]).Caption);

  for i := 0 to Pred(pnlButtons.ControlCount) do
    if pnlButtons.Controls[i].InheritsFrom(TButton)
      then TButton(pnlButtons.Controls[i]).Width:= len + ChrWdt * 2;

  for AnAction in actList do
  begin
    TAction(AnAction).SecondaryShortCuts.Clear;
    TAction(AnAction).ShortCut := TextToShortCut('');
  end;

  actChoice.SecondaryShortCuts.Add(c_ShortCut_Save);
  actChoice.SecondaryShortCuts.Add(c_ShortCut_Enter);
  actExit.SecondaryShortCuts.Add(c_ShortCut_Cancel);

  {$IF DEFINED(MSWINDOWS) or DEFINED(LCLqt) or DEFINED(LCLqt5) or DEFINED(LCLqt6)}
  btnLeft.OnClick := @actChoiceExecute;
  btnLeft.Hint := Format('%s (%s)', [CaptBtn_Choice, c_ShortCut_Save]);
  btnLeft.Caption := CaptBtn_Choice;


  btnRight.OnClick := @actExitExecute;
  btnRight.Hint := Format('%s (%s)', [CaptBtn_Cancel, c_ShortCut_Cancel]);
  btnRight.Caption := CaptBtn_Cancel;
  {$ELSE}
  btnRight.OnClick:= @actChoiceExecute;
  btnRight.Hint:= Format('%s (%s)',[CaptBtn_Choice, c_ShortCut_Save]);
  btnRight.Caption:= CaptBtn_Choice;

  btnLeft.OnClick:= @actExitExecute;
  btnLeft.Hint:= Format('%s (%s)',[CaptBtn_Cancel, c_ShortCut_Cancel]);
  btnLeft.Caption:= CaptBtn_Cancel;
  {$ENDIF}

  btnHelp.OnClick := @actHelpExecute;
  btnHelp.Hint := Format('%s (%s)', [CaptBtn_Help, c_ShortCut_Help]);
  btnHelp.Caption := CaptBtn_Help;

  trbSingDimW.Tag:= 1;
  edtSingDimW.Tag:= trbSingDimW.Tag;

  trbSingDimH.Tag:= 2;
  edtSingDimH.Tag:= trbSingDimH.Tag;

  trbSingDimTh.Tag:= 3;
  edtSingDimTh.Tag:= trbSingDimTh.Tag;

  trbSingDimV.Tag:= 4;
  edtSingDimV.Tag:= trbSingDimV.Tag;

  trbMultDimMin.Tag:= 5;
  edtMultDimMin.Tag:= trbMultDimMin.Tag;

  trbMultDimMax.Tag:= 6;
  edtMultDimMax.Tag:= trbMultDimMax.Tag;
end;

procedure TfrmFrameDimension.FormDestroy(Sender: TObject);
begin
  FMainNode.Free;
  FGenText.Free;
end;

procedure TfrmFrameDimension.FormShow(Sender: TObject);
var
  N: TJsonNode = nil;
begin
  actSwitchBoxExecute(Sender);

  //грузим настройки
  LoadSettings(Self, SettingsFile, MainNode);

  N:= nil;
  N:= MainNode.Find(UTF8LowerCase(Self.Name + '/chbVolCalculation/checked'));
  if Assigned(N) then Self.chbVolCalculation.Checked:= Boolean(StrToIntDef(N.AsString, 0));
end;

procedure TfrmFrameDimension.trbSingDimWChange(Sender: TObject);
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
  if not TTrackBar(Sender).Enabled then Exit;

  tmpEdt:= FindEditByTag(Self,TTrackBar(Sender).Tag);
  if not Assigned(tmpEdt) then Exit;

  tmpEdt.Text:= IntToStr(TTrackBar(Sender).Position);
  actCalcVolumeExecute(Sender);
end;

procedure TfrmFrameDimension.chbVolCalculationChange(Sender: TObject);
begin
  if gbSingleness.Enabled then
  begin
    trbSingDimV.Enabled:= (chbVolCalculation.State = cbUnchecked);
    edtSingDimV.ReadOnly:= (chbVolCalculation.State = cbChecked);

    if chbVolCalculation.Checked
      then actCalcVolumeExecute(Sender)
      else edtSingDimWEditingDone(edtSingDimV) ;
  end;
end;

procedure TfrmFrameDimension.actSwitchBoxExecute(Sender: TObject);
begin
  gbSingleness.Enabled:= sbtnSingleness.Down;
  gbMultiplicity.Enabled:= not sbtnSingleness.Down;
end;

procedure TfrmFrameDimension.actCalcVolumeExecute(Sender: TObject);
var
  W: LongInt = 0;
  H: LongInt = 0;
  Th: LongInt = 0;
begin
  if not chbVolCalculation.Checked then Exit;

  if not TryStrToInt(edtSingDimW.Text,W) then W:= 0;
  if not TryStrToInt(edtSingDimH.Text,H) then H:= 0;
  if not TryStrToInt(edtSingDimTh.Text,Th) then Th:= 0;

  FVolume:= (W * H * Th) div 1000;

  edtSingDimV.Text:= IntToStr(Volume);
end;

procedure TfrmFrameDimension.actChoiceExecute(Sender: TObject);
begin
  if sbtnSingleness.Down
    then actResultSinglenessExecute(Sender)
    else actResultMultiplicityExecute(Sender);
end;

procedure TfrmFrameDimension.actExitExecute(Sender: TObject);
begin
  Self.ModalResult:= mrCancel;
end;

procedure TfrmFrameDimension.actHelpExecute(Sender: TObject);
begin
//
end;

procedure TfrmFrameDimension.actResultMultiplicityExecute(Sender: TObject);
var
  NotZeroValue: Boolean = False;
begin
  NotZeroValue:= ((StrToInt(edtMultDimMin.Text) <> 0) or (StrToInt(edtMultDimMax.Text) <> 0));

  if not NotZeroValue then
  begin
    QuestionDlg(MsgCaptNotEnoughData,
            MsgTextDimensionNoData,
            mtInformation,
            [mrOk_cust, CaptDlgBtnAllRight],
            0
            );
    Exit;
  end;

  GenText.Clear;
  GenText.Append('размеры ');
  if (StrToInt(edtMultDimMin.Text) <> 0) then GenText.AppendFormat('от %s',[edtMultDimMin.Text]);
  if (StrToInt(edtMultDimMax.Text) <> 0) then
    if (StrToInt(edtMultDimMin.Text) <> 0)
      then GenText.AppendFormat(' мм до %s',[edtMultDimMax.Text])
      else GenText.AppendFormat('до %s',[edtMultDimMax.Text]);
  GenText.Append(' мм');

  Self.ModalResult:= mrOK;
end;

procedure TfrmFrameDimension.actResultSinglenessExecute(Sender: TObject);
var
  NotZeroValue: Boolean = False;
  i: SizeInt = -1;
begin
  NotZeroValue:= False;

  for i := 0 to Pred(gbSingleness.ControlCount) do
    if gbSingleness.Controls[i].InheritsFrom(TEdit) then
      if not TEdit(gbSingleness.Controls[i]).Equals(edtSingDimV) then
      begin
        NotZeroValue:= (StrToInt(TEdit(gbSingleness.Controls[i]).Text) <> 0);
        if NotZeroValue then Break;
      end;

  if not NotZeroValue then
  begin
    QuestionDlg(MsgCaptNotEnoughData,
            MsgTextDimensionNoData,
            mtInformation,
            [mrOk_cust, CaptDlgBtnAllRight],
            0
            );
    Exit;
  end;

  GenText.Clear;
  GenText.Append('размер ');
  if (StrToInt(edtSingDimW.Text) <> 0) then GenText.AppendFormat('%s',[edtSingDimW.Text]);
  if (StrToInt(edtSingDimH.Text) <> 0) then
    if (StrToInt(edtSingDimW.Text) <> 0)
      then GenText.AppendFormat(' мм x %s',[edtSingDimH.Text])
      else GenText.AppendFormat('%s',[edtSingDimH.Text]);

  if (StrToInt(edtSingDimTh.Text) <> 0) then
    if ((StrToInt(edtSingDimW.Text) <> 0)  or (StrToInt(edtSingDimH.Text) <> 0))
      then GenText.AppendFormat(' мм x %s',[edtSingDimTh.Text])
      else GenText.AppendFormat('%s',[edtSingDimTh.Text]);
  GenText.Append(' мм');

  if (StrToInt(edtSingDimV.Text) <> 0)
    then GenText.Append(', объем V = %s мл',[edtSingDimV.Text]);

  Self.ModalResult:= mrOK;
end;

procedure TfrmFrameDimension.edtSingDimWEditingDone(Sender: TObject);
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

procedure TfrmFrameDimension.edtSingDimWKeyPress(Sender: TObject; var Key: char);
begin
  if not (Key in ['0'..'9']) then Key:= #0;
end;

procedure TfrmFrameDimension.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
var
  N: TJsonNode = Nil;
  RootNodePath: String = '';
begin
  RootNodePath:= LowerCase(Self.Name);

  if not MainNode.Find(RootNodePath, N) then N:= MainNode.Force(RootNodePath);
  N.Force(UTF8LowerCase('chbVolCalculation/checked')).AsString:= IntToStr(PtrInt(Self.chbVolCalculation.Checked));

  SaveSettings(Self, SettingsFile, MainNode);
end;

end.

