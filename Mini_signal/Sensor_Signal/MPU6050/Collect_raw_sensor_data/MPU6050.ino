
#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>

Adafruit_MPU6050 mpu;

unsigned long startTime;
unsigned long lastSample = 0;

const unsigned long sampleInterval = 10; // 10 ms = 100 Hz

void setup() {
  Serial.begin(115200);
  Wire.begin(21,22);

  if (!mpu.begin()) {
    Serial.println("ERROR: MPU6050 not found!");
    while (1) {
      delay(10);
    }
  }

  // Set sensor ranges
  mpu.setAccelerometerRange(MPU6050_RANGE_2_G);
  mpu.setGyroRange(MPU6050_RANGE_250_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_260_HZ);

  delay(1000);

  // CSV header
  Serial.println(
    "Time_ms,AccelX,AccelY,AccelZ,GyroX,GyroY,GyroZ"
  );

  startTime = millis();
}

void loop() {
  unsigned long now = millis();

  if (now - lastSample >= sampleInterval) {
    lastSample = now;

    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);

    unsigned long elapsed = now - startTime;

    // Time in milliseconds
    Serial.print(elapsed);
    Serial.print(",");

    // Accelerometer: m/s^2
    Serial.print(a.acceleration.x, 6);
    Serial.print(",");
    Serial.print(a.acceleration.y, 6);
    Serial.print(",");
    Serial.print(a.acceleration.z, 6);
    Serial.print(",");

    // Gyroscope: rad/s
    Serial.print(g.gyro.x, 6);
    Serial.print(",");
    Serial.print(g.gyro.y, 6);
    Serial.print(",");
    Serial.println(g.gyro.z, 6);
  }
}