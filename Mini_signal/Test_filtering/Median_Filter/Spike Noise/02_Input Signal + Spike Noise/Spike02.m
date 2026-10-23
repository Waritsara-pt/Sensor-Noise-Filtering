% Input Signal + Spike Noise
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

% แสดงกราฟ
figure;
plot(t,x4,'b');
xlabel('Time (s)');
ylabel('Amplitude');
title('Input Signal + Spike Noise');
grid on;