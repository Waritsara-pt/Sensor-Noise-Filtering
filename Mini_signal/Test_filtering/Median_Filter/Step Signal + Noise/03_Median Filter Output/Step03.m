% Median Filter Output
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

% เพิ่ม Random Noise
rng(1);                 % ใช้ Noise ชุดเดิม
x3 = s3 + 0.2*randn(1,N);

% กรองสัญญาณด้วย Median Filter
M = 5;                  % ขนาดหน้าต่าง 5 จุด
y3 = medfilt1(x3,M);    % กรองสัญญาณด้วยค่ามัธยฐาน

% แสดงกราฟหลังกรอง
figure;
plot(t,y3,'r');
xlabel('Time (s)');
ylabel('Amplitude');
title('Median Filter Output');
grid on;