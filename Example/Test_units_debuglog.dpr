program Test_units_debuglog;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {frmMain},
  debug_unit in '..\debug_unit.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
