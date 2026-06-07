%{
    Date: Oct 22, 2023

    Compute summed log likelihood for each subject given subject data.
    Given each subject's response, find the corresponding probability.

    Input:
        AllSubj_cell: 1 x 18 subject cells, each {20 trials × 12 stimulus × 3 types}
        InputData: prior, xstimulus, xrad

    Apply the function to each element, then sum together.

    1. Mean and std for each subject.
    2. Log likelihood for each subject.
    3. Sum the log likelihood to optimize.
%}

%%
% Default figure settings
set(groot, 'DefaultLineLineWidth', 2);
set(groot, 'DefaultAxesFontSize', 30, 'DefaultAxesFontname', 'Times New Roman')
set(groot, 'defaultfigurecolor', 'white', 'defaultAxesTitleFontWeight', 'normal')


% Load data
BasicData_file = 'stimulus_grid.mat';
PriorData_file = 'PriorFrom_Crane2012.mat';
AllSubj_cell_FileName = 'AllSubj_cell.mat';
AllSubjData_file = 'AllSubj_mean_std.mat';

FullName_Basic = fullfile(BasicData_file);
FullName_Prior = fullfile(PriorData_file);
FullName_AllSubj = fullfile(AllSubj_cell_FileName);
FullName_AllSubjData = fullfile(AllSubjData_file);

load(FullName_Basic, 'x_stimulus_deg', 'xx_deg', 'xx_rad', 'x_stimulus_deg', 'xx_deg', 'xx_rad')
load(FullName_Prior, 'Prior_Crane2012')
load(FullName_AllSubj, 'AllSubj_cell')
load(FullName_AllSubjData, 'AllSubj_rad', 'AllSubj_std_rad')

% Initial parameters
fit_param_initial = [14.8448, 0.6802, 0.9349, 1.0503];

% Fit the parameter
BasicData.x_stimulus_deg = x_stimulus_deg;
BasicData.xx_rad = xx_rad;
BasicData.prior = Prior_Crane2012;

options = optimset('PlotFcns', @optimplotfval, 'TolX', 1e-10, 'TolFun', 1e-10, 'Display', 'off');
best_parm = fminsearch(@(Unknown_parm) fun_groupFitLoss(Unknown_parm, AllSubj_cell, BasicData), fit_param_initial, options);

% Assign best parameters
% best_parm = [14.8448, 0.6802, 0.9349, 1.0503];

prior = Prior_Crane2012;
[mu_thh_dic, ~, std_thh_dic, p_thh_gv_th_dic] = fun_BayesInference(xx_rad, prior, best_parm);

ST_idx = fun_getIDX(x_stimulus_deg);
pred_mean_ST_rad = mu_thh_dic(:, ST_idx);
pred_std_ST_rad = std_thh_dic(:, ST_idx);

mean_deg = rad2deg(pred_mean_ST_rad);
std_deg = rad2deg(pred_std_ST_rad);

% Plot Mean and Variance
f1 = figure(1); clf
plot_Data_vs_Model(x_stimulus_deg, AllSubj_rad, AllSubj_std_rad, mean_deg, std_deg)

% Create invisible large axes with title
hh = mtit('', 'FontSize', 30, 'Fontname', 'Times New Roman', 'Fontweight', 'normal');
hh.th.String = '';
hh.th.Position = [0.5, 1.03, 0.5];
xlh = xlabel(hh.ah, 'Actual Heading (deg.)');
set(xlh, 'Visible', 'On')

% Export data (commented out to avoid errors)
% exportData_path = '/Users/linghao/Downloads/BaysianCode_export/MLE Results/Export/Exp3Arc/';
% CombineSubj_predic_file = 'CombineSubj_prediction.mat';
% OutputDataFile = fullfile(exportData_path, CombineSubj_predic_file);
% save(OutputDataFile, 'mean_deg', 'std_deg');

figure(2), clf
plot_HeatMap(p_thh_gv_th_dic)

hh = mtit('Prob. density of estimates', 'FontSize', 30, 'Fontname', 'Times New Roman', 'Fontweight', 'normal');

% Make y labels
ylh = ylabel(hh.ah, 'Estimate (deg.)');
set(ylh, 'Visible', 'On')
ylh.Position = [-0.0714 0.5000 7.1054e-15];

xlh = xlabel(hh.ah, 'Actual Heading (deg.)');
xlh.Position = [0.5 0.1000 0];
set(xlh, 'Visible', 'On')


