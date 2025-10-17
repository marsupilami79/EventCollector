unit DmTransfer;

{$IFDEF FPC}
{$mode Delphi}{$H+}
{$ENDIF}

interface

uses
  Classes, SysUtils, ZConnection, ZDataset, ZSequence, winevt,
  ZAbstractConnection, Data.DB, ZAbstractRODataset, ZAbstractDataset;

type
  EventException = Class(Exception);

  { TTransferDM }

  TTransferDM = class(TDataModule)
    Conn: TZConnection;
    InsertQ: TZQuery;
    ComputersQ: TZQuery;
    LogsQ: TZQuery;
    LastTimestampsQ: TZQuery;
    SequenceQ: TZReadOnlyQuery;
    LoglevelsQ: TZQuery;
    procedure DataModuleCreate(Sender: TObject);
    procedure LoglevelsQBeforeEdit(DataSet: TDataSet);
    procedure LoglevelsQBeforePost(DataSet: TDataSet);
  private
    MaxTime: TDateTime;
    function GetNextValue: Int64;
  public
    RunIndefinitly: Boolean;
    procedure TransferLog(LogName: String);
    procedure TransferLogData(LogName: UnicodeString; ComputerID, LogID: Int64; LastTimestamp: String);
  end;

  TEvent = record
    Provider: String;
    ProviderGUID: String;
    EventID: Integer;
    Level: Integer;
    LevelName: String;
    TimeCreated: TDateTime;
    MicroSeconds: Single;
    TimeStamp: String;
    EventrecordID: Integer;
    Channel: String;
    Computer: String;
    XML: String;
    Message: String;
    Error: String;
    procedure Reset;
    procedure LoadFromHandle(EvtHandle: EVT_HANDLE);
    procedure FormatEventData(EventHandle: EVT_HANDLE);
  end;

var
  TransferDM: TTransferDM;

implementation

{$R *.dfm}

uses Windows, {$IFDEF FPC}dom, xmlread, {$ELSE} Xml.XMLDoc, Xml.XMLIntf, {$ENDIF}DateUtils, Math, ZXmlCompat, Variants;

// The Windows portion is taken from here:
// https://www.delphipraxis.net/107832-post3.html
// The Unix portion is taken from here:
// https://forum.lazarus.freepascal.org/index.php/topic,30885.msg196955.html#msg196955
function GetComputerName: String;
{$IF DEFINED(WINDOWS) OR DEFINED(MSWINDOWS)}
var
  Size: DWORD;
{$IFEND}
begin
  {$IF DEFINED(WINDOWS) OR DEFINED(MSWINDOWS)}
  Size := MAX_COMPUTERNAME_LENGTH + 1;
  SetLength(Result, Size);
  if Windows.GetComputerName(PChar(Result), Size) then
    SetLength(Result, Size)
  else
    Result := '';
  {$ELSE}
  Result := GetHostName;
  {$IFEND}
end;

function GetEventXml(EventHandle: EVT_HANDLE): UnicodeString;
var
  Buf: UnicodeString;
  BufUsed: DWORD;
  PropCnt: DWORD;
  Status: DWORD;
  Flags: Cardinal;
begin
  Flags := Cardinal(EvtRenderEventXml);
  EvtRender(0, EventHandle, Flags, 0, nil, @BufUsed, @PropCnt);
  Status := GetLastError;
  if Status <>  ERROR_INSUFFICIENT_BUFFER then
    raise EventException.Create('First call to EvtRender failed with error code ' + IntToStr(Status))
  else begin
    SetLength(Buf, BufUsed);
    if not EvtRender(0, EventHandle, Cardinal(EvtRenderEventXml), Length(Buf) * 2, @Buf[1], @BufUsed, @PropCnt) then
      raise EventException.Create('Second call to EvtRender failed with error code ' + IntToStr(Status))
    else begin
      SetLength(Buf, (BufUsed shr 1) -  1);
      Result := Buf;
    end
  end;
end;

function WebSvcDateTimeToDateTime(InStr: String): TDateTime;
var
  D, M, Y, H, N, S, MS: Word;
  ZPos: Integer;
  TempStr: String;
