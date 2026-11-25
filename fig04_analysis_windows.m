% fig04_analysis_windows.m
% Figure 4: tide and drone altitude of the five video records.
%   (a) Water level: tide predicted from the Anheung tide-gauge harmonic constants and transferred to the site
%       (line), 10-min mean water level from the APF pressure (dots), mean water level of each record at its
%       start (circles), high water (HW) and low water (LW) of the predicted tide (triangles), and the drone
%       flights for the SfM topography (green) and the Depth from Waves (DfW) bathymetry (orange).
%   (b)-(f) Drone altitude (ellipsoidal height recorded by the drone) against time from the start of each
%       video; the bar is the analysis interval.
%
% Data file: data/fig04_analysis_windows.nc
%   root   tide_time         [h since 2026-07-14 00:00 KST]  time of the predicted tide (5-min step)
%          tide_eta          [m]   predicted tide, deviation from its own mean
%          apf_time          [h since 2026-07-14 00:00 KST]  centre of the 10-min APF windows
%          apf_water_level   [m, MSL]  10-min mean water level from the APF pressure
%          high_water_time, low_water_time  [h since 2026-07-14 00:00 KST]  HW and LW of the predicted tide
%          sfm_flight_time   [h since 2026-07-14 00:00 KST]  start/end of the SfM flights (bounds x flight)
%          dfw_flight_time   [h since 2026-07-14 00:00 KST]  start/end of the DfW video (bounds x flight)
%   /D1V1, /D1V2, /D2V1, /D2V2, /D2V3
%          elapsed_time      [s]   time from the start of the video
%          drone_altitude    [m]   ellipsoidal height recorded by the drone
%          analysis_interval [s]   start and end of the analysis interval
%          video_start_time  [h since 2026-07-14 00:00 KST]
%          mean_water_level  [m, MSL]  mean water level of the record (10-min APF window)
%
% Computation: the predicted tide is a deviation from its own mean; it is shifted by the mean difference
%   between the APF 10-min water levels and the tide interpolated to their times, so that the curve sits on
%   the APF (MSL) datum. HW/LW markers are placed on the shifted curve.
%
% Sections: 0 settings, 1 read data, 2 compute, 3 panel positions, 4 figure (a), 5 figure (b)-(f), 6 export.
% Run from this folder.

%% 0 settings
op = struct();
op.dataFile  = fullfile('data', 'fig04_analysis_windows.nc');
op.exportFig = false;
op.outName   = 'fig04_analysis_windows';
op.recName = {'D1V1', 'D1V2', 'D2V1', 'D2V2', 'D2V3'};
op.recCol  = {'#0f7f6e', '#7d3c98', '#b9770e', '#1a5276', '#922b21'};
op.cTIV  = '#008080';  op.cTide = '#2471a3';
op.cAlt  = [0.25 0.25 0.25];  op.cProf = [0.45 0.45 0.45];  op.cEdge = [0.6 0.6 0.6];
op.gridAlpha = 0.1;
% tide panel
op.tRef    = datetime(2026, 7, 14);                    % time origin of the stored hours (KST)
op.tRange  = [datetime(2026, 7, 14, 9, 0, 0), datetime(2026, 7, 15, 12, 0, 0)];
op.tickH   = 6;                                        % tick spacing [h]
op.tidePad = [1.6 1.05];                               % space below and above the water levels [m]
op.noteT   = [datetime(2026, 7, 14, 13, 35, 0), datetime(2026, 7, 15, 7, 32, 0)];   % times the notes point to
op.noteXY  = [0.22 0.06; 0.69 0.06];                   % note positions (axes fraction)
op.noteTxt = {sprintf('%s %c %s', op.recName{1}, char(183), op.recName{2}), ...   % char(183): middle dot
              sprintf('%s %c %s %c %s', op.recName{3}, char(183), op.recName{4}, char(183), op.recName{5})};
op.tideXlabel = 'time [KST]';
op.tideYlabel = 'water level [m, MSL]';
op.tideLegend = {'predicted tide', 'APF, 10-min mean level', 'SfM survey', 'DfW survey'};
op.sfmColor = '#1a9850';  op.sfmAlpha = 0.35;
op.dfwColor = '#f39c12';  op.dfwAlpha = 0.45;
% flight panels
op.xlimF = [-100 520];                                 % time axis [s]
op.barY  = 0.08;                                       % bar centre height (axes fraction)
op.barH  = 0.08;                                       % bar thickness (axes fraction)
op.fYlabel = 'drone altitude [m]';
op.fYlabelPanel = 3;                                   % flight panel that carries the y label
op.fXlabel = 'time [s]';
op.barLegend = 'analysis interval';
% layout (figure fractions)
op.figIn     = [8.5 8.5];                              % figure size [in]
op.margin    = [0.09 0.025 0.075 0.07];                % left, right, bottom, top
op.hRatio    = [2.6 1 1 1 1 1];                        % tide row : flight panels
op.vGap      = [0.10 0.046 0.046 0.046 0.046];         % gaps between rows
op.wRatioTop = [5.7 0.7];                              % top row widths: water level, record key
op.wGapTop   = 0.057;
op.keyStep   = 0.13;                                   % record key line spacing (axes fraction)
% fonts
op.font = 'Arial';
op.fs = struct('tick', 14, 'label', 14, 'title', 14, 'legend', 14, 'hwlw', 12, 'note', 14, 'key', 14);

