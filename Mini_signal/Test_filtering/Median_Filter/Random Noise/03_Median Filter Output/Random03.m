% Median Filter Output
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

% เพิ่ม Random Noise
rng(1);                % ให้ Noise เหมือนเดิมทุกครั้งที่รัน
x1 = s1 + 0.5*randn(1,N);

% กรอง Noise ด้วย Median Filter
M = 5;                 % ใช้ข้อมูลครั้งละ 5 จุด
y = medfilt1(x1,M);    % คำนวณค่ามัธยฐานเพื่อกรองสัญญาณ

% แสดงกราฟหลังกรอง
figure;
plot(t,y,'r');
xlabel('Time (s)');
ylabel('Amplitude');
title('Median Filter Output');
grid on;