begin
  if (InStr[5]  <> '-') or
     (InStr[8]  <> '-') or
     (InStr[11] <> 'T') or
     (InStr[14] <> ':') or
     (InStr[17] <> ':')
  then raise Exception.Create('''' + InStr + ''' ist kein WebSvcDateTime.');
  Y := StrToInt(Copy(InStr, 1, 4)); //1-4
  M := StrToInt(Copy(InStr, 6, 2)); //6,7
  D := StrToInt(Copy(InStr, 9, 2)); //9,10
  H := StrToInt(Copy(InStr, 12, 2)); //12,13
  N := StrToInt(Copy(InStr, 15, 2)); //15,16
  S := StrToInt(Copy(InStr, 18, 2)); //18,19
  MS := 0;
  ZPos := Pos('Z', InStr);
  if ZPos > 0 then
    Delete(InStr, ZPos, Length(InStr));
  if Length(InStr) >= 21 then begin
    if InStr[20] = '.' then begin
      case Length(InStr) of
        21: InStr := InStr + '00';
        22: InStr := InStr + '0';
      end;
      MS := StrToInt(Copy(InStr, 21, 3));
    end;
  end;
  Result := EncodeDateTime(Y, M, D, H, N, S, MS);
end;

function CleanStr(InStr: String): String;
var
  x: Integer;
begin
  for x := Length(InStr) downto 1 do begin
    if InStr[x] = #0 then
      Delete(InStr, x, 1)
    else
      break;
  end;
  Result := InStr;
end;

procedure TEvent.Reset;
begin
  Provider := '';
  ProviderGUID := '';
  EventID := 0;
  Level := 0;
  TimeCreated := 0;
  MicroSeconds := 0;
  EventrecordID := 0;
  Channel := '';
  Computer := '';
  XML := '';
  Message := '';
  Error := '';
end;

procedure TEvent.LoadFromHandle(EvtHandle: EVT_HANDLE);
var
  LogHandle: EVT_HANDLE;
  //EventHandle: EVT_HANDLE;
  Cnt: DWORD;
  status: DWORD;
  x, y: Integer;
  XmlStr: UTF8String;
  XmlDoc: IXmlDocument;
  XmlStream: TMemoryStream;
  RootNode: IXMLNode;
  SystemNode: IXMLNode;
  Node: IXMLNode;
  ProviderName: UnicodeString;
  TempStr: String;
  DotPos, ZPos: Integer;
  NodeName: String;
const
    {$IFDEF FPC}
    BOM: AnsiString = #$FF#$FE;
    {$ELSE}
    BOM: WideString = #$FEFF;
    {$ENDIF}
begin
  Reset;
  try
    XML := GetEventXml(EvtHandle);

    {$IFDEF FPC}
    XmlDoc := TZXmlDocument.Create as IXmlDocument;
    {$ELSE}
    XmlDoc := TXmlDocument.Create(nil) as IXmlDocument;
    {$ENDIF}

    {$IFNDEF FPC}
    //XmlStr := #$FEFF + '<?xml version="1.0" encoding="UTF-16" standalone="yes"?>' + #13 + XML;
    {$ENDIF}
    try
      XmlStream := TMemoryStream.Create;
      try
        XmlStream.Write(BOM[1], Length(BOM) * SizeOf(CHAR));
        XmlStream.Write(XML[1], Length(XML) * SizeOf(CHAR));
        XmlStream.Position := 0;
        XmlDoc.LoadFromStream(XmlStream);
      finally
        FreeAndNil(XmlStream);
      end;

      RootNode := XmlDoc.ChildNodes.Get(0);
      for x := 0 to RootNode.ChildNodes.Count - 1 do begin
        Node := RootNode.ChildNodes.Get(x);
        if Node.GetNodeName = 'System' then begin
          SystemNode := Node;
          for y := 0 to SystemNode.ChildNodes.Count - 1 do begin
            Node := SystemNode.ChildNodes.Get(y);
            NodeName := Node.GetNodeName;
            if NodeName = 'Provider' then begin
              ProviderName := CleanStr(VarToStr(Node.Attributes['Name']));
              Provider := ProviderName;
            end else if NodeName = 'EventID' then
              EventID := StrToInt(Node.GetText)
            else if NodeName = 'Level' then
              Level := StrToInt(Node.GetText)
            else if NodeName = 'TimeCreated' then begin
              TempStr := VarToStr(Node.Attributes['SystemTime']);
              TimeStamp := TempStr;
              TimeCreated := WebSvcDateTimeToDateTime(TempStr);
              DotPos := Pos('.', TempStr);
              ZPos := Pos('Z', TempStr);
              Delete(TempStr, ZPos, Length(TempStr));
              Delete(TempStr, 1, DotPos);
              Delete(TempStr, 1, 3);
              MicroSeconds := Length(TempStr);
              MicroSeconds := Power(10, MicroSeconds - 3);
              MicroSeconds := StrToFloat(TempStr) / MicroSeconds;
            end else if NodeName = 'EventRecordID' then
              EventrecordID := StrToInt(Node.GetText)
            else if NodeName = 'Channel' then
              Channel := CleanStr(Node.GetText)
            else if NodeName = 'Computer' then
              Computer := CleanStr(Node.GetText);
          end;
        end;
      end;
    finally
      if Assigned(XmlDoc) then
        XmlDoc := nil;
      if Assigned(XmlStream) then
        FreeAndNil(XmlStream);
    end;

    FormatEventData(EvtHandle);
  except
    on E: EventException do
      Error := E.Message;
  end;
end;

procedure TEvent.FormatEventData(EventHandle: EVT_HANDLE);
var
  PublisherHandle: EVT_HANDLE;
  MsgBuf: UnicodeString;
  MsgBufUsed: DWORD;
  Status: DWORD;
begin
  Message := '';
  LevelName := '';
  PublisherHandle := EvtOpenPublisherMetadata(0, PWideChar(Provider), nil, 0, 0);
  if PublisherHandle = 0 then
    raise EventException.Create('Could not get metadata for provider ' + Provider)
  else try
    EvtFormatMessage(PublisherHandle, EventHandle, 0, 0, nil, DWORD(EvtFormatMessageEvent), 0, PWideChar(MsgBuf), @MsgBufUsed);
    Status := GetLastError;
    if Status <>  ERROR_INSUFFICIENT_BUFFER then
      raise EventException.Create('First call to EvtFormatMessage failed with error code ' + IntToStr(Status))
    else begin
      SetLength(MsgBuf, MsgBufUsed);
      if not EvtFormatMessage(PublisherHandle, EventHandle, 0, 0, nil, DWORD(EvtFormatMessageEvent), Length(MsgBuf), PWideChar(MsgBuf), @MsgBufUsed) then begin
        Status := GetLastError;
        raise EventException.Create('Second call to EvtFormatMessage failed with error code ' + IntToStr(Status));
      end else begin
        SetLength(MsgBuf, MsgBufUsed - 1);
        Message := CleanStr(MsgBuf);
      end;
    end;

    EvtFormatMessage(PublisherHandle, EventHandle, 0, 0, nil, DWORD(EvtFormatMessageLevel), 0, PWideChar(MsgBuf), @MsgBufUsed);
    Status := GetLastError;
    if Status <>  ERROR_INSUFFICIENT_BUFFER then
      raise EventException.Create('Third call to EvtFormatMessage failed with error code ' + IntToStr(Status))
    else begin
      SetLength(MsgBuf, MsgBufUsed);
      if not EvtFormatMessage(PublisherHandle, EventHandle, 0, 0, nil, DWORD(EvtFormatMessageLevel), Length(MsgBuf), PWideChar(MsgBuf), @MsgBufUsed) then begin
        Status := GetLastError;
        raise EventException.Create('Fourth call to EvtFormatMessage failed with error code ' + IntToStr(Status));
      end else begin
        SetLength(MsgBuf, MsgBufUsed - 1);
        LevelName := CleanStr(MsgBuf);
      end;
    end;
  finally
    EvtClose(PublisherHandle);
  end;
end;

procedure TTransferDM.DataModuleCreate(Sender: TObject);
begin
  MaxTime := Now;
  MaxTime := IncSecond(MaxTime, 55);
end;

function TTransferDM.GetNextValue: Int64;
begin
  SequenceQ.Close;
  try
    SequenceQ.Open;
    Result := SequenceQ.FieldByName('generic').AsLargeInt;
  finally
    SequenceQ.Close;
  end;
end;

procedure TTransferDM.LoglevelsQBeforeEdit(DataSet: TDataSet);
begin
  raise Exception.Create('May not edit a log level.');
end;

procedure TTransferDM.LoglevelsQBeforePost(DataSet: TDataSet);
begin
  if LoglevelsQ.FieldByName('ID').IsNull then
    LoglevelsQ.FieldByName('ID').AsLargeInt := GetNextValue;
  if LoglevelsQ.FieldByName('COMPUTER').IsNull then
    LoglevelsQ.FieldByName('COMPUTER').AsLargeInt := LoglevelsQ.ParamByName('COMPUTER').AsLargeInt;
  if LoglevelsQ.FieldByName('LOG').IsNull then
    LoglevelsQ.FieldByName('LOG').AsLargeInt := LoglevelsQ.ParamByName('LOG').AsLargeInt;
end;

procedure TTransferDM.TransferLog(LogName: String);
var
  ComputerID: Int64;
  LogID: Int64;
  LastTimestamp: String;
begin
  Conn.Connect;
  if RunIndefinitly or (Now < MaxTime) then try
    ComputersQ.Close;
    ComputersQ.ParamByName('COMPUTERNAME').AsString := GetComputerName;
    ComputersQ.Open;
    try
      if ComputersQ.RecordCount = 0 then begin
        ComputersQ.Append;
        ComputersQ.FieldByName('NAME').AsString := GetComputerName;
        ComputersQ.FieldByName('ID').AsLargeInt := GetNextValue;
        ComputersQ.Post;
      end;
      ComputerID := ComputersQ.FieldByName('ID').AsLargeInt;
    finally
      ComputersQ.Close;
    end;

    LogsQ.Close;
    LogsQ.ParamByName('LOGNAME').AsString := LogName;
    LogsQ.Open;
    try
      if LogsQ.RecordCount = 0 then begin
        LogsQ.Append;
        LogsQ.FieldByName('NAME').AsString := LogName;
        LogsQ.FieldByName('ID').AsLargeInt := GetNextValue;
        LogsQ.Post;
      end;
      LogID := LogsQ.FieldByName('ID').AsLargeInt;
    finally
      LogsQ.Close;
    end;

    LoglevelsQ.Close;
    LoglevelsQ.ParamByName('COMPUTER').AsLargeInt := ComputerID;
    LoglevelsQ.ParamByName('LOG').AsLargeInt := LogID;
    LoglevelsQ.Open;

    LastTimestampsQ.Close;
    LastTimestampsQ.ParamByName('COMPUTER').AsLargeInt := ComputerID;
    LastTimestampsQ.ParamByName('LOG').AsLargeInt := LogID;
    LastTimestampsQ.Open;
    try
      if LastTimestampsQ.RecordCount = 0 then begin
        LastTimestampsQ.Append;
        LastTimestampsQ.FieldByName('COMPUTER').AsLargeInt := ComputerID;
        LastTimestampsQ.FieldByName('LOG').AsLargeInt := LogID;
        LastTimestampsQ.Post;
        LastTimestamp := '';
      end else begin
        LastTimestamp := LastTimestampsQ.FieldByName('LASTTIMESTAMP').AsString;
      end;
    finally
      LogsQ.Close;
    end;

    TransferLogData(LogName, ComputerID, LogID, LastTimestamp);
  finally
    Conn.Disconnect;
  end;
end;

procedure TTransferDM.TransferLogData(LogName: UnicodeString; ComputerID, LogID: Int64; LastTimestamp: String);
var
  XPath: UnicodeString;
  LogHandle: EVT_HANDLE;
  EventHandle: EVT_HANDLE;
  Evt: TEvent;
  status: DWORD;
  Cnt: DWORD;
  KeyValues: Variant;
begin
  KeyValues := VarArrayCreate([0,1], varVariant);
  if LastTimestamp = '' then
    XPath := '*'
  else
    XPath := '*[System ' +
             '   [TimeCreated[@SystemTime>''' + LastTimestamp + ''']]' +
             ']';

  Conn.StartTransaction;
  try
    LogHandle := EvtQuery(0, PWideChar(LogName), PWideChar(XPath), DWORD(EvtQueryChannelPath) {and DWORD(EvtQueryReverseDirection)});
    if LogHandle = 0 then begin
      status := GetLastError();
      case status of
        87: raise EventException.Create('Invalid argument. -> one of the parameters is bad.');
        ERROR_EVT_CHANNEL_NOT_FOUND: raise EventException.Create('The channel was not found.');
        ERROR_EVT_INVALID_QUERY: raise EventException.Create('The query is not valid.');
        else raise EventException.Create('Unbekannter Fehler: ' + IntToStr(status));
      end;
    end else begin
      InsertQ.ParamByName('COMPUTER').AsLargeInt := ComputerID;
      InsertQ.ParamByName('LOG').AsLargeInt := LogID;
      while EvtNext(LogHandle, 1, @EventHandle, 500, 0, @Cnt) do try
        if Cnt = 1 then begin
          Evt.LoadFromHandle(EventHandle);
          //:id, :computer, :log, :provider, :eventid, :level, :timecreated, :microseconds, :eventrecordid, :channel, :computername, :xml, :message, :error
          //InsertQ.ParamByName('ID').AsLargeInt := GetNextValue;
          InsertQ.ParamByName('PROVIDER').AsString := Evt.Provider;
          InsertQ.ParamByName('EVENTID').AsInteger := Evt.EventID;
          InsertQ.ParamByName('LEVEL').AsInteger := Evt.Level;
          InsertQ.ParamByName('TIMECREATED').AsDateTime := Evt.TimeCreated;
          InsertQ.ParamByName('MICROSECONDS').AsSingle := Evt.MicroSeconds;
          InsertQ.ParamByName('EVENTRECORDID').AsInteger := Evt.EventrecordID;
          InsertQ.ParamByName('CHANNEL').AsString := Evt.Channel;
          InsertQ.ParamByName('COMPUTERNAME').AsString := Evt.Computer;
          InsertQ.ParamByName('XML').AsString := Evt.XML;
          if Evt.Message = '' then
            InsertQ.ParamByName('MESSAGE').Clear
          else
            InsertQ.ParamByName('MESSAGE').AsString := Evt.Message;
          if Evt.LevelName = '' then
            InsertQ.ParamByName('LEVELNAME').Clear
          else
            InsertQ.ParamByName('LEVELNAME').AsString := Evt.LevelName;
          if Evt.Error = '' then
            InsertQ.ParamByName('ERROR').Clear
          else
            InsertQ.ParamByName('ERROR').AsString := Evt.Error;
          if Evt.TimeStamp <> '' then
            LastTimestamp := Evt.TimeStamp;
          InsertQ.ExecSQL;

          if Evt.LevelName <> '' then begin
            KeyValues[0] := Evt.Level;
            KeyValues[1] := Evt.LevelName;
            if not LoglevelsQ.Locate('LEVEL;NAME', KeyValues, []) then begin
              LoglevelsQ.Append;
              LoglevelsQ.FieldByName('LEVEL').AsInteger := Evt.Level;
              LoglevelsQ.FieldByName('NAME').AsString := Evt.LevelName;
              LoglevelsQ.Post;
            end;
          end;

          if (not RunIndefinitly) and (Now > MaxTime) then
            Break
        end;


      finally
        EvtClose(EventHandle);
      end;
    end;

    if LastTimestamp <> '' then begin
      LastTimestampsQ.Edit;
      LastTimestampsQ.FieldByName('LASTTIMESTAMP').AsString := LastTimestamp;
      LastTimestampsQ.Post;
    end;

    Conn.Commit;
  except
    Conn.Rollback;
    raise;
  end;
end;

end.

