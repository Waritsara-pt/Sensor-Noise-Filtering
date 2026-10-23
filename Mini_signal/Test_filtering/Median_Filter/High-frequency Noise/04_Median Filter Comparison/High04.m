% Median Filter Comparison
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

% เพิ่ม Noise ความถี่สูง
x2 = s2 + 0.5*sin(2*pi*10*n/fs);

% กรองสัญญาณด้วย Median Filter
M = 5;                  % ขนาดหน้าต่าง 5 จุด
y2 = medfilt1(x2,M);    % สัญญาณหลังกรอง

% แสดงกราฟเปรียบเทียบ 3 เส้น
figure;
plot(t,x2,'b');         % สีน้ำเงิน: สัญญาณที่มี Noise
hold on;
plot(t,y2,'r','LineWidth',1.5); % สีแดง: สัญญาณหลังกรอง
plot(t,s2,'g--','LineWidth',1.5); % สีเขียวประ: สัญญาณต้นฉบับ

xlabel('Time (s)');
ylabel('Amplitude');
title('Median Filter Comparison');
legend('Input Signal + High-frequency Noise', ...
    'Median Filter Output', ...
    'Original Signal');
grid on;
hold off;