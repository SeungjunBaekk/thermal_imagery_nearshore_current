% fig08_swash_profiles.m
% Figure 8: cross-shore SWASH profiles (KMA wind runs) of (a) Hs, (b) wave energy dissipation rate D, (c) mean water
%   level, (d) depth-averaged V and (e) depth-averaged U, averaged over |y| <= 20 m and 1200-2100 s, for the five records
%   (columns). Markers: observations at the APF (star) and the ACM (square), with 95% intervals for the APF currents.
%
% Data file: data/fig08_swash_profiles.nc
%   groups /D1V1 /D1V2 /D2V1 /D2V2 /D2V3, each with
%     model (time means over 1200-2100 s of the SWASH run; x shoreward +, y toward 29 deg, origin at the APF)
%       x (m), y (m); depth_still, Hs, setup (y,x) m; U, V (y,x) m s^-1; Tp (s) APF peak period
%     APF profiler, 1-Hz samples of the 10-min window centred on the analysis interval (seconds from time_origin)
%       apf_time (s), apf_pressure (dbar), cell_hab (m above bed)
%       apf_U, apf_V (time,cell) m s^-1 cross-shore (119 deg) and alongshore (29 deg) velocity
%       apf_corr, apf_pgood (time,cell) percent  beam correlation and percent good
%       analysis_interval (s) [start end) of the AThIVe analysis interval
%     wave height, 1-Hz pressure from 5 min before the start to 5 min after the end of the video (seconds from time_origin)
%       apf_wave_time, apf_wave_pressure (s, dbar); acm_time, acm_pressure (s, dbar)
%     swash_hab_top (m)   top of the SWASH fixed-height mean profile at the APF (below the wave trough)
%   root: apf_x, acm_x (m); apf_sensor_hab, acm_sensor_hab (m) pressure-sensor heights above the bed
%
% Computation
%   model: cells are wet where the time-mean total depth > 0.05 m and Hs > 0; profiles are means over |y| <= 20 m,
%     drawn where the band-mean total depth > 0.2 m. D = -d(E c_g)/dx, E = rho g Hs^2/16, c_g = linear group velocity
%     at Tp and the time-mean total depth (Hs not used where that depth < 0.2 m); E c_g is smoothed by moving means
%     over 5 m in x and 3 rows (15 m) in y, differenced centrally in x, and not used for x < -100 m.
%   Hs: 4 standard deviations of the hydrostatic pressure head p/(rho g) over the video span +-5 min (no depth-attenuation
%     correction, no band limit), the definition of Table 1 of the article; the APF value is rounded as printed in
%     Table 1 (to three decimals, then to two).
%   APF mean current (phase-balanced): cells kept where the mean correlation > 65% and percent good > 40% over the
%     analysis interval and over the window and below the side-lobe limit 0.906 h; samples with correlation or percent
%     good < 50% are dropped; the wave phase of the 0.07-0.35 Hz band-passed pressure (Hilbert transform) is divided
%     into 12 bins, each bin with >= 3 samples is averaged and the bins are weighted equally (>= 11 bins required).
%     The plotted value is the mean over the cells at or below swash_hab_top; the 95% interval is 1.96 times the
%     standard deviation of that mean over 1000 bootstrap resamples of whole wave cycles.
%   The APF mean water level is zero by construction (the model still-water level is the APF 10-min mean).
%
% Sections: 0 settings, 1 read data, 2 model profiles, 3 observations, 4 layout, 5 figure, 6 export.
% Run from this folder.

