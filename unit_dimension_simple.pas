unit unit_dimension_simple;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls;

type

  { TfrmDimensionSimple }

  TfrmDimensionSimple = class(TForm)
    edtSingDimW: TEdit;
    edtSingDimW1: TEdit;
    edtSingDimW2: TEdit;
    lblSingDimWUnit: TLabel;
    lblSingDimWUnit1: TLabel;
    lblSingDimWUnit2: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    trbSingDimW: TTrackBar;
    trbSingDimW1: TTrackBar;
    trbSingDimW2: TTrackBar;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormDeactivate(Sender: TObject);
  private
    FOnClosed: TNotifyEvent;
    FReadyText: String;
  public
    property OnClosed: TNotifyEvent read FOnClosed write FOnClosed;
    property ReadyText: String read FReadyText;
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

procedure TfrmDimensionSimple.FormDeactivate(Sender: TObject);
begin
  Self.Close;
end;

end.

