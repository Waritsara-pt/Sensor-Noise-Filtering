
import serial
import csv
import time

PORT = "COM4"       # แก้ให้ตรงกับพอร์ต ESP32
BAUD_RATE = 115200
FILENAME = "mpu6050_walk_data.csv"
RECORD_SECONDS = 60  # เก็บข้อมูล 60 วินาที

ser = None

try:
    ser = serial.Serial(PORT, BAUD_RATE, timeout=2)
    time.sleep(2)
    ser.reset_input_buffer()

    start_time = time.monotonic()
    count = 0

    with open(FILENAME, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)

        # Header: เวลา + MPU6050 ทั้ง 6 แกน
        writer.writerow([
            "Time_ms",
            "AccelX", "AccelY", "AccelZ",
            "GyroX", "GyroY", "GyroZ"
        ])

        print("กำลังบันทึกข้อมูลจาก MPU6050...")
        print("วางเซนเซอร์ให้นิ่งระหว่างทดลอง")

        while time.monotonic() - start_time < RECORD_SECONDS:
            line = ser.readline().decode(
                "utf-8", errors="ignore"
            ).strip()

            values = line.split(",")

            # ต้องมี 7 ค่า: เวลา + 6 แกน
            if len(values) != 7:
                continue

            try:
                row = [
                    int(values[0]),
                    float(values[1]),  # AccelX
                    float(values[2]),  # AccelY
                    float(values[3]),  # AccelZ
                    float(values[4]),  # GyroX
                    float(values[5]),  # GyroY
                    float(values[6])   # GyroZ
                ]
            except ValueError:
                continue

            writer.writerow(row)
            f.flush()
            count += 1
            print(row)

    print(f"\nบันทึกเสร็จแล้ว {count} แถว")
    print(f"ไฟล์: {FILENAME}")

except KeyboardInterrupt:
    print("\nหยุดการบันทึกโดยผู้ใช้")

except serial.SerialException as e:
    print("ไม่สามารถเปิดพอร์ต Serial ได้:", e)
    print("ตรวจสอบ PORT, สาย USB และปิด Serial Monitor")

finally:
    if ser is not None and ser.is_open:
        ser.close()
