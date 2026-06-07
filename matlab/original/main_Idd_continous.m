% continous version for ploting each subject response and std
% also plot the shadedErrorBar

% Clear command window, turn off warnings
clear, clc
warning off 

% Default figure settings
set(groot, 'DefaultLineLineWidth', 2);
set(groot,'DefaultAxesFontSize', 30, 'DefaultAxesFontname','Times New Roman')
set(groot,'defaultfigurecolor', 'white', 'defaultAxesTitleFontWeight', 'normal')

% Load data
dataset_path = '';
BasicData_file = 'stimulus_grid.mat';
FullName_Basic = strcat(dataset_path, BasicData_file);
load(FullName_Basic, 'x_stimulus_deg', 'xx_deg', 'xx_rad')

PriorData_file = 'PriorFrom_Crane2012';
FullName_Prior = strcat(dataset_path, PriorData_file);
load(FullName_Prior, 'Prior_Crane2012') % Get xx_rad, prior

FilePath = 'IddDataRad/';
load('iidData/NameList.mat', 'DataNameList')

% Load parameters
dataset_path = '';
BestParam_file = 'iddParamFit_Crane2012.mat';
FullName_Basic = strcat(dataset_path, BestParam_file);
load(FullName_Basic, 'BestParam_mat')

% Load data
iddData_file = 'iddData_Crane2012.mat'; % Data name
FullName_data = strcat(dataset_path, iddData_file);
load(FullName_data, 'DataMean_deg_cell', 'DataStd_deg_cell')

%% Plot all the subject fitting results

% Get each subject fitting result
prior = Prior_Crane2012;
row_list = 1:size(BestParam_mat, 1);
[mean_deg_cell, std_deg_cell] = arrayfun(@(ith) fun_eachSubj_Result(x_stimulus_deg, xx_rad, prior, BestParam_mat(ith, :)), row_list, 'UniformOutput', false);
% mean_deg_cell: 1 x 18 subjects, each position is a 3×12 matrix

n = 1000;
[~, ~, th_rad, ~] = gen_grid(n);
th_deg = rad2deg(th_rad);
th_deg = th_deg';

%% Mean 
figure(2), clf

for i = row_list
    nexttile
    hold on
    % plot_mean_iddData(x_stimulus_deg, DataMean_deg_cell{i})
    plot_mean_idd(th_deg, mean_deg_cell{i})
    hold off
    % if  ismember( i, [1 7 13] )
    %     set(gca,'YTick',linspace(-20, 20, 5) );
    % end
end
%%
hh = mtit('', 'FontSize', 30, 'Fontname','Times New Roman', 'Fontweight', 'normal');
hh.th.String = 'Mean Prediction (Line) for 18 Individual Subjects' ;
hh.th.Position = [0.5, 1.03, 0.5];

xlh = xlabel(hh.ah, 'Actual Heading (deg.)');
set(xlh, 'Visible', 'On')

ylh = ylabel(hh.ah, 'Bias (deg.)');
set(ylh, 'Visible', 'On')

legend({'80','160', '240'} ,'Location','northeastoutside', 'Box','off');

%% Std 
figure(3),clf 
for i = row_list
    nexttile
    hold on
    % plot_std_iddData(x_stimulus_deg, DataStd_deg_cell{i})
    plot_std_idd(th_deg, std_deg_cell{i})
    hold off
end
%%
hh = mtit('', 'FontSize', 30, 'Fontname','Times New Roman', 'Fontweight', 'normal');
hh.th.String = 'Prediction Std (Line) for 18 Individual Subjects' ;
hh.th.Position = [0.5, 1.03, 0.5];
xlh = xlabel(hh.ah, 'Actual Heading (deg.)');
set(xlh, 'Visible', 'On')

ylh = ylabel(hh.ah, 'Std');
set(ylh, 'Visible', 'On')

legend({'80','160', '240'} ,'Location','northeastoutside', 'Box','off');

%% Compute the mean and SEM across subjects
% Save all subject data into a matrix: 3 cases x 12 stimulus x 18 subjects

temp_mean_deg_mat18 = reshape(mean_deg_cell, [1, 1, 18]);
mean_deg_mat18 = cell2mat(temp_mean_deg_mat18);

temp_std_deg_mat18 = reshape(std_deg_cell, [1, 1, 18]);
std_deg_mat18 = cell2mat(temp_std_deg_mat18);

avgX18_mean = mean(mean_deg_mat18, 3);
avgX18_std =  mean(std_deg_mat18, 3);

num_subj = size(mean_deg_mat18, 3);

% Errorbar
error_avgX18_mean = std(mean_deg_mat18, [], 3);
error_avgX18_std = std(std_deg_mat18, [], 3);

sem_avgX18_mean = error_avgX18_mean / sqrt(num_subj);
sem_avgX18_std = error_avgX18_std / sqrt(num_subj);

% Plot Mean and Variance
fg = figure(4); clf 
nexttile
hold on
plot_mean_idd(th_deg, avgX18_mean)

s = shadedErrorBar(th_deg, avgX18_mean(1, :) - th_deg, sem_avgX18_mean(1, :),...
    'lineprops',{'.k','MarkerFaceColor','k'},...
    'transparent',true);
s.patch.FaceColor = 'k';
s.patch.FaceAlpha=0.1;
s.patch.FaceAlpha=0.1;

s = shadedErrorBar(th_deg, avgX18_mean(2, :) - th_deg, sem_avgX18_mean(2, :),...
    'lineprops',{'.b','MarkerFaceColor','b'},...
    'transparent',true);
s.patch.FaceColor = 'b';
s.patch.FaceAlpha=0.2;
s.patch.EdgeAlpha=0.2;

