#include <BLE2902.h>
#include <BLEDevice.h>

#define DEVICE_NAME             "GATT NOTIFY TEST"
#define MTU_SIZE                247
#define SERVICE_UUID            "4D97EA15-CFD2-4C76-9AD6-0E49040BC496"
#define CHARACTERISTIC_UUID     "89F2BD95-D019-4057-BEAA-50DE0016442C"
#define BUF_SIZE                2048
#define PAYLOAD_SIZE            (MTU_SIZE - 3)


BLECharacteristic* Characteristic = NULL;
bool ClientConnected = false;


class CServerCallback : public BLEServerCallbacks
{
public:
    void onConnect(BLEServer* pServer) override
    {
        Serial.println("Client connected");
        ClientConnected = true;
    }

    void onDisconnect(BLEServer* pServer) override
    {
        Serial.println("Client disconnected");
        Serial.println("Restart advertising");
        ClientConnected = false;

        pServer->getAdvertising()->start();
    }
};


void setup()
{
    Serial.begin(115200);
    delay(2000);

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
    static uint32_t Count = 1;

    Serial.println("Send notification");
    
    uint8_t Buf[PAYLOAD_SIZE] = { 0 };
    Buf[0] = (uint8_t)Count;
    Buf[1] = (uint8_t)(Count >> 8);
    Buf[2] = (uint8_t)(Count >> 16);
    Buf[3] = (uint8_t)(Count >> 24);
    Buf[4] = ceil((float)BUF_SIZE / (float)PAYLOAD_SIZE);

    for (uint8_t i = 0; i < Buf[4]; i++)
    {
        Buf[5] = i;
        Characteristic->setValue(Buf, PAYLOAD_SIZE);
        Characteristic->notify();
    }

    Count++;
    delay(500);
}