%% 1 read data
rd = @(v) ncread(op.dataFile, v);
TD = struct();
TD.tH   = rd('/tide_time');
TD.eta0 = rd('/tide_eta');
TD.qH   = rd('/apf_time');
TD.lvl  = rd('/apf_water_level');
TD.hwH  = rd('/high_water_time');
TD.lwH  = rd('/low_water_time');
sfmH = rd('/sfm_flight_time').';                       % [flight, start/end]
dfwH = rd('/dfw_flight_time').';
nF = numel(op.recName);
FL = struct('name', op.recName, 'col', op.recCol);
for i = 1:nF
    g = ['/' FL(i).name '/'];
    FL(i).tAlt = rd([g 'elapsed_time']);
    FL(i).alt  = rd([g 'drone_altitude']);
    FL(i).tAna = rd([g 'analysis_interval']).';
    FL(i).t0H  = rd([g 'video_start_time']);
    FL(i).mwl  = rd([g 'mean_water_level']);
end

%% 2 compute
hx   = @(h) sscanf(h(2:end), '%2x%2x%2x', [1 3]) / 255;   % '#rrggbb' -> [r g b]
mix  = @(c, a) a*c + (1 - a)*[1 1 1];                      % colour mixed with white (opaque)
toH  = @(t) hours(t - op.tRef);                            % datetime -> hours since op.tRef
% shift the predicted tide onto the APF datum
TD.off = mean(TD.lvl - interp1(TD.tH, TD.eta0, TD.qH), 'omitnan');
TD.eta = TD.eta0 + TD.off;
for i = 1:nF
    FL(i).dur  = max(FL(i).tAlt);                          % video duration
    FL(i).when = char(string(op.tRef + hours(FL(i).t0H), 'dd MMM HH:mm', 'en_US'));
end
fprintf('tide shifted by %+.4f m\n', TD.off);
fprintf('%-5s %-13s %9s %7s %7s %7s\n', 'name', 'start', 'interval', 'dur', 'alt', 'mwl');
for i = 1:nF
    fprintf('%-5s %-13s %4g-%-4g %7.1f %7.2f %7.3f\n', FL(i).name, FL(i).when, FL(i).tAna, FL(i).dur, ...
            mean(FL(i).alt(FL(i).tAlt >= FL(i).tAna(1) & FL(i).tAlt <= FL(i).tAna(2))), FL(i).mwl);
end

%% 3 panel positions
W   = 1 - op.margin(1) - op.margin(2);
nR  = numel(op.hRatio);
vg  = op.vGap;
hU  = (1 - op.margin(3) - op.margin(4) - sum(vg)) / sum(op.hRatio);
hh  = op.hRatio*hU;
yb  = 1 - op.margin(4) - cumsum(hh) - [0 cumsum(vg)];         % bottom of each row
wU  = (W - op.wGapTop*(numel(op.wRatioTop) - 1)) / sum(op.wRatioTop);
ww  = op.wRatioTop*wU;
xl  = op.margin(1) + [0, cumsum(ww(1:end - 1) + op.wGapTop)];
POS = struct();
POS.tide   = [xl(1) yb(1) ww(1) hh(1)];
POS.key    = [xl(2) yb(1) ww(2) hh(1)];
POS.flight = [repmat(op.margin(1), nR - 1, 1), yb(2:end).', repmat(W, nR - 1, 1), hh(2:end).'];

%% 4 figure: (a) water level and record key
fig = figure('Units', 'inches', 'Position', [0.4 0.1 op.figIn], 'Color', 'w', 'Name', op.outName, ...
             'DefaultAxesFontName', op.font, 'DefaultTextFontName', op.font, 'DefaultLegendFontName', op.font);