%% 0 settings
op = struct();
op.dataFile  = fullfile('data', 'fig08_swash_profiles.nc');
op.exportFig = false;
op.outName   = 'fig08_swash_profiles';
op.names     = {'D1V1', 'D1V2', 'D2V1', 'D2V2', 'D2V3'};
op.lband     = 20;                       % alongshore band |y| <= lband (m)
op.hwet      = 0.05;                     % wet: time-mean total depth (m)
op.hwetP     = 0.20;                     % profiles drawn where the band-mean total depth exceeds this (m)
op.rho       = 1025;  op.g = 9.81;
op.dpMin     = 0.20;  op.smoothX = 5;  op.smoothY = 3;  op.xDmin = -100;   % D: min depth, smoothing x (m), y (rows), offshore limit
op.corrMin   = 65;  op.pgMin = 40;  op.sideLobe = 0.906;   % cell selection
op.cMin      = 50;  op.pMin = 50;        % sample screening
op.fPhase    = [0.07 0.35];  op.nBin = 12;  op.nMin = 3;   % phase bins
op.nBoot     = 1000;  op.seed = 0;
op.slim      = [-120 150];
op.col       = {'#c0392b', '#e08e0b', '#7f8c8d', '#8e44ad', '#2471a3'};   % record colours
op.lw        = 2.0;
op.rows      = {'Hs', 'Dbr', 'setup', 'V', 'U'};
op.ylab      = {'\itH\rm_s (m)', '\itD\rm (W m^{-2})', '$\overline{\eta}$ (m)', '\itV\rm (m s^{-1})', '\itU\rm (m s^{-1})'};
op.ylabInt   = {'tex', 'tex', 'latex', 'tex', 'tex'};
op.ylim      = {[0 1.2], [0 55], [-0.03 0.10], [-0.15 0.70], [-0.20 0.06]};
op.rowTags   = {'(a)', '(b)', '(c)', '(d)', '(e)'};
op.mszAPF    = 11;  op.mszACM = 8;
op.boxIn     = [1.75 1.25];              % panel size (in)
op.font      = 'Arial';
op.fs        = struct('tag', 24, 'head', 21, 'label', 20, 'tick', 18, 'legend', 18);
op.dpi       = 300;

%% 1 read data
nRec = numel(op.names);
rd = @(g, v) double(ncread(op.dataFile, ['/' g '/' v]));
xAPF = ncread(op.dataFile, 'apf_x');  xACM = ncread(op.dataFile, 'acm_x');
habAPF = ncread(op.dataFile, 'apf_sensor_hab');
MD = struct([]);  OB = struct([]);
for i = 1:nRec
    g = op.names{i};
    MD(i).s = rd(g, 'x')';  MD(i).l = rd(g, 'y');
    MD(i).h0 = rd(g, 'depth_still');  MD(i).Hs = rd(g, 'Hs');  MD(i).st = rd(g, 'setup');
    MD(i).U = rd(g, 'U');  MD(i).V = rd(g, 'V');  MD(i).Tp = rd(g, 'Tp');
    OB(i).t = rd(g, 'apf_time');  OB(i).p = rd(g, 'apf_pressure');  OB(i).hab = rd(g, 'cell_hab');
    OB(i).U = rd(g, 'apf_U');  OB(i).V = rd(g, 'apf_V');  OB(i).cr = rd(g, 'apf_corr');  OB(i).pg = rd(g, 'apf_pgood');
    OB(i).ana = rd(g, 'analysis_interval');
    OB(i).pw = rd(g, 'apf_wave_pressure');  OB(i).pa = rd(g, 'acm_pressure');
    OB(i).habTop = rd(g, 'swash_hab_top');
end

