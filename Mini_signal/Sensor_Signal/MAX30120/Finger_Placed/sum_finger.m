
clc;
clear;
close all;

%% 1. LOAD CSV DATA
data = readtable("max30102_Monitoring_data.csv");

disp('Loaded Columns:');
disp(data.Properties.VariableNames);

% Check required columns
requiredColumns = {'Time_ms', 'IR_Raw', 'Red_Raw'};

if ~all(ismember(requiredColumns, data.Properties.VariableNames))
    error('CSV ต้องมีคอลัมน์ Time_ms, IR_Raw และ Red_Raw');
end

%% 2. CONVERT TIME AND PREPARE SIGNALS
t = double(data.Time_ms(:)) / 1000;

signals = {data.IR_Raw, data.Red_Raw};
signalNames = {'IR', 'Red'};

%% 3. CALCULATE SAMPLING FREQUENCY
% ตรวจสอบเวลาและลบเวลาที่ซ้ำก่อนคำนวณ fs
validTime = isfinite(t);
t = t(validTime);

if length(t) < 10
    error('ข้อมูลเวลามีน้อยเกินไป');
end

[t, timeIdx] = unique(t, 'stable');

if length(t) < 10
    error('ข้อมูลเวลาที่ไม่ซ้ำกันมีน้อยเกินไป');
end

t = t - t(1);

dt = median(diff(t));

if ~isfinite(dt) || dt <= 0
    error('ไม่สามารถคำนวณ Sampling Frequency ได้');
end

fs = 1 / dt;
fprintf('Sampling frequency: %.2f Hz\n', fs);

%% 4. CREATE FIGURE (4 ROWS x 2 COLUMNS)
figure('Name', 'MAX30102 Filtering and Frequency Spectrum', ...
    'NumberTitle', 'off', ...
    'Position', [100 50 1200 850], ...
    'Color', 'w');

% Store results for IR and Red
results = cell(length(signals), 5);

