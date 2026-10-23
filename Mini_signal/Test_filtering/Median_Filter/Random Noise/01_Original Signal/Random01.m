% Original Signal

clc;
clear;
close all;

% กำหนดตัวแปร
N = 1000;              % จำนวนจุดข้อมูล
fs = 100;              % ความถี่สุ่มตัวอย่าง 100 Hz
n = 0:N-1;             % ลำดับจุดข้อมูล
t = n/fs;              % เวลา

% สร้างสัญญาณคลื่นไซน์ 1 Hz
s1 = sin(2*pi*1*n/fs);

% แสดงกราฟสัญญาณต้นฉบับ
figure;
plot(t,s1,'b');
xlabel('Time (s)');
ylabel('Amplitude');
title('Original Signal');
grid on;