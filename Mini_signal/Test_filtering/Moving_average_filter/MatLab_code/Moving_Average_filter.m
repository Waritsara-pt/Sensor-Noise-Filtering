
clc;
clear;
close all;

%% 1. INPUT SIGNAL
fs = 100;
t = 0:1/fs:9.99;
N = length(t);

rng(1);

% Case 1: Sine + Random Noise
s1 = sin(2*pi*1*t);
x1 = s1 + 0.25*randn(size(t));

% Case 2: Sine + High-frequency Noise
s2 = sin(2*pi*1*t);
x2 = s2 + 0.35*sin(2*pi*20*t);

% Case 3: Step + Random Noise
s3 = double(t >= 5);
x3 = s3 + 0.2*randn(size(t));

% Case 4: Sine + Spike Noise
s4 = sin(2*pi*1*t);
x4 = s4;
idx4 = [100 300 600 800];
x4(idx4) = x4(idx4) + [2 -2 2 -2];

% Case 5: Sine + Low-frequency Drift
s5 = sin(2*pi*5*t);
x5 = s5 + 0.8*(t/max(t));

% Case 6: Spike Noise + High-frequency Noise 
s6 = sin(2*pi*1*t);
x6 = s6 + 0.25*sin(2*pi*20*t);
idx6 = [100 300 600 800];
x6(idx6) = x6(idx6) + [2 -2 2 -2];

% Store all signals
cleanSignals = [s1; s2; s3; s4; s5; s6];
inputSignals = [x1; x2; x3; x4; x5; x6];

signalNames = {
    'Sine + Random Noise'
    'Sine + High-frequency Noise'
    'Step + Random Noise'
    'Sine + Spike Noise'
    'Sine + Low-frequency Drift'
    'Spike Noise + High-frequency Noise'
};

%% 2. SELECT INPUT SIGNAL
fprintf('============================================\n');
fprintf('       Moving Average Filter System\n');
fprintf('============================================\n');
fprintf('1. Sine + Random Noise\n');
fprintf('2. Sine + High-frequency Noise\n');
fprintf('3. Step + Random Noise\n');
fprintf('4. Sine + Spike Noise\n');
fprintf('5. Sine + Low-frequency Drift\n');
fprintf('6. Spike Noise + High-frequency Noise \n');

choice = input('Select signal (1-6): ');

if isempty(choice) || ~isscalar(choice) || ...
        ~isfinite(choice) || choice ~= floor(choice) || ...
        choice < 1 || choice > 6
    error('Please select a valid signal from 1 to 6.');
end

s = cleanSignals(choice,:);
x = inputSignals(choice,:);
signalName = signalNames{choice};

%% 3. MOVING AVERAGE FILTER
% Moving Average only; window size M = 7
M = 7;
y = zeros(1,N);

for k = M:N
    y(k) = sum(x(k-M+1:k))/M;
end


%% 4. MSE CALCULATION
mseBefore = mean((x - s).^2);
mseAfter = mean((y - s).^2);

fprintf('\n========== MSE RESULTS ==========\n');
fprintf('Selected Signal: %s\n', signalName);
fprintf('MSE Before Filtering = %.6f\n', mseBefore);
fprintf('MSE After Filtering  = %.6f\n', mseAfter);

if mseAfter < mseBefore
    fprintf('Result: Moving Average filter reduced the MSE.\n');
elseif mseAfter > mseBefore
    fprintf('Result: Moving Average filter increased the MSE.\n');
else
    fprintf('Result: MSE remained unchanged.\n');
end
fprintf('=================================\n');


%% 5. FREQUENCY SPECTRUM
Xfft = fft(x);
Yfft = fft(y);

halfN = floor(N/2) + 1;
f = (0:halfN-1)*(fs/N);

Xmag = abs(Xfft(1:halfN))/N;
Ymag = abs(Yfft(1:halfN))/N;

% Convert to one-sided amplitude spectrum
if rem(N,2) == 0
    Xmag(2:end-1) = 2*Xmag(2:end-1);
    Ymag(2:end-1) = 2*Ymag(2:end-1);
else
    Xmag(2:end) = 2*Xmag(2:end);
    Ymag(2:end) = 2*Ymag(2:end);
end

%% 6. PLOT RESULTS
figure('Name','Moving Average Filter System', ...
       'NumberTitle','off');

% Plot 1: Input Signal
subplot(2,2,1);
plot(t,x,'r');
grid on;
title(['Input Signal: ' signalName]);
xlabel('Time (s)');
ylabel('Amplitude');

% Plot 2: Filtered Output
subplot(2,2,2);
plot(t,y,'b','LineWidth',1.2);
grid on;
title('Output after Moving Average Filter (M = 7)');
xlabel('Time (s)');
ylabel('Amplitude');

% Plot 3: Frequency Spectrum Comparison
subplot(2,2,3);
plot(f,Xmag,'r');
hold on;
plot(f,Ymag,'b','LineWidth',1.2);
hold off;
grid on;
title('Frequency Spectrum Comparison');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
legend('Before Filtering','After Filtering');
xlim([0 fs/2]);

% Plot 4: Raw vs Filtered
subplot(2,2,4);
plot(t,x,'Color',[0.7 0.7 0.7]);
hold on;
plot(t,y,'b','LineWidth',1.2);
hold off;
grid on;
title(['Raw vs Filtered: ' signalName]);
xlabel('Time (s)');
ylabel('Amplitude');
legend('Noisy Input','Filtered Output','Clean Signal', ...
       'Location','best');

sgtitle('Moving Average Filter System');
