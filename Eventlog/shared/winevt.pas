unit winevt;

{$IFDEF FPC}
{$mode ObjFPC}{$H+}
{$ENDIF}
//{$Packrecords c} ??
interface

uses
  windows;
Const
  LibName = 'Wevtapi.dll';



  EVT_VARIANT_TYPE_MASK         = $7f;
  EVT_VARIANT_TYPE_ARRAY        = 128;
  EVT_READ_ACCESS               = $1;
  EVT_WRITE_ACCESS              = $2;
  EVT_CLEAR_ACCESS              = $4;
  EVT_ALL_ACCESS                = $7;

  ERROR_EVT_INVALID_CHANNEL_PATH                           = 15000;
  ERROR_EVT_INVALID_QUERY                                  = 15001;
  ERROR_EVT_PUBLISHER_METADATA_NOT_FOUND                   = 15002;
  ERROR_EVT_EVENT_TEMPLATE_NOT_FOUND                       = 15003;
  ERROR_EVT_INVALID_PUBLISHER_NAME                         = 15004;
  ERROR_EVT_INVALID_EVENT_DATA                             = 15005;
  ERROR_EVT_CHANNEL_NOT_FOUND                              = 15007;
  ERROR_EVT_MALFORMED_XML_TEXT                             = 15008;
  ERROR_EVT_SUBSCRIPTION_TO_DIRECT_CHANNEL                 = 15009;
  ERROR_EVT_CONFIGURATION_ERROR                            = 15010;
  ERROR_EVT_QUERY_RESULT_STALE                             = 15011;
  ERROR_EVT_QUERY_RESULT_INVALID_POSITION                  = 15012;
  ERROR_EVT_NON_VALIDATING_MSXML                           = 15013;
  ERROR_EVT_FILTER_ALREADYSCOPED                           = 15014;
  ERROR_EVT_FILTER_NOTELTSET                               = 15015;
  ERROR_EVT_FILTER_INVARG                                  = 15016;
  ERROR_EVT_FILTER_INVTEST                                 = 15017;
  ERROR_EVT_FILTER_INVTYPE                                 = 15018;
  ERROR_EVT_FILTER_PARSEERR                                = 15019;
  ERROR_EVT_FILTER_UNSUPPORTEDOP                           = 15020;
  ERROR_EVT_FILTER_UNEXPECTEDTOKEN                         = 15021;
  ERROR_EVT_INVALID_OPERATION_OVER_ENABLED_DIRECT_CHANNEL  = 15022;
  ERROR_EVT_INVALID_CHANNEL_PROPERTY_VALUE                 = 15023;
  ERROR_EVT_INVALID_PUBLISHER_PROPERTY_VALUE               = 15024;
  ERROR_EVT_CHANNEL_CANNOT_ACTIVATE                        = 15025;
  ERROR_EVT_FILTER_TOO_COMPLEX                             = 15026;
  ERROR_EVT_MESSAGE_NOT_FOUND                              = 15027;
  ERROR_EVT_MESSAGE_ID_NOT_FOUND                           = 15028;
  ERROR_EVT_UNRESOLVED_VALUE_INSERT                        = 15029;
  ERROR_EVT_UNRESOLVED_PARAMETER_INSERT                    = 15030;
  ERROR_EVT_MAX_INSERTS_REACHED                            = 15031;
  ERROR_EVT_EVENT_DEFINITION_NOT_FOUND                     = 15032;
  ERROR_EVT_MESSAGE_LOCALE_NOT_FOUND                       = 15033;
  ERROR_EVT_VERSION_TOO_OLD                                = 15034;
  ERROR_EVT_VERSION_TOO_NEW                                = 15035;
  ERROR_EVT_CANNOT_OPEN_CHANNEL_OF_QUERY                   = 15036;
  ERROR_EVT_PUBLISHER_DISABLED                             = 15037;
  ERROR_EVT_FILTER_OUT_OF_RANGE                            = 15038;

