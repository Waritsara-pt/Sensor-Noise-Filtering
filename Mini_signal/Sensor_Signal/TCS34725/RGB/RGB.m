clc;
clear;
close all;

%% 1. READ DATA FROM CSV
% อ่านข้อมูลจากไฟล์ CSV
data = readtable("RGB.csv");

% แสดงชื่อคอลัมน์และข้อมูลตัวอย่าง
disp('Loaded Columns:');
disp(data.Properties.VariableNames);
disp(head(data));

% แยกเวลาและค่าสี Red
t = data.Time_ms / 1000;
x = data.Red;

% แปลงเป็นเวกเตอร์แนวตั้ง
t = t(:);
x = x(:);

% ลบข้อมูลที่ไม่ใช่ตัวเลข
valid = isfinite(t) & isfinite(x);
t = t(valid);
x = x(valid);

% ตรวจสอบจำนวนข้อมูล
if length(x) < 10
    error('ข้อมูลมีน้อยเกินไป');
end

% ปรับเวลาให้เริ่มต้นที่ 0
t = t - t(1);

% ลบแถวที่เวลาซ้ำ เพื่อคำนวณ Sampling Frequency
[ t, idx ] = unique(t, 'stable');
x = x(idx);

if length(t) < 10
    error('ข้อมูลเวลาที่ไม่ซ้ำกันมีน้อยเกินไป');
end

% คำนวณ Sampling Frequency
dt = median(diff(t));
if ~isfinite(dt) || dt <= 0
    error('ไม่สามารถคำนวณ Sampling Frequency ได้');
end
fs = 1 / dt;

fprintf('Number of samples: %d\n', length(x));
fprintf('Sampling frequency: %.3f Hz\n', fs);

% กำหนดชื่อสัญญาณ
signalName = 'TCS34725 RGB';

%% 2. SIGNAL ANALYSIS
% Detect sudden outliers
localMedian = movmedian(x, 7);
residual = x - localMedian;
robustSigma = 1.4826 * median(abs(residual - median(residual)));
if robustSigma < 1e-10
    robustSigma = 1e-10;
end
spikeCount = sum(abs(residual) > 4 * robustSigma);

% Estimate high-frequency fluctuation
shortSmooth = movmean(x, 7);
hfRatio = std(x - shortSmooth) / (std(x) + eps);

% Estimate slow trend
trendWindow = max(1, round(fs));
trendWindow = min(trendWindow, length(x));
slowTrend = movmean(x, trendWindow);
trendRatio = std(slowTrend - mean(slowTrend)) / (std(x) + eps);

p = polyfit(t, x, 1);
if std(t) > 0 && std(x) > 0
    trendCorr = corr(t(:), x(:));
else
    trendCorr = 0;
end

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

% Fallback when no rule is triggered
if isempty(filters)
    filters{end+1} = 'Moving Average';
    reasons{end+1} = 'Default smoothing filter';
end

%% 4. APPLY FILTERS IN SELECTED ORDER
y = x;
nyquist = fs / 2;

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

%% 5. DISPLAY SELECTION
fprintf('\n=== Selected Filter Sequence ===\n');
for k = 1:length(filters)
    fprintf('%d. %s -- %s\n', k, filters{k}, reasons{k});
end
fprintf('\nInput: %s\n', signalName);
fprintf('Number of filters: %d\n', length(filters));

%% 6. PLOT RESULTS (3 Subplots)
figure('Name', 'Automatic Multi-Filter System');

% Subplot 1: สัญญาณก่อนกรอง (Raw)
subplot(3, 1, 1);
plot(t, x, 'r', 'LineWidth', 1); % ใช้สีแดง 'r' เพื่อความเข้ากันได้กับทุกเวอร์ชัน
grid on;
title(['Input Signal: ' signalName]);
xlabel('Time (s)');
ylabel('Red Raw Value');

% Subplot 2: สัญญาณหลังกรอง (Filtered)
subplot(3, 1, 2);
plot(t, y, 'b', 'LineWidth', 1.2);
grid on;
title(['Output after filtering: ' strjoin(filters, ' -> ')]);
xlabel('Time (s)');
ylabel('Filtered Red Value');

% Subplot 3: กราฟเปรียบเทียบก่อนกรองกับหลังกรอง (Comparison)
subplot(3, 1, 3);
plot(t, x, 'Color', [0.7 0.7 0.7], 'LineWidth', 1); % สีเทา [0.7 0.7 0.7]
hold on;
plot(t, y, 'b', 'LineWidth', 1.2);                 % สีฟ้า 'b'
grid on;
title('Comparison: Raw vs Filtered Signal');
xlabel('Time (s)');
ylabel('Red Value');
legend('Raw', 'Filtered', 'Location', 'best');
hold off;

sgtitle('Automatic Multi-Filter Selection System');