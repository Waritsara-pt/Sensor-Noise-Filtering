
clc;
clear;
close all;

%% 1. INPUT SIGNAL

fs = 100;
t = 0:1/fs:9.99;
N = length(t);

rng(1);

%% PREPARE STORAGE FOR ALL 6 CASES

caseNames = strings(6,1);
filterNames = strings(6,1);
mseBefore = zeros(6,1);
mseAfter = zeros(6,1);
mseReduction = zeros(6,1);

%% PROCESS ALL 6 SIGNAL CASES

for choice = 1:6

    %% CREATE SIGNAL

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

    trendCorr = corr(t(:), x(:));

    % Estimate random fluctuation
    randomScore = std(residual) / (std(x) + eps);

    fprintf('\n========================================\n');
    fprintf('Signal Case %d: %s\n', choice, signalName);
    fprintf('========================================\n');

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

        % Fallback filter
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

    %% 5. CALCULATE MSE

    % MSE before filtering
    mseBefore(choice) = mean((s - x).^2);

    % MSE after filtering
    mseAfter(choice) = mean((s - y).^2);

    % Percentage reduction in MSE
    if mseBefore(choice) > 0
        mseReduction(choice) = ...
            (mseBefore(choice) - mseAfter(choice)) ...
            / mseBefore(choice) * 100;
    else
        mseReduction(choice) = NaN;
    end

    % Store case name and selected filters
    caseNames(choice) = string(signalName);
    filterNames(choice) = string(strjoin(filters, ' -> '));

    %% 6. DISPLAY FILTER SELECTION

    fprintf('\nSelected Filter Sequence:\n');

    for k = 1:length(filters)
        fprintf('%d. %s -- %s\n', ...
            k, filters{k}, reasons{k});
    end

    fprintf('Number of filters: %d\n', length(filters));
    fprintf('MSE Before Filtering: %.6f\n', mseBefore(choice));
    fprintf('MSE After Filtering: %.6f\n', mseAfter(choice));
    fprintf('MSE Reduction: %.2f%%\n', mseReduction(choice));

    %% 7. FREQUENCY SPECTRUM USING FFT

    X = fft(x);
    Y = fft(y);

    halfN = floor(N/2) + 1;
    f = (0:halfN-1) * (fs/N);

    % One-sided amplitude spectrum
    Xmag = abs(X(1:halfN)) / N;
    Ymag = abs(Y(1:halfN)) / N;

    if rem(N, 2) == 0
        Xmag(2:end-1) = 2 * Xmag(2:end-1);
        Ymag(2:end-1) = 2 * Ymag(2:end-1);
    else
        Xmag(2:end) = 2 * Xmag(2:end);
        Ymag(2:end) = 2 * Ymag(2:end);
    end

    %% 8. PLOT RESULTS

    figure('Name', sprintf('Signal Case %d', choice));

    % Plot 1: Input signal
    subplot(2,2,1);
    plot(t, x, 'r');
    grid on;
    title(['Input Signal: ' signalName]);
    xlabel('Time (s)');
    ylabel('Amplitude');

    % Plot 2: Filtered output
    subplot(2,2,2);
    plot(t, y, 'b', 'LineWidth', 1.2);
    grid on;
    title(['Filtered: ' strjoin(filters, ' -> ')]);
    xlabel('Time (s)');
    ylabel('Amplitude');

    % Plot 3: Frequency spectrum
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
    plot(t, y, 'b', 'LineWidth', 1.2);
    hold off;
    grid on;
    title(['Raw vs Filtered: ' signalName]);
    xlabel('Time (s)');
    ylabel('Amplitude');
    legend('Raw Signal', 'Filtered Signal');

    sgtitle(sprintf('Automatic Multi-Filter System - Case %d', choice));

end  % End of processing loop

%% 9. MSE PERFORMANCE SUMMARY TABLE

Results = table( ...
    caseNames, ...
    filterNames, ...
    mseBefore, ...
    mseAfter, ...
    mseReduction, ...
    'VariableNames', { ...
        'SignalCase', ...
        'SelectedFilters', ...
        'MSE_Before', ...
        'MSE_After', ...
        'MSE_Reduction_Percent'});

fprintf('\n\n========================================\n');
fprintf('MSE PERFORMANCE SUMMARY\n');
fprintf('========================================\n');

disp(Results);

%% 10. EXPORT RESULTS TO CSV

writetable(Results, 'MSE_Results.csv');

fprintf('Results saved to MSE_Results.csv\n');
