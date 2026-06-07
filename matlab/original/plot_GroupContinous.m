%{
Plot continuous mean and std for the group level fitting
%}

% Default figure settings
set(groot, 'DefaultLineLineWidth', 2);
set(groot,'DefaultAxesFontSize', 30, 'DefaultAxesFontname','Times New Roman')
set(groot,'defaultfigurecolor', 'white', 'defaultAxesTitleFontWeight', 'normal')


% Load data
dataset_path = '';
BasicData_file = 'stimulus_grid.mat';
FullName_Basic = fullfile(dataset_path, BasicData_file);
load(FullName_Basic, 'x_stimulus_deg', 'xx_deg', 'xx_rad')

PriorData_file = 'PriorFrom_Crane2012';
FullName_Prior = fullfile(dataset_path, PriorData_file);
load(FullName_Prior, "Prior_Crane2012")

AllSubj_cell_FileName= 'AllSubj_cell.mat';
FullName_AllSubj = fullfile(dataset_path, AllSubj_cell_FileName);
load(FullName_AllSubj, 'AllSubj_cell')

% Mean activity
AllSubjData_file = 'AllSubj_mean_std.mat';
FullName_AllSubj = fullfile(dataset_path, AllSubjData_file);
load(FullName_AllSubj, 'AllSubj_rad', 'AllSubj_std_rad'); % Subject mean and std

% Initial parameters
fit_param_initial = [14.8448, 0.6802, 0.9349, 1.0503];

% Fit the parameter
BasicData.x_stimulus_deg = x_stimulus_deg;
BasicData.xx_rad = xx_rad;
BasicData.prior = Prior_Crane2012;

best_parm = [14.8448, 0.6802, 0.9349, 1.0503]; % Change this if needed
prior = Prior_Crane2012;
[mu_thh_dic, ~, std_thh_dic, ~] = fun_BayesInference(xx_rad, prior, best_parm);

ST_idx = fun_getIDX(x_stimulus_deg);
pred_mean_ST_rad = mu_thh_dic; % Mean prediction: 12 x 1
pred_std_ST_rad = std_thh_dic;

mean_deg = rad2deg(pred_mean_ST_rad);
std_deg = rad2deg(pred_std_ST_rad);

% Plot Mean and Variance
f1 = figure(1); clf

n = 1000;
[~, ~, th_rad, ~] = gen_grid(n);
th_deg = rad2deg(th_rad);
th_deg = th_deg';

nexttile
plot_mean_idd(th_deg, mean_deg)

nexttile
plot_std_idd(th_deg, std_deg)

%% Function Definitions

function plot_mean_idd(x_stimulus_deg, mean_deg, error_mean_deg)
    [YPred_80, YPred_160, YPred_240] = deal(mean_deg(1, :), mean_deg(2, :), mean_deg(3, :));

    if exist('error_mean_deg', 'var')
        plot_predictions(x_stimulus_deg, YPred_80, YPred_160, YPred_240, error_mean_deg)
    else
        plot_predictions(x_stimulus_deg, YPred_80, YPred_160, YPred_240)
    end
end

function plot_std_idd(x_stimulus_deg, std_deg, error_std_deg)
    [Std_80, Std_160, Std_240] = deal(std_deg(1, :), std_deg(2, :), std_deg(3, :));

    if exist('error_std_deg', 'var')
        plot_STD(x_stimulus_deg, Std_80, Std_160, Std_240, error_std_deg)
    else
        plot_STD(x_stimulus_deg, Std_80, Std_160, Std_240)
    end
end

function plot_STD(x, std80, std160, std240, error_std_deg, rawSTD)
    MarkerSizes = 30;

    hold on
    if exist('error_std_deg', 'var')
        errorbar(x, std80, error_std_deg(1, :), 'LineWidth', 2, 'Color', 'black');
        errorbar(x, std160, error_std_deg(2, :), 'LineWidth', 2, 'Color', 'blue');
        errorbar(x, std240, error_std_deg(3, :), 'LineWidth', 2, 'Color', 'red');
    end

    plot(x, std80, 'MarkerSize', MarkerSizes, 'Color', 'black');
    plot(x, std160, 'MarkerSize', MarkerSizes, 'Color', 'blue');
    plot(x, std240, 'MarkerSize', MarkerSizes, 'Color', 'red');

    plot([0 0], [0, 20], '-', 'Color', [0.7 0.7 0.7]); % x = 0

    if exist('rawSTD')
        plot(x, rawSTD, '--o', 'MarkerSize', MarkerSizes(4), 'Color', [0.7 0.7 0.7]);
    end

    hold off

    xlim([-45 45])
    ylim([2, 20])
    set(gca, 'XTick', linspace(-40, 40, 5), 'YTick', linspace(2, 18, 5))
    box off
    axis square
end

function [x0, x, th, m] = gen_grid(n)
    x0 = linspace(-pi, pi, n); % end to end

    x = linspace(-pi, pi, n+1); % shifted by 1/2 - non-overlapping for marginalization
    dx = x(2) - x(1);
    x(1) = [];
    x = x - dx/2;

    % Variable and measurement
    th = x'; % column
    m = x; % row
end


function plot_predictions(x, y80, y160, y240, error_mean_deg)
% Plot IDD predictions
MarkerSizes = 5;

hold on
Bias80 = y80 - x;
Bias160 = y160 - x;
Bias240 = y240 - x;

if exist('error_mean_deg', 'var')
    errorbar(x, Bias80, error_mean_deg(1, :), '.-',  'LineWidth', 2, 'Color', 'black');
    errorbar(x, Bias160, error_mean_deg(2, :), '.-', 'LineWidth', 2, 'Color', 'blue');
    errorbar(x, Bias240, error_mean_deg(3, :), '.-',  'LineWidth', 2, 'Color', 'red');
end

% plot(x, Bias80, '.-', 'MarkerSize', MarkerSizes, 'Color', 'black');
% plot(x, Bias160, '.-', 'MarkerSize', MarkerSizes, 'Color', 'blue');
% plot(x, Bias240, '.-', 'MarkerSize', MarkerSizes, 'Color', 'red');

plot(x, Bias80,  'MarkerSize', MarkerSizes, 'Color', 'black');
plot(x, Bias160, 'MarkerSize', MarkerSizes, 'Color', 'blue');
plot(x, Bias240, 'MarkerSize', MarkerSizes, 'Color', 'red');

% Plot reference lines
plot_range = [-45 45];
plot(plot_range,[0 0],'-','Color',[0.7 0.7 0.7]); % y = 0
hold off

xlim([-45,45])
ylim([-20, 20])
set(gca,'XTick',linspace(-40, 40, 5),'YTick',linspace(-20, 20, 5))
axis square
end

