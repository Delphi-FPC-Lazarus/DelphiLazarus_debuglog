object frmMain: TfrmMain
  Left = 0
  Top = 0
  ClientHeight = 299
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object btnClose: TButton
    Left = 16
    Top = 8
    Width = 75
    Height = 25
    Caption = 'btnClose'
    TabOrder = 0
    OnClick = btnCloseClick
  end
  object btnCrash: TButton
    Left = 97
    Top = 8
    Width = 75
    Height = 25
    Caption = 'btnCrash'
    TabOrder = 1
    OnClick = btnCrashClick
  end
  object btnTerminate: TButton
    Left = 178
    Top = 8
    Width = 75
    Height = 25
    Caption = 'btnTerminate'
    TabOrder = 2
    OnClick = btnTerminateClick
  end
  object Timer1: TTimer
    Enabled = False
    OnTimer = Timer1Timer
    Left = 48
    Top = 16
  end
end
