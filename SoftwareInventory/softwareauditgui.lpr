program softwareauditgui;

{$MODE Delphi}

uses
  Forms, Interfaces, opensslsockets,
  FormMain in 'FormMain.pas' {Form1},
  DmAudit in 'DmAudit.pas' {AuditDM: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TAuditDM, AuditDM);
  Application.Run;
end.