Type
  {$IFNDEF FPC}
  HANDLE = THandle;
  PInt8 = ^Shortint;
  PInt16 = ^Smallint;
  PInt32 = ^Longint;
  PUint8 = ^Byte;
  PUint16 = ^Word;
  {$ENDIF}
  TEVT_CHANNEL_CLOCK_TYPE = (
    EvtChannelClockTypeSystemTime = 0,
    EvtChannelClockTypeQPC);
  TEVT_CHANNEL_CONFIG_PROPERTY_ID = (
    EvtChannelConfigEnabled = 0,
    EvtChannelConfigIsolation,
    EvtChannelConfigType,
    EvtChannelConfigOwningPublisher,
    EvtChannelConfigClassicEventlog,
    EvtChannelConfigAccess,
    EvtChannelLoggingConfigRetention,
    EvtChannelLoggingConfigAutoBackup,
    EvtChannelLoggingConfigMaxSize,
    EvtChannelLoggingConfigLogFilePath,
    EvtChannelPublishingConfigLevel,
    EvtChannelPublishingConfigKeywords,
    EvtChannelPublishingConfigControlGuid,
    EvtChannelPublishingConfigBufferSize,
    EvtChannelPublishingConfigMinBuffers,
    EvtChannelPublishingConfigMaxBuffers,
    EvtChannelPublishingConfigLatency,
    EvtChannelPublishingConfigClockType,
    EvtChannelPublishingConfigSidType,
    EvtChannelPublisherList,
    EvtChannelPublishingConfigFileMax,
    EvtChannelConfigPropertyIdEND);
  TEVT_CHANNEL_ISOLATION_TYPE = (
    EvtChannelIsolationTypeApplication = 0,
    EvtChannelIsolationTypeSystem,
    EvtChannelIsolationTypeCustom);
  TEVT_CHANNEL_REFERENCE_FLAGS = (
    EvtChannelReferenceImported = $1);
  TEVT_CHANNEL_SID_TYPE = (
    EvtChannelSidTypeNone = 0,
    EvtChannelSidTypePublishing);
  TEVT_CHANNEL_TYPE = (
    EvtChannelTypeAdmin = 0,
    EvtChannelTypeOperational,
    EvtChannelTypeAnalytic,
    EvtChannelTypeDebug);
  TEVT_EVENT_METADATA_PROPERTY_ID = (
    EventMetadataEventID,
    EventMetadataEventVersion,
    EventMetadataEventChannel,
    EventMetadataEventLevel,
    EventMetadataEventOpcode,
    EventMetadataEventTask,
    EventMetadataEventKeyword,
    EventMetadataEventMessageID,
    EventMetadataEventTemplate,
    EvtEventMetadataPropertyIdEND);
  TEVT_EVENT_PROPERTY_ID = (
    EvtEventQueryIDs = 0,
    EvtEventPath,
    EvtEventPropertyIdEND);
  TEVT_EXPORTLOG_FLAGS = (
    EvtExportLogChannelPath = $1,
    EvtExportLogFilePath = $2,
    EvtExportLogTolerateQueryErrors = $1000,
    EvtExportLogOverwrite = $2000);
  TEVT_FORMAT_MESSAGE_FLAGS = (
    EvtFormatMessageEvent = 1,
    EvtFormatMessageLevel,
    EvtFormatMessageTask,
    EvtFormatMessageOpcode,
    EvtFormatMessageKeyword,
    EvtFormatMessageChannel,
    EvtFormatMessageProvider,
    EvtFormatMessageId,
    EvtFormatMessageXml);
  TEVT_LOG_PROPERTY_ID = (
    EvtLogCreationTime = 0,
    EvtLogLastAccessTime,
    EvtLogLastWriteTime,
    EvtLogFileSize,
    EvtLogAttributes,
    EvtLogNumberOfLogRecords,
    EvtLogOldestRecordNumber,
    EvtLogFull);
  TEVT_LOGIN_CLASS = (
    EvtRpcLogin = 1);
  TEVT_OPEN_LOG_FLAGS = (
    EvtOpenChannelPath = $1,
    EvtOpenFilePath = $2);
  TEVT_PUBLISHER_METADATA_PROPERTY_ID = (
    EvtPublisherMetadataPublisherGuid = 0,
    EvtPublisherMetadataResourceFilePath,
    EvtPublisherMetadataParameterFilePath,
    EvtPublisherMetadataMessageFilePath,
    EvtPublisherMetadataHelpLink,
    EvtPublisherMetadataPublisherMessageID,
    EvtPublisherMetadataChannelReferences,
    EvtPublisherMetadataChannelReferencePath,
    EvtPublisherMetadataChannelReferenceIndex,
    EvtPublisherMetadataChannelReferenceID,
    EvtPublisherMetadataChannelReferenceFlags,
    EvtPublisherMetadataChannelReferenceMessageID,
    EvtPublisherMetadataLevels,
    EvtPublisherMetadataLevelName,
    EvtPublisherMetadataLevelValue,
    EvtPublisherMetadataLevelMessageID,
    EvtPublisherMetadataTasks,
    EvtPublisherMetadataTaskName,
    EvtPublisherMetadataTaskEventGuid,
    EvtPublisherMetadataTaskValue,
    EvtPublisherMetadataTaskMessageID,
    EvtPublisherMetadataOpcodes,
    EvtPublisherMetadataOpcodeName,
    EvtPublisherMetadataOpcodeValue,
    EvtPublisherMetadataOpcodeMessageID,
    EvtPublisherMetadataKeywords,
    EvtPublisherMetadataKeywordName,
    EvtPublisherMetadataKeywordValue,
    EvtPublisherMetadataKeywordMessageID,
    EvtPublisherMetadataPropertyIdEND);
  TEVT_QUERY_FLAGS = (
    EvtQueryChannelPath = $1,
    EvtQueryFilePath = $2,
    EvtQueryForwardDirection = $100,
    EvtQueryReverseDirection = $200,
    EvtQueryTolerateQueryErrors = $1000);
  TEVT_QUERY_PROPERTY_ID = (
    EvtQueryNames,
    EvtQueryStatuses,
    EvtQueryPropertyIdEND);
  TEVT_RENDER_CONTEXT_FLAGS = (
    EvtRenderContextValues = 0,
    EvtRenderContextSystem,
    EvtRenderContextUser);
  TEVT_RENDER_FLAGS = (
    EvtRenderEventValues = 0,
    EvtRenderEventXml,
    EvtRenderBookmark);
  TEVT_RPC_LOGIN_FLAGS = (
    EvtRpcLoginAuthDefault = 0,
    EvtRpcLoginAuthNegotiate,
    EvtRpcLoginAuthKerberos,
    EvtRpcLoginAuthNTLM);
  TEVT_SEEK_FLAGS = (
    EvtSeekRelativeToFirst = 1,
    EvtSeekRelativeToLast = 2,
    EvtSeekRelativeToCurrent = 3,
    EvtSeekRelativeToBookmark = 4,
    EvtSeekOriginMask = 7,
    EvtSeekStrict = $10000);
  TEVT_SUBSCRIBE_FLAGS = (
    EvtSubscribeToFutureEvents = 1,
    EvtSubscribeStartAtOldestRecord = 2,
    EvtSubscribeStartAfterBookmark = 3,
    EvtSubscribeOriginMask = 3,
    EvtSubscribeTolerateQueryErrors = $1000,
    EvtSubscribeStrict = $10000);
  TEVT_SUBSCRIBE_NOTIFY_ACTION = (
    EvtSubscribeActionError = 0,
    EvtSubscribeActionDeliver);
  TEVT_SYSTEM_PROPERTY_ID = (
    EvtSystemProviderName = 0,
    EvtSystemProviderGuid,
    EvtSystemEventID,
    EvtSystemQualifiers,
    EvtSystemLevel,
    EvtSystemTask,
    EvtSystemOpcode,
    EvtSystemKeywords,
    EvtSystemTimeCreated,
    EvtSystemEventRecordId,
    EvtSystemActivityID,
    EvtSystemRelatedActivityID,
    EvtSystemProcessID,
    EvtSystemThreadID,
    EvtSystemChannel,
    EvtSystemComputer,
    EvtSystemUserID,
    EvtSystemVersion,
    EvtSystemPropertyIdEND);
  TEVT_VARIANT_TYPE = (
    EvtVarTypeNull = 0,
    EvtVarTypeString = 1,
    EvtVarTypeAnsiString = 2,
    EvtVarTypeSByte = 3,
    EvtVarTypeByte = 4,
    EvtVarTypeInt16 = 5,
    EvtVarTypeUInt16 = 6,
    EvtVarTypeInt32 = 7,
    EvtVarTypeUInt32 = 8,
    EvtVarTypeInt64 = 9,
    EvtVarTypeUInt64 = 10,
    EvtVarTypeSingle = 11,
    EvtVarTypeDouble = 12,
    EvtVarTypeBoolean = 13,
    EvtVarTypeBinary = 14,
    EvtVarTypeGuid = 15,
    EvtVarTypeSizeT = 16,
    EvtVarTypeFileTime = 17,
    EvtVarTypeSysTime = 18,
    EvtVarTypeSid = 19,
    EvtVarTypeHexInt32 = 20,
    EvtVarTypeHexInt64 = 21,
    EvtVarTypeEvtHandle = 32,
    EvtVarTypeEvtXml = 35);

  TEVT_RPC_LOGIN = Record
    Server       : LPWSTR;
    User         : LPWSTR;
    Domain       : LPWSTR;
    Password     : LPWSTR;
    Flags        : DWORD;
  end;

  EVT_HANDLE  = Handle;
  PEVT_HANDLE = ^EVT_HANDLE;
  EVT_OBJECT_ARRAY_PROPERTY_HANDLE = Handle;
  PLPCWSTR = ^LPCWSTR;
  PLPWSTR = ^LPWSTR;
  PLPSTR = ^LPSTR;
  PPSID = ^PSID;
  PSize_t = ^Size_t;


  TDummy = Record
    Case Integer Of
      0  : (BooleanVal:bool);
      1  : (SByteVal:Int8);
      2  : (Int16Val:Int16);
      3  : (Int32Val:Int32);
      4  : (Int64Val:Int64);
      5  : (ByteVal:UInt8);
      6  : (UInt16Val:UInt16);
      7  : (UInt32Val:UInt32);
      8  : (UInt64Val:UInt64);
      9  : (SingleVal:Single);
      10 : (DoubleVal:Double);
      11 : (FileTimeVal:UlongLong);
      12 : (SysTimeVal:PSystemTime);
      13 : (GuidVal:PGUID);
      14 : (StringVal: LPCWSTR);
      15 : (AnsiStringVal:LPCSTR);
      16 : (BinaryVal:PByte);
      17 : (SidVal:PSID);
      18 : (SizeTVal:size_t);
      19 : (BooleanArr:PBool);
      20 : (SByteArr:PInt8);
      21 : (Int16Arr:PInt16);
      22 : (Int32Arr:PInt32);
      23 : (Int64Arr:PInt64);
      24 : (ByteArr:PUInt8);
      25 : (UInt16Arr:PUInt16);
      26 : (UInt32Arr:PUInt32);
      27 : (UInt64Arr:PUInt64);
      28 : (SingleArr:PSingle);
      29 : (DoubleArr:PDouble);
      30 : (FileTimeArr:PFileTime);
      31 : (SysTimeArr:PSystemTime);
      32 : (GuidArr:PGUID);
      //Not sure about these here
      33 : (StringArr:PLPWSTR);
      34 : (AnsiStringArr:PLPSTR);
      35 : (SidArr:PPSID);
      36 : (SizeTArr:PSize_t);
      37 : (EvtHandleVal:EVT_HANDLE);
      38 : (XmlVal:LPCWSTR);
      39 : (XmlValArr:PLPCWSTR);
  end;

  PEVT_VARIANT = ^TEVT_VARIANT;
  TEVT_VARIANT = Record
    Dummy      : TDummy;
    Count      : DWORD;
    Type_      : DWORD;
  end;

  TEvtSubscribeCallback    = Function(Action:TEVT_SUBSCRIBE_NOTIFY_ACTION ;
                                      UserContext: PVoid;
                                      Event: EVT_HANDLE ):DWORD;

