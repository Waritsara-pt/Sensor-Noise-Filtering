% Input Signal + Random Noise
clc;
clear;
close all;

% กำหนดตัวแปร
N = 1000;              % จำนวนจุดข้อมูล
fs = 100;              % ความถี่สุ่มตัวอย่าง 100 Hz
n = 0:N-1;             % ลำดับจุดข้อมูล
t = n/fs;              % เวลา

% สร้างสัญญาณต้นฉบับ
s1 = sin(2*pi*1*n/fs);

% เพิ่ม Random Noise เข้าไปในสัญญาณ
rng(1);                % ให้ Noise เหมือนเดิมทุกครั้งที่รัน
x1 = s1 + 0.5*randn(1,N);

% แสดงกราฟสัญญาณที่มี Noise
figure;
plot(t,x1,'b');
xlabel('Time (s)');
ylabel('Amplitude');
title('Input Signal with Random Noise');
grid on;