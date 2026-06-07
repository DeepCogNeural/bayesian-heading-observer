%{
Individual Subject Fitting and Analysis Script

This script is designed to perform the following tasks:

1. Fit parameters individually for each subject based on their response data.
2. Plot the distribution of the best-fit parameters, including 'kappa', 
   'alpha_1', 'alpha_2', and 'alpha_3'.
3. Utilize the best-fit parameters for each subject to plot their response
   mean and standard deviation.

%}


% Clearing previous data and settings
clear, clc

% Default figure settings
set(groot, 'DefaultLineLineWidth', 2);
set(groot, 'DefaultAxesFontSize', 30, 'DefaultAxesFontname', 'Times New Roman')
set(groot, 'defaultfigurecolor', 'white', 'defaultAxesTitleFontWeight', 'normal')

% Load data
BasicData_file = 'stimulus_grid.mat';
PriorData_file = 'PriorFrom_Crane2012';

FullName_Basic = fullfile(BasicData_file);
FullName_Prior = fullfile(PriorData_file);

load(FullName_Basic, 'x_stimulus_deg', 'xx_deg', 'xx_rad', 'x_stimulus_deg', 'xx_deg', 'xx_rad')
load(FullName_Prior, 'Prior_Crane2012')


FilePath = 'IddDataRad/';
load('iidData/NameList.mat', 'DataNameList')

% Fit the parameter
BasicData.x_stimulus_deg = x_stimulus_deg;
BasicData.xx_rad = xx_rad;
BasicData.prior = Prior_Crane2012;

% Initializing matrices for best parameters and subject data
BestParam_mat = nan(length(DataNameList), 4);
DataMean_deg_cell = cell(1, length(DataNameList));
DataStd_deg_cell = cell(1, length(DataNameList));

for i = 1:length(DataNameList)
    DataFile = DataNameList(i).name;

    SubjData_FullName = fullfile(FilePath, ['Processed_' DataFile]);
    load(SubjData_FullName, 'SubData_rad'); % subj individual data: 20 trails x 12 stimulus x 3 types
    EachSubj_rad = SubData_rad;

    fit_param_initial = [8.7113 0.7554 1.0445 1.1652];
    
    options = optimset('TolX', 1e-10, 'TolFun', 1e-10, 'Display', 'off');
    BestParam_vec = fminsearch(@(Unkown_parm) fun_idd_logMLE(Unkown_parm, EachSubj_rad, BasicData), fit_param_initial, options);
    BestParam_mat(i, :) = BestParam_vec;

    % Each subject response mean and std across 20 trails
    temp_mean = circ_mean(EachSubj_rad);
    EachSubjMean_rad = squeeze(temp_mean); % 12 x 3
    EachSubjMean_rad = transpose(EachSubjMean_rad); % 3 x 12
    EachSubjMean_deg = rad2deg(EachSubjMean_rad);

    temp_std = circ_std(EachSubj_rad);
    EachSubjStd_rad = squeeze(temp_std);
    EachSubjStd_rad = transpose(EachSubjStd_rad);
    EachSubjStd_deg = rad2deg(EachSubjStd_rad);

    DataMean_deg_cell{i} = EachSubjMean_deg;
    DataStd_deg_cell{i} = EachSubjStd_deg;
end

% %% Save best_param_dic
% BestParam_file = 'iddParamFit_Crane2012.mat'; % data name
% FullName_Basic = fullfile(BestParam_file);
% save(FullName_Basic, 'BestParam_mat')
% 
% % Save subject data
% iddData_file = 'iddData_Crane2012.mat'; % data name
% FullName_data = fullfile(iddData_file);
% save(FullName_data, 'DataMean_deg_cell', 'DataStd_deg_cell')
% 
% %% Load data
% % Load parameter
% BestParam_file = 'iddParamFit_Crane2012.mat';
% FullName_Basic = fullfile(BestParam_file);
% load(FullName_Basic, 'BestParam_mat')
% 
% % Load data
% iddData_file = 'iddData_Crane2012.mat'; % data name
% FullName_data = fullfile( iddData_file);
% load(FullName_data, 'DataMean_deg_cell', 'DataStd_deg_cell')


% Plot parameter distribution
figure(2), clf

subplot(1, 2, 1)
x_text = {'\kappa'};
violinplot(BestParam_mat(:, 1), x_text);
axis square

subplot(1, 2, 2)
x_text = {'\alpha_1', '\alpha_2', '\alpha_3'};
violinplot(BestParam_mat(:, 2:end), x_text);
axis square

sgtitle('Distribution of the parameter', 'FontSize', 30, 'Fontname', 'Times New Roman', 'Fontweight', 'normal')

