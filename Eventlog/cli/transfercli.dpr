program transfercli;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Xml.omnixmldom,
  Xml.xmldom,
  IniFiles,
  dmtransfer in '..\shared\dmtransfer.pas' {TransferDM: TDataModule},
  winevt in '..\shared\winevt.pas';

const
  SectionName = 'database';

var
  dm: TTransferDM;
  IniFile: TInifile;
  IniName: String;

begin
  DefaultDOMVendor := sOmniXmlVendor;
  IniName := ExtractFilePath(ParamStr(0)) + 'eventlog.ini';
  try
    { TODO -oUser -cConsole Main : Code hier einfügen }
    dm := TTransferDM.Create(nil);
    try
      if FileExists(IniName) then begin
        IniFile := TIniFile.Create(IniName);
        try
          dm.Conn.HostName := IniFile.ReadString(SectionName, 'HostName', ''); //www.iks.ag
          dm.Conn.Database := IniFile.ReadString(SectionName, 'Database', ''); //'evt_iks';
          dm.Conn.User := IniFile.ReadString(SectionName, 'User', '');  //'evtiks';
          dm.Conn.Password := IniFile.ReadString(SectionName, 'Password', ''); // 'Un6aiRaiGhoopooch7chohceeghee9iuj6of1moTaet0aiWoh7muohooPheix6ee';
          dm.Conn.Protocol := IniFile.ReadString(SectionName, 'Protocol', ''); //  'WebServiceProxy';
          dm.Conn.LibraryLocation := IniFile.ReadString(SectionName, 'Library', '');
          if (dm.Conn.Database = '') or (dm.Conn.User = '') or (dm.Conn.Protocol = '') then
            exit;
          dm.RunIndefinitly := FindCmdLineSwitch('i');

          dm.TransferLog('Application');
          dm.TransferLog('System');
        finally
          FreeAndNil(IniFile);
        end;
      end;
    finally
      FreeAndNil(dm);
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
