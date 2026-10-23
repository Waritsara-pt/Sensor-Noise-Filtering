clc;
clear;
close all;

%% 1. READ DATA FROM CSV
data = readtable("mpu6050_data.csv");
disp('Loaded Columns:');
disp(data.Properties.VariableNames);

% ดึงเวลาและแปลงเป็นวินาที
t = data.Time_ms / 1000;
t = t(:);
t = t - t(1); % ปรับเวลาเริ่มที่ 0

dt = median(diff(t));
if ~isfinite(dt) || dt <= 0
    error('ไม่สามารถคำนวณ Sampling Frequency ได้');
end
fs = 1 / dt;
nyquist = fs / 2;

% รายชื่อคอลัมน์ทั้ง 6 แกนและหน่วย
axisNames = {'AccelX', 'AccelY', 'AccelZ', 'GyroX', 'GyroY', 'GyroZ'};
axisUnits = {'m/s^2', 'm/s^2', 'm/s^2', 'rad/s', 'rad/s', 'rad/s'};

%% 2. PROCESS AND PLOT ALL 6 AXES
figure('Name', 'Automatic Multi-Filter System (All 6 Axes)', 'NumberTitle', 'off');

for idx = 1:length(axisNames)
    colName = axisNames{idx};
    unitStr = axisUnits{idx};
    
    % ดึงข้อมูลสัญญาณของแกนปัจจุบัน
    x = data.(colName);
    x = x(:);
    
    % ลบข้อมูลที่ไม่ใช่ตัวเลข (NaN/Inf)
    valid = isfinite(t) & isfinite(x);
    t_clean = t(valid);
    x_clean = x(valid);
    
    if length(x_clean) < 10
        continue;
    end
    
    %% SIGNAL ANALYSIS
    % 1. Detect sudden outliers
    localMedian = movmedian(x_clean, 7);
    residual = x_clean - localMedian;
    robustSigma = 1.4826 * median(abs(residual - median(residual)));
    if robustSigma < 1e-10
        robustSigma = 1e-10;
    end
    spikeCount = sum(abs(residual) > 4 * robustSigma);
    
    % 2. High-frequency fluctuation
    shortSmooth = movmean(x_clean, 7);
    hfRatio = std(x_clean - shortSmooth) / (std(x_clean) + eps);
    
    % 3. Slow trend
    trendWindow = max(1, round(fs));
    trendWindow = min(trendWindow, length(x_clean));
    slowTrend = movmean(x_clean, trendWindow);
    trendRatio = std(slowTrend - mean(slowTrend)) / (std(x_clean) + eps);
    
    % 4. Linear trend correlation
    if std(t_clean) > 0 && std(x_clean) > 0
        trendCorr = corr(t_clean, x_clean);
    else
        trendCorr = 0;
    end
    
    % 5. Random fluctuation score
    randomScore = std(residual) / (std(x_clean) + eps);
    
    %% AUTOMATIC FILTER SELECTION
    filters = {};
    reasons = {};
    
    if spikeCount >= 2
        filters{end+1} = 'Median';
        reasons{end+1} = 'Spike / outlier detected';
    end
    if trendRatio > 0.20 && abs(trendCorr) > 0.65
        filters{end+1} = 'High-pass';
        reasons{end+1} = 'Low-frequency drift';
    end
    if hfRatio > 0.35
        filters{end+1} = 'Low-pass';
        reasons{end+1} = 'High-frequency noise';
    end
    if randomScore > 0.18 && hfRatio <= 0.45
        filters{end+1} = 'Moving Average';
        reasons{end+1} = 'Random fluctuation';
    end
    if isempty(filters)
        filters{end+1} = 'Moving Average';
        reasons{end+1} = 'Default smoothing';
    end
    
    %% APPLY FILTERS IN SELECTED ORDER
    y = x_clean;
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
    
    %% PLOT RESULTS (3x2 Subplot Layout)
    subplot(3, 2, idx);
    plot(t_clean, x_clean, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.8); % สัญญาณดิบ
    hold on;
    plot(t_clean, y, 'b-', 'LineWidth', 1.2);                        % สัญญาณหลังกรอง
    grid on;
    
    titleStr = sprintf('%s (%s)', colName, strjoin(filters, ' -> '));
    title(titleStr, 'FontSize', 9);
    xlabel('Time (s)', 'FontSize', 8);
    ylabel(unitStr, 'FontSize', 8);
    legend('Original', 'Filtered', 'FontSize', 7, 'Location', 'best');
    hold off;
    
    % แสดงผลสรุปใน Command Window
    fprintf('\n=== Axis: %s ===\n', colName);
    fprintf('Selected Filters: %s\n', strjoin(filters, ' -> '));
end

sgtitle('Automatic Multi-Filter Selection System (6-Axis IMU Data)');