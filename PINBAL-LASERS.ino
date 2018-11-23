#include "Adafruit_VL53L0X.h"
 
// address we will assign if dual sensor is present
#define LOX1_ADDRESS 0x30
#define LOX2_ADDRESS 0x31
 
// set the pins to shutdown
#define SHT_LOX1 A0
#define SHT_LOX2 A1
 
Adafruit_VL53L0X lox1 = Adafruit_VL53L0X();
Adafruit_VL53L0X lox2 = Adafruit_VL53L0X();
 
VL53L0X_RangingMeasurementData_t measure1;
VL53L0X_RangingMeasurementData_t measure2;

const int buttonRed = 2;
const int buttonGreen = 4;
const int buttonYellow = 7;
 
void setID() {
  // all reset
  digitalWrite(SHT_LOX1, LOW);
  digitalWrite(SHT_LOX2, LOW);
  delay(10);
  // all unreset
  digitalWrite(SHT_LOX1, HIGH);
  digitalWrite(SHT_LOX2, HIGH);
  delay(10);
 
  // activating LOX1 and reseting LOX2
  digitalWrite(SHT_LOX1, HIGH);
  digitalWrite(SHT_LOX2, LOW);
 
  // initing LOX1
  if (!lox1.begin(LOX1_ADDRESS)) {
    while (1);
  }
  delay(10);
 
  // activating LOX2
  digitalWrite(SHT_LOX2, HIGH);
  delay(10);
 
  //initing LOX2
  if (!lox2.begin(LOX2_ADDRESS)) {
    while (1);
  }
}
 
void readDualSensors() {
 
  lox1.rangingTest(&measure1, false); // pass in 'true' to get debug data printout!
  lox2.rangingTest(&measure2, false); // pass in 'true' to get debug data printout!
 
  // print sensor one reading
  Serial.print("LEFT");
  if (measure1.RangeStatus != 4) {    // if not out of range
    Serial.println(measure1.RangeMilliMeter);
  }
 
  // print sensor two reading
  Serial.print("RIGHT");
  if (measure2.RangeStatus != 4) {
    Serial.println(measure2.RangeMilliMeter);
  }
}
 
void setup() {
  Serial.begin(115200);
 
  // wait until serial port opens for native USB devices
  while (! Serial) {
    delay(1);
  }
 
  pinMode(SHT_LOX1, OUTPUT);
  pinMode(SHT_LOX2, OUTPUT);
  pinMode(buttonRed, INPUT);
  pinMode(buttonGreen, INPUT);
 
  Serial.println("Shutdown pins inited...");
 
  digitalWrite(SHT_LOX1, LOW);
  digitalWrite(SHT_LOX2, LOW);
  setID();
 
}

void handleButtons() {
  if (digitalRead(buttonRed)) {
    Serial.print("RESET");
  } else if (digitalRead(buttonGreen)) {
    Serial.print("START");
  } else if (digitalRead(buttonYellow)) {
    Serial.print("PAUSE");
  } 
}
 
void loop() {
  handleButtons();
  readDualSensors();

  int val = int(analogRead(A7));
  Serial.print("SPEED");
  Serial.println(map(val, 0, 1023, 1, 8));

}
