% fig12_apf_profiles.m
% Figure 12: vertical structure of the mean current at the APF for the five records D1V1, D1V2, D2V1, D2V2, D2V3,
%   (a) U (shoreward positive, toward 119 deg) and (b) V (toward 29 deg) against height above the bed.
%   Black circles: phase-balanced profiler means with 95 % intervals; black dashed line: their depth mean.
%   Blue line and shading: SWASH fixed-height time mean below the trough level (mean of 5 alongshore points,
%   +-2 standard deviations); blue dashed line: SWASH whole-depth mean; blue diamond: SWASH top-layer time mean
%   (+-2 standard deviations of the 5 points) at the model mean water level. Square and triangle: AThIVe and
%   RGB PIV surface means at the observed mean water level. Gray band: layer affected by side-lobe interference;
%   black solid and blue dotted horizontal lines: observed and modeled mean water levels.
%
% Data: data/fig12_apf_profiles.nc, one group per record (/D1V1 ... /D2V3), local frame x shoreward (119 deg),
% y alongshore (29 deg), origin at the APF.
%   adcp_t, adcp_p                 APF time (s since 00:00 KST, 1 Hz) and pressure                  (s, dbar)
%   adcp_hab                       profiler cell height above the bed                               (m)
%   adcp_u, adcp_v                 profiler velocity, time x cell, quality-controlled (NaN = rejected) (m s-1)
%   adcp_profile_window            10-min window of the phase-balanced mean [start end)             (s)
%   adcp_depth_window              analysis interval on the APF clock [start end)                   (s)
%   athive_t, athive_u, athive_v   AThIVe surface velocity at the APF over the analysis interval   (s, m s-1)
%   piv_t, piv_u, piv_v            RGB PIV surface velocity at the node nearest the APF            (s, m s-1)
%   swash_t, swash_u_top, swash_v_top   SWASH top-layer velocity, time x 5 alongshore points       (s, m s-1)
%   swash_hab                      SWASH fixed heights above the model bed                          (m)
%   swash_u_profile, swash_v_profile    SWASH fixed-height time-mean velocity, 5 points x height    (m s-1)
%   swash_u_depthmean, swash_v_depthmean SWASH time-mean depth-mean velocity                        (m s-1)
%   swash_mean_depth               SWASH time-mean water depth at the APF                           (m)
%
% Statistics computed here:
%   APF profile   phase-balanced mean per cell: the wave phase is the Hilbert phase of the APF pressure band-passed
%                 to 0.07-0.35 Hz; samples are averaged in 12 phase bins (bins with >= 3 samples) and the bins are
%                 weighted equally (cells need >= 11 bins). 95 % interval per cell: bootstrap of whole wave cycles
%                 (1000 resamples). Depth mean: mean over the cells.
%   Water level   mean depth = mean pressure head over the analysis interval + 0.15 m (sensor height); side-lobe
%                 limit = 0.906 x head + 0.15 m.
%   SWASH         profile = mean of the 5 alongshore points, band = +-2 standard deviations; top layer = time
%                 mean per point, then mean and 2 standard deviations over the points.
%   AThIVe, PIV   time means over the analysis interval.
%
% Sections: 0 settings, 1 read data, 2 APF phase-balanced profiles, 3 means of the other estimates,
%           4 figure, 5 row labels and y-label spacing, 6 export.
% Run from this folder.

%% 0 settings
op = struct();
op.dataFile  = fullfile('data', 'fig12_apf_profiles.nc');
op.exportFig = false;
op.outName   = 'fig12_apf_profiles';
op.names     = {'D1V1', 'D1V2', 'D2V1', 'D2V2', 'D2V3'};
op.nbin = 12;  op.nmin = 3;  op.bandPh = [0.07 0.35];  op.nbootAPF = 1000;  op.seed = 0;
op.g = 9.81;  op.rho = 1025;  op.zSensor = 0.15;  op.sidelobe = 0.906;
op.rowTags = {'(a)', '(b)'};
op.fs = struct('tag', 11, 'head', 10, 'label', 9.5, 'tick', 9, 'legend', 9);
op.sc = 0.9;                                 % marker and line scale
op.tagMargin = 0.045;                        % width of the row-label margin (figure fraction)
op.xlabU = '\itU\rm (m s^{-1})';  op.xlabV = '\itV\rm (m s^{-1})';
op.xtickU = -0.2:0.2:0.2;  op.xtickV = 0:0.2:0.6;
op.xlimU = [-0.27 0.20];  op.xlimV = [-0.05 0.65];
op.Um = char(362);                           % U with macron (overbar symbol of the mean current)
op.legTop = {'APF, phase-balanced mean, 95% interval', ['APF, depth mean, \bf' op.Um '\rm_{APF}'], ...
             'SWASH, time mean (5 alongshore points)', 'SWASH, whole-depth mean', ...
             ['SWASH, top-layer time mean, \bf' op.Um '\rm_{top}'], ...
             ['AThIVe, surface time mean, \bf' op.Um '\rm_{AThIVe}'], 'RGB PIV, surface time mean'};
