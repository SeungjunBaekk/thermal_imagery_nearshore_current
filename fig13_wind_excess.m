% fig13_wind_excess.m
% Figure 13: observed surface excess dU_obs at the APF relative to the KMA 10-m wind.
%   (a) dU_obs of each record on a compass (north up, directions toward which dU_obs points), with the downwind
%       direction of the KMA 10-m wind (dashed), the APF mean wave direction (red tick) and the fixed axes +x, +y
%       (dotted). Shading: speeds of 1-3.5% of U10 within 15 deg of downwind (orange 14 July, blue 15 July).
%   (b) dU_obs of all records relative to the KMA downwind direction (top); arcs and radial bars are the 95%
%       intervals of direction and magnitude; shading as in (a), one band per day.
%
% Data: data/fig13_wind_excess.nc, one group per record (/D1V1, /D1V2, /D2V1, /D2V2, /D2V3), attributes
%   date and regime ('breaking' | 'non-breaking'). Frame: x shoreward toward 119 deg, y alongshore toward 29 deg
%   (grid north), origin at the APF. Times in seconds since 2026-07-14 00:00:00 KST.
%   athive_time (s), athive_U, athive_V (m/s)   AThIVe surface velocity at the APF over the analysed interval
%   apf_time (s), apf_eta (m)                    APF water level (pressure head anomaly) over the 10-min window
%                                                centred on the AThIVe interval
%   apf_hab (m), apf_U, apf_V (m/s, time x cell) APF profiler cells (screened samples are NaN)
%   kma_U10 (m/s), kma_toward (deg)              KMA 10-m wind speed and the direction it blows toward
%   wave_toward (deg)                            APF mean wave direction (toward)
%
% Computation:
%   AThIVe mean = time mean of the series; its 95% interval from a circular block bootstrap (20-s blocks,
%   2000 resamples; half-width = half the 2.5-97.5 percentile range).
%   APF depth mean = phase-balanced (EQ) mean: phase of the 0.07-0.35 Hz band-passed water level (FFT band-pass,
%   Hilbert phase), 12 phase bins, per cell the mean of the bin means (bins with >= 3 samples, cells with >= 11
%   such bins), then the mean over the cells; its 95% interval = 1.96 x standard deviation of the same mean over
%   1000 bootstrap resamples of whole wave cycles.
%   dU_obs = AThIVe mean - APF depth mean, with half-widths hypot(AThIVe, APF) per component.
%   95% ranges in (b): the axis-aligned ellipse of the half-widths around dU_obs, mapped to direction and
%   magnitude; when the ellipse contains the origin, the direction has no interval and the lower magnitude is 0.
%   Drift band: speeds of op.frac x U10 within op.sector of downwind; in (b) from the smallest to the largest
%   U10 of each day.
%   Bootstrap intervals depend on the random numbers, so the bars differ slightly from the published figure.
%
% Sections: 0 settings, 1 read data, 2 compute dU_obs and its intervals, 3 figure frame, 4 panel (a), 5 panel (b),
%   6 export.
% Run from this folder.

