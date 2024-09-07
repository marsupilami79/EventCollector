unit DmMain;

{$mode Delphi}

interface

uses
  Classes, SysUtils, ZConnection, ZDataset;

type

  { TEvaluatorDM }

  TEvaluatorDM = class(TDataModule)
    MainConn: TZConnection;
    ComputersQ: TZReadOnlyQuery;
    LogMessagesQ: TZReadOnlyQuery;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    FMinTimestamp: TDateTime;
    FSmtpServer: String;
    FMailFrom: String;

    FDocument: TStringlist;
    FIsCritical: Boolean;
    FMsgSubject: String;
    FClientName: String;
    FRcptToList: String;
    procedure EvaluateSingleClient;
    procedure EvaluateTimestamps;
    procedure EvaluateSingleComputer(ComputerName: String; ComputerID: Int64);
  public
    Kunde: String;
    procedure Evaluate;
  end;

var
  EvaluatorDM: TEvaluatorDM;

implementation

{$R *.lfm}

uses iksTools, DateUtils, mimemess, mimepart, smtpsend, IniFiles;

procedure TEvaluatorDM.Evaluate;
var
  ConfigFile: String;
  Ini: TIniFile;
  Sections: TStringList;
  Section: String;
begin
  FMinTimestamp := Now;
  FMinTimestamp := StartOfTheDay(FMinTimestamp);
  FMinTimestamp := IncDay(FMinTimestamp, -1);
  {$IFDEF WINDOWS}
  ConfigFile := ExtractFilePath(ParamStr(0)) + 'mailgenerator.ini';
  {$ELSE}
  ConfigFile := '/etc/eventlog/mailgenerator.ini';
  {$ENDIF}

  if not FileExists(ConfigFile) then
    raise Exception.Create(Format('The config file %s does not exist.', [ConfigFile]));

  try
    Ini := TIniFile.Create(ConfigFile);
    FSmtpServer := Ini.ReadString('general', 'smtp server', '');
    FMailFrom := Ini.ReadString('general', 'mail from', '');
    MainConn.HostName := Ini.ReadString('general', 'database server', '');
    MainConn.User := Ini.ReadString('general', 'database user name', '');
    MainConn.Password := Ini.ReadString('general', 'database password', '');
    MainConn.Protocol := Ini.ReadString('general', 'database protocol', 'firebird');
    MainConn.LibraryLocation := Ini.ReadString('general', 'database client library', '');

    if FSmtpServer = '' then
      raise Exception.Create('Config Error: SMTP Server must not be empty.');
    if FMailFrom = '' then
      raise Exception.Create('Config Error: Mail From must not be empty.');

    Sections := TStringList.Create;
    Ini.ReadSections(Sections);

    while Sections.Count > 0 do begin
      Section := Sections[0];
      Sections.Delete(0);
      if LowerCase(section) <> 'general' then begin
        FClientName := Ini.ReadString(Section, 'Client Name', '');
        FRcptToList := Ini.ReadString(Section, 'RcptTo List', '');
        MainConn.Database := Ini.ReadString(Section, 'Database', '');;
        if FClientName = '' then begin
          WriteLn(Format('Config Error in Section %s. Client Name must not be empty.', [Section]));
          Continue;
        end;
        if FRcptToList = '' then begin
          WriteLn(Format('Config Error in Section %s. RcptTo List must not be empty.', [Section]));
          Continue;
        end;

        EvaluateSingleClient;
      end;
    end;
  finally
    if Assigned(Ini) then
      FreeAndNil(Ini);
    if Assigned(Sections) then
      FreeAndNil(Sections);
  end;
end;

procedure TEvaluatorDM.DataModuleCreate(Sender: TObject);
begin
  FDocument := TStringList.Create;
end;

procedure TEvaluatorDM.DataModuleDestroy(Sender: TObject);
begin
  if Assigned(FDocument) then
    FreeAndNil(FDocument);
end;

procedure TEvaluatorDM.EvaluateSingleClient;
var
  MimeMsg: TMimeMess;
