unit main;

interface

uses
  Forms, wclBluetooth, Classes, Controls, StdCtrls;

type
  TfmMain = class(TForm)
    wclBluetoothManager: TwclBluetoothManager;
    wclGattClient: TwclGattClient;
    wclBluetoothLeBeaconWatcher: TwclBluetoothLeBeaconWatcher;
    btConnect: TButton;
    btDisconnect: TButton;
    ListBox: TListBox;
    btClear: TButton;
    procedure btClearClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btConnectClick(Sender: TObject);
    procedure wclBluetoothManagerAfterOpen(Sender: TObject);
    procedure wclBluetoothManagerClosed(Sender: TObject);
    procedure btDisconnectClick(Sender: TObject);
    procedure wclBluetoothLeBeaconWatcherStarted(Sender: TObject);
    procedure wclBluetoothLeBeaconWatcherStopped(Sender: TObject);
    procedure wclBluetoothLeBeaconWatcherAdvertisementUuidFrame(Sender: TObject;
      const Address: Int64; const Timestamp: Int64; const Rssi: Shortint;
      const Uuid: TGUID);
    procedure wclGattClientDisconnect(Sender: TObject;
      const Reason: Integer);
    procedure wclGattClientMaxPduSizeChanged(Sender: TObject);
    procedure wclGattClientConnect(Sender: TObject; const Error: Integer);
    procedure wclGattClientCharacteristicChanged(Sender: TObject;
      const Handle: Word; const Value: TwclGattCharacteristicValue);
  end;

var
  fmMain: TfmMain;

implementation

uses
  wclErrors, Dialogs, SysUtils;

const
  SERVICE_UUID: TGUID = '{4D97EA15-CFD2-4C76-9AD6-0E49040BC496}';
  CHARACTERISTIC_UUID: TGUID = '{89F2BD95-D019-4057-BEAA-50DE0016442C}';

{$R *.dfm}

procedure TfmMain.btClearClick(Sender: TObject);
begin
  ListBox.Items.Clear;
end;

procedure TfmMain.FormDestroy(Sender: TObject);
begin
  wclBluetoothManager.Close;
end;

procedure TfmMain.btConnectClick(Sender: TObject);
var
  Res: Integer;
  Radio: TwclBluetoothRadio;
begin
  Res := wclBluetoothManager.Open;
  if Res <> WCL_E_SUCCESS then
    ShowMessage('Open Bluetooth Manager failed: 0x' + IntToHex(Res, 8))

  else begin
    Res := wclBluetoothManager.GetLeRadio(Radio);
    if Res <> WCL_E_SUCCESS then
      ShowMessage('Get LE radio failed: 0x' + IntToHex(Res, 8))

    else begin
      Res := wclBluetoothLeBeaconWatcher.Start(Radio);
      if Res <> WCL_E_SUCCESS then
        ShowMessage('Start Beacon Watcher failed: 0x' + IntToHex(Res, 8))

      else begin
        btDisconnect.Enabled := True;
        btConnect.Enabled := False;
      end;
    end;

    if Res <> WCL_E_SUCCESS then
      wclBluetoothManager.Close;
  end;
end;

procedure TfmMain.wclBluetoothManagerAfterOpen(Sender: TObject);
begin
  ListBox.Items.Add('Bluetooth Manager opened');
end;

procedure TfmMain.wclBluetoothManagerClosed(Sender: TObject);
begin
  ListBox.Items.Add('Bluetooth Manager closed');

  btDisconnect.Enabled := False;
  btConnect.Enabled := True;
end;

procedure TfmMain.btDisconnectClick(Sender: TObject);
begin
  wclBluetoothManager.Close;
end;

procedure TfmMain.wclBluetoothLeBeaconWatcherStarted(Sender: TObject);
begin
  ListBox.Items.Add('Beacon watcher started');
end;

procedure TfmMain.wclBluetoothLeBeaconWatcherStopped(Sender: TObject);
begin
  ListBox.Items.Add('Beacon watcher stopped');
end;

procedure TfmMain.wclBluetoothLeBeaconWatcherAdvertisementUuidFrame(
  Sender: TObject; const Address: Int64; const Timestamp: Int64;
  const Rssi: Shortint; const Uuid: TGUID);
var
  Radio: TwclBluetoothRadio;
  Res: Integer;