%% 0 settings
op = struct();
op.dataFile  = fullfile('data', 'fig13_wind_excess.nc');
op.exportFig = false;
op.outName   = 'fig13_wind_excess';
op.names     = {'D1V1', 'D1V2', 'D2V1', 'D2V2', 'D2V3'};
op.xax = 119;  op.yax = 29;                 % fixed axes, bearing from grid north (deg)
op.blkT  = 20;    op.nbootT = 2000;         % AThIVe circular block bootstrap: block (s), resamples
op.band  = [0.07 0.35];                     % APF phase band (Hz)
op.nb    = 12;    op.nmin = 3;              % phase bins, minimum samples per bin
op.nbootA = 1000;                           % APF wave-cycle bootstrap resamples
op.frac   = [0.01 0.035];                   % drift band: fractions of U10
op.sector = 15;                             % drift band: half-angle about downwind (deg)
op.rmaxA = 0.40; op.rtickA = [0.2 0.4];     % (a) radius (m/s)
op.rmaxB = 0.40; op.rtickB = [0.1 0.2 0.3 0.4];   % (b) radius (m/s)
op.cNB = [0.09 0.63 0.52];  op.cBR = [0.45 0.45 0.45];  op.cWind = [0 0 0];  op.cWave = [0.70 0.12 0.12];
op.dayTag  = {'D1', 'D2'};  op.dayName = {'14 July', '15 July'};
op.cDay    = [0.96 0.70 0.35; 0.45 0.66 0.93];   % drift band colours (14 July, 15 July)
op.aDay    = 0.45;                               % drift band opacity
% (b) record labels: 'cw' / 'ccw' = outside the clockwise / counter-clockwise end of the arc,
% 'fix' = at op.labFix [angle (deg) radius (m/s)] with the alignment op.labAlign
op.labSide = struct('D1V1', 'fix', 'D1V2', 'ccw', 'D2V1', 'cw', 'D2V2', 'cw', 'D2V3', 'fix');
op.labFix  = struct('D1V1', [192 0.125], 'D2V3', [-118 0.085]);
op.labAlign = struct('D1V1', 'right', 'D2V3', 'right');
op.font = 'Arial';
op.fs   = struct('panel', 12, 'head', 10, 'tick', 9, 'legend', 9, 'small', 8.5);
op.fig   = [7.2 4.24];       % figure size (in)
op.dA    = 1.02;             % (a) compass diameter (in)
op.pitch = [1.40 1.72];      % (a) grid pitch (in)
op.a0    = [0.30 0.82];      % (a) lower-left compass position (in)
op.dB    = 2.45;             % (b) compass diameter (in)
op.b0    = [4.30 1.07];      % (b) compass position (in)
op.dpi   = 300;
rng(0, 'twister');

%% 1 read data
n = numel(op.names);
D = struct();
for i = 1:n
    g = ['/' op.names{i} '/'];
    for v = {'athive_time', 'athive_U', 'athive_V', 'apf_time', 'apf_eta', 'apf_hab', 'apf_U', 'apf_V', ...
             'kma_U10', 'kma_toward', 'wave_toward'}
        D(i).(v{1}) = ncread(op.dataFile, [g v{1}]);
    end
    D(i).regime = ncreadatt(op.dataFile, ['/' op.names{i}], 'regime');
end

