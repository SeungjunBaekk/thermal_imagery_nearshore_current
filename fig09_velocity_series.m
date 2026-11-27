% fig09_velocity_series.m
% Figure 9: cross-shore velocity U at the APF (shoreward positive) in the five records: AThIVe surface velocity
% at the APF (5 Hz) and the APF depth mean (1 Hz), over the first 94 s of each analysis interval.
% AThIVe is shifted by the lag of maximum correlation of the band-passed series; each panel header gives that
% correlation and lag, computed over the analysis interval.
%
% Data file: data/fig09_velocity_series.nc, one group per record (/D1V1, /D1V2, /D2V1, /D2V2, /D2V3):
%   t_athive          (athive_time)  s      time since clip start, drone clock
%   u_athive          (athive_time)  m s-1  AThIVe surface U at the APF, 5 Hz
%   t_apf             (apf_time)     s      time since clip start, APF clock
%   u_apf             (apf_time)     m s-1  APF depth-mean U, 1 Hz (NaN = invalid sample)
%   clock_offset      scalar         s      drone clock minus APF clock
%   analysis_interval (bound)        s      start and end of the analysis interval, drone clock
%
% Computation:
%   - APF times are moved to the drone clock: t = t_apf + clock_offset.
%   - Means: time means of AThIVe and APF U inside the analysis interval (removed before the band-pass; printed only).
%   - Correlation: both series are interpolated to a 5-Hz grid over the analysis interval, gaps filled linearly,
%     the mean removed and band-passed (0.07-0.35 Hz, 3rd-order Butterworth, zero phase). AThIVe is shifted by
%     lags of -5 to +5 s (0.2-s steps) and correlated with the APF series on grid points within 1 s of a valid
%     APF sample. r is the maximum correlation and lag its lag (positive = AThIVe lags the APF).
%   - Plot: AThIVe is advanced by the lag; time axis starts at the start of the analysis interval.
%
% Sections: 0 settings, 1 read data, 2 statistics, 3 figure, 4 export.
% Run from this folder.

%% 0 settings
op = struct();
op.dataFile  = fullfile('data', 'fig09_velocity_series.nc');
op.exportFig = false;
op.outName   = 'fig09_velocity_series';
op.records   = {'D1V1', 'D1V2', 'D2V1', 'D2V2', 'D2V3'};
op.titles    = {'D1V1 (14 Jul 13:24)', 'D1V2 (14 Jul 13:45)', 'D2V1 (15 Jul 07:11)', 'D2V2 (15 Jul 07:33)', 'D2V3 (15 Jul 07:48)'};
op.excerptLen = 94;                       % plotted length from the start of the analysis interval [s]
op.band   = [0.07 0.35];                  % band-pass [Hz]
op.fsGrid = 5;                            % common grid for the correlation [Hz]
op.lagMax = 5;                            % lag search range [s] (0.2-s steps)
op.cAPF   = [0.10 0.35 0.80];  op.cTIV = [0 0 0];
op.legend = {'AThIVe at the APF, surface (5 Hz)', 'APF, depth mean (1 Hz)'};
op.ylab   = '\itU\rm (m s^{-1})';
op.xlab   = 'Time since start of analysis interval (s)';
op.xtickStep = 10;
op.figIn  = [5.4 7.6];                    % figure size [in]
op.font   = 'Arial';
op.fs     = struct('tick', 8, 'label', 9, 'name', 9, 'stat', 8, 'legend', 8.5);
op.mg     = struct('left', 0.58, 'right', 0.08, 'top', 0.40, 'bottom', 0.40, 'gapY', 0.40);   % margins [in]
op.lw     = struct('tiv', 0.9, 'apf', 0.9, 'ms', 6);
op.dpi    = 300;
nC = numel(op.records);

%% 1 read data
DAT = cell(1, nC);
for ic = 1:nC
    g = ['/' op.records{ic} '/'];
    dd = struct();
    dd.tT = ncread(op.dataFile, [g 't_athive']);
    dd.uT = ncread(op.dataFile, [g 'u_athive']);
    dd.tA = ncread(op.dataFile, [g 't_apf']);
    dd.uA = ncread(op.dataFile, [g 'u_apf']);
    dd.D  = ncread(op.dataFile, [g 'clock_offset']);
    dd.tw = ncread(op.dataFile, [g 'analysis_interval'])';
    DAT{ic} = dd;
end

