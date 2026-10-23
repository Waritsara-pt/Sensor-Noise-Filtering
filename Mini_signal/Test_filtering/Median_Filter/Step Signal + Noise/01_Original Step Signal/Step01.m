% Original Step Signal
clc;
clear;
close all;

% กำหนดตัวแปร
N = 1000;               % จำนวนจุดข้อมูล
fs = 100;               % ความถี่สุ่มตัวอย่าง 100 Hz
n = 0:N-1;              % ลำดับจุดข้อมูล
t = n/fs;               % เวลา

% สร้างสัญญาณขั้นบันได โดยเริ่มจาก 0 แล้วเปลี่ยนเป็น 1
s3 = zeros(1,N);
s3(n >= 100) = 1;

% แสดงกราฟสัญญาณต้นฉบับ
figure;
plot(t,s3,'b');
xlabel('Time (s)');
ylabel('Amplitude');
title('Original Step Signal');
grid on;