% Plot all the subject fitting result
% Get each subject fitting result
prior = Prior_Crane2012;
row_list = 1:size(BestParam_mat, 1);
[mean_deg_cell, std_deg_cell] = arrayfun(@(ith) fun_eachSubj_Result(x_stimulus_deg, xx_rad, prior, BestParam_mat(ith, :)), row_list, 'UniformOutput', false);

% Mean
figure(3), clf

for i = row_list
    nexttile
    plot_mean_idd(x_stimulus_deg, mean_deg_cell{i})
end

hh = mtit('', 'FontSize', 30, 'Fontname', 'Times New Roman', 'Fontweight', 'normal');
hh.th.String = '18 Subjects: Individual Fit (Mean)';
hh.th.Position = [0.5, 1.03, 0.5];

xlh = xlabel(hh.ah, 'Actual Heading (deg.)');
set(xlh, 'Visible', 'On')

ylh = ylabel(hh.ah, 'Bias (deg.)');
set(ylh, 'Visible', 'On')

legend({'80', '160', '240'}, 'Location', 'northeastoutside', 'Box', 'off');

% Std
figure(4), clf 
for i = row_list
    nexttile
    plot_std_idd(x_stimulus_deg, std_deg_cell{i})
end

hh = mtit('', 'FontSize', 30, 'Fontname', 'Times New Roman', 'Fontweight', 'normal');
hh.th.String = '18 Subjects: Individual Fit (Std)';
hh.th.Position = [0.5, 1.03, 0.5];
xlh = xlabel(hh.ah, 'Actual Heading');



%% function

% Plot the mean of IDD
function plot_mean_idd(x_stimulus_deg, mean_deg, error_mean_deg)
    % Extract mean predictions for each case
    [YPred_80, YPred_160, YPred_240] = deal(mean_deg(1, :), mean_deg(2, :), mean_deg(3, :));

    % Check if error_mean_deg exists and plot predictions accordingly
    if exist('error_mean_deg', 'var')
        plot_predictions(x_stimulus_deg, YPred_80, YPred_160, YPred_240, error_mean_deg);
    else
        plot_predictions(x_stimulus_deg, YPred_80, YPred_160, YPred_240);
    end
end

% Plot the predictions with error bars
function plot_predictions(x, y80, y160, y240, error_mean_deg)
    MarkerSizes = 30;

    hold on
    % Calculate biases for each case
    Bias80 = y80 - x;
    Bias160 = y160 - x;
    Bias240 = y240 - x;

    % Check if error_mean_deg exists and plot error bars accordingly
    if exist('error_mean_deg', 'var')
        errorbar(x, Bias80, error_mean_deg(1, :), '.-', 'LineWidth', 2, 'Color', 'black');
        errorbar(x, Bias160, error_mean_deg(2, :), '.-', 'LineWidth', 2, 'Color', 'blue');
        errorbar(x, Bias240, error_mean_deg(3, :), '.-', 'LineWidth', 2, 'Color', 'red');
    end

    % Plot biases with markers
    plot(x, Bias80, 'MarkerSize', MarkerSizes, 'Color', 'black');
    plot(x, Bias160, 'MarkerSize', MarkerSizes, 'Color', 'blue');
    plot(x, Bias240, 'MarkerSize', MarkerSizes, 'Color', 'red');

    % Plot reference lines
    plot_range = [-45 45];
    plot(plot_range, [0 0], '-', 'Color', [0.7 0.7 0.7]); % y = 0
    plot([0 0], plot_range, '-', 'Color', [0.7 0.7 0.7]); % x = 0
    hold off

    % Set plot properties
    xlim([-45, 45]);
    ylim([-20, 20]);
    set(gca, 'XTick', linspace(-40, 40, 5), 'YTick', linspace(-20, 20, 5));
    axis square
end

% Plot the standard deviation of IDD
function plot_std_idd(x_stimulus_deg, std_deg, error_std_deg)
    % Extract standard deviations for each case
    [Std_80, Std_160, Std_240] = deal(std_deg(1, :), std_deg(2, :), std_deg(3, :));

    % Check if error_std_deg exists and plot standard deviations accordingly
    if exist('error_std_deg', 'var')
        plot_STD(x_stimulus_deg, Std_80, Std_160, Std_240, error_std_deg);
    else
        plot_STD(x_stimulus_deg, Std_80, Std_160, Std_240);
    end
end

