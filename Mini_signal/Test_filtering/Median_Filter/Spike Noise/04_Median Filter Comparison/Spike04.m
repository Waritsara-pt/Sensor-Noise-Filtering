% Median Filter Comparison
clc;
clear;
close all;

% กำหนดตัวแปร
N = 1000;
fs = 100;
n = 0:N-1;
t = n/fs;

% สร้างสัญญาณต้นฉบับ
s4 = sin(2*pi*1*n/fs);

% สร้าง Spike Noise
noise4 = zeros(1,N);
noise4([40 90 140 180]) = [2 -2 2 -2];

% เพิ่ม Noise เข้าไปในสัญญาณ
x4 = s4 + noise4;

% กรองสัญญาณด้วย Median Filter
M = 5;
y4 = medfilt1(x4,M);

% แสดงกราฟเปรียบเทียบ
figure;
plot(t,x4,'b');
hold on;
plot(t,y4,'r','LineWidth',1.5);
plot(t,s4,'g--','LineWidth',1.5);

xlabel('Time (s)');
ylabel('Amplitude');
title('Median Filter Comparison');
legend('Input Signal + Spike Noise', ...
    'Median Filter Output', ...
    'Original Signal');
grid on;
hold off;