%% function
function neg_SumSubj_log_LL = fun_groupFitLoss(fit_param, AllSubj_cell, BasicData)
    neg_EachSubj_log_LL_dic = cellfun(@(EachSubj_rad) fun_idd_logMLE(fit_param, EachSubj_rad, BasicData), AllSubj_cell);
    neg_SumSubj_log_LL = sum(neg_EachSubj_log_LL_dic);
end

function neg_EachSubj_log_LL = fun_idd_logMLE(fit_param, EachSubj_rad, BasicData)
    x_stimulus_deg = BasicData.x_stimulus_deg;
    xx_rad = BasicData.xx_rad;
    prior = BasicData.prior;

    [~, ~, ~, p_thh_gv_th_dic, x] = fun_BayesInference(xx_rad, prior, fit_param);

    ST_idx = fun_getIDX(x_stimulus_deg);
    p_thh_gv_th_dic_select = p_thh_gv_th_dic(:, ST_idx, :);

    neg_EachSubj_log_LL = fun_each_logLL(EachSubj_rad, p_thh_gv_th_dic_select, x);
end

function neg_EachSubj_log_LL = fun_each_logLL(EachSubj_rad, p_thh_gv_th_dic_select, x)
    Ntrials = size(EachSubj_rad, 1);
    Nstim = size(EachSubj_rad, 2);
    Ncase = size(EachSubj_rad, 3);

    log_LL = zeros(Ntrials, Nstim, Ncase);

    for kth = 1:Ncase
        for th_i = 1:Nstim
            p_thh_gv_th_i = p_thh_gv_th_dic_select(:, th_i, kth);
            subjR_gv_th_i = EachSubj_rad(:, th_i, kth);
            estimGrid = x';
            tol = 1e-3;
            [~, estimate_idx] = ismembertol(subjR_gv_th_i, estimGrid, tol);
            flag = find(estimate_idx == 0);

            if ~isempty(flag)
                [~, estimate_idx(flag)] = ismembertol(subjR_gv_th_i(flag), estimGrid, 1e-2);
            end

            p_subjR_gv_th_i = p_thh_gv_th_i(estimate_idx);

            LL_vec = p_subjR_gv_th_i;
            log_LL(:, th_i, kth) = log(LL_vec);
        end
    end

    sum_log_LL = sum(log_LL(:));
    neg_EachSubj_log_LL = -sum_log_LL;
end

%% Function

% Plot Data vs Model
function plot_Data_vs_Model(x_stimulus_deg, AllSubj_rad, AllSubj_std_rad, mean_deg, std_deg, sem_mean_deg, sem_std_deg)
    [YPred_80, YPred_160, YPred_240] = deal(mean_deg(1, :), mean_deg(2, :), mean_deg(3, :));
    [Std_80, Std_160, Std_240] = deal(std_deg(1, :), std_deg(2, :), std_deg(3, :));

    subplot(2, 2, 1) % Data mean
    x = x_stimulus_deg;

    mean_data_rad = mean(AllSubj_rad);
    mean_data_deg = rad2deg(mean_data_rad);

    std_data_rad = mean(AllSubj_std_rad);
    std_data_deg = rad2deg(std_data_rad);

    y80 = mean_data_deg(:, :, 1);
    y160 = mean_data_deg(:, :, 2);
    y240 = mean_data_deg(:, :, 3);

    std_80_deg = std_data_deg(:, :, 1);
    std_160_deg = std_data_deg(:, :, 2);
    std_240_deg = std_data_deg(:, :, 3);

    colorList = [0 0 0; 0.4 0.4 0.4; 0.7 0.7 0.7];
    MarkerSizes = [30, 30, 30, 10];

    hold on
    Bias80 = y80 - x;
    Bias160 = y160 - x;
    Bias240 = y240 - x;

    plot(x, Bias80, '.-', 'MarkerSize', MarkerSizes(1), 'Color', 'black');
    plot(x, Bias160, '.-', 'MarkerSize', MarkerSizes(2), 'Color', 'blue');
    plot(x, Bias240, '.-', 'MarkerSize', MarkerSizes(3), 'Color', 'red');

    % plot: reference line
    x_range = [-45 45];
    y_range = [-20, 20];
    plot(x_range, [0 0], '-', 'Color', [0.7 0.7 0.7]); % y = 0
    plot([0 0], y_range, '-', 'Color', [0.7 0.7 0.7]); % x = 0
    hold off

    ylabel('Data', 'Rotation', 0)
    title('Mean (18 subjects)')

    xlim(x_range)
    ylim(y_range)
    set(gca, 'XTick', linspace(-40, 40, 5), 'YTick', linspace(-20, 20, 5))
    axis square

    % STD
    subplot(2, 2, 2)
    MarkerSizes = [30, 30, 30, 10];

    hold on
    plot(x_stimulus_deg, std_80_deg, '.-', 'MarkerSize', MarkerSizes(1), 'Color', 'black');
    plot(x_stimulus_deg, std_160_deg, '.-', 'MarkerSize', MarkerSizes(2), 'Color', 'blue');
    plot(x_stimulus_deg, std_240_deg, '.-', 'MarkerSize', MarkerSizes(3), 'Color', 'red');

    plot([0 0], y_range, '-', 'Color', [0.7 0.7 0.7]); % x = 0

    % plot: reference line
    x_range = [-45 45];

    if exist('rawSTD')
        plot(x, rawSTD, '--o', 'MarkerSize', MarkerSizes(4), 'Color', [0.7 0.7 0.7]);
    end

    hold off

    title('Standard Deviation')
    xlim(x_range)
    ylim([2, 17])
    set(gca, 'XTick', linspace(-40, 40, 5), 'YTick', linspace(0, 16, 5))
    axis square

    subplot(2, 2, 3) % Model mean

    if exist('sem_mean_deg', 'var')
        plot_predictions(x_stimulus_deg, YPred_80, YPred_160, YPred_240, sem_mean_deg)
    else % no error plot
        plot_predictions(x_stimulus_deg, YPred_80, YPred_160, YPred_240)
    end

    ylabel('Model', 'Rotation', 0)
    legend({'80', '160', '240'}, 'Location', 'northeastoutside', 'Box', 'off');

    subplot(2, 2, 4)
    if exist('sem_mean_deg', 'var')
        plot_STD(x_stimulus_deg, Std_80, Std_160, Std_240, sem_std_deg);
    else % no error plot
        plot_STD(x_stimulus_deg, Std_80, Std_160, Std_240);
    end
