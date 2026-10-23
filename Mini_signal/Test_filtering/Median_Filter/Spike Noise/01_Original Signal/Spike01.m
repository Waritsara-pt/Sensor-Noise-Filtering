% Original Signal
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

% แสดงกราฟ
figure;
plot(t,s4,'b');
xlabel('Time (s)');
ylabel('Amplitude');
title('Original Signal');
grid on;