op.legCols = 2;
op.ylabPad = 2;                              % extra y-label offset (pt)
op.cEQ = [0 0 0];  op.cM = [0.10 0.35 0.75];  op.cT = [0.09 0.63 0.52];  op.cP = [0.58 0.20 0.70];
op.capsz = 2;
op.ytopPad = 0.15;  op.ytickStep = 0.5;
op.figCm = [17 12];
op.dpi = 300;  op.font = 'Arial';

%% 1 read data
n = numel(op.names);
rd = @(i, v) double(ncread(op.dataFile, ['/' op.names{i} '/' v]));
D = struct();
for i = 1:n
    for v = {'adcp_t', 'adcp_p', 'adcp_hab', 'adcp_u', 'adcp_v', 'adcp_profile_window', 'adcp_depth_window', ...
             'athive_t', 'athive_u', 'athive_v', 'piv_t', 'piv_u', 'piv_v', 'swash_t', 'swash_u_top', 'swash_v_top', ...
             'swash_hab', 'swash_u_profile', 'swash_v_profile', 'swash_u_depthmean', 'swash_v_depthmean', ...
             'swash_mean_depth'}
        D(i).(v{1}) = rd(i, v{1});
    end
end

%% 2 APF phase-balanced profiles with wave-cycle bootstrap
nb = op.nbin;
APF = struct();
for i = 1:n
    m = D(i).adcp_t >= D(i).adcp_profile_window(1) & D(i).adcp_t < D(i).adcp_profile_window(2);
    t = D(i).adcp_t(m);  p = D(i).adcp_p(m);  U = D(i).adcp_u(m, :);  V = D(i).adcp_v(m, :);
    N = numel(p);  nc = size(U, 2);
    % wave phase: FFT band-pass of the pressure, then the Hilbert phase
    x = p - mean(p);  x = x - mean(x);
    fk = min(0:N - 1, N - (0:N - 1)).'*(1/(N*median(diff(t))));   % bin frequency k*df (sets the band-edge bins)
    X = fft(x);  X(fk < op.bandPh(1) | fk > op.bandPh(2)) = 0;
    xb = real(ifft(X));
    hw = zeros(N, 1);  hw(1) = 1;
    if mod(N, 2) == 0, hw(N/2 + 1) = 1;  hw(2:N/2) = 2; else, hw(2:(N + 1)/2) = 2; end
    ph = angle(ifft(fft(xb).*hw));
    pb = min(max(floor((ph + pi)/(2*pi)*nb), 0), nb - 1) + 1;     % phase bin
    [~, ~, ci] = unique(floor((unwrap(ph) + pi)/(2*pi)));          % wave cycle
    ncy = max(ci);
    % sums per (cycle, bin) and cell
    idx = sub2ind([ncy nb], ci, pb);
    SU = zeros(ncy*nb, nc);  SV = SU;  CN = SU;
    for j = 1:nc
        ok = isfinite(U(:, j)) & isfinite(V(:, j));
        SU(:, j) = accumarray(idx(ok), U(ok, j), [ncy*nb 1]);
        SV(:, j) = accumarray(idx(ok), V(ok, j), [ncy*nb 1]);
        CN(:, j) = accumarray(idx(ok), 1, [ncy*nb 1]);
    end
    SU = reshape(SU, ncy, []);  SV = reshape(SV, ncy, []);  CN = reshape(CN, ncy, []);
    % estimate with cycle weights w (w = 1: all cycles once; bootstrap: multiplicity of each resampled cycle)
    rsA = RandStream('mt19937ar', 'Seed', op.seed);
    UB = nan(op.nbootAPF, nc);  VB = UB;
    for b = 0:op.nbootAPF
        if b == 0, w = ones(ncy, 1); else, w = accumarray(randi(rsA, ncy, ncy, 1), 1, [ncy 1]); end
        cn = reshape(w.'*CN, nb, nc);  valid = cn >= op.nmin;
        mu = reshape(w.'*SU, nb, nc)./max(cn, 1);  mv = reshape(w.'*SV, nb, nc)./max(cn, 1);
        mu(~valid) = NaN;  mv(~valid) = NaN;
        keep = sum(valid, 1) >= nb - 1;
        ue = mean(mu, 1, 'omitnan');  ve = mean(mv, 1, 'omitnan');
        ue(~keep) = NaN;  ve(~keep) = NaN;
        if b == 0, Ueq = ue;  Veq = ve; else, UB(b, :) = ue;  VB(b, :) = ve; end
    end
    use = isfinite(Ueq);
    APF(i).hab = D(i).adcp_hab(use);
    APF(i).Ueq = Ueq(use).';  APF(i).Veq = Veq(use).';
    APF(i).Ueq_ci = prctile(UB(:, use), [2.5 97.5]).';           % cells x [lo hi]
    APF(i).Veq_ci = prctile(VB(:, use), [2.5 97.5]).';
    APF(i).n_cycles = ncy;
    % mean water depth and side-lobe limit over the analysis interval
    md = D(i).adcp_t >= D(i).adcp_depth_window(1) & D(i).adcp_t < D(i).adcp_depth_window(2);
    hd = mean(D(i).adcp_p(md))*1e4/(op.rho*op.g);
    APF(i).H_obs = hd + op.zSensor;
    APF(i).hab_sidelobe = op.sidelobe*hd + op.zSensor;
end

%% 3 means of the other estimates
OTH = struct();
for i = 1:n
    OTH(i).tiv = [mean(D(i).athive_u, 'omitnan'), mean(D(i).athive_v, 'omitnan')];
    OTH(i).piv = [mean(D(i).piv_u, 'omitnan'), mean(D(i).piv_v, 'omitnan')];
    up = mean(D(i).swash_u_top, 1, 'omitnan');  vp = mean(D(i).swash_v_top, 1, 'omitnan');   % per point
    OTH(i).sw_top = [mean(up), mean(vp)];
    OTH(i).sw_top2sd = [2*std(up), 2*std(vp)];
    OTH(i).sw_U = mean(D(i).swash_u_profile, 1).';  OTH(i).sw_Usd = std(D(i).swash_u_profile, 0, 1).';
    OTH(i).sw_V = mean(D(i).swash_v_profile, 1).';  OTH(i).sw_Vsd = std(D(i).swash_v_profile, 0, 1).';
end

%% 4 figure
fig = figure('Color', 'w', 'Units', 'centimeters', 'Position', [1 1 op.figCm]);
set(fig, 'DefaultAxesFontName', op.font, 'DefaultTextFontName', op.font, 'DefaultAxesFontSize', op.fs.tick, ...
    'DefaultLegendFontName', op.font);
tl = tiledlayout(fig, 2, n, 'TileSpacing', 'compact', 'Padding', 'compact');
AXP = gobjects(2, n);
for i = 1:n
    A = APF(i);  O = OTH(i);
    zA = A.hab;  zM = D(i).swash_hab;  Hm = D(i).swash_mean_depth;
    ytop = max(A.H_obs, Hm) + op.ytopPad;
    for row = 1:2
        ax = nexttile(tl, (row - 1)*n + i);  hold(ax, 'on');  AXP(row, i) = ax;
        if row == 1
            a = A.Ueq;  aL = A.Ueq_ci(:, 1);  aH = A.Ueq_ci(:, 2);
            mm = O.sw_U;  sd = O.sw_Usd;  dm = D(i).swash_u_depthmean;
            ms = O.sw_top(1);  ms2 = O.sw_top2sd(1);  tv = O.tiv(1);  pv = O.piv(1);  xl = op.xlimU;
        else
            a = A.Veq;  aL = A.Veq_ci(:, 1);  aH = A.Veq_ci(:, 2);
            mm = O.sw_V;  sd = O.sw_Vsd;  dm = D(i).swash_v_depthmean;
            ms = O.sw_top(2);  ms2 = O.sw_top2sd(2);  tv = O.tiv(2);  pv = O.piv(2);  xl = op.xlimV;
        end
        % side-lobe layer, mean water levels
        patch(ax, [xl(1) xl(2) xl(2) xl(1)], [A.hab_sidelobe A.hab_sidelobe A.H_obs A.H_obs], [0.9 0.9 0.9], ...
            'EdgeColor', 'none', 'HandleVisibility', 'off');
        yline(ax, A.H_obs, '-', 'Color', [0 0 0], 'LineWidth', 0.6*op.sc, 'HandleVisibility', 'off');
        yline(ax, Hm, ':', 'Color', op.cM, 'LineWidth', 0.9*op.sc, 'HandleVisibility', 'off');
        xline(ax, 0, '-', 'Color', [0.8 0.8 0.8], 'HandleVisibility', 'off');
        % SWASH: +-2 s.d. band and mean of the 5 alongshore points, depth mean
        fill(ax, [mm - 2*sd; flipud(mm + 2*sd)], [zM; flipud(zM)], op.cM, 'FaceAlpha', 0.22, 'EdgeColor', 'none');
        h1 = plot(ax, mm, zM, '-', 'Color', op.cM, 'LineWidth', 2.0*op.sc);
        h2 = xline(ax, dm, '--', 'Color', op.cM, 'LineWidth', 1.0*op.sc);
        % APF depth mean over the resolved cells, then the phase-balanced profile with 95 % intervals
        h3 = plot(ax, mean(a, 'omitnan')*[1 1], [min(zA) max(zA)], '--', 'Color', op.cEQ, 'LineWidth', 1.0*op.sc);
        h4 = errorbar(ax, a, zA, [], [], a - aL, aH - a, 'o-', 'Color', op.cEQ, 'MarkerFaceColor', op.cEQ, ...
            'MarkerSize', 3.4*op.sc, 'LineWidth', 0.9*op.sc, 'CapSize', op.capsz*op.sc);
        h5 = plot(ax, tv, A.H_obs, 's', 'MarkerSize', 7*op.sc, 'MarkerEdgeColor', op.cT, 'LineWidth', 1.6*op.sc);
        h6 = plot(ax, pv, A.H_obs, '^', 'MarkerSize', 6.5*op.sc, 'MarkerEdgeColor', op.cP, 'LineWidth', 1.3*op.sc);
        % SWASH top-layer time mean (+-2 s.d.) at the model mean water level
        h7 = errorbar(ax, ms, Hm, [], [], ms2, ms2, 'd', 'Color', op.cM, 'MarkerFaceColor', op.cM, ...
            'MarkerSize', 5.5*op.sc, 'LineWidth', 1.0*op.sc, 'CapSize', op.capsz*op.sc);
        xlim(ax, xl);  ylim(ax, [0 ytop]);  yticks(ax, 0:op.ytickStep:ytop);  grid(ax, 'on');  box(ax, 'on');
        if row == 1, xticks(ax, op.xtickU); else, xticks(ax, op.xtickV); end
        ax.Toolbar.Visible = 'off';
        if row == 1
            title(ax, op.names{i}, 'FontWeight', 'bold', 'FontSize', op.fs.head);
            xlabel(ax, op.xlabU, 'FontSize', op.fs.label);
        else
            xlabel(ax, op.xlabV, 'FontSize', op.fs.label);
        end
        if i == 1, ylabel(ax, 'height above bed (m)', 'FontSize', op.fs.label); end
        if i == 1 && row == 1, hl = [h4 h3 h1 h2 h7 h5 h6]; end
    end
end
lg = legend(hl, op.legTop, 'Orientation', 'horizontal', 'FontSize', op.fs.legend, 'NumColumns', op.legCols);
lg.Layout.Tile = 'north';

%% 5 row labels (left margin, level with the top of each row) and y-label spacing
tl.Units = 'normalized';  tl.OuterPosition = [op.tagMargin 0 1 - op.tagMargin 1];
drawnow;
ytops = [sum(AXP(1, 1).Position([2 4])), sum(AXP(2, 1).Position([2 4]))];
for p = 1:2
    annotation(fig, 'textbox', [0.004 ytops(p) - 0.04 op.tagMargin 0.04], 'String', op.rowTags{p}, ...
        'FontName', op.font, 'FontSize', op.fs.tag, 'FontWeight', 'bold', 'EdgeColor', 'none', 'Margin', 0, ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', 'FitBoxToText', 'off');
end
drawnow;
for r = 1:2
    yl = AXP(r, 1).YLabel;  yl.Units = 'points';  yl.Position(1) = yl.Position(1) - op.ylabPad;
end

%% 6 export
if op.exportFig
    exportgraphics(fig, [op.outName '.png'], 'Resolution', op.dpi);
    exportgraphics(fig, [op.outName '.pdf'], 'ContentType', 'vector');
end
