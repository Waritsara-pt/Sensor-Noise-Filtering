
import serial
import csv
import time

PORT = "COM4"  # แก้ให้ตรงกับพอร์ต ESP32
BAUD_RATE = 115200
FILENAME = "max30102_Monitoring_data.csv"
RECORD_SECONDS = 60

ser = None

try:
    ser = serial.Serial(PORT, BAUD_RATE, timeout=2)
    time.sleep(2)
    ser.reset_input_buffer()

    start_time = time.monotonic()
    count = 0

    with open(FILENAME, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)

        writer.writerow(["Time_ms", "IR_Raw", "Red_Raw"])

        print("กำลังบันทึกข้อมูลจาก MAX30102...")
        print("วางนิ้วบนเซนเซอร์ให้นิ่ง และอย่ากดแรงเกินไป")

        while time.monotonic() - start_time < RECORD_SECONDS:
            line = ser.readline().decode(
                "utf-8", errors="ignore"
            ).strip()

            values = line.split(",")

            if len(values) != 3:
                continue

            try:
                row = [
                    int(values[0]),
                    int(values[1]),
                    int(values[2])
                ]
            except ValueError:
                continue

            writer.writerow(row)
            count += 1
            print(row)

    print(f"\nบันทึกเสร็จแล้ว {count} แถว")
    print(f"ไฟล์: {FILENAME}")

except KeyboardInterrupt:
    print("\nหยุดการบันทึกโดยผู้ใช้")

except serial.SerialException as e:
    print("ไม่สามารถเปิดพอร์ต Serial ได้:", e)
    print("ตรวจสอบ PORT และปิด Serial Monitor")

finally:
    if ser is not None and ser.is_open:
        ser.close()
