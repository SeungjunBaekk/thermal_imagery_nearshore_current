% fig07_swash_maps.m
% Figure 7: SWASH fields with the KMA wind, averaged over 1200-2100 s of each run, for the five records (columns).
%   (a) time-mean depth-averaged alongshore velocity V (colour) with mean-velocity vectors (U, V)
%   (b) wave energy dissipation rate D (filled contours every 5 W m^-2, lines every 10 W m^-2)
%   Markers: APF (star, origin) and ACM (square); teal outline = AThIVe analysis grid; thick black line = still-water
%   shoreline (still-water depth = 0); dotted lines = |y| = 20 m band of Figure 8; grey dashed lines = |y| = y_blend,
%   beyond which the model bed is blended toward the periodic lateral boundaries.
%
% Data file: data/fig07_swash_maps.nc
%   groups /D1V1 /D1V2 /D2V1 /D2V2 /D2V3, each with
%     x (m, cross-shore, shoreward +), y (m, alongshore, toward 29 deg); origin at the APF
%     depth_still (y,x) m      still-water depth of the model bed (0 = still-water shoreline)
%     U, V (y,x) m s^-1        time-mean depth-averaged velocities (NaN on dry cells: total depth <= 0.05 m or Hs = 0)
%     D (y,x) W m^-2           wave energy dissipation rate D = -d(E c_g)/dx, E = rho g Hs^2/16
%                              (NaN where the total depth < 0.2 m or x < -100 m)
%     footprint_x, footprint_y (corner) m   corners of the AThIVe analysis grid
%   root: apf_x, apf_y, acm_x, acm_y (m) instrument positions; y_blend (m) half-width of the model interior
%
% Computation: none beyond plotting; the vectors are drawn at the grid nodes nearest to a fixed 25-m lattice.
%
% Sections: 0 settings, 1 read data, 2 layout, 3 figure, 4 export.
% Run from this folder.

%% 0 settings
op = struct();
op.dataFile  = fullfile('data', 'fig07_swash_maps.nc');
op.exportFig = false;
op.outName   = 'fig07_swash_maps';
op.names     = {'D1V1', 'D1V2', 'D2V1', 'D2V2', 'D2V3'};
op.lband     = 20;                       % instrument band |y| <= lband (m), dotted lines
op.slim      = [-120 150];  op.llim = [-125 125];
op.climV     = [-0.7 0.7];               % (a) V colour range (m s^-1)
op.qS        = -112.5:25:137.5;          % vector positions x (m)
op.qL        = -110:25:115;              % vector positions y (m)
op.qsA       = 40;                       % vector length (m per m s^-1)
op.refA      = 0.5;                      % reference vector (m s^-1)
op.qLW       = 0.6;  op.qHead = 0.45;
op.DbrLevels = 0:5:50;                   % (b) filled-contour levels (W m^-2)
op.DbrLines  = 10:10:40;                 % (b) contour lines (W m^-2)
op.cmapDbr   = interp1([0 0.35 0.7 1], [1 1 1; 1.0 0.85 0.45; 0.93 0.45 0.12; 0.55 0.08 0.05], linspace(0, 1, 256));
op.rowTags   = {'(a)', '(b)'};
op.figW      = 7.0;                      % figure width (in)
op.gapXc     = 0.07;                     % gap between columns (in)
op.cbH       = 0.09;                     % colour-bar thickness (in)
op.cbCols    = {[1 2], [4 5]};           % columns under which the (a) and (b) colour bars are drawn
op.cbInset   = 0.12;                     % colour-bar inset from the column edges (in)
op.cbTicks   = {-0.6:0.3:0.6, 0:10:50};
op.font      = 'Arial';
op.fs        = struct('tag', 10.5, 'head', 10, 'label', 9.5, 'tick', 9.5, 'cb', 9.5, 'small', 9.5);
op.msAPF     = 6;  op.msACM = 3.6;  op.mLW = 0.5;
op.lwShore   = 1.0;  op.lwBand = 0.8;  op.lwTaper = 0.7;  op.lwDbr = 0.35;
op.xtick     = -100:50:100;  op.xtickLab = {'-100', '', '0', '', '100'};
op.ytick     = -100:50:100;
op.fpColor   = [0 0.62 0.62];  op.fpLW = 1.0;
op.dpi       = 300;

