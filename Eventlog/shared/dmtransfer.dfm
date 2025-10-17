object TransferDM: TTransferDM
  OnCreate = DataModuleCreate
  Height = 448
  Width = 644
  object Conn: TZConnection
    ControlsCodePage = cCP_UTF16
    ClientCodepage = 'UTF8'
    Catalog = ''
    Properties.Strings = (
      'RawStringEncoding=DB_CP'
      'codepage=UTF8')
    DesignConnection = True
    HostName = 'localhost'
    Port = 0
    Database = 'C:\Projekte\iks\events\EVENTS.FDB'
    User = 'sysdba'
    Password = 'kawd6hesq'
    Protocol = 'firebird'
    LibraryLocation = 
      'C:\Projekte\TopSales\additional\firebird-embedded-5.0.1\fbclient' +
      '.dll'
    Left = 32
    Top = 24
  end
  object InsertQ: TZQuery
    Connection = Conn
    SQL.Strings = (
      
        'insert into events (id, computer, log, provider, eventid, level,' +
        ' levelname, timecreated, microseconds, eventrecordid, channel, c' +
        'omputername, xml, message, error)'
      
        'values (gen_id(generic, 1), :computer, :log, :provider, :eventid' +
        ', :level, :levelname, :timecreated, :microseconds, :eventrecordi' +
        'd, :channel, :computername, :xml, :message, :error)')
    Params = <
      item
        Name = 'computer'
      end
      item
        Name = 'log'
      end
      item
        Name = 'provider'
      end
      item
        Name = 'eventid'
      end
      item
        Name = 'level'
      end
      item
        Name = 'levelname'
      end
      item
        Name = 'timecreated'
      end
      item
        Name = 'microseconds'
      end
      item
        Name = 'eventrecordid'
      end
      item
        Name = 'channel'
      end
      item
        Name = 'computername'
      end
      item
        Name = 'xml'
      end
      item
        Name = 'message'
      end
      item
        Name = 'error'
      end>
    Left = 32
    Top = 96
    ParamData = <
      item
        Name = 'computer'
      end
      item
        Name = 'log'
      end
      item
        Name = 'provider'
      end
      item
        Name = 'eventid'
      end
      item
        Name = 'level'
      end
      item
        Name = 'levelname'
      end
      item
        Name = 'timecreated'
      end
      item
        Name = 'microseconds'
      end
      item
        Name = 'eventrecordid'
      end
      item
        Name = 'channel'
      end
      item
        Name = 'computername'
      end
      item
        Name = 'xml'
      end
      item
        Name = 'message'
      end
      item
        Name = 'error'
      end>
  end
  object ComputersQ: TZQuery
    Connection = Conn
    SequenceField = 'ID'
    SQL.Strings = (
      'select * from computers where name = :computername')
    Params = <
      item
        Name = 'computername'
      end>
    Left = 104
    Top = 96
    ParamData = <
      item
        Name = 'computername'
      end>
  end
  object LogsQ: TZQuery
    Connection = Conn
    SequenceField = 'ID'
    SQL.Strings = (
      'select * from lognames where name = :logname')
    Params = <
      item
        Name = 'logname'
      end>
    Left = 176
    Top = 96
    ParamData = <
      item
        Name = 'logname'
      end>
  end
  object LastTimestampsQ: TZQuery
    Connection = Conn
    SQL.Strings = (
      
        'select * from lasttimestamps where computer = :computer and log ' +
        '= :log')
    Params = <
      item
        Name = 'computer'
      end
      item
        Name = 'log'
      end>
    Left = 104
    Top = 176
    ParamData = <
      item
        Name = 'computer'
      end
      item
        Name = 'log'
      end>
  end
  object SequenceQ: TZReadOnlyQuery
    Connection = Conn
    SQL.Strings = (
      'select gen_id(generic, 1) as generic from rdb$database')
    Params = <>
    Left = 102
    Top = 26
  end
  object LoglevelsQ: TZQuery
    Connection = Conn
    BeforeEdit = LoglevelsQBeforeEdit
    BeforePost = LoglevelsQBeforePost
    SQL.Strings = (
      
        'select * from loglevels where computer = :computer and log = :lo' +
        'g')
    Params = <
      item
        Name = 'computer'
      end
      item
        Name = 'log'
      end>
    Left = 224
    Top = 96
    ParamData = <
      item
        Name = 'computer'
      end
      item
        Name = 'log'
      end>
  end
end
