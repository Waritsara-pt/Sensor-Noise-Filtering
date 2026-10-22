clc; 
clear; 
close all;

% 1. กำหนดพารามิเตอร์และสัญญาณ
fs = 100;
T = 1/fs;
N = 200;
n = 0:N-1;
t = n * T;

s1 = sin(2*pi*1*t);            % สัญญาณความถี่ต่ำ 1 Hz

rng('default');
noise1 = 0.5 * randn(1, N);    % Random Noise
x1 = s1 + noise1;              % สัญญาณผสม

% 2. กรองสัญญาณด้วย High-Pass Filter
fc = 3;
[b, a] = butter(4, fc/(fs/2), 'high');
y1 = filtfilt(b, a, x1);

% Figure 1: สัญญาณต้นฉบับแบบ Discrete
figure(1);
stem(n, s1, 'b', 'filled');
title('Ex 1 - Original Discrete Signal s1[n]');
xlabel('Sample n');
ylabel('Amplitude');
grid on;

% Figure 2: สัญญาณผสม Noise แบบ Discrete
figure(2);
stem(n, x1, 'r', 'filled');
title('Ex 1 - Combined Discrete Signal x1[n]');
xlabel('Sample n');
ylabel('Amplitude');
grid on;

% Figure 3: สัญญาณหลังกรองแบบ Discrete
figure(3);
stem(n, y1, 'r', 'filled');
title('Ex 1 - Filtered Discrete Signal y1[n]');
xlabel('Sample n');
ylabel('Amplitude');
grid on;

% Figure 4: เปรียบเทียบสัญญาณแบบกราฟเส้นต่อเนื่อง
figure(4);
plot(t, x1, 'b');
hold on;
plot(t, y1, 'r--', 'LineWidth', 1.5);
plot(t, s1, 'g:', 'LineWidth', 1.5);
hold off;
title('Ex 1 - High-Pass Filtering Result');
legend('Input Signal x1', 'Filtered Output y1', ...
    'Original Signal s1');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;