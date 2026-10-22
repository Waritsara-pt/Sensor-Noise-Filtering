
clc;
clear;
close all;

%% 1. INPUT SIGNAL

fs = 100;
t = 0:1/fs:9.99;
N = length(t);

rng(1);

fprintf('=== Automatic Multi-Filter Selection ===\n');
fprintf('1. Sine + Random Noise\n');
fprintf('2. Sine + High-frequency Noise\n');
fprintf('3. Step + Random Noise\n');
fprintf('4. Sine + Spike Noise\n');
fprintf('5. Sine + Low-frequency Drift\n');
fprintf('6. Spike + High-frequency Noise\n');

choice = input('Select signal (1-6): ');

switch choice
    case 1
        s = sin(2*pi*1*t);
        x = s + 0.25*randn(size(t));
        signalName = 'Sine + Random Noise';

    case 2
        s = sin(2*pi*1*t);
        x = s + 0.35*sin(2*pi*20*t);
        signalName = 'Sine + High-frequency Noise';

    case 3
        s = double(t >= 5);
        x = s + 0.2*randn(size(t));
        signalName = 'Step + Random Noise';

    case 4
        s = sin(2*pi*1*t);
        x = s;
        idx = [100 300 600 800];
        x(idx) = x(idx) + [2 -2 2 -2];
        signalName = 'Sine + Spike Noise';

    case 5
        s = sin(2*pi*5*t);
        x = s + 0.8*(t/max(t));
        signalName = 'Sine + Low-frequency Drift';

    case 6
        s = sin(2*pi*1*t);
        x = s + 0.25*sin(2*pi*20*t);
        idx = [100 300 600 800];
        x(idx) = x(idx) + [2 -2 2 -2];
        signalName = 'Spike + High-frequency Noise';

    otherwise
        error('Select a number from 1 to 6.');
end

%% 2. SIGNAL ANALYSIS

% Detect sudden outliers
localMedian = movmedian(x, 7);
residual = x - localMedian;

robustSigma = 1.4826 * ...
    median(abs(residual - median(residual)));

if robustSigma < 1e-10
    robustSigma = 1e-10;
end

spikeCount = sum(abs(residual) > 4*robustSigma);

% Estimate high-frequency fluctuation
shortSmooth = movmean(x, 7);
hfRatio = std(x - shortSmooth) / (std(x) + eps);

% Estimate slow trend
trendWindow = round(fs);
slowTrend = movmean(x, trendWindow);

trendRatio = std(slowTrend - mean(slowTrend)) ...
    / (std(x) + eps);

p = polyfit(t, x, 1);
trendCorr = corr(t(:), x(:));

% Estimate random fluctuation
randomScore = std(residual) / (std(x) + eps);

fprintf('\n=== Analysis Results ===\n');
fprintf('Spike count: %d\n', spikeCount);
fprintf('High-frequency ratio: %.3f\n', hfRatio);
fprintf('Trend ratio: %.3f\n', trendRatio);
fprintf('Random fluctuation score: %.3f\n', randomScore);

%% 3. AUTOMATIC FILTER SELECTION

filters = {};
reasons = {};

if choice == 3
    filters{end+1} = 'Median';
    reasons{end+1} = 'Reduce random noise in step signal';

    filters{end+1} = 'Moving Average';
    reasons{end+1} = 'Smooth remaining fluctuations';

else
    % Rule 1: Spike detection
    if spikeCount >= 2
        filters{end+1} = 'Median';
        reasons{end+1} = 'Spike / outlier detected';
    end

    % Rule 2: Low-frequency drift detection
    if trendRatio > 0.20 && abs(trendCorr) > 0.65
        filters{end+1} = 'High-pass';
        reasons{end+1} = 'Possible low-frequency drift';
    end

    % Rule 3: High-frequency noise detection
    if hfRatio > 0.35
        filters{end+1} = 'Low-pass';
        reasons{end+1} = 'High-frequency fluctuation detected';
    end

    % Rule 4: General random fluctuation
    if randomScore > 0.18 && hfRatio <= 0.45
        filters{end+1} = 'Moving Average';
        reasons{end+1} = 'Additional smoothing may be useful';
    end

    % Fallback
    if isempty(filters)
        filters{end+1} = 'Moving Average';
        reasons{end+1} = 'Default smoothing filter';
    end
end

%% 4. APPLY FILTERS IN SELECTED ORDER

y = x;

for k = 1:length(filters)
    switch filters{k}
        case 'Median'
            y = medfilt1(y, 5);

        case 'High-pass'
            y = highpass(y, 0.5, fs);

        case 'Low-pass'
            y = lowpass(y, 5, fs);

        case 'Moving Average'
            y = movmean(y, 5);
    end
end

%% 5. DISPLAY SELECTION

fprintf('\n=== Selected Filter Sequence ===\n');

for k = 1:length(filters)
    fprintf('%d. %s -- %s\n', ...
        k, filters{k}, reasons{k});
end

fprintf('\nInput: %s\n', signalName);
fprintf('Number of filters: %d\n', length(filters));

%% 6. FREQUENCY SPECTRUM USING FOURIER ANALYSIS

% FFT calculates the DFT of sampled signals
X = fft(x);
Y = fft(y);

% Frequency axis
halfN = floor(N/2) + 1;
f = (0:halfN-1) * (fs/N);

% One-sided amplitude spectrum
Xmag = abs(X(1:halfN)) / N;
Ymag = abs(Y(1:halfN)) / N;

% Correct amplitudes for one-sided spectrum
if rem(N, 2) == 0
    Xmag(2:end-1) = 2 * Xmag(2:end-1);
    Ymag(2:end-1) = 2 * Ymag(2:end-1);
else
    Xmag(2:end) = 2 * Xmag(2:end);
    Ymag(2:end) = 2 * Ymag(2:end);
end

%% 7. PLOT RESULTS

figure('Name', 'Automatic Multi-Filter System');

% Plot 1: Input signal
subplot(2,2,1);
plot(t, x,'r');
grid on;
title(['Input Signal: ' signalName]);
xlabel('Time (s)');
ylabel('Amplitude');

% Plot 2: Filtered output
subplot(2,2,2);
plot(t, y,'b','LineWidth', 1.2);
grid on;
title(['Output after filtering: ' ...
    strjoin(filters, ' -> ')]);
xlabel('Time (s)');
ylabel('Amplitude');

% Plot 3: Frequency spectrum before and after filtering
subplot(2,2,3);
plot(f, Xmag, 'r', 'LineWidth', 1);
hold on;
plot(f, Ymag, 'b', 'LineWidth', 1.2);
hold off;
grid on;
title('Frequency Spectrum Comparison');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
legend('Before Filtering', 'After Filtering');
xlim([0 fs/2]);

% Plot 4: Raw vs filtered signal
subplot(2,2,4);
plot(t, x, 'Color', '#bdbdbd');
hold on;
plot(t, y,'b', 'LineWidth', 1.2);
hold off;
grid on;
title(['Raw vs Filtered: ' signalName]);
xlabel('Time (s)');
ylabel('Amplitude');
legend('Raw Signal', 'Filtered Signal');

sgtitle('Automatic Multi-Filter Selection System');