//Rework for dynamic loading
Function EvtArchiveExportedLog(Session:EVT_HANDLE;
                               LogFilePath:LPCWSTR;
                               Locale:LCID;
                               Flags:DWORD):Bool;stdcall;external libname;
Function EvtCancel(Object_:EVT_HANDLE):Bool;stdcall;external libname;
Function EvtClearLog(Session:EVT_HANDLE;
                     ChannelPath:LPCWSTR;
                     TargetFilePath:LPCWSTR;
                     Flags:DWord):Bool;stdcall;external libname;
Function EvtClose(Object_:EVT_HANDLE):Bool;stdcall;external libname;
Function EvtCreateBookmark(BookmarkXml:LPCWSTR):Bool;stdcall;external libname;
Function EvtCreateRenderContext(ValuePathsCount:DWord;
                                ValuePaths:PLPCWSTR;
                                Flags:Dword):EVT_HANDLE;stdcall;external libname;
Function EvtExportLog(Session:EVT_HANDLE;
                      Path:LPCWSTR;
                      Query:LPCWSTR;
                      TargetFilePath:LPCWSTR;
                      Flags:Dword):Bool;stdcall;external libname;
Function EvtFormatMessage(PublisherMetadata:EVT_HANDLE;
                          Event:EVT_HANDLE;
                          MessageId:Dword;
                          ValueCount:DWord;
                          Values:PEVT_VARIANT;
                          Flags:Dword;
                          BufferSize:DWord;
                          Buffer:LPWSTR;
                          BufferUsed:PDWord):Bool;stdcall;external libname;