for s = 1:length(signals)

    %% 5. PREPARE SIGNAL
    xAll = double(signals{s}(:));

    % ใช้แถวที่มีเวลาและสัญญาณถูกต้อง
    validSignal = isfinite(double(data.Time_ms(:))) & ...
                  isfinite(xAll);

    tSignal = double(data.Time_ms(validSignal)) / 1000;
    x = xAll(validSignal);

    % Remove duplicate timestamps using the first occurrence
    [tSignal, idx] = unique(tSignal, 'stable');
    x = x(idx);

    % Set start time to zero
    tSignal = tSignal - tSignal(1);

    N = length(x);
    name = signalNames{s};

    if N < 10
        warning('ข้อมูล %s มีน้อยเกินไป', name);
        continue;
    end

    fprintf('\n=== Analyzing Signal: %s ===\n', name);

    %% 6. SIGNAL ANALYSIS

    % Detect spikes / outliers
    localMedian = movmedian(x, 7);
    residual = x - localMedian;

    robustSigma = 1.4826 * ...
        median(abs(residual - median(residual)));

    robustSigma = max(robustSigma, 1e-10);

    spikeCount = sum(abs(residual) > 4 * robustSigma);

    % Estimate high-frequency fluctuation
    shortSmooth = movmean(x, 7);
    hfRatio = std(x - shortSmooth) / (std(x) + eps);

    % Estimate slow trend
    trendWindow = max(1, min(round(fs), N));
    slowTrend = movmean(x, trendWindow);

    trendRatio = std(slowTrend - mean(slowTrend)) ...
        / (std(x) + eps);

    % Correlation with time
    if std(tSignal) > 0 && std(x) > 0
        trendCorr = corr(tSignal(:), x(:), ...
            'Rows', 'complete');
    else
        trendCorr = 0;
    end

    if ~isfinite(trendCorr)
        trendCorr = 0;
    end

    % Estimate random fluctuation
    randomScore = std(residual) / (std(x) + eps);

    fprintf('Spike count: %d\n', spikeCount);
    fprintf('High-frequency ratio: %.4f\n', hfRatio);
    fprintf('Trend ratio: %.4f\n', trendRatio);
    fprintf('Random fluctuation score: %.4f\n', randomScore);

    %% 7. AUTOMATIC FILTER SELECTION
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

    %% 8. APPLY FILTERS
    y = x;
    nyquist = fs / 2;

    for k = 1:length(filters)

        switch filters{k}

            case 'Median'
                y = medfilt1(y, 5);

            case 'High-pass'
                cutoff = min(0.5, 0.9 * nyquist);

                if cutoff > 0
                    y = highpass(y, cutoff, fs);
                end

            case 'Low-pass'
                cutoff = min(5, 0.9 * nyquist);

                if cutoff > 0
                    y = lowpass(y, cutoff, fs);
                end

            case 'Moving Average'
                y = movmean(y, 5);

        end
    end

    fprintf('\nSelected Filters for %s: %s\n', ...
        name, strjoin(filters, ' -> '));

    for k = 1:length(filters)
        fprintf('%d. %s -- %s\n', ...
            k, filters{k}, reasons{k});
    end

    %% 9. STANDARD DEVIATION ANALYSIS

    % 1. SD before filtering
    SD_Before = std(x);

    % 2. SD after filtering
    SD_After = std(y);

    % 3. SD reduction (%)
    SD_Reduction = ...
        (SD_Before - SD_After) / (SD_Before + eps) * 100;

    fprintf('\n===== %s STANDARD DEVIATION =====\n', name);
    fprintf('SD before filtering : %.4f\n', SD_Before);
    fprintf('SD after filtering  : %.4f\n', SD_After);
    fprintf('SD reduction        : %.2f%%\n', SD_Reduction);

    %% 10. FREQUENCY SPECTRUM USING FFT
    N = length(x);

    X = fft(x);
    Y = fft(y);

    halfN = floor(N/2) + 1;
    f = (0:halfN-1)' * (fs/N);

    Xmag = abs(X(1:halfN)) / N;
    Ymag = abs(Y(1:halfN)) / N;

    % Single-sided amplitude spectrum
    if rem(N, 2) == 0
        if halfN > 2
            Xmag(2:end-1) = 2 * Xmag(2:end-1);
            Ymag(2:end-1) = 2 * Ymag(2:end-1);
        end
    else
        if halfN > 1
            Xmag(2:end) = 2 * Xmag(2:end);
            Ymag(2:end) = 2 * Ymag(2:end);
        end
    end

    %% 11. STORE RESULTS
    results(s,:) = {name, SD_Before, SD_After, ...
        SD_Reduction, strjoin(filters, ' -> ')};

    %% 12. PLOT RAW SIGNAL
    subplot(4, 2, s);

    plot(tSignal, x, 'Color', '#880e4f', 'LineWidth', 1);
    grid on;
    title(['Raw Signal: ' name]);
    xlabel('Time (s)');
    ylabel('Raw value');

    %% 13. PLOT FILTERED SIGNAL
    subplot(4, 2, s+2);

    plot(tSignal, y, 'b', 'LineWidth', 1.2);
    grid on;
    title(['Filtered Signal: ' name]);
    xlabel('Time (s)');
    ylabel('Filtered value');

    %% 14. PLOT RAW VS FILTERED
    subplot(4, 2, s+4);

    plot(tSignal, x, 'Color', [0.7 0.7 0.7], ...
        'LineWidth', 1);

    hold on;
    plot(tSignal, y, 'b', 'LineWidth', 1.2);
    hold off;

    grid on;
    title(sprintf('%s: Raw vs Filtered', name));
    xlabel('Time (s)');
    ylabel('Signal value');
    legend('Raw', 'Filtered', 'Location', 'best');

    %% 15. PLOT FREQUENCY SPECTRUM
    subplot(4, 2, s+6);

    plot(f, Xmag, 'r', 'LineWidth', 1);
    hold on;
    plot(f, Ymag, 'b', 'LineWidth', 1.2);
    hold off;

    grid on;
    title(['Frequency Spectrum: ' name]);
    xlabel('Frequency (Hz)');
    ylabel('Magnitude');

    legend('Before Filtering', 'After Filtering', ...
        'Location', 'best');

    xlim([0 fs/2]);

end

sgtitle('MAX30102 Automatic Filtering and Frequency Analysis');

%% 16. DISPLAY STANDARD DEVIATION RESULTS TABLE
ResultsTable = cell2table(results, ...
    'VariableNames', {'Sensor', ...
    'SD_Before', ...
    'SD_After', ...
    'SD_Reduction_Percent', ...
    'Selected_Filters'});

disp(' ');
disp('===== MAX30102 STANDARD DEVIATION RESULTS =====');
disp(ResultsTable);

%% 17. EXPORT RESULTS TO CSV
writetable(ResultsTable, 'MAX30102_SD_Results.csv');

fprintf('\nResults saved to MAX30102_SD_Results.csv\n');
