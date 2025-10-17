program softwareauditgui;

uses
  Vcl.Forms,
  FormMain in 'FormMain.pas' {Form1},
  DmAudit in 'DmAudit.pas' {AuditDM: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TAuditDM, AuditDM);
  Application.Run;
end.
