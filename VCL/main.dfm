object fmMain: TfmMain
  Left = 409
  Top = 191
  BorderStyle = bsSingle
  Caption = 'Long notification sequence test'
  ClientHeight = 555
  ClientWidth = 743
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object laPackatesCaption: TLabel
    Left = 8
    Top = 48
    Width = 42
    Height = 13
    Caption = 'Packets:'
  end
  object laPackets: TLabel
    Left = 64
    Top = 48
    Width = 6
    Height = 13
    Caption = '0'
  end
  object laErrorsCaption: TLabel
    Left = 176
    Top = 48
    Width = 30
    Height = 13
    Caption = 'Errors:'
  end
  object laErrors: TLabel
    Left = 208
    Top = 48
    Width = 6
    Height = 13
    Caption = '0'
  end
  object btConnect: TButton
    Left = 8
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Connect'
    TabOrder = 0
    OnClick = btConnectClick
  end
  object btDisconnect: TButton
    Left = 88
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Disconnect'
    Enabled = False
    TabOrder = 1
    OnClick = btDisconnectClick
  end
  object ListBox: TListBox
    Left = 8
    Top = 72
    Width = 729
    Height = 473
    ItemHeight = 13
    TabOrder = 2
  end
  object btClear: TButton
    Left = 664
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Clear'
    TabOrder = 3
    OnClick = btClearClick
  end
  object wclBluetoothManager: TwclBluetoothManager
    AfterOpen = wclBluetoothManagerAfterOpen
    OnClosed = wclBluetoothManagerClosed
    Left = 168
    Top = 112
  end
  object wclGattClient: TwclGattClient
    OnCharacteristicChanged = wclGattClientCharacteristicChanged
    OnConnect = wclGattClientConnect
    OnConnectionParamsChanged = wclGattClientConnectionParamsChanged
    OnDisconnect = wclGattClientDisconnect
    OnMaxPduSizeChanged = wclGattClientMaxPduSizeChanged
    Left = 168
    Top = 192
  end
  object wclBluetoothLeBeaconWatcher: TwclBluetoothLeBeaconWatcher
    OnAdvertisementUuidFrame = wclBluetoothLeBeaconWatcherAdvertisementUuidFrame
    OnStarted = wclBluetoothLeBeaconWatcherStarted
    OnStopped = wclBluetoothLeBeaconWatcherStopped
    Left = 304
    Top = 96
  end
end
