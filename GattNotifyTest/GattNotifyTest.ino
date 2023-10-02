#include <BLE2902.h>
#include <BLEDevice.h>

#define MTU_SIZE                247
#define MIN_INTERVAL            60
#define MAX_INTERVAL            60
#define LATENCY                 3
#define TIMEOUT                 200

#define DEVICE_NAME             "GATT NOTIFY TEST"
#define SERVICE_UUID            "4D97EA15-CFD2-4C76-9AD6-0E49040BC496"
#define CHARACTERISTIC_UUID     "89F2BD95-D019-4057-BEAA-50DE0016442C"

#define BUF_SIZE                2048
#define PAYLOAD_SIZE            (MTU_SIZE - 3)
#define SLEEP_INTERVAL          100
#define CLIENT_INIT_DELAY       5000


BLECharacteristic* Characteristic = NULL;
bool ClientConnected = false;
uint8_t Buf[BUF_SIZE];


class CServerCallback : public BLEServerCallbacks
{
public:
    void onConnect(BLEServer* pServer, esp_ble_gatts_cb_param_t *param) override
    {
        Serial.println("Client connected");

        pServer->updateConnParams(param->connect.remote_bda, MIN_INTERVAL, MAX_INTERVAL,
            LATENCY, TIMEOUT);
        ClientConnected = true;
    }

    void onDisconnect(BLEServer* pServer) override
    {
        Serial.println("Client disconnected");
        
        ClientConnected = false;
        pServer->getAdvertising()->start();
    }
};


void setup()
{
    Serial.begin(115200);
    delay(2000);

    Serial.println("Prepare buffer");
    uint8_t Cnt = 0;
    for (uint16_t i = 0; i < BUF_SIZE; i++)
        Buf[i] = Cnt++;

    Serial.println("Create BLE device");
    BLEDevice::init(DEVICE_NAME);
    Serial.println("Set MTU");
    BLEDevice::setMTU(MTU_SIZE);

    Serial.println("Create GATT server");
    BLEServer* Server = BLEDevice::createServer();
    Server->setCallbacks(new CServerCallback());

    Serial.println("Create primary service");
    BLEService* Service = Server->createService(SERVICE_UUID);
    
    Serial.println("Create characteristic");
    Characteristic = new BLECharacteristic(CHARACTERISTIC_UUID, BLECharacteristic::PROPERTY_NOTIFY);
    Serial.println("Add client configuration descriptor");
    Characteristic->addDescriptor(new BLE2902());

    Serial.println("Add characteristic");
    Service->addCharacteristic(Characteristic);

    Serial.println("Start service");
    Service->start();

    Serial.println("Add service advertising UUID");
    BLEAdvertising* Advertising = BLEDevice::getAdvertising();
    Advertising->addServiceUUID(SERVICE_UUID);
    
    Serial.println("Start advertising");
    Server->getAdvertising()->start();
}


void loop()
{
    // What for client connection
    if (!ClientConnected)
        return;

    Serial.println("Client connected. Wait client initialization");
    delay(CLIENT_INIT_DELAY);
    Serial.println("Assume client initialized.");
    if (!ClientConnected)
    {
        Serial.println("Client disconnected.");
        return;
    }
    Serial.println("Client still connected. Start sending.");
    
    do
    {
        for (uint8_t i = 0; i < ceil((float)BUF_SIZE / (float)PAYLOAD_SIZE) && ClientConnected; i++)
        {
            size_t Size = PAYLOAD_SIZE;
            if (i * PAYLOAD_SIZE + PAYLOAD_SIZE > BUF_SIZE)
                Size = BUF_SIZE - i * PAYLOAD_SIZE;
            Characteristic->setValue(&Buf[i * PAYLOAD_SIZE], Size);

            if (ClientConnected)
                Characteristic->notify();
        }

        if (ClientConnected)
            delay(SLEEP_INTERVAL);
    } while (ClientConnected);

    Serial.println("Client disconnected. Sending stopped");
}
