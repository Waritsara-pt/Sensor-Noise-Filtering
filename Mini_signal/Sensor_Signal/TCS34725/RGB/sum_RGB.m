
clc;
clear;
close all;

%% 1. READ DATA FROM CSV
data = readtable("RGB.csv");

disp('Loaded Columns:');
disp(data.Properties.VariableNames);
disp(head(data));

% Convert time to seconds
t = double(data.Time_ms(:)) / 1000;
x = double(data.Red(:));

% Remove invalid values
valid = isfinite(t) & isfinite(x);
t = t(valid);
x = x(valid);

if length(x) < 10
    error('ข้อมูลมีน้อยเกินไป');
end

% Set start time to zero
t = t - t(1);

% Remove duplicate timestamps
[t, idx] = unique(t, 'stable');
x = x(idx);

if length(t) < 10
    error('ข้อมูลเวลาที่ไม่ซ้ำกันมีน้อยเกินไป');
end

% Calculate sampling frequency
dt = median(diff(t));

if ~isfinite(dt) || dt <= 0
    error('ไม่สามารถคำนวณ Sampling Frequency ได้');
end

fs = 1 / dt;
nyquist = fs / 2;

fprintf('Number of samples: %d\n', length(x));
fprintf('Sampling frequency: %.3f Hz\n', fs);

signalName = 'TCS34725 RGB - Red';

%% 2. SIGNAL ANALYSIS

% Detect sudden outliers
localMedian = movmedian(x, 7);
residual = x - localMedian;

robustSigma = 1.4826 * ...
    median(abs(residual - median(residual)));

robustSigma = max(robustSigma, 1e-10);

spikeCount = sum(abs(residual) > 4 * robustSigma);

% High-frequency fluctuation
shortSmooth = movmean(x, 7);

hfRatio = std(x - shortSmooth) / (std(x) + eps);

% Slow trend
trendWindow = max(1, round(fs));
trendWindow = min(trendWindow, length(x));

slowTrend = movmean(x, trendWindow);

trendRatio = std(slowTrend - mean(slowTrend)) ...
             / (std(x) + eps);

% Linear trend correlation
if std(t) > 0 && std(x) > 0
    trendCorr = corr(t(:), x(:), 'Rows', 'complete');
else
    trendCorr = 0;
end

if ~isfinite(trendCorr)
    trendCorr = 0;
end

% Random fluctuation score
randomScore = std(residual) / (std(x) + eps);

fprintf('\n=== Analysis Results ===\n');
fprintf('Spike count: %d\n', spikeCount);
fprintf('High-frequency ratio: %.3f\n', hfRatio);
fprintf('Trend ratio: %.3f\n', trendRatio);
fprintf('Trend correlation: %.3f\n', trendCorr);
fprintf('Random fluctuation score: %.3f\n', randomScore);

%% 3. AUTOMATIC FILTER SELECTION
filters = {};
reasons = {};

% Rule 1: Spike detection
if spikeCount >= 2
    filters{end+1} = 'Median';
    reasons{end+1} = 'Spike / outlier detected';
end

% Rule 2: Low-frequency drift
if trendRatio > 0.20 && abs(trendCorr) > 0.65
    filters{end+1} = 'High-pass';
    reasons{end+1} = 'Possible low-frequency drift';
end

% Rule 3: High-frequency noise
if hfRatio > 0.35
    filters{end+1} = 'Low-pass';
    reasons{end+1} = 'High-frequency fluctuation detected';
end

% Rule 4: Random fluctuation
if randomScore > 0.18 && hfRatio <= 0.45
    filters{end+1} = 'Moving Average';
    reasons{end+1} = 'Additional smoothing may be useful';
end

% Default filter
if isempty(filters)
    filters{end+1} = 'Moving Average';
    reasons{end+1} = 'Default smoothing filter';
end

%% 4. APPLY FILTERS
y = x;

