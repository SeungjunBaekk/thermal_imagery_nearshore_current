% fig10_mean_fields.m
% Figure 10: time-mean AThIVe surface velocity of each record (every second node) in the local coordinates
% (x shoreward, y alongshore), with the thermal footprint (dashed) and the analysis grid (solid), the APF
% (origin) and the ACM.
%
% Data file: data/fig10_mean_fields.nc, one group per record (/D1V1, /D1V2, /D2V1, /D2V2, /D2V3):
%   t                       (time)        s      time since clip start, drone clock (1-s samples)
%   x, y                    (node)        m      node positions
%   node_col, node_row      (node)        -      column/row index of the node in the regular grid
%   u, v                    (time, node)  m s-1  AThIVe surface velocity, x and y components (NaN = no vector)
%   footprint_x, footprint_y (corner)     m      corners of the thermal image footprint
%   grid_x, grid_y          (corner)      m      corners of the analysis grid outline
%   analysis_interval       (bound)       s      start and end of the analysis interval
% and at the root: acm_xy (xy) m, position of the ACM.
%
% Computation:
%   - Time mean of u and v at each node over the samples inside the analysis interval (NaN samples ignored);
%     nodes with valid samples in less than half of the interval are left blank.
%   - Arrows are drawn at every second node in both grid directions, phased so that the node nearest the APF is drawn.
%   - The ACM marker is filled when the ACM lies inside the analysis grid outline.
%
% Sections: 0 settings, 1 read data and time means, 2 layout, 3 figure, 4 export.
% Run from this folder.

%% 0 settings
op = struct();
op.dataFile  = fullfile('data', 'fig10_mean_fields.nc');
op.exportFig = false;
op.outName   = 'fig10_mean_fields';
op.records   = {'D1V1', 'D1V2', 'D2V1', 'D2V2', 'D2V3'};
op.minValid  = 0.5;                       % minimum fraction of valid samples at a node
op.layout    = [2 3];                     % rows x columns; the sixth cell holds the legend
op.stride    = 2;                         % arrows at every second node
op.arrowK    = 8;                         % arrow length [m per m s^-1]
op.refSpd    = 0.3;                       % reference arrow [m s^-1]
op.xl = [-9 20];  op.yl = [-7 17];  op.xt = [0 10 20];  op.yt = [0 10];
op.cArrow    = [0.85 0.10 0.10];
op.cFrame    = [0.45 0.45 0.45];  op.cGrid = [0.20 0.20 0.20];
op.figW      = 5.4;                       % figure width [in]
op.gapIn     = 0.10;                      % gap between panels [in]
op.font      = 'Arial';
op.fs        = struct('head', 8.5, 'label', 8, 'tick', 7.5, 'legend', 7.5);
op.lw        = struct('arrow', 0.6, 'frame', 0.6, 'grid', 0.7, 'ms', 5);
op.Um        = char(362);                 % U with macron (overbar symbol of the time mean)
op.legLabels = {'APF', 'ACM, inside the grid', 'ACM, outside the grid', 'Thermal footprint', ...
                'Analysis grid', ['AThIVe time mean, \bf' op.Um '\rm_{AThIVe}']};
op.dpi       = 300;
nR = numel(op.records);

