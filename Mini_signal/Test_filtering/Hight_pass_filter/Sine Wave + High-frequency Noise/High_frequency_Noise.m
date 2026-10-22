
clc; 
clear; 
close all;

% 1. กำหนดพารามิเตอร์และสัญญาณ
fs = 100;
T = 1/fs;
N = 200;
n = 0:N-1;
t = n * T;

noise = sin(2*pi*1*t);                % Noise ความถี่ต่ำ 1 Hz
s2 = 0.5*sin(2*pi*10*t);    % สัญญาณหลักความถี่สูง 10 Hz
x2 = noise + s2 ;               % สัญญาณผสม

% 2. กรองสัญญาณด้วย High-Pass Filter
fc = 3;
[b, a] = butter(4, fc/(fs/2), 'high');
y2 = filtfilt(b, a, x2);

% Figure 1: สัญญาณต้นฉบับแบบ Discrete
figure(1);
stem(n, s2, 'b', 'filled');
title('Ex 2 - Original Discrete Signal s2\_target[n]');
xlabel('Sample n');
ylabel('Amplitude');
grid on;

% Figure 2: สัญญาณผสมแบบ Discrete
figure(2);
stem(n, x2, 'r', 'filled');
title('Ex 2 - Combined Discrete Signal x2[n]');
xlabel('Sample n');
ylabel('Amplitude');
grid on;

% Figure 3: สัญญาณหลังกรองแบบ Discrete
figure(3);
stem(n, y2, 'r', 'filled');
title('Ex 2 - Filtered Discrete Signal y2[n]');
xlabel('Sample n');
ylabel('Amplitude');
grid on;

% Figure 4: เปรียบเทียบสัญญาณแบบกราฟเส้นต่อเนื่อง
figure(4);
plot(t, x2, 'k');
hold on;
plot(t, y2, 'r--', 'LineWidth', 1.5);
plot(t, s2, 'b.', 'LineWidth', 1.5);
hold off;
title('Ex 2 - High-Pass Filtering Result');
legend('Input Signal x2', 'Filtered Output y2', ...
    'Original Target Signal 10 Hz');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;