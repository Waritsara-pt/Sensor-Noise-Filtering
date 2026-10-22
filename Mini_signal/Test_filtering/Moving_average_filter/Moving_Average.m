clc;
clear;
close all;

%% 1. สร้างสัญญาณ Input
N = 201;
n = 0:N-1;
fs = 100;

rng(1);

% กรณีที่ 1: Sine Wave + Random Noise
s1 = sin(2*pi*1*n/fs);
x1 = s1 + 0.5*randn(1,N);

% กรณีที่ 2: Sine Wave + High-frequency Noise
s2 = sin(2*pi*1*n/fs);
x2 = s2 + 0.5*sin(2*pi*10*n/fs);

% กรณีที่ 3: Step Signal + Random Noise
s3 = zeros(1,N);
s3(n >= 100) = 1;
x3 = s3 + 0.2*randn(1,N);

% กรณีที่ 4: Sine Wave + Spike Noise
s4 = sin(2*pi*1*n/fs);
noise4 = zeros(1,N);
noise4([40 90 140 180]) = [2 -2 2 -2];
x4 = s4 + noise4;

%% 2. กำหนด Window Size
M = 7;

%% 3. กรองสัญญาณด้วย Moving Average
X = [x1; x2; x3; x4];
S = [s1; s2; s3; s4];

Y = zeros(size(X));

for c = 1:4
    for k = M:N
        Y(c,k) = sum(X(c,k-M+1:k)) / M;
    end
end

%% 4. แสดงกราฟ

% 4.1 กรณีที่ 1: Sine Wave + Random Noise
figure(1);
clf;
stem(n,s1,'Color','#056f00');
xlabel('Sample Index n');
ylabel('Amplitude');
title('x(t) Sine Wave Without Noise');
grid on;
drawnow;

figure(2);
clf;
stem(n,x1,'Color','#d7ccc8');
xlabel('Sample Index n');
ylabel('Amplitude');
title('x(t) Sine Wave + Random Noise');
grid on;
drawnow;

figure(3);
clf;
stem(n(M:N), Y(1,M:N),'Color', '#168AAD') 
xlabel('Sample Index n');
ylabel('Amplitude');
title('Moving Average Filter - Random Noise');
grid on;
drawnow;

figure(4);
clf;
plot(n(M:N), Y(1,M:N),'Color', '#168AAD') 
hold on;
plot(n,s1,'Color','#056f00','LineWidth',1.5);
plot(n,x1,'Color','#d7ccc8');
hold off
legend('Signal After Moving Average Filter','x(t) Sine Wave Without Noise','x(t) Sine Wave + Random Noise');
xlabel('Sample Index n');
ylabel('Amplitude');
title('Moving Average Filter - Sine Wave + Random Noise');
grid on;
drawnow;

% 4.2 กรณีที่ 2: Sine Wave + High-frequency Noise
figure(5);
clf;
stem(n,s2,'Color','#8E44AD');
xlabel('Sample Index n');
ylabel('Amplitude');
title('x(t) Sine Wave Without Noise');
grid on;
drawnow;

figure(6);
clf;
stem(n,x2,'Color','#bdbdbd');
xlabel('Sample Index n');
ylabel('Amplitude');
title('x(t) Sine Wave + High-frequency Noise');
grid on;
drawnow;

figure(7);
clf;
stem(n(M:N), Y(2,M:N),'Color', '#168AAD') 
xlabel('Sample Index n');
ylabel('Amplitude');
title('Moving Average Filter - High-frequency Noise');
grid on;
drawnow;

figure(8);
clf;
plot(n(M:N), Y(2,M:N),'Color', '#168AAD') 
hold on;
plot(n,s2,'Color','#8E44AD','LineWidth',1.5);
plot(n,x2,'Color','#bdbdbd');
hold off
legend('Signal After Moving Average Filter','x(t) Sine Wave Without Noise','x(t) Sine Wave + Random Noise');
xlabel('Sample Index n');
ylabel('Amplitude');
title('Sine Wave + High-frequency Noise');
grid on;
drawnow;

% 4.3 กรณีที่ 3: Step Signal + Random Noise
figure(9);
clf;
stem(n,s3,'Color','#3f51b5');
xlabel('Sample Index n');
ylabel('Amplitude');
title('x(t) Step Signal Without Noise');
grid on;
drawnow;

figure(10);
clf;
stem(n,x3,'Color','#4db6ac');
xlabel('Sample Index n');
ylabel('Amplitude');
title('x(t) Step Signal + Random Noise');
grid on;
drawnow;

figure(11);
clf;
stem(n(M:N), Y(3,M:N),'Color', '#c0ca33') 
xlabel('Sample Index n');
ylabel('Amplitude');
title('Moving Average Filter - Random Noise');
grid on;
drawnow;

figure(12);
clf;
plot(n(M:N), Y(3,M:N),'Color', '#c0ca33') 
hold on;
plot(n,s3,'Color','#3f51b5','LineWidth',1.5);
plot(n,x3,'Color','#4db6ac');
hold off
legend('Signal After Moving Average Filter','x(t) Step Signal Without Noise','x(t) Step Signal + Random Noise');
xlabel('Sample Index n');
ylabel('Amplitude');
title('Moving Average Filter - Step Signal + Random Noise');
grid on;
drawnow;

% 4.4 กรณีที่ 4: Sine Wave + Spike Noise
figure(13);
clf;
stem(n,s4,'Color','#689f38');
xlabel('Sample Index n');
ylabel('Amplitude');
title('x(t) Sine Wave Without Noise');
grid on;
drawnow;

figure(14);
clf;
stem(n,x4,'Color','#ff8f00');
xlabel('Sample Index n');
ylabel('Amplitude');
title('x(t) Sine Wave + Spike Noise');
grid on;
drawnow;

figure(15);
clf;
stem(n(M:N), Y(4,M:N),'Color', '#bf360c') 
xlabel('Sample Index n');
ylabel('Amplitude');
title('Moving Average Filter - Spike Noise');
grid on;
drawnow;

figure(16);
clf;
plot(n(M:N), Y(4,M:N),'Color', '#bf360c') 
hold on;
plot(n,s4,'Color','#689f38','LineWidth',1.5);
plot(n,x4,'Color','#ff8f00');
hold off
legend('Signal After Moving Average Filter','x(t) Sine Wave Without Noise','x(t) Sine Wave + Spike Noise');
xlabel('Sample Index n');
ylabel('Amplitude');
title('Moving Average Filter - Sine Wave + Spike Noise');
grid on;
drawnow;