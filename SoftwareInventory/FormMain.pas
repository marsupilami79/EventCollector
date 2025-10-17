unit FormMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.WinXCtrls,
  Vcl.ExtCtrls;

type
  TAuditThread = class(TThread)
    procedure Execute; override;
  end;

  TForm1 = class(TForm)
    ActivityIndicator: TActivityIndicator;
    Label1: TLabel;
    AuditTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure AuditTimerTimer(Sender: TObject);
    procedure Label1DblClick(Sender: TObject);
  private
    { Private-Deklarationen }
    AuditThread: TAuditThread;
  public
    { Public-Deklarationen }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses DmAudit;

procedure TAuditThread.Execute;
begin
  doSoftwareAudit;
end;

procedure TForm1.AuditTimerTimer(Sender: TObject);
begin
  if not Assigned(AuditThread) then begin
    AuditThread := TAuditThread.Create(False);
    ActivityIndicator.Animate := True;
  end else begin
    if AuditThread.Finished then begin
      AuditTimer.Enabled := False;
      FreeAndNil(AuditThread);
      Close;
    end;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  AuditTimer.Enabled := True;
end;

procedure TForm1.Label1DblClick(Sender: TObject);
begin
  Application.Terminate;
end;

end.
