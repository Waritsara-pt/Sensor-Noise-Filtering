
#include <Wire.h>
#include "MAX30105.h"

MAX30105 particleSensor;

unsigned long startTime;
unsigned long lastSample = 0;

const unsigned long sampleInterval = 10; // เป้าหมาย 100 Hz

void setup() {
  Serial.begin(115200);
  Wire.begin(21, 22); // SDA, SCL ของ ESP32

  if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) {
    Serial.println("ERROR: MAX30102 not found!");
    while (1) {
      delay(10);
    }
  }

  // ตั้งค่าการอ่าน IR และ Red
  // LED power, averaging, LED mode, sample rate,
  // pulse width, ADC range
  particleSensor.setup(0x1F, 4, 2, 100, 411, 4096);

  particleSensor.setPulseAmplitudeRed(0x1F);
  particleSensor.setPulseAmplitudeIR(0x1F);
  particleSensor.setPulseAmplitudeGreen(0);

  delay(1000);

  Serial.println("Time_ms,IR_Raw,Red_Raw");

  startTime = millis();
}

void loop() {
  // อ่านข้อมูลจาก FIFO ของเซนเซอร์
  particleSensor.check();

  while (particleSensor.available()) {
    unsigned long now = millis();

    // จำกัดการส่งข้อมูลออก Serial ตามช่วงเวลาที่กำหนด
    if (now - lastSample >= sampleInterval) {
      lastSample = now;

      unsigned long elapsed = now - startTime;

      uint32_t irValue = particleSensor.getIR();
      uint32_t redValue = particleSensor.getRed();

      Serial.print(elapsed);
      Serial.print(",");
      Serial.print(irValue);
      Serial.print(",");
      Serial.println(redValue);
    }

    particleSensor.nextSample();
  }
}