%% 2 model profiles: band means over |y| <= lband of the time-mean fields, and D
PR = struct([]);
for i = 1:nRec
    M = MD(i);  s = M.s;  l = M.l;  iu = abs(l) <= op.lband + 1e-6;
    Hs = M.Hs;  st = M.st;  U = M.U;  V = M.V;
    wet = M.h0 + M.st > op.hwet & M.Hs > 0;
    Hs(~wet) = NaN;  U(~wet) = NaN;  V(~wet) = NaN;  st(~wet) = NaN;
    pr_ = @(q) mean(q(iu, :), 1, 'omitnan');
    % dissipation rate on the full grid, then band mean
    dep = M.h0 + M.st;  Hd = M.Hs;  Hd(dep < op.dpMin) = NaN;
    w_ = 2*pi / M.Tp;  y0 = w_^2 * max(dep, 0.05) / op.g;
    kh = sqrt(y0) .* (y0 < 1) + y0 .* (y0 >= 1);
    for it_ = 1:40, th_ = tanh(kh);  kh = kh - (kh .* th_ - y0) ./ (th_ + kh .* (1 - th_.^2)); end
    cg = 0.5 * (w_ ./ (kh ./ max(dep, 0.05))) .* (1 + 2*kh ./ sinh(min(2*kh, 50)));
    F = op.rho * op.g * Hd.^2 / 16 .* cg;                        % energy flux (W m^-1)
    ds = mean(diff(s));  dl = mean(diff(l));
    Fs = movmean(movmean(F, round(op.smoothX / ds), 2, 'omitnan'), op.smoothY, 1, 'omitnan');  Fs(isnan(F)) = NaN;
    [Fx, ~] = gradient(Fs, ds, dl);  Dm = -Fx;  Dm(:, s < op.xDmin) = NaN;
    PR(i).s = s;  PR(i).Hs = pr_(Hs);  PR(i).setup = pr_(st);  PR(i).V = pr_(V);  PR(i).U = pr_(U);
    PR(i).D = mean(M.h0(iu, :), 1) + pr_(st);                    % band-mean total depth
    PR(i).Dbr = pr_(Dm);
end

