
clc;
clear;
close all;

%% 1. READ DATA FROM CSV
data = readtable("mpu6050_walk_data.csv");

disp('Loaded Columns:');
disp(data.Properties.VariableNames);

% Convert time to seconds
t = data.Time_ms / 1000;
t = t(:);
t = t - t(1);

dt = median(diff(t));

if ~isfinite(dt) || dt <= 0
    error('ไม่สามารถคำนวณ Sampling Frequency ได้');
end

fs = 1 / dt;
nyquist = fs / 2;

fprintf('Sampling frequency: %.2f Hz\n', fs);

% Axis names and units
axisNames = {'AccelX', 'AccelY', 'AccelZ', ...
             'GyroX', 'GyroY', 'GyroZ'};

axisUnits = {'m/s^2', 'm/s^2', 'm/s^2', ...
             'rad/s', 'rad/s', 'rad/s'};

% Prepare result storage
numAxes = length(axisNames);
results = cell(numAxes, 5);

%% 2. CREATE FIGURES
figure(1);
set(gcf, 'Name', 'MPU6050 Walking - Original vs Filtered', ...
         'NumberTitle', 'off');

figure(2);
set(gcf, 'Name', 'MPU6050 Walking - FFT Before vs After Filtering', ...
         'NumberTitle', 'off');

