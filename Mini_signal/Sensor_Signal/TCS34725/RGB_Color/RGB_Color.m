clc;
clear;
close all;

%% 1. READ DATA FROM CSV
data = readtable("RGB_Color.csv");

disp('Loaded Columns:');
disp(data.Properties.VariableNames);
disp(head(data));

% แปลงเวลาเป็นวินาที
t = data.Time_ms / 1000;
t = t(:);

% ดึงค่าสีทั้ง 3 แกน
r = double(data.Red(:));
g = double(data.Green(:));
b = double(data.Blue(:));

% ลบข้อมูลที่ไม่ใช่ตัวเลข (NaN/Inf)
valid = isfinite(t) & isfinite(r) & isfinite(g) & isfinite(b);
t = t(valid);
r = r(valid);
g = g(valid);
b = b(valid);

% ปรับเวลาเริ่มต้นที่ 0
t = t - t(1);

% ตัดเวลาที่ซ้ำเพื่อคำนวณ Sampling Frequency
[t, idx] = unique(t, 'stable');
r = r(idx);
g = g(idx);
b = b(idx);

if length(t) < 10
    error('ข้อมูลมีน้อยเกินไป');
end

% คำนวณ Sampling Frequency
dt = median(diff(t));
if ~isfinite(dt) || dt <= 0
    error('ไม่สามารถคำนวณ Sampling Frequency ได้');
end
fs = 1 / dt;

fprintf('Number of samples: %d\n', length(t));
fprintf('Sampling frequency: %.3f Hz\n', fs);

%% รวมสัญญาณ 3 สีเป็นสัญญาณเดียว (Luminance Signal)
x = 0.299 * r + 0.587 * g + 0.114 * b;
signalName = 'TCS34725 Combined Luminance (RGB)';

%% 2. SIGNAL ANALYSIS
localMedian = movmedian(x, 7);
residual = x - localMedian;
robustSigma = 1.4826 * median(abs(residual - median(residual)));
if robustSigma < 1e-10
    robustSigma = 1e-10;
end
spikeCount = sum(abs(residual) > 4 * robustSigma);

shortSmooth = movmean(x, 7);
hfRatio = std(x - shortSmooth) / (std(x) + eps);

trendWindow = max(1, round(fs));
trendWindow = min(trendWindow, length(x));
slowTrend = movmean(x, trendWindow);
trendRatio = std(slowTrend - mean(slowTrend)) / (std(x) + eps);

if std(t) > 0 && std(x) > 0
    trendCorr = corr(t(:), x(:));
else
    trendCorr = 0;
end

randomScore = std(residual) / (std(x) + eps);

fprintf('\n=== Analysis Results ===\n');
fprintf('Spike count: %d\n', spikeCount);
fprintf('High-frequency ratio: %.3f\n', hfRatio);
fprintf('Trend ratio: %.3f\n', trendRatio);
fprintf('Random fluctuation score: %.3f\n', randomScore);

%% 3. AUTOMATIC FILTER SELECTION
filters = {};
reasons = {};

if spikeCount >= 2
    filters{end+1} = 'Median';
    reasons{end+1} = 'Spike / outlier detected';
end
if trendRatio > 0.20 && abs(trendCorr) > 0.65
    filters{end+1} = 'High-pass';
    reasons{end+1} = 'Possible low-frequency drift';
end
if hfRatio > 0.35
    filters{end+1} = 'Low-pass';
    reasons{end+1} = 'High-frequency fluctuation detected';
end
if randomScore > 0.18 && hfRatio <= 0.45
    filters{end+1} = 'Moving Average';
    reasons{end+1} = 'Additional smoothing may be useful';
end
if isempty(filters)
    filters{end+1} = 'Moving Average';
    reasons{end+1} = 'Default smoothing filter';
end

%% 4. APPLY FILTERS
y = x;
nyquist = fs / 2;

for k = 1:length(filters)
    switch filters{k}
        case 'Median'
            y = medfilt1(y, 5);
        case 'High-pass'
            fc = min(0.5, 0.9 * nyquist);
            if fc > 0, y = highpass(y, fc, fs); end
        case 'Low-pass'
            fc = min(5, 0.9 * nyquist);
            if fc > 0, y = lowpass(y, fc, fs); end
        case 'Moving Average'
            y = movmean(y, 5);
    end
end

%% 5. DISPLAY SELECTION
fprintf('\n=== Selected Filter Sequence ===\n');
for k = 1:length(filters)
    fprintf('%d. %s -- %s\n', k, filters{k}, reasons{k});
end

%% 6. PLOT RESULTS (3 Subplots)
figure('Name', 'Automatic Multi-Filter System (Combined Signal)');

% Subplot 1: สัญญาณรวมดิบก่อนกรอง (เปลี่ยนเป็นสีแดง 'r')
subplot(3, 1, 1);
plot(t, x, 'r', 'LineWidth', 1);
grid on;
title(['Input Signal: ' signalName]);
xlabel('Time (s)');
ylabel('Combined Value');

% Subplot 2: สัญญาณรวมหลังกรอง
subplot(3, 1, 2);
plot(t, y, 'b', 'LineWidth', 1.2);
grid on;
title(['Output after filtering: ' strjoin(filters, ' -> ')]);
xlabel('Time (s)');
ylabel('Filtered Value');

% Subplot 3: กราฟเปรียบเทียบก่อนกรองกับหลังกรอง
subplot(3, 1, 3);
plot(t, x, 'Color', [0.7 0.7 0.7], 'LineWidth', 1); % สัญญาณดิบสีเทา
hold on;
plot(t, y, 'b', 'LineWidth', 1.2);                 % สัญญาณหลังกรองสีฟ้า
grid on;
title('Comparison: Raw Combined vs Filtered Signal');
xlabel('Time (s)');
ylabel('Signal Value');
legend('Raw Combined', 'Filtered', 'Location', 'best');
hold off;

sgtitle('Automatic Multi-Filter Selection System');