%% 3 observations: Hs at the APF and ACM, phase-balanced APF mean current with cycle bootstrap
rhoG = op.rho * op.g;
OBS = struct([]);
for i = 1:nRec
    o = OB(i);
    % --- Hs = 4 standard deviations of the hydrostatic pressure head (Table 1); APF as printed there
    OBS(i).HsAPF = round(round(4 * std(o.pw * 1e4 / rhoG, 1), 3), 2);
    OBS(i).HsACM = 4 * std(o.pa * 1e4 / rhoG, 1);
    % --- cell selection
    z = o.hab' - habAPF;                                         % cell height above the sensor
    ma = o.t >= o.ana(1) & o.t < o.ana(2);
    hA = mean(o.p(ma)) * 1e4 / rhoG;  h10 = mean(o.p) * 1e4 / rhoG;
    good = mean(o.cr(ma, :), 1) > op.corrMin & mean(o.pg(ma, :), 1) > op.pgMin & z < op.sideLobe * hA & ...
           mean(o.cr, 1) > op.corrMin & mean(o.pg, 1) > op.pgMin & z < op.sideLobe * h10;
    % --- wave phase of the band-passed pressure, phase bins and wave cycles
    n = numel(o.p);  dtm = median(diff(o.t));
    xp = o.p - mean(o.p);  xp = xp - mean(xp);
    Xf = fft(xp);  kk = (0:n - 1)';  fa = min(kk, n - kk) * (1 / (n * dtm));   % bin frequency (Hz)
    Xf(fa < op.fPhase(1) | fa > op.fPhase(2)) = 0;
    phs = angle(hilbert(real(ifft(Xf))));
    pb = min(max(floor((phs + pi) / (2*pi) * op.nBin), 0), op.nBin - 1) + 1;
    [~, ~, ci] = unique(floor((unwrap(phs) + pi) / (2*pi)));
    ncy = max(ci);  nc = numel(z);
    % --- sums per (cycle, bin, cell) of the screened samples
    ok = isfinite(o.U) & isfinite(o.V) & o.cr >= op.cMin & o.pg >= op.pMin;
    U0 = o.U;  U0(~ok) = 0;  V0 = o.V;  V0(~ok) = 0;
    SU = zeros(ncy, op.nBin, nc);  SV = SU;  CN = SU;
    for j = 1:nc
        SU(:, :, j) = accumarray([ci pb], U0(:, j), [ncy op.nBin]);
        SV(:, :, j) = accumarray([ci pb], V0(:, j), [ncy op.nBin]);
        CN(:, :, j) = accumarray([ci pb], double(ok(:, j)), [ncy op.nBin]);
    end
    SU = reshape(SU, ncy, []);  SV = reshape(SV, ncy, []);  CN = reshape(CN, ncy, []);
    % for cycle weights w (column vector): bin counts, bin means, and the equal-weight mean over the valid bins
    cnt  = @(w) reshape(w' * CN, op.nBin, nc);
    bmU  = @(w) reshape(w' * SU, op.nBin, nc) ./ max(cnt(w), 1);
    bmV  = @(w) reshape(w' * SV, op.nBin, nc) ./ max(cnt(w), 1);
    eqm  = @(m, v) sum(m .* v, 1) ./ sum(v, 1);                  % v = valid bins (>= nMin samples)
    v1 = cnt(ones(ncy, 1)) >= op.nMin;
    Ueq = eqm(bmU(ones(ncy, 1)), v1);  Veq = eqm(bmV(ones(ncy, 1)), v1);
    Ueq(sum(v1, 1) < op.nBin - 1) = NaN;  Veq(sum(v1, 1) < op.nBin - 1) = NaN;
    use = good & isfinite(Ueq);
    k = use & o.hab' <= o.habTop + 1e-9;                         % cells the model profile reaches
    OBS(i).U = mean(Ueq(k));  OBS(i).V = mean(Veq(k));
    % --- bootstrap over whole wave cycles
    rng(op.seed, 'twister');
    bU = nan(op.nBoot, 1);  bV = bU;
    for q = 1:op.nBoot
        w = accumarray(randi(ncy, ncy, 1), 1, [ncy 1]);
        v = cnt(w) >= op.nMin;  u_ = eqm(bmU(w), v);  v_ = eqm(bmV(w), v);
        u_(sum(v, 1) < op.nBin - 1) = NaN;  v_(sum(v, 1) < op.nBin - 1) = NaN;
        bU(q) = mean(u_(k), 'omitnan');  bV(q) = mean(v_(k), 'omitnan');
    end
    OBS(i).Uci = 1.96 * std(bU, 1, 'omitnan');  OBS(i).Vci = 1.96 * std(bV, 1, 'omitnan');
end

%% 4 layout (inches; margins from the font sizes)
em = @(pt) pt / 72;  f = op.fs;  Mg = struct();
Mg.tag    = 1.4*em(f.tag) + 0.10;
Mg.left   = Mg.tag + (4*0.56 + 0.4)*em(f.tick) + 1.5*em(f.label) + 0.05;
Mg.gapX   = 0.18;
Mg.right  = 0.15;
Mg.legend = 1.6*em(f.legend) + 0.16;
Mg.top    = Mg.legend + 1.5*em(f.head) + 0.08;
Mg.gapY   = 1.4*em(f.tick) + 0.18;
Mg.bottom = 1.4*em(f.tick) + 1.5*em(f.label) + 0.15;
bw = op.boxIn(1);  bh = op.boxIn(2);  nr = numel(op.rows);
fw = Mg.left + nRec*bw + (nRec - 1)*Mg.gapX + Mg.right;
fh = Mg.bottom + nr*bh + (nr - 1)*Mg.gapY + Mg.top;
posOf = @(r, c) [Mg.left + (c - 1)*(bw + Mg.gapX), Mg.bottom + (nr - r)*(bh + Mg.gapY), bw, bh] ./ [fw fh fw fh];

%% 5 figure
hx = @(h) sscanf(h(2:end), '%2x%2x%2x', [1 3]) / 255;
fig = figure;
set(fig, 'Units', 'inches', 'Position', [0.2 0.2 fw fh], 'Color', 'w', 'Name', op.outName, ...
    'DefaultAxesFontName', op.font, 'DefaultTextFontName', op.font, 'DefaultLegendFontName', op.font);
AX = gobjects(nr, nRec);
mA_ = {'kp', 'MarkerFaceColor', 'k', 'MarkerSize', op.mszAPF};   % APF
mC_ = {'ks', 'MarkerFaceColor', 'k', 'MarkerSize', op.mszACM};   % ACM
for r = 1:nr
    q = op.rows{r};
    for i = 1:nRec
        ax = axes(fig, 'Position', posOf(r, i));  hold(ax, 'on');  AX(r, i) = ax;
        ax.Toolbar.Visible = 'off';
        P_ = PR(i);  mP = P_.D > op.hwetP & isfinite(P_.(q));
        plot(ax, P_.s(mP), P_.(q)(mP), '-', 'Color', hx(op.col{i}), 'LineWidth', op.lw);
        xline(ax, xAPF, ':', 'Color', [0.35 0.35 0.35]);  xline(ax, xACM, ':', 'Color', [0.35 0.35 0.35]);
        if any(strcmp(q, {'setup', 'V', 'U'})), yline(ax, 0, '-', 'Color', [0.65 0.65 0.65]); end
        switch q
            case 'Hs'
                plot(ax, xAPF, OBS(i).HsAPF, mA_{:});
                plot(ax, xACM, OBS(i).HsACM, mC_{:});
            case 'setup'
                plot(ax, xAPF, 0, mA_{:});
            case 'V'
                errorbar(ax, xAPF, OBS(i).V, OBS(i).Vci, mA_{:}, 'CapSize', 4);
            case 'U'
                errorbar(ax, xAPF, OBS(i).U, OBS(i).Uci, mA_{:}, 'CapSize', 4);
        end
        set(ax, 'XLim', op.slim, 'FontSize', f.tick, 'TickDir', 'out', 'Box', 'on', 'Layer', 'top');
        grid(ax, 'on');
        ylim(ax, op.ylim{r});
        if i == 1
            ylabel(ax, op.ylab{r}, 'Interpreter', op.ylabInt{r}, 'FontSize', f.label + 1.5 * strcmp(op.ylabInt{r}, 'latex'));
        else
            ax.YTickLabel = [];
        end
        if r == nr
            xlabel(ax, '\itx\rm (m)', 'FontSize', f.label);
        else
            ax.XTickLabel = [];
        end
        if r == 1, title(ax, op.names{i}, 'FontSize', f.head, 'FontWeight', 'bold'); end
        if i == 1
            text(ax, -Mg.tag / bw - ((4*0.56 + 0.4)*em(f.tick) + 1.5*em(f.label)) / bw, 1, op.rowTags{r}, ...
                 'Units', 'normalized', 'FontSize', f.tag, 'FontWeight', 'bold', 'VerticalAlignment', 'top');
        end
    end
end
% legend across the top
axL = axes(fig, 'Position', [0 0 1 1], 'Visible', 'off');  hold(axL, 'on');  axL.Toolbar.Visible = 'off';
hL = [plot(axL, NaN, NaN, '-', 'Color', 'k', 'LineWidth', op.lw), plot(axL, NaN, NaN, mA_{:}), plot(axL, NaN, NaN, mC_{:})];
lg = legend(axL, hL, {'SWASH 3D', 'APF', 'ACM'}, 'NumColumns', numel(hL), 'FontSize', f.legend, 'Box', 'off', 'Units', 'normalized');
lg.ItemTokenSize = [22 10];
lg.Position(1:2) = [0.5 - lg.Position(3) / 2, 1 - (Mg.legend - 0.04) / fh];

%% 6 export
if op.exportFig
    exportgraphics(fig, [op.outName '.png'], 'Resolution', op.dpi);
    exportgraphics(fig, [op.outName '.pdf'], 'ContentType', 'vector');
end
