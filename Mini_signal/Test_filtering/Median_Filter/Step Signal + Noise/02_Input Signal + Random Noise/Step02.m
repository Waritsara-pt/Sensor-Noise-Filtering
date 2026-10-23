% Input Signal + Random Noise
clc;
clear;
close all;

% กำหนดตัวแปร
N = 1000;               % จำนวนจุดข้อมูล
fs = 100;               % ความถี่สุ่มตัวอย่าง 100 Hz
n = 0:N-1;              % ลำดับจุดข้อมูล
t = n/fs;               % เวลา

% สร้างสัญญาณขั้นบันได
s3 = zeros(1,N);
s3(n >= 100) = 1;

% เพิ่ม Random Noise ขนาด 0.2 เข้าไปในสัญญาณ
rng(1);                 % กำหนด Noise ให้เหมือนเดิมทุกครั้ง
x3 = s3 + 0.2*randn(1,N);

% แสดงกราฟสัญญาณที่มี Noise
figure;
plot(t,x3,'b');
xlabel('Time (s)');
ylabel('Amplitude');
title('Input Signal + Random Noise');
grid on;