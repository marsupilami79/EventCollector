unit FormMain;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls;

type
  TAuditThread = class(TThread)
    procedure Execute; override;
  end;

  { TForm1 }

  TForm1 = class(TForm)
    Label1: TLabel;
    AuditTimer: TTimer;
    ProgressBar1: TProgressBar;
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

{$R *.lfm}

uses DmAudit;

procedure TAuditThread.Execute;
begin
  doSoftwareAudit;
end;

procedure TForm1.AuditTimerTimer(Sender: TObject);
begin
  if not Assigned(AuditThread) then begin
    AuditThread := TAuditThread.Create(False);
    //ActivityIndicator.Animate := True;
    ProgressBar1.Style := pbstMarquee;
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