%% 1 read data
nRec = numel(op.names);
MP = struct('name', {}, 's', {}, 'l', {}, 'h0', {}, 'U', {}, 'V', {}, 'D', {}, 'fp', {});
for i = 1:nRec
    g = ['/' op.names{i} '/'];
    MP(i).name = op.names{i};
    MP(i).s  = ncread(op.dataFile, [g 'x'])';
    MP(i).l  = ncread(op.dataFile, [g 'y']);
    MP(i).h0 = double(ncread(op.dataFile, [g 'depth_still']));
    MP(i).U  = double(ncread(op.dataFile, [g 'U']));
    MP(i).V  = double(ncread(op.dataFile, [g 'V']));
    MP(i).D  = double(ncread(op.dataFile, [g 'D']));
    MP(i).fp = [ncread(op.dataFile, [g 'footprint_x']), ncread(op.dataFile, [g 'footprint_y'])];
end
xAPF = ncread(op.dataFile, 'apf_x');  yAPF = ncread(op.dataFile, 'apf_y');
xACM = ncread(op.dataFile, 'acm_x');  yACM = ncread(op.dataFile, 'acm_y');
yBlend = ncread(op.dataFile, 'y_blend');

%% 2 layout (inches; margins from the font sizes)
em = @(pt) pt / 72;  f = op.fs;  nr = 2;  Mg = struct();
Mg.left   = (4*0.56 + 0.4)*em(f.tick) + 1.45*em(f.label) + 0.04;
Mg.right  = 0.05;  Mg.gapX = op.gapXc;
Mg.top    = 1.45*max(em(f.head), em(f.tag)) + 0.03;
Mg.gapY   = 1.45*em(f.tag) + 0.03;
Mg.xlab   = 1.35*em(f.tick) + 1.45*em(f.label) + 0.04;
Mg.cbY    = 1.6*em(f.tick) + 1.6*em(f.cb) + 0.08;
Mg.bottom = Mg.cbY + op.cbH + 0.05 + Mg.xlab;
bw = (op.figW - Mg.left - Mg.right - (nRec - 1)*Mg.gapX) / nRec;  bh = bw * diff(op.llim) / diff(op.slim);
fw = op.figW;
fh = Mg.bottom + nr*bh + (nr - 1)*Mg.gapY + Mg.top;
xOf = @(c) Mg.left + (c - 1)*(bw + Mg.gapX);
yRow = Mg.bottom + (nr - (1:nr))*(bh + Mg.gapY);
posOf = @(q, c) [xOf(c) yRow(q) bw bh];

%% 3 figure
fig = figure;
set(fig, 'Units', 'inches', 'Position', [0.2 0.2 fw fh], 'Color', 'w', 'Name', op.outName, ...
    'DefaultAxesFontName', op.font, 'DefaultTextFontName', op.font);