end

function plot_STD(x, y80, y160, y240, error_std_deg, rawSTD)
    MarkerSizes = 30;
    hold on

    if exist('error_std_deg', 'var')
        errorbar(x, y80, error_std_deg(1, :), 'LineWidth', 2, 'Color', 'black');
        errorbar(x, y160, error_std_deg(2, :), 'LineWidth', 2, 'Color', 'blue');
        errorbar(x, y240, error_std_deg(3, :), 'LineWidth', 2, 'Color', 'red');
    end

    plot(x, y80, '.-', 'MarkerSize', MarkerSizes, 'Color', 'black');
    plot(x, y160, '.-', 'MarkerSize', MarkerSizes, 'Color', 'blue');
    plot(x, y240, '.-', 'MarkerSize', MarkerSizes, 'Color', 'red');

    plot([0 0], [0, max(y240)], '-', 'Color', [0.7 0.7 0.7]); % x = 0

    if exist('rawSTD')
        plot(x, rawSTD, '--o', 'MarkerSize', MarkerSizes(4), 'Color', [0.7 0.7 0.7]);
    end

    hold off

    xlim([-45 45])
    ylim([1, max(y240)])
    set(gca, 'XTick', linspace(-40, 40, 5))
    yticks([4 8 12 16 20])
    box off
    axis square
end

function plot_predictions(x, y80, y160, y240, error_mean_deg)
    MarkerSizes = 30;
    hold on
    Bias80 = y80 - x;
    Bias160 = y160 - x;
    Bias240 = y240 - x;

    if exist('error_mean_deg', 'var')
        errorbar(x, Bias80, error_mean_deg(1, :), '.-', 'LineWidth', 2, 'Color', 'black');
        errorbar(x, Bias160, error_mean_deg(2, :), '.-', 'LineWidth', 2, 'Color', 'blue');
        errorbar(x, Bias240, error_mean_deg(3, :), '.-', 'LineWidth', 2, 'Color', 'red');
    end

    plot(x, Bias80, '.-', 'MarkerSize', MarkerSizes, 'Color', 'black');
    plot(x, Bias160, '.-', 'MarkerSize', MarkerSizes, 'Color', 'blue');
    plot(x, Bias240, '.-', 'MarkerSize', MarkerSizes, 'Color', 'red');

    % plot: reference line
    plot_range = [-45 45];
    plot(plot_range, [0 0], '-', 'Color', [0.7 0.7 0.7]); % y = 0
    plot([0 0], plot_range, '-', 'Color', [0.7 0.7 0.7]); % x = 0
    hold off

    xlim([-45, 45])
    ylim([-20, 20])
    set(gca, 'XTick', linspace(-40, 40, 5), 'YTick', linspace(-20, 20, 5))
    axis square
end