s = shadedErrorBar(th_deg, avgX18_mean(3, :) - th_deg, sem_avgX18_mean(3, :),...
    'lineprops',{'.r','MarkerFaceColor','r'},...
    'transparent',true);
s.patch.FaceColor = 'r';

s.patch.FaceAlpha=0.2;
s.patch.EdgeAlpha=0.2;

hold off


nexttile

hold on
plot_std_idd(th_deg, avgX18_std)

s = shadedErrorBar(th_deg, avgX18_std(1, :), sem_avgX18_std(1, :),...
    'lineprops',{'.k','MarkerFaceColor','k'},...
    'transparent',true);
s.patch.FaceColor = 'k';
s.patch.FaceAlpha=0.1;
s.patch.FaceAlpha=0.1;

s = shadedErrorBar(th_deg, avgX18_std(2, :), sem_avgX18_std(2, :),...
    'lineprops',{'.b','MarkerFaceColor','b'},...
    'transparent',true);
s.patch.FaceColor = 'b';
s.patch.FaceAlpha=0.2;
s.patch.EdgeAlpha=0.2;

s = shadedErrorBar(th_deg, avgX18_std(3, :), sem_avgX18_std(3, :),...
    'lineprops',{'.r','MarkerFaceColor','r'},...
    'transparent',true);
s.patch.FaceColor = 'r';

s.patch.FaceAlpha=0.2;
s.patch.EdgeAlpha=0.2;

hold off

%% Functions

function plot_mean_iddData(x, Data)
% Plot mean IDD data
bias = Data - x;
[Data80, Data160, Data240] = deal(bias(1, :), bias(2, :), bias(3, :));
MarkerSizes = 20;
plot(x, Data80, '.', 'MarkerSize', MarkerSizes, 'Color', 'black');
plot(x, Data160, '.', 'MarkerSize', MarkerSizes, 'Color', 'blue');
plot(x, Data240, '.', 'MarkerSize', MarkerSizes, 'Color', 'red');
% set(gca,'YTickLabel',[]);
end

function plot_std_iddData(x, Data)
% Plot standard deviation of IDD data
[std80, std160, std240] = deal(Data(1, :), Data(2, :), Data(3, :));
MarkerSizes = 20;
plot(x, std80, '.', 'MarkerSize', MarkerSizes, 'Color', 'black');
plot(x, std160, '.', 'MarkerSize', MarkerSizes, 'Color', 'blue');
plot(x, std240, '.', 'MarkerSize', MarkerSizes, 'Color', 'red');
end

function plot_mean_idd(x_stimulus_deg, mean_deg, error_mean_deg)
% Plot mean IDD predictions
[YPred_80, YPred_160, YPred_240] = deal(mean_deg(1, :), mean_deg(2, :), mean_deg(3, :));

if exist('error_mean_deg', 'var')
    plot_predictions(x_stimulus_deg, YPred_80, YPred_160, YPred_240, error_mean_deg)
else
    plot_predictions(x_stimulus_deg, YPred_80, YPred_160, YPred_240)
end

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

function plot_std_idd(x_stimulus_deg, std_deg, error_std_deg)
% Plot standard deviation of IDD predictions
[Std_80, Std_160, Std_240] = deal(std_deg(1, :), std_deg(2, :), std_deg(3, :));

if exist('error_std_deg', 'var')
    plot_STD(x_stimulus_deg, Std_80, Std_160, Std_240, error_std_deg);
else
    plot_STD(x_stimulus_deg, Std_80, Std_160, Std_240);
end

end

function plot_STD(x, std80, std160, std240, error_std_deg, rawSTD)
% Plot standard deviation of IDD
MarkerSizes = 30;
hold on

if exist('error_std_deg', 'var')
    errorbar(x, std80, error_std_deg(1, :),  'LineWidth', 2,  'Color', 'black');
    errorbar(x, std160, error_std_deg(2, :),  'LineWidth', 2, 'Color', 'blue');
    errorbar(x, std240, error_std_deg(3, :),  'LineWidth', 2, 'Color', 'red');
end

plot(x, std80,  'MarkerSize', MarkerSizes, 'Color', 'black');
plot(x, std160, 'MarkerSize', MarkerSizes, 'Color', 'blue');
plot(x, std240, 'MarkerSize', MarkerSizes, 'Color', 'red');

% Plot reference lines
x_range = [-45 45];

% Plot x = 0 line
plot([0 0], [0, 20],'-','Color',[0.7 0.7 0.7]); 

if exist('rawSTD')
    % Plot raw STD data
    plot(x, rawSTD, '--o', 'MarkerSize', MarkerSizes(4), 'Color', [0.7 0.7 0.7]);
end

hold off

xlim(x_range)
ylim([2, 20])
set(gca, 'XTick', linspace(-40, 40, 5), 'YTick', linspace(2, 18, 5))
yticks([5:5:20])
box off
axis square
end

function [mean_deg, std_deg] = fun_eachSubj_Result(x_stimulus_deg, xx_rad, prior, best_parm)
    [mu_thh_dic, ~, std_thh_dic, ~] = fun_BayesInference(xx_rad, prior, best_parm);

    pred_mean_ST_rad = mu_thh_dic; % mean prediction: 12 x 1
    pred_std_ST_rad = std_thh_dic;

    mean_deg = rad2deg(pred_mean_ST_rad);
    std_deg = rad2deg(pred_std_ST_rad);
end

function ST_idx = fun_getIDX(stim_deg)
    n = 1000;
    [~, ~, th_rad, ~] = gen_grid(n);
    th_deg = rad2deg(th_rad);
    true_degree = stim_deg;
    [~, ST_idx] = ismember(round(true_degree), round(th_deg));
end

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