%% 1 read data and time means
acm = ncread(op.dataFile, '/acm_xy')';
FLD = struct([]);
for i = 1:nR
    g = ['/' op.records{i} '/'];
    t  = ncread(op.dataFile, [g 't']);
    tw = ncread(op.dataFile, [g 'analysis_interval']);
    u  = ncread(op.dataFile, [g 'u']);                                  % node x time
    v  = ncread(op.dataFile, [g 'v']);
    k  = t >= tw(1) & t <= tw(2);
    nv = sum(isfinite(u(:, k)) & isfinite(v(:, k)), 2);
    U  = mean(u(:, k), 2, 'omitnan');  V = mean(v(:, k), 2, 'omitnan');
    bad = nv < op.minValid * nnz(k);  U(bad) = NaN;  V(bad) = NaN;
    FLD(i).name = op.records{i};
    FLD(i).x  = ncread(op.dataFile, [g 'x']);  FLD(i).y = ncread(op.dataFile, [g 'y']);
    FLD(i).ix = double(ncread(op.dataFile, [g 'node_col']));  FLD(i).iy = double(ncread(op.dataFile, [g 'node_row']));
    FLD(i).U = U;  FLD(i).V = V;  FLD(i).nValid = nv;  FLD(i).nT = nnz(k);
    FLD(i).frame_xy = [ncread(op.dataFile, [g 'footprint_x']) ncread(op.dataFile, [g 'footprint_y'])];
    FLD(i).grid_xy  = [ncread(op.dataFile, [g 'grid_x']) ncread(op.dataFile, [g 'grid_y'])];
    FLD(i).acm_in_grid = inpolygon(acm(1), acm(2), FLD(i).grid_xy(:, 1), FLD(i).grid_xy(:, 2));
    [~, FLD(i).iA] = min(hypot(FLD(i).x, FLD(i).y));                     % node nearest the APF
    ok = isfinite(U) & isfinite(V);
    fprintf('%s: %d/%d nodes, %d samples, grid mean U %+.3f V %+.3f m/s, nearest-APF node U %+.3f V %+.3f m/s\n', ...
        FLD(i).name, nnz(ok), numel(U), nnz(k), mean(U(ok)), mean(V(ok)), U(FLD(i).iA), V(FLD(i).iA));
end

%% 2 layout (margins from the font sizes)
em = @(pt) pt/72;  f = op.fs;
nRow = op.layout(1);  nCol = op.layout(2);
mL = (2*0.56 + 0.4)*em(f.tick) + 1.4*em(f.label) + 0.06;
mR = 0.08;
boxW = (op.figW - mL - mR - (nCol - 1)*op.gapIn) / nCol;
boxH = boxW * diff(op.yl)/diff(op.xl);
hHead = 1.25*em(f.head) + 0.05;
hXlab = 1.3*em(f.tick) + 1.3*em(f.label) + 0.04;
fw = op.figW;  fh = nRow*(hXlab + boxH + hHead) + 0.01;
POSAX = zeros(nR, 4);
for i = 1:nR
    rI = ceil(i / nCol);  cI = i - (rI - 1)*nCol;
    POSAX(i, :) = [mL + (cI - 1)*(boxW + op.gapIn), (nRow - rI)*(hXlab + boxH + hHead) + hXlab, boxW, boxH];
end
inPerM = boxW/diff(op.xl);                                              % inches per metre on the panels

%% 3 figure
fig = figure('Units', 'inches', 'Position', [0.2 0.5 fw fh], 'Color', 'w', ...
    'DefaultAxesFontName', op.font, 'DefaultTextFontName', op.font, 'DefaultLegendFontName', op.font);
