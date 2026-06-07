function plot_HeatMap(p_thh_gv_th_dic)

% Basic Grid Parameter
n = 1000;
x0 = linspace(-pi,pi,n);  % end to end

x = linspace(-pi,pi,n+1); % shifted by 1/2 - non-overlapping for marginalization
dx = x(2)-x(1);
x(1) = [ ];
x = x - dx/2;

% variable and measurment
th = x';  % column
m = x;  % row

plot_LB = -40; % lower bond of the plot (deg)
plot_UB = 40;

plot_LB_rad = deg2rad(plot_LB);
plot_UB_rad = deg2rad(plot_UB);

% find closest index
[ ~, LB_index] = min( (th -  plot_LB_rad).^2 );
[ ~, UB_index] = min( (th -  plot_UB_rad).^2 );

PlotData = p_thh_gv_th_dic;
for i = 1: 3 % plot different motion coherence level
    subplot( 1, 3, i)


    % Partial Data
    % partial_p_thh_gv_th = p_thh_gv_th( LB_index: UB_index, LB_index: UB_index);
    partial_p_thh_gv_th = PlotData( LB_index: UB_index, LB_index: UB_index, i );

    colormap('hot');
    imagesc( partial_p_thh_gv_th)

    partial_th = th( LB_index: UB_index);

    xx_deg = rad2deg(partial_th)';
    yy_deg = rad2deg(partial_th)';

    len = length(yy_deg);

    ticks = [1 len/2 len];
    xticks(ticks);

    th_deg = rad2deg(partial_th);
    xticklabels( num2str( round(th_deg(ticks) ) ) );

    yticks(ticks);
    yticklabels( num2str( round( th_deg(ticks) ) )  );

    hold on
    plot( 1:len, 1:len, 'black--' )
    plot( 1:len, len/2+ zeros(1, len), 'black--' )
    hold off

    set(gca,'YDir','normal');
    % if i == 1
    %     ylabel('estimate (deg)');
    % elseif i == 2
    %     xlabel('stimulus variable (deg)');
    % end

    textcell = {'80', '160' , '240' };
    title(textcell(i));

    axis square
    grid on;

end

% sgtitle('prob. density of estimates','FontWeight','normal', 'FontName', 'Times New Roman', 'FontSize', 30)

end


