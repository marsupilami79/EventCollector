object Form1: TForm1
  Left = 0
  Top = 0
  BorderIcons = []
  BorderStyle = bsSingle
  Caption = 'Softwareaudit'
  ClientHeight = 63
  ClientWidth = 232
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object Label1: TLabel
    Left = 56
    Top = 16
    Width = 128
    Height = 15
    Caption = 'Inventarisiere Software...'
    OnDblClick = Label1DblClick
  end
  object ActivityIndicator: TActivityIndicator
    Left = 8
    Top = 8
  end
  object AuditTimer: TTimer
    Enabled = False
    OnTimer = AuditTimerTimer
    Left = 184
    Top = 8
  end
end