%% 2 statistics (analysis interval)
[bb, aa] = butter(3, op.band/(0.5*op.fsGrid), 'bandpass');
fillnan = @(x) interp1(find(isfinite(x)), x(isfinite(x)), (1:numel(x))', 'linear', 'extrap');
lags = -op.lagMax:0.2:op.lagMax;
S = struct('meanT', cell(1, nC), 'meanA', [], 'rmax', [], 'lag', []);
for ic = 1:nC
    dd = DAT{ic};  tw = dd.tw;
    ta  = dd.tA + dd.D;                                                 % APF time on the drone clock
    okA = isfinite(dd.uA);
    ka  = ta >= tw(1) & ta <= tw(2);  kt = dd.tT >= tw(1) & dd.tT <= tw(2);
    tg  = (tw(1):1/op.fsGrid:tw(2))';
    okg = interp1(ta(okA), ones(nnz(okA), 1), tg, 'nearest', 0) > 0 & ...
          abs(tg - interp1(ta(okA), ta(okA), tg, 'nearest', 'extrap')) <= 1;   % within 1 s of a valid APF sample
    mT = mean(dd.uT(kt), 'omitnan');  mA = mean(dd.uA(ka), 'omitnan');
    gT = filtfilt(bb, aa, fillnan(interp1(dd.tT, dd.uT, tg, 'linear')) - mT);
    gA = filtfilt(bb, aa, fillnan(interp1(ta(okA), dd.uA(okA), tg, 'linear')) - mA);
    rr = nan(size(lags));
    for il = 1:numel(lags)
        gS = interp1(tg, gT, tg + lags(il), 'linear');  ok = okg & isfinite(gS) & isfinite(gA);
        if nnz(ok) > 50, cc = corrcoef(gS(ok), gA(ok));  rr(il) = cc(1, 2); end
    end
    [rmax, im] = max(rr);
    S(ic).meanT = mT;  S(ic).meanA = mA;  S(ic).rmax = rmax;  S(ic).lag = lags(im);
    DAT{ic}.ta = ta;
    fprintf('%s: mean AThIVe %+.3f, APF %+.3f m/s | r = %.3f at lag %+.1f s\n', op.records{ic}, mT, mA, rmax, lags(im));
end

%% 3 figure (one row per record)
f = op.fs;  mg = op.mg;  FW = op.figIn(1);  FH = op.figIn(2);
pw = FW - mg.left - mg.right;  ph = (FH - mg.top - mg.bottom - (nC - 1)*mg.gapY)/nC;
fig = figure('Units', 'inches', 'Position', [0.3 0.3 FW FH], 'Color', 'w', ...
    'DefaultAxesFontName', op.font, 'DefaultTextFontName', op.font, 'DefaultLegendFontName', op.font, ...
    'DefaultAxesFontSize', f.tick);
ax = gobjects(nC, 1);
for ic = 1:nC
    dd = DAT{ic};  s_ = S(ic);
    ex = dd.tw(1) + [0 op.excerptLen];                                  % plotted interval
    a_ = axes(fig, 'Units', 'inches', 'Position', [mg.left, FH - mg.top - ic*ph - (ic-1)*mg.gapY, pw, ph]);
    ax(ic) = a_;  hold(a_, 'on');
    yline(a_, 0, ':', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.6);
    ka = dd.ta >= ex(1) - 1 & dd.ta <= ex(2) + 1;
    hA = plot(a_, dd.ta(ka) - ex(1), dd.uA(ka), '.-', 'Color', op.cAPF, 'LineWidth', op.lw.apf, 'MarkerSize', op.lw.ms);
    sh = s_.lag;                                                        % AThIVe advanced by the lag
    kt = dd.tT - sh >= ex(1) - 1 & dd.tT - sh <= ex(2) + 1;
    hT = plot(a_, dd.tT(kt) - sh - ex(1), dd.uT(kt), '-', 'Color', op.cTIV, 'LineWidth', op.lw.tiv);
    xr = ex - ex(1);
    xlim(a_, xr);  grid(a_, 'on');  box(a_, 'on');
    yl = max(abs([dd.uA(ka); dd.uT(kt)]), [], 'omitnan');  yl = 0.25*ceil(max(0.5, yl)/0.25);  ylim(a_, [-yl yl]);
    ytS = 1;  if yl < 1, ytS = 0.5; end
    set(a_, 'FontSize', f.tick, 'TickDir', 'in', 'TickLength', [0.008 0.008], 'LineWidth', 0.6, 'GridAlpha', 0.12, ...
        'Layer', 'top', 'XTick', 0:op.xtickStep:xr(2), 'YTick', -floor(yl/ytS)*ytS:ytS:floor(yl/ytS)*ytS);
    ylabel(a_, op.ylab, 'FontSize', f.label);
    if ic == nC, xlabel(a_, op.xlab, 'FontSize', f.label); end
    yH = 1 + 0.03/ph;                                                   % header line just above the axes
    text(a_, 0, yH, op.titles{ic}, 'Units', 'normalized', 'FontSize', f.name, 'FontWeight', 'bold', ...
        'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left', 'Margin', 1);
    txt = sprintf('r = %.2f (lag %+.1f s)', s_.rmax, s_.lag);
    text(a_, 1.0, yH, txt, 'Units', 'normalized', 'FontSize', f.stat, 'HorizontalAlignment', 'right', ...
        'VerticalAlignment', 'bottom', 'Margin', 1);
    if ic == 1
        lg = legend(a_, [hT hA], op.legend, 'Orientation', 'horizontal', 'AutoUpdate', 'off', ...
            'FontSize', f.legend, 'Box', 'off');
        lg.Units = 'inches';  lg.Position = [mg.left + (pw - lg.Position(3))/2, FH - lg.Position(4) - 0.02, lg.Position(3), lg.Position(4)];
    end
    a_.Toolbar.Visible = 'off';
end

%% 4 export
if op.exportFig
    exportgraphics(fig, [op.outName '.pdf'], 'ContentType', 'vector');
    exportgraphics(fig, [op.outName '.png'], 'Resolution', op.dpi);
end
