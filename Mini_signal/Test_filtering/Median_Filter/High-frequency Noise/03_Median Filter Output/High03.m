% Median Filter Output
clc;
clear;
close all;

% กำหนดตัวแปร
N = 1000;               % จำนวนจุดข้อมูล
fs = 100;               % ความถี่สุ่มตัวอย่าง 100 Hz
n = 0:N-1;              % ลำดับจุดข้อมูล
t = n/fs;               % เวลา

% สร้างสัญญาณต้นฉบับ
s2 = sin(2*pi*1*n/fs);

% เพิ่ม Noise ความถี่สูงเข้าไป
x2 = s2 + 0.5*sin(2*pi*10*n/fs);

% กรองสัญญาณด้วย Median Filter
M = 5;                  % ขนาดหน้าต่าง 5 จุด
y2 = medfilt1(x2,M);    % กรองสัญญาณโดยใช้ค่ามัธยฐาน

% แสดงกราฟหลังกรอง
figure;
plot(t,y2,'r');
xlabel('Time (s)');
ylabel('Amplitude');
title('Median Filter Output');
grid on;