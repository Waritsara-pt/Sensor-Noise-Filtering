
clc;
clear;
close all;

%% 1. LOAD CSV DATA
data = readtable("max30102_data.csv");

disp('Loaded Columns:');
disp(data.Properties.VariableNames);

% Convert time to seconds
t = double(data.Time_ms(:)) / 1000;
t = t - t(1);

% MAX30102 signals
signals = {data.IR_Raw, data.Red_Raw};
signalNames = {'IR', 'Red'};

axisUnits = {'Raw value', 'Raw value'};

% Calculate sampling frequency
dt = median(diff(t));

if ~isfinite(dt) || dt <= 0
    error('ไม่สามารถคำนวณ Sampling Frequency ได้');
end

fs = 1 / dt;

fprintf('Sampling frequency: %.2f Hz\n', fs);

%% 2. CREATE FIGURES
figure(1);
set(gcf, ...
    'Name', 'MAX30102 - Original vs Filtered', ...
    'NumberTitle', 'off');

figure(2);
set(gcf, ...
    'Name', 'MAX30102 - FFT Before vs After Filtering', ...
    'NumberTitle', 'off');

%% 3. PROCESS IR AND RED
for s = 1:length(signals)

    name = signalNames{s};

    %% 3.1 PREPARE SIGNAL
    x = double(signals{s}(:));

    valid = isfinite(t) & isfinite(x);

    tv = t(valid);
    x = x(valid);

    if length(x) < 10
        warning('ข้อมูลของ %s น้อยเกินไป', name);
        continue;
    end

    % Local sampling frequency
    dtLocal = median(diff(tv));

    if ~isfinite(dtLocal) || dtLocal <= 0
        warning('ไม่สามารถคำนวณ Sampling Frequency ของ %s ได้', name);
        continue;
    end

    fsLocal = 1 / dtLocal;
    nyquistLocal = fsLocal / 2;

    %% 3.2 SIGNAL ANALYSIS

    % Detect spikes / outliers
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
    trendWindow = max(1, round(fsLocal));
    trendWindow = min(trendWindow, length(x));

    slowTrend = movmean(x, trendWindow);

    trendRatio = std(slowTrend - mean(slowTrend)) ...
                 / (std(x) + eps);

    % Linear trend correlation
    if std(tv) > 0 && std(x) > 0
        trendCorr = corr(tv(:), x(:), 'Rows', 'complete');
    else
        trendCorr = 0;
    end

    if ~isfinite(trendCorr)
        trendCorr = 0;
    end

    % Random fluctuation score
    randomScore = std(residual) / (std(x) + eps);

    %% 3.3 AUTOMATIC FILTER SELECTION
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

    %% 3.4 APPLY FILTERS
    y = x;

    for k = 1:length(filters)

        switch filters{k}

            case 'Median'
                y = medfilt1(y, 5);

            case 'High-pass'
                cutoff = min(0.5, 0.9 * nyquistLocal);

                if cutoff > 0
                    y = highpass(y, cutoff, fsLocal);
                end

            case 'Low-pass'
                cutoff = min(5, 0.9 * nyquistLocal);

                if cutoff > 0
                    y = lowpass(y, cutoff, fsLocal);
                end

            case 'Moving Average'
                y = movmean(y, 5);

        end
    end

    %% 3.5 FFT BEFORE AND AFTER FILTERING
    N = length(x);

    X = fft(x);
    Y = fft(y);

    halfN = floor(N/2) + 1;

    f = (0:halfN-1) * (fsLocal/N);

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

    %% 4. FIGURE 1: RAW SIGNAL
    figure(1);

    % Row 1: Raw signals
    subplot(3, 2, s);

    plot(tv, x, 'r', 'LineWidth', 1);

    grid on;
    title(['Raw Signal: ' name]);
    xlabel('Time (s)');
    ylabel(axisUnits{s});

    %% 5. FIGURE 1: FILTERED SIGNAL
    % Row 2: Filtered signals
    subplot(3, 2, s + 2);

    plot(tv, y, 'b', 'LineWidth', 1.2);

    grid on;

    title(sprintf('Filtered Signal (%s): %s', ...
        name, strjoin(filters, ' -> ')));

    xlabel('Time (s)');
    ylabel(axisUnits{s});

    %% 6. FIGURE 1: RAW VS FILTERED COMPARISON
    % Row 3: Overlay comparison
    subplot(3, 2, s + 4);

    % Raw signal: Gray
    plot(tv, x, ...
        'Color', [0.7 0.7 0.7], ...
        'LineWidth', 1);

    hold on;

    % Filtered signal: Blue
    plot(tv, y, 'b', 'LineWidth', 1.2);

    hold off;
    grid on;

    title(['Comparison: ' name]);
    xlabel('Time (s)');
    ylabel(axisUnits{s});

    legend('Raw', 'Filtered', 'Location', 'best');

    %% 7. FIGURE 2: FFT COMPARISON
    figure(2);

    subplot(1, 2, s);

    % Before filtering: Red
    plot(f, Xmag, 'r', 'LineWidth', 1);

    hold on;

    % After filtering: Blue
    plot(f, Ymag, 'b', 'LineWidth', 1.2);

    hold off;
    grid on;

    title(sprintf('%s FFT (%s)', ...
        name, strjoin(filters, ' -> ')));

    xlabel('Frequency (Hz)');
    ylabel('Magnitude');

    legend('Before Filtering', 'After Filtering', ...
        'Location', 'best');

    % Include 0 Hz
    xlim([0 fsLocal/2]);

    %% 8. DISPLAY RESULTS
    fprintf('\n=== Signal: %s ===\n', name);
    fprintf('Sampling Frequency: %.2f Hz\n', fsLocal);
    fprintf('Spike count: %d\n', spikeCount);
    fprintf('High-frequency ratio: %.3f\n', hfRatio);
    fprintf('Trend ratio: %.3f\n', trendRatio);
    fprintf('Trend correlation: %.3f\n', trendCorr);
    fprintf('Random fluctuation score: %.3f\n', randomScore);

    fprintf('Selected Filters: %s\n', ...
        strjoin(filters, ' -> '));

    for k = 1:length(filters)
        fprintf('  %s: %s\n', filters{k}, reasons{k});
    end

end

%% 9. OVERALL FIGURE TITLES
figure(1);
sgtitle('MAX30102: Raw, Filtered and Comparison Signals (IR and Red)');

figure(2);
sgtitle('MAX30102: FFT Before and After Filtering (IR and Red)');
