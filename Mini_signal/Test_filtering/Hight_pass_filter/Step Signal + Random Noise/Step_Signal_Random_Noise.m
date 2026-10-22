
clc; clear; close all;

% 1. กำหนดพารามิเตอร์และสัญญาณ
fs = 100;
T = 1/fs;
N = 200;
n = 0:N-1;
t = n * T;

s3 = zeros(1, N);
s3(n >= 100) = 1;           % Step Signal ที่ n = 100

rng('default');
x3 = s3 + 0.2 * randn(1, N); % สัญญาณผสม Noise

% 2. กรองสัญญาณด้วย High-Pass Filter
fc = 3;
[b, a] = butter(4, fc/(fs/2), 'high');
y3 = filtfilt(b, a, x3);

% Figure 1: สัญญาณต้นฉบับแบบ Discrete
figure(1);
stem(n, s3, 'g', 'filled');
title('Ex 3 - Original Discrete Step Signal s3[n]');
xlabel('Sample n');
ylabel('Amplitude');
grid on;

% Figure 2: สัญญาณผสม Noise แบบ Discrete
figure(2);
stem(n, x3, 'b', 'filled');
title('Ex 3 - Combined Discrete Signal x3[n]');
xlabel('Sample n');
ylabel('Amplitude');
grid on;

% Figure 3: สัญญาณหลังกรองแบบ Discrete
figure(3);
stem(n, y3, 'r', 'filled');
title('Ex 3 - Filtered Discrete Signal y3[n]');
xlabel('Sample n');
ylabel('Amplitude');
grid on;

% Figure 4: เปรียบเทียบสัญญาณแบบกราฟเส้นต่อเนื่อง
figure(4);
plot(t, x3, 'b');
hold on;
plot(t, y3, 'r--', 'LineWidth', 1.5);
plot(t, s3, 'g', 'LineWidth', 1.5);
hold off;
title('Ex 3 - High-Pass Filtering Result');
legend('Input Signal x3', 'Filtered Output y3', ...
    'Original Step Signal s3');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;