drawnow;
ptOf = @(p) p(3:4) .* fig.Position(3:4) * 72;              % panel [width height] in pt
% top and right frame lines without ticks
frameTR = @(ax) plot(ax, ax.XLim([1 2 2]), ax.YLim([2 2 1]), '-', 'Color', ax.XColor, ...
                     'LineWidth', ax.LineWidth, 'Clipping', 'off', 'HandleVisibility', 'off');
axT = axes(fig, 'Position', POS.tide, 'FontSize', op.fs.tick, 'TickDir', 'out', 'Layer', 'top', 'Box', 'off');
hold(axT, 'on');
xr = toH(op.tRange);
m  = TD.tH >= xr(1) & TD.tH <= xr(2);
mq = TD.qH >= xr(1) & TD.qH <= xr(2);
for q = 1:size(sfmH, 1)                                    % survey flights as vertical bands
    hSfm = patch(axT, sfmH(q, [1 2 2 1]), [-1e3 -1e3 1e3 1e3], mix(hx(op.sfmColor), op.sfmAlpha), 'EdgeColor', 'none');
end
for q = 1:size(dfwH, 1)
    hDfw = patch(axT, dfwH(q, [1 2 2 1]), [-1e3 -1e3 1e3 1e3], mix(hx(op.dfwColor), op.dfwAlpha), 'EdgeColor', 'none');
end
hTide = plot(axT, TD.tH(m), TD.eta(m), '-', 'Color', hx(op.cTide), 'LineWidth', 1.2);
hProf = plot(axT, TD.qH(mq), TD.lvl(mq), '.', 'Color', op.cProf, 'MarkerSize', 6);
lo = min([TD.eta(m); TD.lvl(mq)]);  hi = max([TD.eta(m); TD.lvl(mq)]);
set(axT, 'XLim', xr, 'YLim', [lo - op.tidePad(1), hi + op.tidePad(2)]);
ylT = axT.YLim;  szT = ptOf(POS.tide);
dxdp = diff(xr)/szT(1);  dydp = diff(ylT)/szT(2);          % data units per pt
hwlw = {TD.hwH, 'v', 'HW', 8; TD.lwH, '^', 'LW', -16};    % times, marker, text, text offset [pt]
for r = 1:2
    tt = hwlw{r, 1};  tt = tt(tt >= xr(1) & tt <= xr(2));
    for q = 1:numel(tt)
        x = tt(q);  y = interp1(TD.tH, TD.eta, x);
        plot(axT, x, y, hwlw{r, 2}, 'MarkerSize', 5, 'Color', [.25 .25 .25], 'MarkerFaceColor', [.25 .25 .25]);
        tq = dateshift(op.tRef + hours(x), 'start', 'minute', 'nearest');  tq.Format = 'HH:mm';
        hL = text(axT, x, y + hwlw{r, 4}*dydp, [hwlw{r, 3} ' ' char(tq)], 'HorizontalAlignment', 'center', ...
                  'VerticalAlignment', 'baseline', 'FontSize', op.fs.hwlw, 'Color', [.25 .25 .25]);
        e = hL.Extent;                                     % keep the text inside the axes
        if e(1) + e(3) > xr(2), set(hL, 'HorizontalAlignment', 'right', 'Position', [xr(2) - 2*dxdp, hL.Position(2), 0]); end
        if e(1) < xr(1),        set(hL, 'HorizontalAlignment', 'left',  'Position', [xr(1) + 2*dxdp, hL.Position(2), 0]); end
    end
end
for i = 1:nF                                               % record mean water level at the video start
    plot(axT, FL(i).t0H, FL(i).mwl, 'o', 'MarkerSize', 6, 'MarkerFaceColor', 'w', ...
         'MarkerEdgeColor', hx(FL(i).col), 'LineWidth', 1.5);
end
drawnow;
for q = 1:numel(op.noteTxt)                                % record-group notes with a pointer line
    x  = toH(op.noteT(q));  y = interp1(TD.tH, TD.eta, x);
    xa = xr(1) + op.noteXY(q, 1)*diff(xr);  ya = ylT(1) + op.noteXY(q, 2)*diff(ylT);
    hN = text(axT, xa, ya, op.noteTxt{q}, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
              'FontSize', op.fs.note, 'Interpreter', 'none');
    e  = hN.Extent;  yt = e(2) + e(4);
    d  = [(x - xa)/dxdp, (y - yt)/dydp];  s = max(0, 1 - 6/norm(d));   % stop 6 pt before the curve
    plot(axT, [xa, xa + s*(x - xa)], [yt, yt + s*(y - yt)], '-', 'Color', [.5 .5 .5], 'LineWidth', 0.7);