Function EvtGetChannelConfigProperty(ChannelConfig:EVT_HANDLE;
                                     PropertyId:TEVT_CHANNEL_CONFIG_PROPERTY_ID;
                                     Flags:Dword;
                                     PropertyValueBufferSize:Dword;
                                     PropertyValueBuffer:PEVT_VARIANT;
                                     PropertyValueBufferUsed:PDword):Bool;stdcall;external libname;
Function EvtGetEventInfo(Event:EVT_HANDLE;
                         PropertyId:TEVT_EVENT_PROPERTY_ID;
                         PropertyValueBufferSize:DWord;
                         PropertyValueBuffer:PEVT_VARIANT;
                         PropertyValueBufferUsed:PDword):Bool;stdcall;external libname;
Function EvtGetEventMetadataProperty(EventMetadata:EVT_HANDLE;
                                     PropertyId:TEVT_EVENT_METADATA_PROPERTY_ID;
                                     Flags:DWord;
                                     EventMetadataPropertyBufferSize:DWord;
                                     EventMetadataPropertyBuffer:PEVT_VARIANT;
                                     EventMetadataPropertyBufferUsed:PDword):Bool;stdcall;external libname;
Function EvtGetExtendedStatus(BufferSize:Dword;
                              Buffer:LPWSTR;
                              BufferUsed:PDword):Bool;stdcall;external libname;
