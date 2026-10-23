% Input Signal + High-frequency Noise
clc;
clear;
close all;

% กำหนดตัวแปร
N = 1000;               % จำนวนจุดข้อมูล
fs = 100;               % ความถี่สุ่มตัวอย่าง 100 Hz
n = 0:N-1;              % ลำดับจุดข้อมูล
t = n/fs;               % เวลา

% สร้างสัญญาณต้นฉบับ ความถี่ 1 Hz
s2 = sin(2*pi*1*n/fs);

% สร้าง Noise ความถี่สูง 10 Hz แล้วบวกเข้ากับสัญญาณเดิม
x2 = s2 + 0.5*sin(2*pi*10*n/fs);

% แสดงกราฟสัญญาณที่มี Noise
figure;
plot(t,x2,'b');
xlabel('Time (s)');
ylabel('Amplitude');
title('Input Signal + High-frequency Noise');
grid on;