end
xt = ceil(xr(1)/op.tickH)*op.tickH : op.tickH : xr(2);
tl = op.tRef + hours(xt);  tl.Format = 'dd HH''h''';
set(axT, 'XTick', xt, 'XTickLabel', cellstr(tl), 'XGrid', 'on', 'YGrid', 'on', 'GridAlpha', op.gridAlpha);
frameTR(axT);
text(axT, 0, 1, '(a)', 'Units', 'normalized', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
     'FontSize', op.fs.title, 'FontWeight', 'bold');
ylabel(axT, op.tideYlabel, 'FontSize', op.fs.label);
xlabel(axT, op.tideXlabel, 'FontSize', op.fs.label, 'Interpreter', 'none');
lgT = legend(axT, [hTide hProf hSfm hDfw], op.tideLegend, 'NumColumns', 2, 'Box', 'off', ...
             'FontSize', op.fs.legend, 'Interpreter', 'none', 'AutoUpdate', 'off');
lgT.ItemTokenSize = [14 8];
drawnow;
lgT.Units = 'normalized';
lgT.Position(1:2) = [POS.tide(1) + POS.tide(3) - lgT.Position(3), POS.tide(2) + POS.tide(4) + 0.001];
% record key
axK = axes(fig, 'Position', POS.key, 'Visible', 'off', 'XLim', [0 1], 'YLim', [0 1]);
hold(axK, 'on');
yk = 0.5 + ((nF - 1)/2 - (0:nF - 1))*op.keyStep;
for i = 1:nF
    plot(axK, 0.08, yk(i), 'o', 'MarkerSize', 6, 'MarkerEdgeColor', hx(FL(i).col), 'MarkerFaceColor', 'w', 'LineWidth', 1.3);
    text(axK, 0.26, yk(i), FL(i).name, 'FontSize', op.fs.key, 'VerticalAlignment', 'middle');
end

%% 5 figure: (b)-(f) drone altitude and analysis interval
axF = gobjects(1, nF);
for i = 1:nF
    ax = axes(fig, 'Position', POS.flight(i, :), 'FontSize', op.fs.tick, 'TickDir', 'out', 'Layer', 'top', 'Box', 'off');
    hold(ax, 'on');  axF(i) = ax;
    lo  = min(FL(i).alt);  hi = max(FL(i).alt);  pad = max(1, 0.15*(hi - lo));
    ylF = [lo - 2*pad, hi + pad];  sp = diff(ylF);         % room for the bar below the altitude line
    yc = ylF(1) + op.barY*sp;  hb = op.barH/2*sp;
    patch(ax, FL(i).tAna([1 2 2 1]), yc + hb*[-1 -1 1 1], hx(op.cTIV), 'EdgeColor', 'none');
    plot(ax, FL(i).tAlt, FL(i).alt, '-', 'Color', op.cAlt, 'LineWidth', 1.1);
    plot(ax, [0 0], ylF, '-', [1 1]*FL(i).dur, ylF, '-', 'Color', op.cEdge, 'LineWidth', 0.6);   % video start and end
    set(ax, 'XLim', op.xlimF, 'YLim', ylF, 'XGrid', 'on', 'YGrid', 'on', 'GridAlpha', op.gridAlpha);
    if i < nF, ax.XTickLabel = {}; end
    frameTR(ax);
    if i == op.fYlabelPanel, ylabel(ax, op.fYlabel, 'FontSize', op.fs.label); end
    ax.TitleHorizontalAlignment = 'left';
    title(ax, sprintf('\\color{black}(%c)   \\color[rgb]{%.4f,%.4f,%.4f}%s   %s', 'a' + i, hx(FL(i).col), ...
          FL(i).name, FL(i).when), 'FontSize', op.fs.title, 'FontWeight', 'bold', 'Interpreter', 'tex');
end
xlabel(axF(end), op.fXlabel, 'FontSize', op.fs.label);
hBar = patch(axF(1), NaN, NaN, hx(op.cTIV), 'EdgeColor', 'none');   % legend entry
lgB = legend(axF(1), hBar, op.barLegend, 'Orientation', 'horizontal', 'Box', 'off', ...
             'FontSize', op.fs.key, 'AutoUpdate', 'off');
lgB.ItemTokenSize = [12 8];
drawnow;
lgB.Units = 'normalized';
lgB.Position(1:2) = [POS.flight(1, 1) + POS.flight(1, 3) - lgB.Position(3), POS.flight(1, 2) + POS.flight(1, 4) + 0.001];
for ax = [axT axK axF], ax.Toolbar.Visible = 'off'; end

%% 6 export
if op.exportFig
    exportgraphics(fig, [op.outName '.png'], 'Resolution', 300);
    exportgraphics(fig, [op.outName '.pdf'], 'ContentType', 'vector');
end