AX = gobjects(1, nR);  hL = struct();
for i = 1:nR
    Fi = FLD(i);  ok = isfinite(Fi.U) & isfinite(Fi.V);
    sel = ok & mod(Fi.ix - Fi.ix(Fi.iA), op.stride) == 0 & mod(Fi.iy - Fi.iy(Fi.iA), op.stride) == 0;
    ax = axes(fig, 'Units', 'inches', 'Position', POSAX(i, :));  hold(ax, 'on');  AX(i) = ax;
    fx = Fi.frame_xy;  gxy = Fi.grid_xy;
    hF = plot(ax, fx([1:end 1], 1), fx([1:end 1], 2), '--', 'Color', op.cFrame, 'LineWidth', op.lw.frame);
    hG = plot(ax, gxy([1:end 1], 1), gxy([1:end 1], 2), '-', 'Color', op.cGrid, 'LineWidth', op.lw.grid);
    hQ = quiver(ax, Fi.x(sel), Fi.y(sel), Fi.U(sel)*op.arrowK, Fi.V(sel)*op.arrowK, 0, 'Color', op.cArrow, ...
        'LineWidth', op.lw.arrow, 'MaxHeadSize', 0.5);
    hP = plot(ax, 0, 0, 'k^', 'MarkerFaceColor', 'k', 'MarkerSize', op.lw.ms);
    if Fi.acm_in_grid
        hC = plot(ax, acm(1), acm(2), 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', op.lw.ms, 'LineWidth', 0.8);
        if ~isfield(hL, 'acmIn'), hL.acmIn = hC; end
    else
        hC = plot(ax, acm(1), acm(2), 'ks', 'MarkerFaceColor', 'w', 'MarkerSize', op.lw.ms, 'LineWidth', 0.8);
        if ~isfield(hL, 'acmOut'), hL.acmOut = hC; end
    end
    if i == 1, hL.frame = hF;  hL.grid = hG;  hL.apf = hP;  hL.q = hQ; end
    axis(ax, 'equal');  xlim(ax, op.xl);  ylim(ax, op.yl);  xticks(ax, op.xt);  yticks(ax, op.yt);
    set(ax, 'FontSize', f.tick, 'TickDir', 'in', 'TickLength', [0.015 0.015], 'Layer', 'top', 'Box', 'on', ...
        'LineWidth', 0.6, 'XGrid', 'on', 'YGrid', 'on', 'GridAlpha', 0.12);
    ax.Toolbar.Visible = 'off';
    xlabel(ax, 'x (m)', 'FontSize', f.label);
    if mod(i - 1, nCol) == 0, ylabel(ax, 'y (m)', 'FontSize', f.label); else, ax.YTickLabel = []; end
    text(ax, 0.5, 1.0 + 0.03/boxH, Fi.name, 'Units', 'normalized', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', f.head, 'FontWeight', 'bold');
end
% legend and reference arrow in the sixth cell, centred on the height of the fifth panel
hh = {hL.apf, [], [], hL.frame, hL.grid, hL.q};
if isfield(hL, 'acmIn'), hh{2} = hL.acmIn; end
if isfield(hL, 'acmOut'), hh{3} = hL.acmOut; end
keep = ~cellfun(@isempty, hh);
lg = legend(AX(1), [hh{keep}], op.legLabels(keep), 'Orientation', 'vertical', 'NumColumns', 1, 'FontSize', f.legend, ...
    'Box', 'off', 'AutoUpdate', 'off');
lg.ItemTokenSize = [16 12];
cell6 = [mL + (nCol - 1)*(boxW + op.gapIn), POSAX(end, 2), boxW, boxH + hHead];
lg.Units = 'inches';
refH = 0.24;
blockH = lg.Position(4) + refH;
yTop = POSAX(end, 2) + (boxH + blockH)/2;
lg.Position = [cell6(1) - 0.05, yTop - lg.Position(4), lg.Position(3), lg.Position(4)];
refBox = [cell6(1) + 0.02, lg.Position(2) - refH, cell6(3) - 0.02, refH];
axR = axes(fig, 'Units', 'inches', 'Position', refBox);  hold(axR, 'on');   % invisible axes with the panel scale
set(axR, 'XLim', [0 refBox(3)/inPerM], 'YLim', [0 refBox(4)/inPerM], 'DataAspectRatio', [1 1 1], 'Visible', 'off');
yR = 0.5*refBox(4)/inPerM;
quiver(axR, 0.12/inPerM, yR, op.refSpd*op.arrowK, 0, 0, 'Color', op.cArrow, 'LineWidth', op.lw.arrow, 'MaxHeadSize', 0.5);
text(axR, 0.12/inPerM + op.refSpd*op.arrowK + 0.06/inPerM, yR, sprintf('%.1f m s^{-1}', op.refSpd), 'FontSize', f.legend, ...
    'Color', op.cArrow, 'VerticalAlignment', 'middle');
axR.Toolbar.Visible = 'off';

%% 4 export
if op.exportFig
    exportgraphics(fig, [op.outName '.pdf'], 'ContentType', 'vector');
    exportgraphics(fig, [op.outName '.png'], 'Resolution', op.dpi);
end
