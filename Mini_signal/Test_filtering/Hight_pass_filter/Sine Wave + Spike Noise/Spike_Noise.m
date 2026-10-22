
clc; clear; close all;

% 1. กำหนดพารามิเตอร์และสัญญาณ
fs = 100;
T = 1/fs;
N = 200;
n = 0:N-1;
t = n * T;

s4 = sin(2*pi*1*t);                 % สัญญาณต้นฉบับความถี่ 1 Hz

noise4 = zeros(1, N);
noise4([40 90 140 180]) = [2 -2 2 -2]; % Spike Noise

x4 = s4 + noise4;                   % สัญญาณรวม

% 2. กรองสัญญาณด้วย High-Pass Filter
fc = 3;
[b, a] = butter(4, fc/(fs/2), 'high');
y4 = filtfilt(b, a, x4);

% --- Figure 1: สัญญาณต้นฉบับ ---
figure(1);
stem(n, s4, 'g', 'filled');
title('Ex 4 - Original Discrete Signal s4[n]');
xlabel('Sample (n)');
ylabel('Amplitude');
grid on;

% --- Figure 2: สัญญาณรวมที่มี Spike Noise ---
figure(2);
stem(n, x4, 'b', 'filled');
title('Ex 4 - Combined Discrete Signal x4[n]');
xlabel('Sample (n)');
ylabel('Amplitude');
grid on;

% --- Figure 3: สัญญาณหลังผ่านการกรอง ---
figure(3);
stem(n, y4, 'r', 'filled');
title('Ex 4 - Filtered Discrete Signal y4[n]');
xlabel('Sample (n)');
ylabel('Amplitude');
grid on;

% --- Figure 4: เปรียบเทียบสัญญาณทั้งหมด ---
figure(4);
plot(t, x4, 'b', 'LineWidth', 1);
hold on;
plot(t, y4, 'r--', 'LineWidth', 1.5);
plot(t, s4, 'g', 'LineWidth', 1.2);
hold off;

title('Ex 4 - Signal Comparison');
xlabel('Time (s)');
ylabel('Amplitude');
legend('Input Signal x4(t)', ...
    'Filtered Signal y4(t)', ...
    'Original Signal s4(t)');
grid on;