function [ mu_thh_dic, var_thh_dic, std_thh_dic, p_thh_gv_th_dic, x] = fun_BayesInference( xx_rad, prior, fit_param)

%{

Output
mu_thh_dic: 3 x n
var_thh_dic: 3 x n
std_thh_dic: 3 x n
p_thh_gv_th_dic: m x th 

Output is after trasposed: 
m -- 1 x 1000, th -- 1000 x 1
1000 different m --> in different row of 1000 x 1
1000 different th --> in different column 1 x 1000
%}

k_sen = fit_param(1);
alpha_list = fit_param( 2: end);

% load('pre_VarPred_VonPrior.mat', 'xx_rad'); % get xx_rad, prior
% load ('/Users/linghao/Downloads/BaysianCode_export/dataset/TwoP_VonPrior.mat', 'TwoPeak_NewPrior' )
% prior = TwoPeak_NewPrior;

%% Basic
% create the grid
n = 1000;
x0 = linspace(-pi,pi,n);  % [-pi, pi]

x = linspace(-pi,pi,n+1); % shifted by 1/2 - non-overlapping for marginalization
dx = x(2)-x(1);
x(1) = [];
x = x - dx/2;

% variable and measurment
th = x';  % column: 1000 x 1
m = x;  % row: 1 x 1000

%% generative model

% prior
% prior = TwoPeak_NewPrior;
p = interp1( xx_rad, prior, x0);  % 1x 1000
p = p./( trapz(x0, p) ); % prior distribution
p_th = interp1(x0, p, th); % prior distirbution values at th

% efficient coding - mapping to sensory space (tilde, t)
x0t = (2*pi*cumtrapz(x0,p))-pi; % 1 x 1000, [-pi, pi]
tht = interp1(x0, x0t, th); % column: 1000 x 1
mt = interp1(x0,x0t,m); % row: 1 x 1000

% jacobian for prob transform into sensory space
a = 1./(2*pi*p_th);

Grid_x = repmat( mt,[n 1]); % 1000        1000
Grid_mu = repmat(tht,[1 n]); % % 1000        1000
p_mt_gv_tht = vonMises( Grid_x, Grid_mu, k_sen); % 1000 x 1000

% transform conditional distribution back to stimulus space
p_m_gv_th = p_mt_gv_tht./repmat(a',n,1); % row -> noise distribution

%% inference
% in stimulus space because loss-function is defined in stimulus space

p_th_gv_m = p_m_gv_th .* repmat( p_th, 1, n); % column -> likelihood
p_th_gv_m = p_th_gv_m ./ repmat( trapz( th, p_th_gv_m), [n 1]);


% BLS estimator - mean of posterior  1 x 1000
thh_gv_m = atan2( sum( p_th_gv_m .* repmat(sin(th),1,n),1), sum(p_th_gv_m .* repmat(cos(th),1,n), 1));

%% test
Ncase = length(alpha_list);
mu_thh_dic = zeros( n, Ncase);
var_thh_dic = zeros( n, Ncase);
std_thh_dic = zeros( n, Ncase);
p_thh_gv_th_dic  = zeros( n, n, Ncase);

for i = 1: length(alpha_list)

    thh_gv_m_alpha = thh_gv_m * alpha_list(i);

    % distribution of estimates
    % marginalization over p_m_gv_th (variable exchange)
    c = 1./gradient( thh_gv_m_alpha, dx); % jacobian
    p_thh_gv_th = repmat( c, n, 1) .* p_m_gv_th;

    % resampling along thh axis:  Vq = interp1( X, V, Xq)

    % at each given th value, p_thh_gv_th is a function of the thh_gv_m
    % now given all  N different th values, interp to evalue the p_thh_gv_th function values
    p_thh_gv_th = interp1( thh_gv_m_alpha', p_thh_gv_th', th, 'linear','extrap')';
    
    % expectation and bias
    % a = sum(p_thh_gv_th .* repmat(sin(th'),n,1),2);
    a = trapz( th, p_thh_gv_th .* repmat(sin(th'),n,1),2);

    %b = sum(p_thh_gv_th .* repmat(cos(th'),n,1),2);
    b = trapz(th, p_thh_gv_th .* repmat(cos(th'),n,1),2);

    % E_thh_gv_th = atan2(sum(p_thh_gv_th.* repmat(sin(th'),n,1),2), sum(p_thh_gv_th .* repmat(cos(th'),n,1),2));
    E_thh_gv_th = atan2( a, b); % 1000 different th value 
    VAR_thh_gv_th = 1 - sqrt(a.^2+b.^2); % 1000 x 1 for different th value
    STD_thh_gv_th = sqrt(2*(1 - sqrt(a.^2+b.^2)));

    mu_thh_dic( :, i)= E_thh_gv_th;  % n x 3
    var_thh_dic( :, i)= VAR_thh_gv_th;  % n x 3
    std_thh_dic( :, i)= STD_thh_gv_th;  % n x 3
    % already transpose: p_thh_gv_th_dic = p_thh_gv_th_dic';
    p_thh_gv_th_dic( :, :, i) = transpose(p_thh_gv_th);
end

mu_thh_dic = mu_thh_dic'; % 3 x n
var_thh_dic = var_thh_dic'; 
std_thh_dic = std_thh_dic';

% traspose: m -- 1 x 1000, th -- 1000 x 1
% 1000 different m --> in different row of 1000 x 1
% 1000 different th --> in different column 1 x 1000


end


% VONMISESPDF
function d = vonMises( x, mu, kappa)
% Usage: d = vonMises(x,mu,kappa)
% If kappa is very large (and the distribution very narrow),
% we can't use the formula below to compute von mises pdf,
% as it just gives NANs.  But when the distribution is very narrow,
% it approaches a Gaussian.

if kappa>600
    x = x - mu;
    x = wrapToPi(x);
    d = normpdf(x,0,1./(sqrt(kappa)));
else
    d = exp(kappa.*cos((x-mu))) ./ (2*pi*besseli(0,kappa));
end
end