Function EvtGetLogInfo(Log:EVT_HANDLE;
                       PropertyId:TEVT_LOG_PROPERTY_ID;
                       PropertyValueBufferSize:DWord;
                       PropertyValueBuffer:PEVT_VARIANT;
                       PropertyValueBufferUsed:PDword):Bool;stdcall;external libname;
Function EvtGetObjectArrayProperty(ObjectArray:EVT_OBJECT_ARRAY_PROPERTY_HANDLE;
                                   PropertyId:DWord;
                                   ArrayIndex:DWord;
                                   Flags:DWord;
                                   PropertyValueBufferSize:DWord;
                                   PropertyValueBuffer:PEVT_VARIANT;
                                   PropertyValueBufferUsed:PDword):Bool;stdcall;external libname;
Function EvtGetObjectArraySize(ObjectArray:EVT_OBJECT_ARRAY_PROPERTY_HANDLE;
                               ObjectArraySize:PDword):Bool;stdcall;external libname;
Function EvtGetPublisherMetadataProperty(PublisherMetadata:EVT_HANDLE;
                                         PropertyId:TEVT_PUBLISHER_METADATA_PROPERTY_ID;
                                         Flags:DWord;
                                         PublisherMetadataPropertyBufferSize:Dword;
                                         PublisherMetadataPropertyBuffer:PEVT_VARIANT;
                                         PublisherMetadataPropertyBufferUsed:PDword):Bool;stdcall;external libname;
Function EvtGetQueryInfo(QueryOrSubscription:EVT_HANDLE;
                         PropertyId:TEVT_QUERY_PROPERTY_ID;
                         PropertyValueBufferSize:DWord;
                         PropertyValueBuffer:PEVT_VARIANT;
                         PropertyValueBufferUsed:PDword):Bool;stdcall;external libname;
