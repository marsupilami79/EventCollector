unit DmAudit;

interface

uses
  System.SysUtils, System.Classes, Data.DB, ZAbstractRODataset,
  ZAbstractDataset, ZDataset, ZAbstractConnection, ZConnection;

type
  TAuditDM = class(TDataModule)
    MainConn: TZConnection;
    TempQ: TZQuery;
  private
    { Private-Deklarationen }
    ComputerID: Int64;
    procedure LoadConfig;
    procedure readRegProducts;
    procedure getComputerId;
  public
    { Public-Deklarationen }
  end;

var
  AuditDM: TAuditDM;

procedure doSoftwareAudit;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

uses Registry, Types, Windows, IksTools, IniFiles,   Xml.omnixmldom, Xml.xmldom;

procedure doSoftwareAudit;
begin
  AuditDM := TAuditDM.Create(nil);
  try
    AuditDM.LoadConfig;
    AuditDM.getComputerId;
    AuditDM.readRegProducts;
  finally
    FreeAndNil(AuditDM);
  end;
end;

procedure TAuditDM.readRegProducts;
const
  BaseKeys: Array[0..1] of String = ('\Software\Microsoft\Windows\CurrentVersion\Uninstall\',
                                     '\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\');
var
  Registry: TRegistry;
  ProductIDs: TStringDynArray;
  KeyNames: TStringList;
  KeyName: String;
  x: Integer;

  function ReadValue(ValueName: String): String;
  begin
    if Registry.ValueExists(ValueName) then Result := Registry.ReadString(ValueName) else Result := '';
  end;
begin
  TempQ.SQL.Text := 'delete from regproducts where computer = :computer';
  TempQ.ParamByName('COMPUTER').AsLargeInt := ComputerId;
  TempQ.ExecSQL;

  TempQ.SQL.Text := 'insert into regproducts (id, computer, name, publisher, versionstring, productid) values (gen_id(GENERIC, 1), :computer, :name, :publisher, :versionstring, :productid)';
  TempQ.ParamByName('COMPUTER').AsLargeInt := ComputerId;

  try
    KeyNames := TStringList.Create;
    Registry := TRegistry.Create(KEY_READ or KEY_WOW64_64KEY);
    Registry.RootKey := HKEY_LOCAL_MACHINE;
    for x := 0 to 1 do begin
      if not Registry.OpenKeyReadOnly(BaseKeys[x]) then
        Continue;

      Registry.GetKeyNames(KeyNames);

      while KeyNames.Count > 0 do begin
        KeyName := BaseKeys[x] + KeyNames.Strings[0] + '\';
        if not Registry.OpenKeyReadOnly(KeyName) then begin
          KeyNames.Delete(0);
          Continue;
        end;

        TempQ.ParamByName('NAME').AsString := ReadValue('DisplayName');
        TempQ.ParamByName('PUBLISHER').AsString := ReadValue('Publisher');
        TempQ.ParamByName('VERSIONSTRING').AsString := ReadValue('DisplayVersion');
        TempQ.ParamByName('PRODUCTID').AsString := KeyNames.Strings[0];
        TempQ.ExecSQL;
        KeyNames.Delete(0);
      end;
    end;
  finally
    if Assigned(Registry) then FreeAndNil(Registry);
    if Assigned(KeyNames) then FreeAndNil(KeyNames);
  end;
end;

procedure TAuditDM.getComputerId;
var
  CompName: String;
begin
  CompName := GetComputerName;
  TempQ.SQL.Text := 'select ID from computers where lower(name) = lower(:computername)';
  TempQ.ParamByName('computername').AsString := CompName;
  TempQ.Open;
  if TempQ.RecordCount > 0 then
    ComputerId := TempQ.FieldByName('ID').AsLargeInt
  else begin
    TempQ.Close;
    TempQ.SQL.Text := 'select gen_id(GENERIC, 1) as id from rdb$database';
    TempQ.Open;
    ComputerId := TempQ.FieldByName('ID').AsLargeInt;
    TempQ.Close;
    TempQ.SQL.Text := 'insert into computers (id, name) values (:id, :name)';
    TempQ.ParamByName('ID').AsLargeInt := ComputerId;
    TempQ.ParamByName('NAME').AsString := CompName;
    TempQ.ExecSQL;
  end;
end;

procedure TAuditDM.LoadConfig;
var
  IniName: String;
  Ini: TIniFile;
begin
  IniName := ExtractFilePath(ParamStr(0)) + 'eventlog.ini';
  if not FileExists(IniName) then
    raise Exception.Create('Kann Konfiguration nicht laden');

  Ini := TIniFile.Create(IniName);
  try
    MainConn.HostName := Ini.ReadString('database', 'HostName', 'www.iks.ag');
    MainConn.Database := Ini.ReadString('database', 'Database', '');
    MainConn.User := Ini.ReadString('database', 'User', '');
    MainConn.Password := Ini.ReadString('database', 'Password', '');
    MainConn.Protocol := Ini.ReadString('database', 'Protocol', 'WebServiceProxy');
  finally
    FreeAndNil(Ini);
  end;
end;

initialization
  DefaultDOMVendor := sOmniXmlVendor;

end.
