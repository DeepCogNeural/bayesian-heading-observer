% Clear command window and workspace
clear, clc

% Set the file path and add it to the MATLAB path
dataFilePath = '';

% Set default visualization settings
set(groot, 'DefaultLineLineWidth', 2);
set(groot, 'DefaultAxesFontSize', 30, 'DefaultAxesFontname', 'Times New Roman')
set(groot, 'defaultfigurecolor', 'white', 'defaultAxesTitleFontWeight', 'normal')

% Load threshold data
load(fullfile(dataFilePath, 'Threshold_Crane2012.mat'));

% Display information about variables in the workspace
whos

%% Prior Calculation

% Calculate the prior using the inverse of the discrimination threshold
prior = 1 ./ y_hdThreshold;
headingDegrees = -180:1:180;

% Interpolate to ensure a smooth prior distribution
priorInterpolated = interp1(x_hd_deg, prior, headingDegrees);
priorInterpolated(isnan(priorInterpolated)) = 0.166; % Handle NaN values

%% Fit the 2-peak von Mises distribution

% Initial parameters for the fitting process
kappaInitial = [166.760 0.0991];
constantTerm = 0.1564;
alphaInitial = [2 1];
fitParametersInitial = [kappaInitial, constantTerm, alphaInitial];

headingRadians = deg2rad(headingDegrees);
targetProbabilities = priorInterpolated;

% Set options for the fitting process
options = optimset('TolX', 1e-10, 'TolFun', 1e-10, 'Display', 'off', 'MaxIter', 10000000);

% Perform the fitting using fminsearch
fitParametersOptimized = fminsearch(@(fitParams) computeFitLoss(fitParams, headingRadians, targetProbabilities), fitParametersInitial, options);

% Display the loss value of the fitting
fprintf('Loss value after fitting: %f\n', computeFitLoss(fitParametersOptimized, headingRadians, targetProbabilities));

% Generate predictions using the fitted parameters
predictedProbabilities = computeFitPrediction(fitParametersOptimized, headingRadians);

%% Visualization

% Create a new figure for visualization
figureHandle = figure; clf

% Plot discrimination threshold data
yyaxis left
box off
plot(x_hd_deg, y_hdThreshold, 'LineWidth', 2)
ylabel('Visual threshold (deg.)')

% Plot the prior and fitted prior
yyaxis right
box off
plotPrior(headingDegrees, targetProbabilities, predictedProbabilities)

% Set title and legend
title('Prior from discrimination threshold data')
legend('Discrimination threshold', 'Prior prop. to 1/threshold', 'Fit Prior', 'box', 'off', 'Location', 'southeast')

%% Save data

% Save the calculated prior
Prior_Crane2012 = predictedProbabilities;
savePath = fullfile(dataFilePath, 'PriorFrom_Crane2012.mat');
save(savePath, 'headingDegrees', 'Prior_Crane2012');

%% Functions

% Function: Loss function
function sumSquaredLoss = computeFitLoss(fitParams, headingRadians, targetProbabilities)
    % Compute the loss function 
    predictedProbabilities = computeFitPrediction(fitParams, headingRadians);
    
    loss = predictedProbabilities - targetProbabilities;
    squaredLoss = loss.^2;
    sumSquaredLoss = sum(squaredLoss);
end

% Function: Prediction function
function predictedProbabilities = computeFitPrediction(fitParams, headingRadians)
    % Parameters extraction
    k1 = 20;
    k2 = 8;
    constantTerm = fitParams(3);
    alpha = fitParams(4:end);
    
    % Von Mises distributions
    vonMises1 = vonMisesDistribution(headingRadians, 0, k1);
    vonMises2 = vonMisesDistribution(headingRadians, pi, k2);
    
    % Linear combination of von Mises distributions
    predictedProbabilities = constantTerm + alpha(1)*vonMises1 + alpha(2)*vonMises2;
end

% Function: Von Mises distribution
function distribution = vonMisesDistribution(x, mu, kappa)
    % Calculate von Mises distribution
    if kappa > 600
        x = x - mu;
        x = wrapToPi(x);
        distribution = normpdf(x, 0, 1./(sqrt(kappa)));
    else
        distribution = exp(kappa.*cos((x-mu))) ./ (2*pi*besseli(0, kappa));
    end
end

% Function: Plot prior
function plotPrior(headingDegrees, targetProbabilities, predictedProbabilities)
    markerSizes = [20, 10];
    
    hold on 
    plot(headingDegrees, targetProbabilities, '-', 'Color', 'blue', 'LineWidth', 5)
    plot(headingDegrees, predictedProbabilities, '-', 'Color', 'red', 'LineWidth', 5)
    hold off

    xlabel('Actual heading');
    ylabel('Probability')

    ylim([0 1.1*max(targetProbabilities)])

    set(gca, 'XTick', linspace(-180, 180, 5))
    axis square
end