%% 2 compute dU_obs and its intervals
tiv = nan(n, 2);  tivCI = nan(n, 2);  apf = nan(n, 2);  apfCI = nan(n, 2);
for i = 1:n
    % AThIVe time mean and circular block bootstrap
    X  = [D(i).athive_U D(i).athive_V];  N = size(X, 1);
    L  = round(op.blkT / median(diff(D(i).athive_time)));  nbk = ceil(N / L);
    B  = nan(op.nbootT, 2);
    for r = 1:op.nbootT
        idx = mod((randi(N, nbk, 1) - 1)' + (0:L - 1)', N) + 1;
        idx = idx(1:N);
        B(r, :) = mean(X(idx, :), 1, 'omitnan');
    end
    tiv(i, :)   = mean(X, 1, 'omitnan');
    tivCI(i, :) = (prctile(B, 97.5, 1) - prctile(B, 2.5, 1)) / 2;
    % APF phase: FFT band-pass of the water level, Hilbert phase, 12 bins, wave cycles from the unwrapped phase
    t  = D(i).apf_time;  e = D(i).apf_eta;  m = numel(t);
    ok = isfinite(e);  xi = interp1(t(ok), e(ok), t);  xi = xi - mean(xi);
    k  = (0:m - 1)';  fk = min(k, m - k) * (1 / (m * median(diff(t))));   % bin frequencies (k x 1/(m dt))
    Xf = fft(xi);  Xf(fk < op.band(1) | fk > op.band(2)) = 0;
    ph = angle(hilbert(real(ifft(Xf))));
    pb = min(op.nb, max(1, floor((ph + pi) / (2 * pi) * op.nb) + 1));
    [~, ~, cy] = unique(floor((unwrap(ph) + pi) / (2 * pi)));  ncy = max(cy);
    % sums per (wave cycle, phase bin) for every cell
    U = D(i).apf_U;  V = D(i).apf_V;  nc = size(U, 2);  okc = isfinite(U) & isfinite(V);
    U(~okc) = 0;  V(~okc) = 0;
    lin = sub2ind([ncy op.nb], cy, pb);
    SU = zeros(ncy * op.nb, nc);  SV = SU;  CN = SU;
    for c = 1:nc
        SU(:, c) = accumarray(lin, U(:, c), [ncy * op.nb 1]);
        SV(:, c) = accumarray(lin, V(:, c), [ncy * op.nb 1]);
        CN(:, c) = accumarray(lin, double(okc(:, c)), [ncy * op.nb 1]);
    end
    SU = reshape(SU, ncy, op.nb * nc);  SV = reshape(SV, ncy, op.nb * nc);  CN = reshape(CN, ncy, op.nb * nc);
    % EQ mean per cell for cycle weights w (w = 1: estimate; w = multiplicity: bootstrap resample)
    Mb = nan(op.nbootA, 2);
    for r = 0:op.nbootA
        if r == 0, w = ones(1, ncy); else, w = accumarray(randi(ncy, ncy, 1), 1, [ncy 1])'; end
        cn = reshape(w * CN, op.nb, nc);  valid = cn >= op.nmin;
        mu = reshape(w * SU, op.nb, nc) ./ cn;  mv = reshape(w * SV, op.nb, nc) ./ cn;
        mu(~valid) = NaN;  mv(~valid) = NaN;
        good = sum(valid, 1) >= op.nb - 1;
        eu = mean(mu, 1, 'omitnan');  ev = mean(mv, 1, 'omitnan');  eu(~good) = NaN;  ev(~good) = NaN;
        if r == 0
            apf(i, :) = [mean(eu) mean(ev)];
        else
            Mb(r, :) = [mean(eu, 'omitnan') mean(ev, 'omitnan')];
        end
    end
    apfCI(i, :) = 1.96 * std(Mb, 1, 1, 'omitnan');
end
Dxy  = tiv - apf;                                    % dU_obs = AThIVe mean - APF depth mean
Dci  = hypot(tivCI, apfCI);
W = table(string(op.names(:)), string({D.regime}'), [D.kma_U10]', hypot(tiv(:, 1), tiv(:, 2)), hypot(apf(:, 1), apf(:, 2)), ...
    Dxy(:, 1), Dxy(:, 2), hypot(Dxy(:, 1), Dxy(:, 2)), mod(op.xax - atan2d(Dxy(:, 2), Dxy(:, 1)), 360), [D.kma_toward]', ...
    [D.wave_toward]', Dci(:, 1), Dci(:, 2), 'VariableNames', {'record', 'regime', 'kma_U10', 'athive_mag', 'apf_mag', ...
    'dU_x', 'dU_y', 'dU_mag', 'dU_brg', 'kma_toward', 'wave_toward', 'dU_ci_x', 'dU_ci_y'});
