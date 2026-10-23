
import serial
import csv
import time

PORT = "/dev/cu.usbserial-0001"       # แก้ให้ตรงกับพอร์ต ESP32
BAUD_RATE = 115200
FILENAME = "RGB_2.csv"
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

        # เขียนหัวตาราง CSV
        writer.writerow([
            "Time_ms", "Red", "Green", "Blue", "Clear"
        ])

        print("กำลังบันทึกข้อมูลจาก TCS34725...")
        print("ทดลองนำวัตถุสีต่าง ๆ ไปไว้หน้าเซนเซอร์")

        while time.monotonic() - start_time < RECORD_SECONDS:
            line = ser.readline().decode(
                "utf-8", errors="ignore"
            ).strip()

            values = line.split(",")

            # ต้องมีข้อมูล 5 ค่า
            if len(values) != 5:
                continue

            try:
                row = [
                    int(values[0]),
                    int(values[1]),
                    int(values[2]),
                    int(values[3]),
                    int(values[4])
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