bwr = interp1([0 0.5 1], [0.15 0.3 0.75; 1 1 1; 0.75 0.15 0.15], linspace(0, 1, 256));
AX = gobjects(nr, nRec);
for r = 1:nr
    for i = 1:nRec
        M_ = MP(i);
        ax = axes(fig, 'Units', 'inches', 'Position', posOf(r, i));  hold(ax, 'on');  AX(r, i) = ax;
        ax.Toolbar.Visible = 'off';
        if r == 1                                                  % (a) V
            imagesc(ax, M_.s, M_.l, M_.V, 'AlphaData', ~isnan(M_.V));
            colormap(ax, bwr);  clim(ax, op.climV);
        else                                                       % (b) D, values above the top level in the top band
            Zc = M_.D;  Zc(Zc > op.DbrLevels(end)) = op.DbrLevels(end) - 1e-6;
            contourf(ax, M_.s, M_.l, Zc, op.DbrLevels, 'LineStyle', 'none');
            contour(ax, M_.s, M_.l, M_.D, op.DbrLines, '-', 'Color', [0.25 0.25 0.25], 'LineWidth', op.lwDbr);
            colormap(ax, interp1(linspace(0, 1, size(op.cmapDbr, 1)), op.cmapDbr, linspace(0, 1, numel(op.DbrLevels) - 1)));
            clim(ax, op.DbrLevels([1 end]));
        end
        contour(ax, M_.s, M_.l, M_.h0, [0 0], 'k', 'LineWidth', op.lwShore);
        if r == 1                                                  % vectors at the nodes nearest to the lattice
            [~, iq] = min(abs(M_.s(:) - op.qS(:)'), [], 1);
            [~, jq] = min(abs(M_.l(:) - op.qL(:)'), [], 1);
            [SS, LL] = meshgrid(M_.s(iq), M_.l(jq));
            quiver(ax, SS, LL, op.qsA * M_.U(jq, iq), op.qsA * M_.V(jq, iq), 0, 'k', 'LineWidth', op.qLW, 'MaxHeadSize', op.qHead);
        end
        yline(ax, [-1 1] * op.lband, ':', 'Color', [0.25 0.25 0.25], 'LineWidth', op.lwBand);
        yline(ax, [-1 1] * yBlend, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', op.lwTaper);
        plot(ax, xAPF, yAPF, 'kp', 'MarkerFaceColor', 'y', 'MarkerSize', op.msAPF, 'LineWidth', op.mLW);
        plot(ax, xACM, yACM, 'ks', 'MarkerFaceColor', 'y', 'MarkerSize', op.msACM, 'LineWidth', op.mLW);
        P_ = M_.fp;  plot(ax, P_([1:end 1], 1), P_([1:end 1], 2), '-', 'Color', op.fpColor, 'LineWidth', op.fpLW);
        set(ax, 'YDir', 'normal', 'XLim', op.slim, 'YLim', op.llim, 'DataAspectRatio', [1 1 1], 'FontSize', f.tick, ...
            'XTick', op.xtick, 'TickDir', 'out', 'Box', 'on', 'Layer', 'top');
        ax.YTick = op.ytick;  ax.XTickLabel = op.xtickLab;  ax.XTickLabelRotation = 0;
        if r == nr && i == ceil(nRec / 2), xlabel(ax, '\itx\rm (m, shoreward +)', 'FontSize', f.label); end
        if r < nr, ax.XTickLabel = []; end
        if r == 1                                                  % column head = record name
            text(ax, 0.5, 1 + 0.02 / bh, op.names{i}, 'Units', 'normalized', 'FontSize', f.head, 'FontWeight', 'bold', ...
                 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
        end
        if i == 1                                                  % row letter and one y label for both rows
            text(ax, 0, 1 + 0.02 / bh, op.rowTags{r}, 'Units', 'normalized', 'FontSize', f.tag, ...
                 'FontWeight', 'bold', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');
            if r == 1
                yc_ = ((yRow(nr) + yRow(1) + bh) / 2 - yRow(1)) / bh;
                text(ax, -(Mg.left - 0.02) / bw, yc_, '\ity\rm (m, alongshore +)', 'Units', 'normalized', 'Rotation', 90, ...
                     'FontSize', f.label, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
            end
        else
            ax.YTickLabel = [];
        end
    end
end
% horizontal colour bars at the bottom, one per row
CB = gobjects(1, nr);
cbLab = {sprintf('%s  \\itV\\rm (m s^{-1})', op.rowTags{1}), sprintf('%s  \\itD\\rm (W m^{-2})', op.rowTags{2})};
for r = 1:nr
    cc_ = op.cbCols{r};  x0_ = xOf(cc_(1)) + op.cbInset;  x1_ = xOf(cc_(end)) + bw - op.cbInset;
    CB(r) = colorbar(AX(r, 1), 'Orientation', 'horizontal', 'Units', 'inches', ...
                     'Position', [x0_, Mg.cbY, x1_ - x0_, op.cbH], 'FontSize', f.tick, 'TickDirection', 'out');
    CB(r).Ticks = op.cbTicks{r};
    CB(r).Label.String = cbLab{r};
    CB(r).Label.FontSize = f.cb;
end
for r = 1:nr, for i = 1:nRec, AX(r, i).Units = 'inches';  AX(r, i).Position = posOf(r, i); end, end
% reference vector in the free column between the colour bars
cr_ = setdiff(1:nRec, [op.cbCols{:}]);
pR_ = [xOf(cr_(1)), 0.02, xOf(cr_(end)) + bw - xOf(cr_(1)), Mg.cbY + op.cbH + 0.06];
inPerM_ = bw / diff(op.slim);
axR = axes(fig, 'Units', 'inches', 'Position', pR_);  hold(axR, 'on');  axR.Toolbar.Visible = 'off';
set(axR, 'XLim', [0 pR_(3) / inPerM_], 'YLim', [0 pR_(4) / inPerM_], 'DataAspectRatio', [1 1 1], 'Visible', 'off');
yA_ = (Mg.cbY - 0.02 + op.cbH / 2) / inPerM_;  L_ = op.qsA * op.refA;
wT_ = 0.58;  xA_ = (pR_(3) / inPerM_ - L_ - (0.05 + wT_) / inPerM_) / 2;
quiver(axR, xA_, yA_, L_, 0, 0, 'k', 'LineWidth', op.qLW, 'MaxHeadSize', op.qHead);
text(axR, xA_ + L_ + 0.05 / inPerM_, yA_, sprintf('%g m s^{-1}', op.refA), 'FontSize', f.small, ...
     'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');

%% 4 export
if op.exportFig
    exportgraphics(fig, [op.outName '.png'], 'Resolution', op.dpi);
    exportgraphics(fig, [op.outName '.pdf'], 'ContentType', 'vector');
end
