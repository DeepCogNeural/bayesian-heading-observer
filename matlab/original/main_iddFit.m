%{
This code is designed for two main purposes:
1. Fit the model to each subject's data.
2. Average the results to plot the mean and standard error of the mean (SEM).
%}

% Clear command window and workspace
clear

% Load data
allSubjectsCellFileName = 'AllSubj_cell.mat';
allSubjectsDataFileName = 'AllSubj_mean_std.mat';
stimulusGridFileName = 'stimulus_grid.mat';
iddParamFitFileName = 'iddParamFit.mat';
priorDataFileName = 'PriorFrom_Crane2012.mat';
datasetPath = '';
fullNameAllSubjectsCell = fullfile(datasetPath, allSubjectsCellFileName);
fullNameAllSubjectsData = fullfile(datasetPath, allSubjectsDataFileName);
fullNameStimulusGrid = fullfile(datasetPath, stimulusGridFileName);
fullNameIddParamFit = fullfile(datasetPath, iddParamFitFileName);
fullNamePriorData = fullfile(datasetPath, priorDataFileName);

load(fullNameAllSubjectsCell, 'AllSubj_cell');
load(fullNameAllSubjectsData, 'AllSubj_rad', 'AllSubj_std_rad');
load(fullNameStimulusGrid, 'x_stimulus_deg', 'xx_deg', 'xx_rad');
load(fullNameIddParamFit, 'BestParam_mat');
load(fullNamePriorData, 'Prior_Crane2012');

% Group parameters
groupBestParameters = [14.8448 0.6802 0.9349 1.0503];

% Perform Bayesian inference
[mu_thh_dic, ~, std_thh_dic, ~] = fun_BayesInference(xx_rad, Prior_Crane2012, groupBestParameters);

% Extract data for specific stimuli
ST_idx = fun_getIDX(x_stimulus_deg);
pred_mean_ST_rad = mu_thh_dic(:, ST_idx);
pred_std_ST_rad = std_thh_dic(:, ST_idx);

% Convert radians to degrees
mean_deg = rad2deg(pred_mean_ST_rad);
std_deg = rad2deg(pred_std_ST_rad);

% Extract and process specific predictions
[YPred_80, YPred_160, YPred_240] = deal(mean_deg(1, :), mean_deg(2, :), mean_deg(3, :));
[Std_80, Std_160, Std_240] = deal(std_deg(1, :), std_deg(2, :), std_deg(3, :));

% Generate IDD predictions
[mean_deg_dic, std_deg_dic] = gen_iddPrediction(BestParam_mat, x_stimulus_deg, xx_rad, Prior_Crane2012);

% Compute errors and standard errors of the mean
error_mean_deg = std(mean_deg_dic, [], 3);
error_std_deg = std(std_deg_dic, [], 3);
numSubjects = size(mean_deg_dic, 3);
sem_mean_deg = error_mean_deg / sqrt(numSubjects);
sem_std_deg = error_std_deg / sqrt(numSubjects);

% Plot Mean and Variance
figureHandle = figure(1); clf 
plot_Data_vs_Model(x_stimulus_deg, AllSubj_rad, AllSubj_std_rad, mean_deg, std_deg, sem_mean_deg, sem_std_deg)

% Create invisible large axes with title
titleHandle = mtit('', 'FontSize', 30, 'Fontname', 'Times New Roman', 'Fontweight', 'normal');
titleHandle.th.String = '';
titleHandle.th.Position = [0.5, 1.03, 0.5];

% Set xlabel visible
xlabelHandle = xlabel(titleHandle.ah, 'Actual Heading (deg.)');
set(xlabelHandle, 'Visible', 'On')

%% Function

function [mean_deg_dic, std_deg_dic] = gen_iddPrediction(BestParam_mat, x_stimulus_deg, xx_rad, prior)

numSubjects = size(BestParam_mat, 1);
numStimuli = length(x_stimulus_deg);
ST_idx = fun_getIDX(x_stimulus_deg);

mean_deg_dic = nan(3, numStimuli, numSubjects); % subj x stim
std_deg_dic = nan(3, numStimuli, numSubjects); % subj x stim

for subjectIndex = 1:numSubjects
    eachSubjectParams = BestParam_mat(subjectIndex, :);
    [mu_thh_dic, ~, std_thh_dic, ~] = fun_BayesInference(xx_rad, prior, eachSubjectParams);

    mean_at_stim_rad = mu_thh_dic(:, ST_idx);
    std_at_stim_rad = std_thh_dic(:, ST_idx);

    mean_deg_dic(:, :, subjectIndex) = rad2deg(mean_at_stim_rad);
    std_deg_dic(:, :, subjectIndex) = rad2deg(std_at_stim_rad);
end

end

% Plot Data vs Model
function plot_Data_vs_Model(x_stimulus_deg, AllSubj_rad, AllSubj_std_rad, ...
    mean_deg, std_deg, sem_mean_deg, sem_std_deg)

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

colorList=[0 0 0;
    0.4 0.4 0.4;
    0.7 0.7 0.7];
MarkerSizes=[30, 30, 30, 10];

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
MarkerSizes=[30, 30, 30, 10];

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
set(gca, 'XTick', linspace(-40, 40, 5), 'YTick', linspace( 0, 16, 5))
axis square

subplot(2, 2, 3) % Model mean

if exist('sem_mean_deg', 'var')
    plot_predictions(x_stimulus_deg, YPred_80, YPred_160, YPred_240, sem_mean_deg)
else % no error plot
    plot_predictions(x_stimulus_deg, YPred_80, YPred_160, YPred_240)
end

ylabel('Model', 'Rotation', 0)

legend({'SEM', '', '', '80', '160', '240'}, 'Location', 'northeastoutside', 'Box', 'off');

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

MarkerSizes= 30;

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



