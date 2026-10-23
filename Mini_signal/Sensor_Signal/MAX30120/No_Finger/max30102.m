clc;
clear;
close all;

%% 1. LOAD CSV DATA
data = readtable("max30102_data.csv");
disp('Loaded Columns:');
disp(data.Properties.VariableNames);

% แปลงเวลาเป็นวินาที
t = data.Time_ms / 1000;
t = t - t(1); % ปรับเวลาเริ่มที่ 0 s

% สัญญาณ MAX30102
signals = {data.IR_Raw, data.Red_Raw};
signalNames = {'IR', 'Red'};

% คำนวณ Sampling Frequency
dt = median(diff(t));
if ~isfinite(dt) || dt <= 0
    error('ไม่สามารถคำนวณ Sampling Frequency ได้');
end
fs = 1 / dt;
fprintf('Sampling frequency: %.2f Hz\n', fs);

%% 2. CREATE FIGURE (3 Rows x 2 Columns)
figure('Name', 'MAX30102 Automatic Multi-Filtering System', 'NumberTitle', 'off');

for s = 1:length(signals)
    x = double(signals{s}(:));
    name = signalNames{s};
    
    % ลบค่าที่ไม่ถูกต้อง (NaN/Inf)
    valid = isfinite(t(:)) & isfinite(x);
    tv = t(valid);
    x = x(valid);
    
    fprintf('\n=== Analyzing Signal: %s ===\n', name);
    
    %% SIGNAL ANALYSIS
    localMedian = movmedian(x, 7);
    residual = x - localMedian;
    robustSigma = 1.4826 * median(abs(residual - median(residual)));
    robustSigma = max(robustSigma, 1e-10);
    spikeCount = sum(abs(residual) > 4 * robustSigma);
    
    shortSmooth = movmean(x, 7);
    hfRatio = std(x - shortSmooth) / (std(x) + eps);
    
    trendWindow = max(1, round(fs));
    slowTrend = movmean(x, trendWindow);
    trendRatio = std(slowTrend - mean(slowTrend)) / (std(x) + eps);
    
    trendCorr = corr(tv(:), x(:), 'Rows', 'complete');
    randomScore = std(residual) / (std(x) + eps);
    
    %% AUTOMATIC FILTER SELECTION
    filters = {};
    reasons = {};
    
    if spikeCount >= 2
        filters{end+1} = 'Median';
        reasons{end+1} = 'Spike/outlier detected';
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
        reasons{end+1} = 'Additional smoothing';
    end
    if isempty(filters)
        filters{end+1} = 'Moving Average';
        reasons{end+1} = 'Default smoothing';
    end
    
    %% APPLY FILTERS
    y = x;
    for k = 1:length(filters)
        switch filters{k}
            case 'Median'
                y = medfilt1(y, 5);
            case 'High-pass'
                cutoff = 0.5;
                if cutoff < fs/2, y = highpass(y, cutoff, fs); end
            case 'Low-pass'
                cutoff = 5;
                if cutoff < fs/2, y = lowpass(y, cutoff, fs); end
            case 'Moving Average'
                y = movmean(y, 5);
        end
    end
    
    %% DISPLAY SELECTION IN COMMAND WINDOW
    fprintf('Selected Filters for %s: %s\n', name, strjoin(filters, ' -> '));
    
    %% PLOT IN SUBPLOT (3 Rows x 2 Columns)
    % แถวที่ 1: Raw Signal (ตำแหน่ง 1 และ 2)
    subplot(3, 2, s);
    plot(tv, x, 'r', 'LineWidth', 1);
    grid on;
    title(['Raw Signal: ' name]);
    xlabel('Time (s)');
    ylabel('Raw value');
    
    % แถวที่ 2: Filtered Signal (ตำแหน่ง 3 และ 4)
    subplot(3, 2, s + 2);
    plot(tv, y, 'b', 'LineWidth', 1.2);
    grid on;
    title(['Filtered Signal (' name '): ' strjoin(filters, ' -> ')]);
    xlabel('Time (s)');
    ylabel('Filtered value');
    
    % แถวที่ 3: Overlay Comparison Signal (ตำแหน่ง 5 และ 6)
    subplot(3, 2, s + 4);
    plot(tv, x, 'Color', [0.7 0.7 0.7], 'LineWidth', 1); % สัญญาณดิบ (สีเทา)
    hold on;
    plot(tv, y, 'b', 'LineWidth', 1.2);                 % สัญญาณหลังกรอง (สีฟ้า)
    grid on;
    title(['Comparison (' name '): Raw vs Filtered']);
    xlabel('Time (s)');
    ylabel('Signal Value');
    legend('Raw', 'Filtered', 'Location', 'best');
    hold off;
    
end % ปิด loop for s = 1:length(signals)

sgtitle('MAX30102 Automatic Filtering System (IR vs Red)');