begin
  if CompareMem(@SERVICE_UUID, @Uuid, SizeOf(TGUID)) then begin
    ListBox.Items.Add('Device found: ' + IntToHex(Address, 12));

    Radio := wclBluetoothLeBeaconWatcher.Radio;
    wclBluetoothLeBeaconWatcher.Stop;

    wclGattClient.Address := Address;
    Res := wclGattClient.Connect(Radio);
    if Res <> WCL_E_SUCCESS then begin
      ListBox.Items.Add('Connect start failed: 0x' + IntToHex(Res, 8));
      ListBox.Items.Add('Restart beacon watcher');

      Res := wclBluetoothLeBeaconWatcher.Start(Radio);
      if Res <> WCL_E_SUCCESS then begin
        ListBox.Items.Add('Start Beacon Watcher failed: 0x' + IntToHex(Res, 8));
        wclBluetoothManager.Close;
      end;

    end else
      ListBox.Items.Add('Connect started');
  end;
end;

procedure TfmMain.wclGattClientDisconnect(Sender: TObject;
  const Reason: Integer);
begin
  ListBox.Items.Add('Client disconnect: 0x' + IntToHex(Reason, 8));
  wclBluetoothManager.Close;
end;

procedure TfmMain.wclGattClientMaxPduSizeChanged(Sender: TObject);
var
  Res: Integer;
  Size: Word;
begin
  Res := wclGattClient.GetMaxPduSize(Size);
  if Res = WCL_E_SUCCESS then
    ListBox.Items.Add('Max PDU size changed: ' + IntToStr(Size))
  else
    ListBox.Items.Add('Max PDU size changed');
end;

procedure TfmMain.wclGattClientConnect(Sender: TObject;
  const Error: Integer);
var
  Res: Integer;
  Uuid: TwclGattUuid;
  Service: TwclGattService;
  Characteristic: TwclGattCharacteristic;
  Size: Word;
begin
  if Error <> WCL_E_SUCCESS then begin
    ListBox.Items.Add('Connect faied: 0x' + IntToHex(Error, 8));
    ListBox.Items.Add('Restart Beacon Watcher');

    Res := wclBluetoothLeBeaconWatcher.Start(wclGattClient.Radio);
    if Res <> WCL_E_SUCCESS then begin
      ListBox.Items.Add('Start Beacon Watcher failed: 0x' + IntToHex(Res, 8));
      wclBluetoothManager.Close;
    end;

  end else begin
    ListBox.Items.Add('Connected');

    Uuid.IsShortUuid := False;

    ListBox.Items.Add('Find service');
    Uuid.LongUuid := SERVICE_UUID;
    Res := wclGattClient.FindService(Uuid, Service);
    if Res <> WCL_E_SUCCESS then
      ListBox.Items.Add('Find service failed: 0x' + IntToHex(Res, 8))

    else begin
      ListBox.Items.Add('Find characteristic');
      Uuid.LongUuid := CHARACTERISTIC_UUID;
      Res := wclGattClient.FindCharacteristic(Service, Uuid, Characteristic);
      if Res <> WCL_E_SUCCESS then
        ListBox.Items.Add('Find characteristic failed: 0x' + IntToHex(Res, 8))

      else begin
        ListBox.Items.Add('Subscribe');
        Res := wclGattClient.SubscribeForNotifications(Characteristic);
        if Res <> WCL_E_SUCCESS then
          ListBox.Items.Add('Subscribe failed: 0x' + IntToHex(Res, 8))

        else begin
          Res := wclGattClient.GetMaxPduSize(Size);
          if Res = WCL_E_SUCCESS then
            ListBox.Items.Add('Max PDU size: ' + IntToStr(Size));
        end;
      end;
    end;

    if Res <> WCL_E_SUCCESS then begin
      ListBox.Items.Add('Unable to connect to device. Disconnect');
      wclGattClient.Disconnect;
    end;
  end;
end;

procedure TfmMain.wclGattClientCharacteristicChanged(Sender: TObject;
  const Handle: Word; const Value: TwclGattCharacteristicValue);
var
  Number: Cardinal;
begin
  if Length(Value) > 0 then begin
    Number := Value[0] + (Value[1] shr 8) + (Value[2] shr 16) +
      (Value[3] shr 24);
    ListBox.Items.Add('Received ' + IntToStr(Number) + ': ' +
      IntToStr(Value[5]) + ' from ' + IntToStr(Value[4]) + '; length = ' +
      IntToStr(Length(Value)));
    ListBox.TopIndex := ListBox.Items.Count - 1;
  end;
end;

end.
