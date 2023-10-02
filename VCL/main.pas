unit main;

interface

uses
  Forms, wclBluetooth, Classes, Controls, StdCtrls;

const
  BUF_SIZE = 2048;

type
  TfmMain = class(TForm)
    wclBluetoothManager: TwclBluetoothManager;
    wclGattClient: TwclGattClient;
    wclBluetoothLeBeaconWatcher: TwclBluetoothLeBeaconWatcher;
    btConnect: TButton;
    btDisconnect: TButton;
    ListBox: TListBox;
    btClear: TButton;
    laPackatesCaption: TLabel;
    laPackets: TLabel;
    laErrorsCaption: TLabel;
    laErrors: TLabel;
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
    procedure FormCreate(Sender: TObject);
    procedure wclGattClientConnectionParamsChanged(Sender: TObject);

  private
    FMtuSize: Word;
    FBuf: array [0..BUF_SIZE - 1] of Byte;
    FIndex: Integer;
    FCounter: Cardinal;
    FErrors: Integer;

    procedure UpdateMtuSize;
    procedure UpdateConnectionParams;
  end;

var
  fmMain: TfmMain;

implementation

uses
  wclErrors, Dialogs, SysUtils, Windows;

const
  SERVICE_UUID: TGUID = '{4D97EA15-CFD2-4C76-9AD6-0E49040BC496}';
  CHARACTERISTIC_UUID: TGUID = '{89F2BD95-D019-4057-BEAA-50DE0016442C}';

var
  Buf: array [0..BUF_SIZE - 1] of Byte;

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
  laPackets.Caption := '0';
  laErrors.Caption := '0';

  ListBox.Items.Add('Client disconnect: 0x' + IntToHex(Reason, 8));
  wclBluetoothManager.Close;
end;

procedure TfmMain.wclGattClientMaxPduSizeChanged(Sender: TObject);
begin
  UpdateMtuSize;
end;

procedure TfmMain.wclGattClientConnect(Sender: TObject;
  const Error: Integer);
var
  Res: Integer;
  Uuid: TwclGattUuid;
  Service: TwclGattService;
  Characteristic: TwclGattCharacteristic;
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
          FIndex := 0;
          FCounter := 0;
          FErrors := 0;

          UpdateMtuSize;
          UpdateConnectionParams;
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
begin
  if Length(Value) > 0 then begin
    CopyMemory(@FBuf[FIndex], Pointer(Value), Length(Value));
    FIndex := FIndex + Length(Value);

    if FIndex >= BUF_SIZE then begin
      if not CompareMem(@FBuf[0], @Buf[0], BUF_SIZE) then
        Inc(FErrors);

      Inc(FCounter);
      FIndex := 0;

      laPackets.Caption := IntToStr(FCounter);
      laErrors.Caption := IntToStr(FErrors);
    end;
  end;
end;

procedure TfmMain.FormCreate(Sender: TObject);
var
  i: Integer;
  Cnt: Byte;
begin
  Cnt := 0;
  for i := 0 to BUF_SIZE - 1 do begin
    Buf[i] := Cnt;
    Inc(Cnt);
  end;
end;

procedure TfmMain.wclGattClientConnectionParamsChanged(Sender: TObject);
begin
  UpdateConnectionParams;
end;

procedure TfmMain.UpdateMtuSize;
begin
  if wclGattClient.GetMaxPduSize(FMtuSize) = WCL_E_SUCCESS then
    ListBox.Items.Add('Max PDU size: ' + IntToStr(FMtuSize));
end;

procedure TfmMain.UpdateConnectionParams;
var
  Params: TwclBluetoothLeConnectionParameters;
begin
  if wclGattClient.GetConnectionParams(Params) = WCL_E_SUCCESS then begin
    ListBox.Items.Add('Connection params:');
    ListBox.Items.Add('  Interval: ' + IntToStr(Params.Interval));
    ListBox.Items.Add('  Latency: ' + IntToStr(Params.Latency));
    ListBox.Items.Add('  Timeout: ' + IntToStr(Params.LinkTimeout));
  end;
end;

end.