begin
  FIsCritical := false;
  FDocument.Clear;
  FDocument.Add('<html><body>');
  FDocument.Add('<style>');
  FDocument.Add('table, th, td { border: thin solid; border-collapse: collapse;}');
  FDocument.Add('</style>');
  MainConn.Connect;
  try
    EvaluateTimestamps;
  finally
    MainConn.Disconnect;
  end;
  FDocument.Add('</body></html>');
  FDocument.SaveToFile('C:\Users\jan.iks\desktop\test.html', TEncoding.UTF8);

  if FIsCritical then
    FMsgSubject := 'Critical event report for ' + FClientName
  else
    FMsgSubject := 'Regular event report for ' + FClientName;

  MimeMsg := TMimeMess.Create;
  try
    MimeMsg.AddPartHTML(FDocument, nil);
    MimeMsg.Header.Date := Now;
    MimeMsg.Header.From := FMailFrom;
    MimeMsg.Header.ToList.Delimiter := ',';
    MimeMsg.Header.ToList.Text := FRcptToList;
    MimeMsg.Header.Subject := FMsgSubject;
    MimeMsg.EncodeMessage;
    SendToRaw(FMailFrom, FRcptToList, FSmtpServer, MimeMsg.Lines, '', '');
  finally
    FreeAndNil(MimeMsg);
  end;
end;

procedure TEvaluatorDM.EvaluateTimestamps;
var
  TimestampStr: String;
  Timestamp: TDateTime;
  InsertLine: Integer;
  ComputerCount: Integer;
  CellStyle: String;
begin
  ComputerCount := 0;

  FDocument.Add('<h1>Computers that did not register new events since yesterday</h1>');
  InsertLine := FDocument.Count;
  FDocument.Add('<table>');
  FDocument.Add('<tr><th>Computer</th><th>Letzte Meldung</th></tr>');
  ComputersQ.Open;
  while not ComputersQ.EOF do begin
    TimestampStr := ComputersQ.FieldByName('LASTTIMESTAMP').AsString;
    Timestamp := WebSvcDateTimeToDateTime(TimestampStr);
    if Timestamp <= FMinTimestamp then begin
      Inc(ComputerCount);
      CellStyle := ' style="color: darkred;"';
    end else begin
      CellStyle := '';
    end;
    FDocument.Add(Format('<tr><td>%s</td><td%s>%s</td></tr>', [ComputersQ.FieldByName('NAME').AsString, CellStyle, FormatDateTime('dd.mm.yyyy hh:nn:ss.zzz', Timestamp)]));
    ComputersQ.Next;
  end;
  FDocument.Add('</table>');
  if ComputerCount > 0 then begin
    FDocument.Insert(InsertLine, Format('There were %d computer(s) that did not report new events since yesterday.', [ComputerCount]));
    FIsCritical := True;
  end else begin
    FDocument.Insert(InsertLine, 'All computers reported new events.');
  end;

  ComputersQ.First;
  while not ComputersQ.EOF do begin
    EvaluateSingleComputer(ComputersQ.FieldByName('NAME').AsString, ComputersQ.FieldByName('ID').AsLargeInt);
    ComputersQ.Next;
  end;
end;

procedure TEvaluatorDM.EvaluateSingleComputer(ComputerName: String; ComputerID: Int64);
var
  Line: String;
begin
  FDocument.Add('<h1>Events for ' + ComputerName + '</h1>');
  LogMessagesQ.Close;
  LogMessagesQ.ParamByName('computer').AsInt64 := ComputerID;
  LogMessagesQ.ParamByName('mintime').AsDateTime := FMinTimestamp;
  LogMessagesQ.Open;
  if LogMessagesQ.RecordCount = 0 then
    FDocument.Add('<p>No events were recorded</p>')
  else begin
    FIsCritical := true;
    FDocument.Add('<table>');
    FDocument.Add('<tr><th>Provider</th><th>Event-ID</th><th>Level</th><th>count</th><th>time(s)</th><th>Message</th></tr>');
    while not LogMessagesQ.EOF do begin
      Line := '<tr><td>';
      Line := Line + LogMessagesQ.FieldByName('Provider').AsString;
      Line := Line + '</td><td>';
      Line := Line + LogMessagesQ.FieldByName('EventID').AsString;
      Line := Line + '</td><td>';
      Line := Line + LogMessagesQ.FieldByName('LevelName').AsString;
      Line := Line + '</td><td>';
      Line := Line + LogMessagesQ.FieldByName('Count').AsString;
      Line := Line + '</td><td>';
      if LogMessagesQ.FieldByName('MINTIME').AsDateTime = LogMessagesQ.FieldByName('MAXTIME').AsDateTime then
        Line := Line + LogMessagesQ.FieldByName('MINTIME').AsString
      else
        Line := Line + LogMessagesQ.FieldByName('MINTIME').AsString + '- <br/>' + LogMessagesQ.FieldByName('MAXTIME').AsString;
      Line := Line + '</td><td>';
      Line := Line + LogMessagesQ.FieldByName('Message').AsString;
      Line := Line + '</td></tr>';
      FDocument.Add(Line);
      LogMessagesQ.Next;
    end;
    FDocument.Add('</table>');
  end;
end;

end.

