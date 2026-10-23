#include <Wire.h>
#include "Adafruit_TCS34725.h"

// กำหนดค่าเซนเซอร์สี
Adafruit_TCS34725 tcs = Adafruit_TCS34725(
  TCS34725_INTEGRATIONTIME_50MS,
  TCS34725_GAIN_4X
);

void setup() {
  Serial.begin(115200);

  // เริ่มต้น I2C สำหรับ ESP32
  Wire.begin(21, 22);

  // ตรวจสอบเซนเซอร์
  if (tcs.begin()) {
    Serial.println("TCS34725 detected!");
  } else {
    Serial.println("ERROR: TCS34725 not found");
    while (1) delay(10);
  }

  // ส่งหัวตาราง CSV
  Serial.println("Time_ms,Red,Green,Blue,Clear");
}

void loop() {
  uint16_t r, g, b, c;

  // อ่านค่าสีจากเซนเซอร์
  tcs.getRawData(&r, &g, &b, &c);

  // ส่งข้อมูลในรูปแบบ CSV
  Serial.print(millis());
  Serial.print(",");
  Serial.print(r);
  Serial.print(",");
  Serial.print(g);
  Serial.print(",");
  Serial.print(b);
  Serial.print(",");
  Serial.println(c);

  delay(100);
}