for k = 1:length(filters)

    switch filters{k}

        case 'Median'
            y = medfilt1(y, 5);

        case 'High-pass'
            fc = min(0.5, 0.9 * nyquist);

            if fc > 0
                y = highpass(y, fc, fs);
            end

        case 'Low-pass'
            fc = min(5, 0.9 * nyquist);

            if fc > 0
                y = lowpass(y, fc, fs);
            end

        case 'Moving Average'
            y = movmean(y, 5);

    end
end

%% 5. DISPLAY FILTER SELECTION
fprintf('\n=== Selected Filter Sequence ===\n');

for k = 1:length(filters)
    fprintf('%d. %s -- %s\n', ...
        k, filters{k}, reasons{k});
end

fprintf('\nInput: %s\n', signalName);
fprintf('Number of filters: %d\n', length(filters));

%% 6. STANDARD DEVIATION ANALYSIS

% 1. SD before filtering
sd_raw = std(x);

% 2. SD after filtering
sd_filtered = std(y);

% 3. SD reduction (%)
sdReduction = (sd_raw - sd_filtered) / (sd_raw + eps) * 100;

fprintf('\n===== STANDARD DEVIATION RESULTS =====\n');
fprintf('SD before filtering : %.4f\n', sd_raw);
fprintf('SD after filtering  : %.4f\n', sd_filtered);
fprintf('SD reduction        : %.2f%%\n', sdReduction);

%% 7. FFT BEFORE AND AFTER FILTERING
N = length(x);

X = fft(x);
Y = fft(y);

halfN = floor(N/2) + 1;

f = (0:halfN-1) * (fs/N);

Xmag = abs(X(1:halfN)) / N;
Ymag = abs(Y(1:halfN)) / N;

% Single-sided amplitude spectrum
if rem(N, 2) == 0

    if halfN > 2
        Xmag(2:end-1) = 2 * Xmag(2:end-1);
        Ymag(2:end-1) = 2 * Ymag(2:end-1);
    end

else

    Xmag(2:end) = 2 * Xmag(2:end);
    Ymag(2:end) = 2 * Ymag(2:end);

end

%% 8. FIGURE 1: RAW SIGNAL
figure(1);
set(gcf, 'Name', 'RGB - Raw, Filtered and Comparison', ...
         'NumberTitle', 'off');

subplot(3, 1, 1);

plot(t, x, 'r', 'LineWidth', 1);

grid on;
title(['Input Signal: ' signalName]);
xlabel('Time (s)');
ylabel('Red Raw Value');

%% 9. FIGURE 1: FILTERED SIGNAL
subplot(3, 1, 2);

plot(t, y, 'b', 'LineWidth', 1.2);

grid on;
title(['Output after filtering: ' strjoin(filters, ' -> ')]);
xlabel('Time (s)');
ylabel('Filtered Red Value');

%% 10. FIGURE 1: COMPARISON
subplot(3, 1, 3);

% Raw signal: Gray
plot(t, x, 'Color', [0.7 0.7 0.7], 'LineWidth', 1);

hold on;

% Filtered signal: Blue
plot(t, y, 'b', 'LineWidth', 1.2);

hold off;
grid on;

title('Comparison: Raw vs Filtered Signal');
xlabel('Time (s)');
ylabel('Red Value');

legend('Raw', 'Filtered', 'Location', 'best');

sgtitle('TCS34725 RGB: Automatic Filtering System');

%% 11. FIGURE 2: FFT COMPARISON
figure(2);
set(gcf, 'Name', 'RGB - FFT Before and After Filtering', ...
         'NumberTitle', 'off');

% FFT before filtering: Red
plot(f, Xmag, 'r', 'LineWidth', 1);

hold on;

% FFT after filtering: Blue
plot(f, Ymag, 'b', 'LineWidth', 1.2);

hold off;
grid on;

title(sprintf('FFT: %s (%s)', ...
    signalName, strjoin(filters, ' -> ')));

xlabel('Frequency (Hz)');
ylabel('Magnitude');

legend('Before Filtering', 'After Filtering', ...
       'Location', 'best');

% Include 0 Hz
xlim([0 fs/2]);

sgtitle('TCS34725 RGB: FFT Before and After Filtering');

fprintf('\nAnalysis completed.\n');