W.angle_kma = mod(W.dU_brg - W.kma_toward + 180, 360) - 180;              % direction of dU_obs relative to downwind
nb  = W.regime == "non-breaking";
dlt = W.angle_kma;  Dm = W.dU_mag;  U10 = W.kma_U10;
cw  = Dm .* sind(dlt);   dw = Dm .* cosd(dlt);                             % crosswind, downwind components
day = ones(n, 1);  day(startsWith(W.record, op.dayTag{2})) = 2;
tt  = linspace(0, 2*pi, 361);
angLo = nan(n, 1);  angHi = nan(n, 1);  rLo = nan(n, 1);  rHi = nan(n, 1);
for i = 1:n
    b  = W.kma_toward(i);
    ex = [sind(op.xax - b), cosd(op.xax - b)];  ey = [sind(op.yax - b), cosd(op.yax - b)];
    P  = cos(tt(:)) * (W.dU_ci_x(i) * ex) + sin(tt(:)) * (W.dU_ci_y(i) * ey) + [cw(i) dw(i)];
    rLo(i) = min(hypot(P(:, 1), P(:, 2)));  rHi(i) = max(hypot(P(:, 1), P(:, 2)));
    if ~inpolygon(0, 0, P(:, 1), P(:, 2))
        a = atan2d(P(:, 1), P(:, 2));  a = dlt(i) + mod(a - dlt(i) + 180, 360) - 180;
        angLo(i) = min(a);  angHi(i) = max(a);
    else
        rLo(i) = 0;                                        % origin inside the interval
    end
end
W.pct_U10 = 100 * Dm ./ U10;  W.pct95_lo = 100 * rLo ./ U10;  W.pct95_hi = 100 * rHi ./ U10;   % magnitude, % of U10
W.ang95_lo = angLo;  W.ang95_hi = angHi;
W.downwind_pct = 100 * dw ./ U10;                                          % downwind component, % of U10
disp(W(:, {'record', 'regime', 'kma_U10', 'athive_mag', 'apf_mag', 'dU_mag', 'pct_U10', 'pct95_lo', 'pct95_hi'}));
disp(W(:, {'record', 'dU_x', 'dU_y', 'dU_ci_x', 'dU_ci_y', 'dU_brg', 'angle_kma', 'ang95_lo', 'ang95_hi', 'downwind_pct'}));
rb = nan(2, 2);                                            % drift band of each day (m/s): [lower upper]
for q = 1:2
    rb(q, :) = [op.frac(1) * min(U10(day == q)), op.frac(2) * max(U10(day == q))];
    fprintf('drift band, %s: %.3f-%.3f m/s (U10 %.2f-%.2f m/s)\n', op.dayName{q}, rb(q, 1), rb(q, 2), ...
        min(U10(day == q)), max(U10(day == q)));
end

%% 3 figure frame
fw = op.fig(1);  fh = op.fig(2);  f = op.fs;
fig = figure;
set(fig, 'Units', 'inches', 'Position', [0.3 0.3 fw fh], 'Color', 'w', 'Name', op.outName, ...
    'DefaultAxesFontName', op.font, 'DefaultTextFontName', op.font, 'DefaultLegendFontName', op.font, ...
    'DefaultPolarAxesFontName', op.font);
drawnow;
nrm = @(p) p ./ [fw fh fw fh];