for idx = 1:numAxes

    colName = axisNames{idx};
    unitStr = axisUnits{idx};

    %% 3. PREPARE SIGNAL
    x = double(data.(colName));
    x = x(:);

    % Remove invalid values
    valid = isfinite(t) & isfinite(x);

    t_clean = t(valid);
    x_clean = x(valid);

    if length(x_clean) < 10
        warning('ข้อมูลของ %s น้อยเกินไป', colName);
        continue;
    end

    % Calculate sampling frequency for valid samples
    dtLocal = median(diff(t_clean));

    if ~isfinite(dtLocal) || dtLocal <= 0
        warning('ไม่สามารถคำนวณ Sampling Frequency ของ %s ได้', ...
                colName);
        continue;
    end

    fsLocal = 1 / dtLocal;
    nyquistLocal = fsLocal / 2;

    %% 4. CALCULATE SD BEFORE FILTERING
    sdBefore = std(x_clean);

    %% 5. SIGNAL ANALYSIS FOR AUTOMATIC FILTER SELECTION

    % Detect sudden outliers
    localMedian = movmedian(x_clean, 7);
    residual = x_clean - localMedian;

    robustSigma = 1.4826 * ...
        median(abs(residual - median(residual)));

    if robustSigma < 1e-10
        robustSigma = 1e-10;
    end

    spikeCount = sum(abs(residual) > 4 * robustSigma);

    % High-frequency fluctuation
    shortSmooth = movmean(x_clean, 7);

    hfRatio = std(x_clean - shortSmooth) ...
              / (std(x_clean) + eps);

    % Slow trend
    trendWindow = max(1, round(fsLocal));
    trendWindow = min(trendWindow, length(x_clean));

    slowTrend = movmean(x_clean, trendWindow);

    trendRatio = std(slowTrend - mean(slowTrend)) ...
                 / (std(x_clean) + eps);

    % Linear trend correlation
    if std(t_clean) > 0 && std(x_clean) > 0
        trendCorr = corr(t_clean, x_clean);
    else
        trendCorr = 0;
    end

    if ~isfinite(trendCorr)
        trendCorr = 0;
    end

    % Random fluctuation score
    randomScore = std(residual) / (std(x_clean) + eps);

    %% 6. AUTOMATIC FILTER SELECTION
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

    %% 7. APPLY FILTERS IN SELECTED ORDER
    y = x_clean;

    for k = 1:length(filters)

        switch filters{k}

            case 'Median'
                y = medfilt1(y, 5);

            case 'High-pass'
                fc = min(0.5, 0.9 * nyquistLocal);

                if fc > 0
                    y = highpass(y, fc, fsLocal);
                end

            case 'Low-pass'
                fc = min(5, 0.9 * nyquistLocal);

                if fc > 0
                    y = lowpass(y, fc, fsLocal);
                end

            case 'Moving Average'
                y = movmean(y, 5);

        end
    end

    %% 8. CALCULATE SD AFTER FILTERING AND SD REDUCTION
    sdAfter = std(y);

    % Percentage reduction in standard deviation
    sdReduction = (sdBefore - sdAfter) ...
                  / (sdBefore + eps) * 100;

    % Save results for summary table
    results(idx, :) = {colName, sdBefore, sdAfter, ...
                       sdReduction, strjoin(filters, ' -> ')};

    %% 9. FFT BEFORE AND AFTER FILTERING
    N = length(x_clean);

    X = fft(x_clean);
    Y = fft(y);

    halfN = floor(N/2) + 1;
    f = (0:halfN-1) * (fsLocal/N);

    Xmag = abs(X(1:halfN)) / N;
    Ymag = abs(Y(1:halfN)) / N;

    if rem(N, 2) == 0
        Xmag(2:end-1) = 2 * Xmag(2:end-1);
        Ymag(2:end-1) = 2 * Ymag(2:end-1);
    else
        Xmag(2:end) = 2 * Xmag(2:end);
        Ymag(2:end) = 2 * Ymag(2:end);
    end

    %% 10. PLOT ORIGINAL VS FILTERED SIGNAL
    figure(1);
    subplot(3, 2, idx);

    plot(t_clean, x_clean, ...
         'Color', [0.7 0.7 0.7], 'LineWidth', 0.8);

    hold on;
    plot(t_clean, y, 'b-', 'LineWidth', 1.2);
    hold off;

    grid on;

    title(sprintf('%s (%s)', ...
        colName, strjoin(filters, ' -> ')), ...
        'FontSize', 9);

    xlabel('Time (s)', 'FontSize', 8);
    ylabel(unitStr, 'FontSize', 8);

    legend('Original', 'Filtered', ...
           'FontSize', 7, 'Location', 'best');

    %% 11. PLOT FFT BEFORE VS AFTER FILTERING
    figure(2);
    subplot(3, 2, idx);

    % Display all frequencies, including 0 Hz
    plot(f, Xmag, 'r', 'LineWidth', 1);

    hold on;
    plot(f, Ymag, 'b', 'LineWidth', 1.2);
    hold off;

    grid on;

    title(sprintf('%s FFT (%s)', ...
        colName, strjoin(filters, ' -> ')), ...
        'FontSize', 9);

    xlabel('Frequency (Hz)');
    ylabel(['Magnitude (' unitStr ')']);

    legend('Before Filtering', 'After Filtering', ...
           'Location', 'best');

    xlim([0 fsLocal/2]);

    %% 12. DISPLAY RESULTS IN COMMAND WINDOW
    fprintf('\n=== Axis: %s ===\n', colName);
    fprintf('Spike count: %d\n', spikeCount);
    fprintf('High-frequency ratio: %.3f\n', hfRatio);
    fprintf('Trend ratio: %.3f\n', trendRatio);
    fprintf('Random fluctuation score: %.3f\n', randomScore);

    fprintf('Selected Filters: %s\n', ...
        strjoin(filters, ' -> '));

    for k = 1:length(filters)
        fprintf('  %s: %s\n', filters{k}, reasons{k});
    end

    fprintf('\n--- Standard Deviation Results ---\n');
    fprintf('SD Before Filtering : %.6f %s\n', ...
            sdBefore, unitStr);
    fprintf('SD After Filtering  : %.6f %s\n', ...
            sdAfter, unitStr);
    fprintf('SD Reduction        : %.2f%%\n', ...
            sdReduction);

end

%% 13. OVERALL FIGURE TITLES
figure(1);
sgtitle('MPU6050 Walking: Original vs Filtered Signals');

figure(2);
sgtitle('MPU6050 Walking: FFT Before and After Filtering');

%% 14. CREATE SUMMARY TABLE
validRows = ~cellfun(@isempty, results(:, 1));
resultsValid = results(validRows, :);

if ~isempty(resultsValid)

    resultTable = cell2table(resultsValid, ...
        'VariableNames', {'Axis', ...
                          'SD_Before', ...
                          'SD_After', ...
                          'SD_Reduction_Percent', ...
                          'Selected_Filters'});

    fprintf('\n\n========================================\n');
    fprintf(' MPU6050 STANDARD DEVIATION SUMMARY\n');
    fprintf('========================================\n');

    disp(resultTable);

    %% 15. EXPORT RESULTS TO CSV
    writetable(resultTable, 'MPU6050_SD_Results.csv');

    fprintf('Results saved to MPU6050_SD_Results.csv\n');

else
    warning('ไม่มีผลลัพธ์เพียงพอสำหรับสร้างตาราง');
end
