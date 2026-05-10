unit DmAudit;

{$MODE Delphi}

interface

uses
  SysUtils, Classes, DB, ZAbstractRODataset,
  ZAbstractDataset, ZDataset, ZAbstractConnection, ZConnection;

type

  { TAuditDM }

  TAuditDM = class(TDataModule)
    MainConn: TZConnection;
    TempQ: TZQuery;
    TempROQ: TZReadOnlyQuery;
  private
    { Private-Deklarationen }
    ComputerID: Int64;
    procedure LoadConfig;
    procedure readRegProducts;
    procedure updateMachineData;
  public
    { Public-Deklarationen }
  end;

var
  AuditDM: TAuditDM;

procedure doSoftwareAudit;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.lfm}

uses Registry, Types, LCLIntf, LCLType, LMessages, IksTools, IniFiles, IksUefi,
  ActiveX, ComObj;

type
  TMachineInfo = record
    Manufacturer: String;
    Model: String;
  end;


procedure doSoftwareAudit;
begin
  CoInitialize(nil);
  AuditDM := TAuditDM.Create(nil);
  try
    AuditDM.LoadConfig;
    AuditDM.updateMachineData;
    AuditDM.readRegProducts;
  finally
    FreeAndNil(AuditDM);
  end;
end;

function WMI_Get_Betriebssystem(const Mit_Version: Boolean = False): String;
const
  wbemFlagForwardOnly = $00000020;
var
  FSWbemLocator: OLEVariant;
  FWMIService: OLEVariant;
  FWbemObjectSet: OLEVariant;
  FWbemObject: OLEVariant;
  iEnum: IEnumvariant;
  iValue: Cardinal;
begin
  Result := '?';
  try
    FSWbemLocator := CreateOleObject('WbemScripting.SWbemLocator');
    FWMIService := FSWbemLocator.ConnectServer('localhost', 'root\CIMV2', '', '');
    FWbemObjectSet := FWMIService.ExecQuery('SELECT Name, Version FROM Win32_OperatingSystem',
                                            'WQL', wbemFlagForwardOnly);
    iEnum := IUnknown(FWbemObjectSet._NewEnum) as IEnumvariant;

    if iEnum.Next(1, @FWbemObject, @iValue) = 0 then
    begin
      Result := String(FWbemObject.Name);
      if Pos('|', Result) > 0 then
        Result := Copy(Result, 1, Pos('|', Result) - 1);

      if Pos('Microsoft ', Result) > 0 then
        Try
          Result := Trim(Copy(Result, Pos('Microsoft ', Result) + 10, 40));
        except
        end;

      if Mit_Version then
        Result := Result + ' [ ' + String(FWbemObject.Version) + ' ]';

      FWbemObject := Unassigned;
    end;
  except
    try
      Result := WMI_Get_Betriebssystem;
    except
      Result := '?';
    end;
  end;
end;

function WMI_Get_MachineInfo(): TMachineInfo;
const
  wbemFlagForwardOnly = $00000020;
var
  FSWbemLocator: OLEVariant;
  FWMIService: OLEVariant;
  FWbemObjectSet: OLEVariant;
  FWbemObject: OLEVariant;
  iEnum: IEnumvariant;
  iValue: Cardinal;
begin
  Result.Manufacturer := '?';
  Result.Model := '?';

  FSWbemLocator := CreateOleObject('WbemScripting.SWbemLocator');
  FWMIService := FSWbemLocator.ConnectServer('localhost', 'root\CIMV2', '', '');
  FWbemObjectSet := FWMIService.ExecQuery('SELECT Manufacturer, Model FROM Win32_ComputerSystem',
                                          'WQL', wbemFlagForwardOnly);
  iEnum := IUnknown(FWbemObjectSet._NewEnum) as IEnumvariant;

  if iEnum.Next(1, @FWbemObject, @iValue) = 0 then begin
    Result.Manufacturer := String(FWbemObject.Manufacturer);
    Result.Model := String(FWbemObject.Model);
    FWbemObject := Unassigned;
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

procedure TAuditDM.updateMachineData;
var
  CompName: String;
  Field: TField;
  MachineInfo: TMachineInfo;
begin
  CompName := GetComputerName;
  TempQ.SQL.Text := 'select * from computers where lower(name) = lower(:computername)';
  TempQ.ParamByName('computername').AsString := CompName;
  TempQ.Open;
  try
    if TempQ.RecordCount = 0 then begin
      CompName := GetComputerName;
      TempROQ.SQL.Text := 'select gen_id(GENERIC, 1) as id from rdb$database';
      TempROQ.Open;
      try
        ComputerID := TempROQ.FieldByName('ID').AsInteger;
      finally
        TempROQ.Close;
      end;

      TempQ.Append;
      TempQ.FieldByName('ID').AsInteger := ComputerID;
      TempQ.FieldByName('NAME').AsString := CompName;
    end else begin
      TempQ.Edit;
    end;

    TempQ.FieldByName('LASTTIMESTAMP').AsDateTime := Now;

    Field := TempQ.FindField('WINVER');
    if Assigned(Field) then
      Field.AsString := WMI_Get_Betriebssystem(true);

    Field := TempQ.FindField('HasWindowsUefiCa2023');
    if Assigned(Field) then
      Field.AsBoolean := HasWindowsUefiCa2023;

    MachineInfo := WMI_Get_MachineInfo;

    Field := TempQ.FindField('MANUFACTURER');
    if Assigned(Field) then
      Field.AsString := MachineInfo.Manufacturer;

    Field := TempQ.FindField('MODEL');
    if Assigned(Field) then
      Field.AsString := MachineInfo.Model;
  finally
    try
      if TempQ.State in [dsEdit, dsInsert] then
        TempQ.Post;
    except
      TempQ.Cancel;
      raise;
    end;
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

end.