%% 4 panel (a): one compass per record (3 + 2 grid)
cell_ = [0 1; 1 1; 2 1; 0.5 0; 1.5 0];
PAX = gobjects(1, n);  hR = gobjects(1, 2);  hW = gobjects(1);  hV = gobjects(1);
for i = 1:n
    pos = [op.a0(1) + cell_(i, 1) * op.pitch(1), op.a0(2) + cell_(i, 2) * op.pitch(2), op.dA, op.dA];
    pax = polaraxes(fig, 'Position', nrm(pos));  hold(pax, 'on');  PAX(i) = pax;
    pax.ThetaZeroLocation = 'top';  pax.ThetaDir = 'clockwise';
    pax.ThetaTick = 0:45:315;  pax.ThetaTickLabel = {'N', '', 'E', '', 'S', '', 'W', ''};
    pax.RLim = [0 op.rmaxA];  pax.RTick = op.rtickA;  pax.RAxisLocation = 225;
    pax.RTickLabel = compose('%.1f', op.rtickA);
    pax.FontSize = f.tick;  pax.GridColor = [0.55 0.55 0.55];  pax.GridAlpha = 0.35;  pax.Layer = 'top';
    polarregion(pax, deg2rad(W.kma_toward(i) + [-op.sector op.sector]), min(op.frac * U10(i), op.rmaxA), ...
        'FaceColor', op.cDay(day(i), :), 'FaceAlpha', op.aDay, 'EdgeColor', 'none');
    for a = [op.xax op.yax]
        polarplot(pax, deg2rad([a a]), [0 op.rmaxA], ':', 'Color', [0.35 0.35 0.35], 'LineWidth', 0.9, ...
            'HandleVisibility', 'off');
    end
    if i == 1
        text(pax, deg2rad(op.xax + 11), 0.86 * op.rmaxA, '+x', 'FontSize', f.small, 'Color', [0.3 0.3 0.3], ...
            'HorizontalAlignment', 'center');
        text(pax, deg2rad(op.yax + 14), 0.86 * op.rmaxA, '+y', 'FontSize', f.small, 'Color', [0.3 0.3 0.3], ...
            'HorizontalAlignment', 'center');
    end
    hW = polarplot(pax, deg2rad([W.kma_toward(i) W.kma_toward(i)]), [0 op.rmaxA], '--', 'Color', op.cWind, 'LineWidth', 1.1);
    hV = polarplot(pax, deg2rad([W.wave_toward(i) W.wave_toward(i)]), [0.80 1] * op.rmaxA, '-', 'Color', op.cWave, ...
        'LineWidth', 2.6);
    c = op.cBR;  if nb(i), c = op.cNB; end
    th = deg2rad(W.dU_brg(i));  r = min(Dm(i), op.rmaxA);
    h = polarplot(pax, [th th], [0 r], '-', 'Color', c, 'LineWidth', 2.2);
    polarplot(pax, th, r, 'o', 'Color', c, 'MarkerFaceColor', c, 'MarkerSize', 5, 'HandleVisibility', 'off');
    if nb(i), hR(1) = h; else, hR(2) = h; end
    pax.Toolbar.Visible = 'off';
    annotation(fig, 'textbox', nrm([pos(1), pos(2) + pos(4) + 0.16, pos(3), 0.2]), 'String', op.names{i}, ...
        'FontSize', f.head, 'FontWeight', 'bold', 'FontName', op.font, 'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', 'EdgeColor', 'none', 'Margin', 0);
end
hBd = gobjects(1, 2);
for q = 1:2
    hBd(q) = polarplot(PAX(1), nan, nan, 's', 'MarkerFaceColor', 1 - op.aDay * (1 - op.cDay(q, :)), 'MarkerEdgeColor', 'none', ...
        'MarkerSize', 9);
end
legBand = @(q) sprintf('%g%s%g%% of {\\itU}_{10}, %s', 100 * op.frac(1), char(8211), 100 * op.frac(2), op.dayName{q});
lgA = legend(PAX(1), [hR(1) hR(2) hW hV hBd(1) hBd(2)], {'\Delta\bfU\rm_{obs}, non-breaking', '\Delta\bfU\rm_{obs}, breaking', ...
    'KMA 10-m wind, downwind', 'mean wave direction (APF)', legBand(1), legBand(2)}, ...
    'FontSize', f.legend, 'Box', 'off', 'AutoUpdate', 'off', 'NumColumns', 3);
lgA.Units = 'inches';  drawnow;
lgA.Position(1:2) = [(fw - lgA.Position(3)) / 2, 0.06];     % common legend below both panels (two rows)
annotation(fig, 'textbox', nrm([0.02, fh - 0.24, 0.4, 0.22]), 'String', '(a)', 'FontSize', f.panel, 'FontWeight', 'bold', ...
    'FontName', op.font, 'EdgeColor', 'none', 'Margin', 0, 'VerticalAlignment', 'top');