% Plot standard deviations with error bars
function plot_STD(x, std80, std160, std240, error_std_deg, rawSTD)
    MarkerSizes = 30;
    hold on

    % Check if error_std_deg exists and plot error bars accordingly
    if exist('error_std_deg', 'var')
        errorbar(x, std80, error_std_deg(1, :), 'LineWidth', 2, 'Color', 'black');
        errorbar(x, std160, error_std_deg(2, :), 'LineWidth', 2, 'Color', 'blue');
        errorbar(x, std240, error_std_deg(3, :), 'LineWidth', 2, 'Color', 'red');
    end

    % Plot standard deviations with markers
    plot(x, std80, 'MarkerSize', MarkerSizes, 'Color', 'black');
    plot(x, std160, 'MarkerSize', MarkerSizes, 'Color', 'blue');
    plot(x, std240, 'MarkerSize', MarkerSizes, 'Color', 'red');

    % Plot reference lines
    plot([0 0], [0, max(std240)], '-', 'Color', [0.7 0.7 0.7]); % x = 0

    % Plot optional raw STD data if provided
    if exist('rawSTD')
        plot(x, rawSTD, '--o', 'MarkerSize', MarkerSizes(4), 'Color', [0.7 0.7 0.7]);
    end

    hold off

    % Set plot properties
    x_range = [-45 45];
    ylim([1, max(std240)]);
    set(gca, 'XTick', linspace(-40, 40, 5), 'YTick', [4 8 12 16 20]);
    box off
    axis square
end

% Compute mean and standard deviation for each subject's result
function [mean_deg, std_deg] = fun_eachSubj_Result(x_stimulus_deg, xx_rad, prior, best_parm)
    [mu_thh_dic, ~, std_thh_dic, ~] = fun_BayesInference(xx_rad, prior, best_parm);

    ST_idx = fun_getIDX(x_stimulus_deg);
    pred_mean_ST_rad = mu_thh_dic(:, ST_idx); % mean prediction: 12 x 1
    pred_std_ST_rad = std_thh_dic(:, ST_idx);

    mean_deg = rad2deg(pred_mean_ST_rad);
    std_deg = rad2deg(pred_std_ST_rad);
end

% Compute negative log likelihood for each subject
function neg_EachSubj_log_LL = fun_idd_logMLE(fit_param, EachSubj_rad, BasicData)
    x_stimulus_deg = BasicData.x_stimulus_deg;
    xx_rad = BasicData.xx_rad;
    prior = BasicData.prior;

    [~, ~, ~, p_thh_gv_th_dic, x] = fun_BayesInference(xx_rad, prior, fit_param);

    ST_idx = fun_getIDX(x_stimulus_deg);
    p_thh_gv_th_dic_select = p_thh_gv_th_dic(:, ST_idx, :);

    neg_EachSubj_log_LL = fun_each_logLL(EachSubj_rad, p_thh_gv_th_dic_select, x);
end

% Compute negative log likelihood for each subject's response
function neg_EachSubj_log_LL = fun_each_logLL(EachSubj_rad, p_thh_gv_th_dic_select, x)
    Ntrails = size(EachSubj_rad, 1); % 20 trails
    Nstim = size(EachSubj_rad, 2); % 12 stim
    Ncase = size(EachSubj_rad, 3); % 3 case

    log_LL = zeros(Ntrails, Nstim, Ncase);

    for kth = 1:Ncase % for 80/160/240
        for th_i = 1:Nstim % for each stimulus point
            p_thh_gv_th_i = p_thh_gv_th_dic_select(:, th_i, kth);
            subjR_gv_th_i = EachSubj_rad(:, th_i, kth);
            estimGrid = x';
            tol = 1e-3;

            [~, estimate_idx] = ismembertol(subjR_gv_th_i, estimGrid, tol);
            flag = find(estimate_idx == 0);

            if flag > 0
                [~, estimate_idx(flag)] = ismembertol(subjR_gv_th_i(flag), estimGrid, 1e-2);
            end

            p_subjR_gv_th_i = p_thh_gv_th_i(estimate_idx);

            LL_vec = p_subjR_gv_th_i;
            log_LL(:, th_i, kth) = log(LL_vec);
        end
    end

    sum_log_LL = sum(sum(sum(log_LL)));
    neg_EachSubj_log_LL = -sum_log_LL;
end

% Get stimulus index
function ST_idx = fun_getIDX(stim_deg)
    n = 1000;
    [~, ~, th_rad, ~] = gen_grid(n);
    th_deg = rad2deg(th_rad);
    true_degree = stim_deg;
    [~, ST_idx] = ismember(round(true_degree), round(th_deg));
end

% Generate grid
function [x0, x, th, m] = gen_grid(n)
    x0 = linspace(-pi, pi, n); % end to end
    x = linspace(-pi, pi, n + 1); % shifted by 1/2 - non-overlapping for marginalization
    dx = x(2) - x(1);
    x(1) = [];
    x = x - dx / 2;

    % variable and measurement
    th = x'; % column
    m = x; % row
end