Function EvtNext(ResultSet:EVT_HANDLE;
                 EventsSize:DWord;
                 Events:PEVT_HANDLE;
                 Timeout:DWord;
                 Flags:DWord;
                 Returned:PDword):Bool;stdcall;external libname;
Function EvtNextChannelPath(ChannelEnum:EVT_HANDLE;
                            ChannelPathBufferSize:DWord;
                            ChannelPathBuffer:LPWSTR;
                            ChannelPathBufferUsed:PDword):Bool;stdcall;external libname;
Function EvtNextEventMetadata(EventMetadataEnum:EVT_HANDLE;
                              Flags:DWord):EVT_HANDLE;stdcall;external libname;
Function EvtNextPublisherId(PublisherEnum:EVT_HANDLE;
                            PublisherIdBufferSize:DWord;
                            PublisherIdBuffer:LPWSTR;
                            PublisherIdBufferUsed:PDWord):Bool;stdcall;external libname;
Function EvtOpenChannelConfig(Session:EVT_HANDLE;
                              ChannelPath:LPCWSTR;
                              Flags:DWord):EVT_HANDLE;stdcall;external libname;
Function EvtOpenChannelEnum(Session:EVT_HANDLE;
                            Flags:DWord):EVT_HANDLE;stdcall;external libname;
Function EvtOpenEventMetadataEnum(PublisherMetadata:EVT_HANDLE;
                                  Flags:DWord):EVT_HANDLE;stdcall;external libname;
Function EvtOpenLog(Session:EVT_HANDLE;
                    Path:LPCWSTR;
                    Flags:DWord):EVT_HANDLE;stdcall;external libname;
Function EvtOpenPublisherEnum(Session:EVT_HANDLE;
                              Flags:DWord):EVT_HANDLE;stdcall;external libname;
Function EvtOpenPublisherMetadata(Session:EVT_HANDLE;
                                  PublisherId:LPCWSTR;
                                  LogFilePath:LPCWSTR;
                                  Locale:LCID;
                                  Flags:DWord):EVT_HANDLE;stdcall;external libname;
Function EvtOpenSession(LoginClass:TEVT_LOGIN_CLASS;
                        Login:PVoid;
                        Timeout:DWord;
                        Flags:DWord):EVT_HANDLE;stdcall;external libname;
Function EvtQuery(Session:EVT_HANDLE;
                  Path:LPCWSTR;
                  Query:LPCWSTR;
                  Flags:DWord):EVT_HANDLE;stdcall;external libname;
Function EvtRender(Context:EVT_HANDLE;
                   Fragment:EVT_HANDLE;
                   Flags:DWord;
                   BufferSize:DWord;
                   Buffer:PVoid;
                   BufferUsed:PDword;
                   PropertyCount:PDword):Bool;stdcall;external libname;
Function EvtSaveChannelConfig(ChannelConfig:EVT_HANDLE;
                              Flags:DWord):Bool;stdcall;external libname;
Function EvtSeek(ResultSet:EVT_HANDLE;
                 Position:LongLong;
                 Bookmark:EVT_HANDLE;
                 Timeout:DWord;
                 Flags:DWord):Bool;stdcall;external libname;
Function EvtSetChannelConfigProperty(ChannelConfig:EVT_HANDLE;
                                     PropertyId:TEVT_CHANNEL_CONFIG_PROPERTY_ID;
                                     Flags:DWord;
                                     PropertyValue:PEVT_VARIANT):Bool;stdcall;external libname;
Function EvtSubscribe(Session:EVT_HANDLE;
                      SignalEvent:Handle;
                      ChannelPath:LPCWSTR;
                      Query:LPCWSTR;
                      Bookmark:EVT_HANDLE;
                      Context:PVoid;
                      Callback:TEvtSubscribeCallback;
                      Flags:DWord):EVT_HANDLE;stdcall;external libname;
Function EvtUpdateBookmark(Bookmark:EVT_HANDLE;
                           Event:EVT_HANDLE):Bool;stdcall;external libname;

implementation

end.