%% 5 panel (b): dU_obs relative to the KMA downwind direction
pax = polaraxes(fig, 'Position', nrm([op.b0 op.dB op.dB]));  hold(pax, 'on');
pax.ThetaZeroLocation = 'top';  pax.ThetaDir = 'clockwise';  pax.RLim = [0 op.rmaxB];  pax.RAxisLocation = 112.5;
pax.ThetaTick = 0:45:315;  pax.ThetaTickLabel = {'downwind', '45\circ', '90\circ', '135\circ', '180\circ', ...
    '-135\circ', '-90\circ', '-45\circ'};
rtl = compose('%.1f', op.rtickB);  rtl{end} = [rtl{end} ' m s^{-1}'];
pax.RTick = op.rtickB;  pax.RTickLabel = rtl;  pax.FontSize = f.tick;  pax.Layer = 'top';
pax.GridColor = [0.55 0.55 0.55];  pax.GridAlpha = 0.35;
for q = 1:2                                                   % drift band of each day
    polarregion(pax, deg2rad([-op.sector op.sector]), min(rb(q, :), op.rmaxB), 'FaceColor', op.cDay(q, :), 'FaceAlpha', op.aDay, ...
        'EdgeColor', op.cDay(q, :) * 0.8, 'LineWidth', 0.6);
end
for i = 1:n
    c = op.cBR;  if nb(i), c = op.cNB; end
    lwE = 1.5 - 0.3 * ~nb(i);
    if isfinite(angLo(i))                                     % direction interval (arc)
        polarplot(pax, deg2rad(linspace(angLo(i), angHi(i), 90)), Dm(i) * ones(1, 90), '-', 'Color', c, 'LineWidth', lwE);
        for a_ = [angLo(i) angHi(i)]
            polarplot(pax, deg2rad([a_ a_]), Dm(i) + [-0.009 0.009], '-', 'Color', c, 'LineWidth', lwE);
        end
    end
    polarplot(pax, deg2rad([dlt(i) dlt(i)]), [rLo(i) rHi(i)], '-', 'Color', c, 'LineWidth', lwE);   % magnitude interval
    for r_ = [rLo(i) rHi(i)]
        if r_ > 0
            polarplot(pax, deg2rad(dlt(i)) + [-1 1] * 0.012 / max(r_, 0.02), [r_ r_], '-', 'Color', c, 'LineWidth', lwE);
        end
    end
    polarplot(pax, deg2rad(dlt(i)), Dm(i), 'o', 'MarkerFaceColor', c, 'MarkerEdgeColor', 'k', 'MarkerSize', 6.5, ...
        'LineWidth', 0.6);
    switch op.labSide.(op.names{i})
        case 'cw',  tl = [angHi(i) + 6, Dm(i)];  ha = 'left';
        case 'ccw', tl = [angLo(i) - 6, Dm(i)];  ha = 'right';
        otherwise,  tl = op.labFix.(op.names{i});  ha = op.labAlign.(op.names{i});
    end
    text(pax, deg2rad(tl(1)), tl(2), op.names{i}, 'FontSize', f.small + 0.5, 'Color', c * 0.8, 'FontWeight', 'bold', ...
        'HorizontalAlignment', ha, 'VerticalAlignment', 'middle');
end
pax.Toolbar.Visible = 'off';
annotation(fig, 'textbox', nrm([op.b0(1) - 0.45, fh - 0.24, 0.4, 0.22]), 'String', '(b)', 'FontSize', f.panel, ...
    'FontWeight', 'bold', 'FontName', op.font, 'EdgeColor', 'none', 'Margin', 0, 'VerticalAlignment', 'top');

%% 6 export
if op.exportFig
    exportgraphics(fig, [op.outName '.png'], 'Resolution', op.dpi);
    exportgraphics(fig, [op.outName '.pdf'], 'ContentType', 'vector');
end
