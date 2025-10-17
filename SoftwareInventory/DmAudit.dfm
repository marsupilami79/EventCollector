object AuditDM: TAuditDM
  Height = 480
  Width = 640
  object MainConn: TZConnection
    ControlsCodePage = cCP_UTF16
    Catalog = ''
    DisableSavepoints = False
    HostName = ''
    Port = 0
    Database = ''
    User = ''
    Password = ''
    Protocol = ''
    Left = 32
    Top = 16
  end
  object TempQ: TZQuery
    Connection = MainConn
    Params = <>
    Left = 112
    Top = 16
  end
end
