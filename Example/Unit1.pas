unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls;

type
  TfrmMain = class(TForm)
    Timer1: TTimer;
    btnClose: TButton;
    btnCrash: TButton;
    btnTerminate: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnCrashClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnTerminateClick(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses debug_unit;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  debug_init('Testapplication',
    IncludeTrailingPathDelimiter(ExtractFilePath(application.ExeName)));
  // path should be in %appdata% but...
  if debug_hasdump then
  begin
    ShowMessage(debug_dump);
  end;

  // do something
  Timer1.Enabled := true;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Timer1.Enabled := false;
  debug_done(true);
end;

// --

procedure TfrmMain.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.btnCrashClick(Sender: TObject);
begin
  // some try except or Application.OnException to catch unhandled exceptions
  ShowMessage(debug_dump);
end;

procedure TfrmMain.btnTerminateClick(Sender: TObject);
begin
  // terminate application, maybe crashed
  ShowMessage('shit happens');
  application.Terminate;
end;

//

procedure TfrmMain.Timer1Timer(Sender: TObject);
begin
  // something;
  if debug_istaktiv then
  begin
    debug_add('Called some function at ' + formatdatetime('hh:nn:ss', now));
  end;
end;

end.
