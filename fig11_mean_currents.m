% fig11_mean_currents.m
% Figure 11: mean current at the APF for the five records D1V1, D1V2, D2V1, D2V2 and D2V3.
%   (a) Speed of the mean current from AThIVe (surface), SWASH (top layer), the APF (phase-balanced depth mean)
%       and RGB PIV (surface), with the bore/crest celerity c_b = sqrt(g(h+Hs)) and the depth-mean flow under the
%       bore c_b*Hs/(h+Hs) on the broken upper axis; error bars are 95 % bootstrap intervals.
%   (b) Directions (flowing toward, clockwise from grid north) on a logarithmic radius, with 95 % direction arcs;
%       dotted lines are +x (119 deg) and +y (29 deg). The compasses are set in two rows (3 + 2).
%   Symbols in the legend: U-bar_AThIVe = AThIVe surface time mean, U-bar_top = SWASH top-layer time mean,
%   U-bar_APF = APF depth mean.
%
% Data: data/fig11_mean_currents.nc, one group per record (/D1V1 ... /D2V3), local frame x shoreward (119 deg),
% y alongshore (29 deg), origin at the APF.
%   athive_t, athive_u, athive_v   AThIVe surface velocity at the APF over the analysis interval   (s, m s-1)
%   piv_t, piv_u, piv_v            RGB PIV surface velocity at the node nearest the APF            (s, m s-1)
%   swash_t                        SWASH model time, 1200-2100 s                                    (s)
%   swash_u_top, swash_v_top       SWASH top-layer velocity, time x 5 alongshore points             (m s-1)
%   adcp_t, adcp_p                 APF time (s since 00:00 KST, 1 Hz) and pressure                  (s, dbar)
%   adcp_hab                       profiler cell height above the bed                               (m)
%   adcp_u, adcp_v                 profiler velocity, time x cell, quality-controlled (NaN = rejected) (m s-1)
%   adcp_profile_window            10-min window of the phase-balanced mean [start end)             (s)
%   adcp_bore_window               10-min window of the bore/crest celerity [start end)             (s)
%
% Statistics computed here:
%   AThIVe, RGB PIV, SWASH  time mean over the stored series (SWASH: mean of the 5 alongshore points first);
%                           95 % interval from a circular block bootstrap (20-s blocks, 2000 resamples).
%   APF depth mean          phase-balanced mean per cell: the wave phase is the Hilbert phase of the APF pressure
%                           band-passed to 0.07-0.35 Hz; samples are averaged in 12 phase bins (bins with >= 3
%                           samples) and the bins are weighted equally (cells need >= 11 bins); the depth mean is the
%                           mean over the cells. 95 % interval: bootstrap of whole wave cycles (1000 resamples).
%   Bore/crest              h = mean pressure head + 0.15 m; Hs = 4 sqrt(m0) of the pressure spectrum (Welch, 128-s
%                           Hann segments, 50 % overlap) converted to the surface with linear wave theory
%                           (attenuation factor <= 5) over 0.05-0.35 Hz; c_b = sqrt(g(h+Hs)), u_b = c_b Hs/(h+Hs).
%                           95 % interval: bootstrap of zero-downcrossing waves of the surface elevation (2000).
%   Speed and direction intervals are percentiles of the speed and direction of the resampled mean vectors.
%
% Sections: 0 settings, 1 read data, 2 surface and model means, 3 APF phase-balanced depth mean,
%           4 bore/crest celerity, 5 layout, 6 panel (a), 7 panel (b), 8 export.
% Run from this folder.

%% 0 settings
op = struct();
op.dataFile  = fullfile('data', 'fig11_mean_currents.nc');
op.exportFig = false;
op.outName   = 'fig11_mean_currents';
op.names     = {'D1V1', 'D1V2', 'D2V1', 'D2V2', 'D2V3'};
op.xax = 119;  op.yax = 29;                  % bearings of +x and +y (deg from grid north)
op.blk = 20;  op.nboot = 2000;  op.seed = 0; % block length (s), resamples, random seed (surface and model series)
op.nbin = 12;  op.nmin = 3;  op.bandPh = [0.07 0.35];  op.nbootAPF = 1000;   % APF phase-balanced mean
op.g = 9.81;  op.rho = 1025;  op.zSensor = 0.15;                              % gravity, density, sensor height
op.bandHs = [0.05 0.35];  op.kpMax = 5;  op.nseg = 128;  op.nbootBore = 2000; % bore/crest
% sources: 1 AThIVe, 2 RGB PIV, 3 SWASH top layer, 4 APF depth mean, 5 bore/crest celerity, 6 depth-mean flow under it
op.Um   = char(362);                         % U with macron (overbar symbol of the mean current)
op.leg  = {['AThIVe, surface time mean, \bf' op.Um '\rm_{AThIVe}'], 'RGB PIV, surface time mean', ...
           ['SWASH, top-layer time mean, \bf' op.Um '\rm_{top}'], ['APF, depth mean, \bf' op.Um '\rm_{APF}']};
op.legB = {'Bore/crest celerity, c_b = \surd(g(h+H_s))', 'Bore/crest depth-mean flow, c_bH_s/(h+H_s)'};
op.col  = [0.09 0.63 0.52; 0.58 0.20 0.70; 0.10 0.35 0.75; 0.38 0.38 0.38];
op.colB = [0.90 0.45 0.05; 0.99 0.80 0.56];
op.edgeB = [0.90 0.45 0.05; 0.90 0.45 0.05];
op.mk   = {'s', '^', 'd', 'o'};
op.drawOrder  = [1 3 4 2 5 6];               % bar order
op.drawOrderC = [1 3 4 2];                   % compass order
op.lw   = [1.8 1.4 1.1 0.8];                 % compass line widths (op.drawOrderC order)
op.arcLW = 1.0;
op.ylimA = [0 0.75];  op.ytickA = 0:0.1:0.7; % lower axis (mean current)
op.ylimU = [0.75 7];  op.ytickU = 1:7;       % upper axis (bore/crest)
op.barW = 0.135;  op.xlimA = [0.45 5.55];
op.legCols = 2;  op.legRows = 3;
op.valFmt = '%.2f';  op.valGap = 0.10;
op.rminLog = 0.02;  op.rmaxLog = 0.8;        % logarithmic compass radius (m s-1)
op.rtickLog = [0.05 0.1 0.2 0.5];  op.rtickLogLabel = {'', '0.1', '', '0.5'};
op.boxA = [10.0 3.6];  op.boxU = 1.6;  op.gapU = 0.12;  op.dC = 2.2;   % box sizes (in)
op.cGrid = [3 2];                            % compasses in the upper and lower row of (b)
op.font = 'Arial';
op.fs = struct('panel', 22, 'label', 20, 'tick', 20, 'legend', 17, 'small', 17, 'val', 14);
op.ylabA = ['|\bf' op.Um '\rm| (m s^{-1})'];
op.ylabU = 'Bore/crest (m s^{-1})';  op.fsYlabU = 16.8;
op.panelPos = [-0.06 1.02];
op.dpi = 300;

%% 1 read data
n = numel(op.names);
rd = @(i, v) double(ncread(op.dataFile, ['/' op.names{i} '/' v]));
D = struct();
for i = 1:n
    for v = {'athive_t', 'athive_u', 'athive_v', 'piv_t', 'piv_u', 'piv_v', 'swash_t', 'swash_u_top', 'swash_v_top', ...
             'adcp_t', 'adcp_p', 'adcp_hab', 'adcp_u', 'adcp_v', 'adcp_profile_window', 'adcp_bore_window'}
        D(i).(v{1}) = rd(i, v{1});
    end
end

%% 2 surface and model means with block bootstrap
ns = 4;
VAL = nan(n, ns, 2);  BOOT = cell(n, ns);
toBrg = @(x, y) mod(atan2d(x*sind(op.xax) + y*sind(op.yax), x*cosd(op.xax) + y*cosd(op.yax)), 360);
wrap  = @(a) mod(a + 180, 360) - 180;
rng(op.seed);
rsX = RandStream('mt19937ar', 'Seed', op.seed + 1);
for i = 1:n
    srs = {1, D(i).athive_t, [D(i).athive_u, D(i).athive_v], []; ...
           3, D(i).swash_t, [mean(D(i).swash_u_top, 2), mean(D(i).swash_v_top, 2)], []; ...
           2, D(i).piv_t, [D(i).piv_u, D(i).piv_v], rsX};
    for q = 1:size(srs, 1)
        s = srs{q, 1};  tt = srs{q, 2};  X = srs{q, 3};  rs = srs{q, 4};  N = size(X, 1);
        L = round(op.blk/median(diff(tt)));  nb = ceil(N/L);
        Bm = zeros(op.nboot, 2);
        for b = 1:op.nboot
            if isempty(rs), st0 = randi(N, 1, nb); else, st0 = randi(rs, N, 1, nb); end
            rows = mod(st0 - 1 + (0:L - 1).', N) + 1;     % circular blocks of L samples
            rows = rows(1:N);
            Bm(b, :) = mean(X(rows, :), 1, 'omitnan');
        end
        VAL(i, s, :) = mean(X, 1, 'omitnan');
        BOOT{i, s} = Bm;
    end
    % the published figure drew from rsX once more per record (model depth mean, not plotted): skip the same draws
    N = numel(D(i).swash_t);  L = round(op.blk/median(diff(D(i).swash_t)));  nb = ceil(N/L);
    for b = 1:op.nboot, randi(rsX, N, 1, nb); end
end

%% 3 APF phase-balanced depth mean with wave-cycle bootstrap
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
    APF(i).Ueq = Ueq(use);  APF(i).Veq = Veq(use);  APF(i).hab = D(i).adcp_hab(use);  APF(i).n_cycles = ncy;
    VAL(i, 4, :) = [mean(Ueq(use)), mean(Veq(use))];
    BOOT{i, 4} = [mean(UB(:, use), 2, 'omitnan'), mean(VB(:, use), 2, 'omitnan')];
end
% speed and direction with 95 % intervals
CI = nan(n, ns, 2, 2);  SPD = nan(n, ns);  SPDCI = nan(n, ns, 2);  BRG = nan(n, ns);  BRGCI = nan(n, ns, 2);
for i = 1:n
    for s = 1:ns
        Bm = BOOT{i, s};
        for c = 1:2, CI(i, s, c, :) = prctile(Bm(:, c), [2.5 97.5]); end
        SPD(i, s) = hypot(VAL(i, s, 1), VAL(i, s, 2));
        SPDCI(i, s, :) = prctile(hypot(Bm(:, 1), Bm(:, 2)), [2.5 97.5]);
        BRG(i, s) = toBrg(VAL(i, s, 1), VAL(i, s, 2));
        BRGCI(i, s, :) = BRG(i, s) + prctile(wrap(toBrg(Bm(:, 1), Bm(:, 2)) - BRG(i, s)), [2.5 97.5]);
    end
end

%% 4 bore/crest celerity and depth-mean flow under the bore (APF pressure)
BORE = nan(n, 8);                            % h, Hs, c_b, c_b lo, c_b hi, u_b, u_b lo, u_b hi
rsB = RandStream('mt19937ar', 'Seed', op.seed);
for i = 1:n
    m = D(i).adcp_t >= D(i).adcp_bore_window(1) & D(i).adcp_t < D(i).adcp_bore_window(2);
    pm = D(i).adcp_p(m)*1e4/(op.rho*op.g);   % pressure head above the sensor (m)
    N = numel(pm);  h = mean(pm) + op.zSensor;
    x = pm - polyval(polyfit((0:N - 1).', pm, 1), (0:N - 1).');
    % Welch spectrum of the head (1 Hz): Hann segments, 50 % overlap, linear detrend per segment
    Ls = op.nseg;  if N < 2*Ls, Ls = floor(N/2); end
    hn = 0.5 - 0.5*cos(2*pi*(0:Ls - 1).'/Ls);
    st = 1:Ls/2:(N - Ls + 1);  tt = (0:Ls - 1).';
    Spp = zeros(Ls/2 + 1, 1);
    for s0 = st
        seg = x(s0:s0 + Ls - 1);  seg = seg - polyval(polyfit(tt, seg, 1), tt);
        F = fft(seg.*hn);  Spp = Spp + abs(F(1:Ls/2 + 1)).^2;
    end
    Spp = Spp/numel(st)/sum(hn.^2);  Spp(2:end - 1) = 2*Spp(2:end - 1);
    f = (0:Ls/2).'/Ls;
    % linear wavenumber (Newton on kh) for the spectrum and FFT frequencies
    fk = min(0:N - 1, N - (0:N - 1)).'*(1/N);
    fa = [f; fk];  w2h = (2*pi*fa).^2*h/op.g;
    kh = sqrt(max(w2h, 1e-12));  kh(w2h >= 1) = w2h(w2h >= 1);
    for it = 1:60, th = tanh(kh);  kh = kh - (kh.*th - w2h)./(th + kh.*(1 - th.^2)); end
    ka = kh/h;  ka(fa == 0) = 0;
    Kp = min(cosh(ka*h)./cosh(ka*op.zSensor), op.kpMax);
    Kf = Kp(1:numel(f));  Ke = Kp(numel(f) + 1:end);
    bnd = f >= op.bandHs(1) & f <= op.bandHs(2);
    Hs = 4*sqrt(sum(Spp(bnd).*Kf(bnd).^2)*(f(2) - f(1)));
    cb = sqrt(op.g*(h + Hs));  ub = cb*Hs/(h + Hs);
    % surface elevation (FFT transfer, 0.05-0.35 Hz) and zero-downcrossing waves
    Ke(fk < op.bandHs(1) | fk > op.bandHs(2)) = 0;
    eta = real(ifft(fft(x).*Ke));
    sg = sign(eta);
    dn = find(sg(1:end - 1) > 0 & sg(2:end) <= 0) + 1;
    a0 = dn(1:end - 1);  a1 = dn(2:end);  k = a1 - a0 >= 3;  a0 = a0(k);  a1 = a1(k);
    nW = numel(a0);
    e2 = arrayfun(@(j) sum(eta(a0(j):a1(j) - 1).^2), (1:nW).');
    nn = a1 - a0;
    pp = arrayfun(@(j) sum(pm(a0(j):a1(j) - 1)), (1:nW).');
    e2all = sum(e2)/sum(nn);
    Bc = zeros(op.nbootBore, 1);  Bu = Bc;
    for b = 1:op.nbootBore
        j = randi(rsB, nW, nW, 1);
        Hs_ = Hs*sqrt((sum(e2(j))/sum(nn(j)))/e2all);
        h_ = sum(pp(j))/sum(nn(j)) + op.zSensor;
        Bc(b) = sqrt(op.g*(h_ + Hs_));  Bu(b) = Bc(b)*Hs_/(h_ + Hs_);
    end
    BORE(i, :) = [h, Hs, cb, prctile(Bc, [2.5 97.5]), ub, prctile(Bu, [2.5 97.5])];
end
% plotted values (record x source 1-6)
SPDd   = [SPD, BORE(:, 3), BORE(:, 6)];
SPDdCI = cat(2, SPDCI, cat(3, BORE(:, [4 7]), BORE(:, [5 8])));
colD   = [op.col; op.colB];
edgD   = [nan(4, 3); op.edgeB];
legD   = [op.leg, op.legB];

%% 5 layout (margins from font sizes, in inches)
em = @(pt) pt/72;  f = op.fs;
Mg = struct();
Mg.left   = (4*0.56 + 0.4)*em(f.tick) + 1.5*em(f.label) + 0.12;
Mg.right  = 0.30;
Mg.legend = op.legRows*1.45*em(f.legend) + 0.10;
Mg.top    = max(Mg.legend, 1.4*em(f.panel)) + 0.10;
Mg.belowA = 1.4*em(f.tick) + 0.18;
Mg.aboveC = 1.5*em(f.label) + 1.5*em(f.tick) + 0.12;     % record name and N label above each compass
Mg.bottom = 1.5*em(f.tick) + 0.10;
boxW = op.boxA(1);  boxH = op.boxA(2);
fw = Mg.left + boxW + Mg.right;
nRowC = numel(op.cGrid);                                                   % compass rows
hC = Mg.bottom + op.dC + Mg.aboveC;                                        % height of one compass row
fh = nRowC*hC + Mg.belowA + boxH + op.gapU + op.boxU + Mg.top;
yA = nRowC*hC + Mg.belowA;
POS = struct();
POS.a = [Mg.left, yA, boxW, boxH] ./ [fw fh fw fh];                        % lower axis
POS.u = [Mg.left, yA + boxH + op.gapU, boxW, op.boxU] ./ [fw fh fw fh];    % upper axis
pitch = boxW/op.cGrid(1);
for i = 1:n                                                                % lower row centred under the upper row
    if i <= op.cGrid(1)
        colC = i - 0.5;  yC = hC + Mg.bottom;
    else
        colC = i - op.cGrid(1) - 0.5 + (op.cGrid(1) - op.cGrid(2))/2;  yC = Mg.bottom;
    end
    POS.c(i, :) = [Mg.left + colC*pitch - op.dC/2, yC, op.dC, op.dC] ./ [fw fh fw fh];
end
fig = figure('Units', 'inches', 'Position', [0.2 0.2 fw fh], 'Color', 'w', 'Name', op.outName, ...
    'DefaultAxesFontName', op.font, 'DefaultTextFontName', op.font, 'DefaultLegendFontName', op.font, ...
    'DefaultPolarAxesFontName', op.font);
drawnow;

%% 6 panel (a): speed bars, lower axis = mean current, upper axis = bore/crest (broken axis)
axA = axes(fig, 'Position', POS.a);  hold(axA, 'on');
axU = axes(fig, 'Position', POS.u);  hold(axU, 'on');
nd = numel(op.drawOrder);
hB = gobjects(1, nd);
xc = nan(n, nd);
for p = 1:nd
    s = op.drawOrder(p);
    if s >= 5, axS = [axA axU]; else, axS = axA; end     % bore bars run through both axes
    if any(isnan(edgD(s, :))), ec = 'none'; else, ec = edgD(s, :); end
    for i = 1:n
        xc(i, p) = i + (p - (nd + 1)/2)*op.barW;
        x0 = xc(i, p) - op.barW/2;  x1 = xc(i, p) + op.barW/2;  hb = SPDd(i, s);
        for a = 1:numel(axS)
            hp = patch(axS(a), [x0 x1 x1 x0], [0 0 hb hb], colD(s, :), 'EdgeColor', ec, 'LineWidth', 0.8);
            if i == 1 && a == 1, hB(p) = hp; end
        end
    end
    errorbar(axS(end), xc(:, p), SPDd(:, s), SPDd(:, s) - SPDdCI(:, s, 1), SPDdCI(:, s, 2) - SPDd(:, s), 'k', ...
        'LineStyle', 'none', 'LineWidth', 1.0, 'CapSize', 4, 'HandleVisibility', 'off');
    if s >= 5
        for i = 1:n
            text(axU, xc(i, p), SPDdCI(i, s, 2) + op.valGap, sprintf(op.valFmt, SPDd(i, s)), ...
                'FontSize', op.fs.val, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
        end
    end
end
xlim(axA, op.xlimA);  ylim(axA, op.ylimA);
xlim(axU, op.xlimA);  ylim(axU, op.ylimU);
set(axA, 'XTick', 1:n, 'XTickLabel', op.names, 'TickLabelInterpreter', 'tex', 'FontSize', op.fs.tick, ...
    'TickDir', 'in', 'Box', 'on', 'YGrid', 'on', 'GridAlpha', 0.15, 'Layer', 'top', 'TickLength', [0.005 0.005], ...
    'YTick', op.ytickA);
set(axU, 'XTick', 1:n, 'XTickLabel', {}, 'FontSize', op.fs.tick, ...
    'TickDir', 'in', 'Box', 'on', 'YGrid', 'on', 'GridAlpha', 0.15, 'Layer', 'top', 'TickLength', [0.005 0.005], ...
    'YTick', op.ytickU);
ylabel(axA, op.ylabA, 'FontSize', op.fs.label, 'Interpreter', 'tex');
ylabel(axU, op.ylabU, 'FontSize', op.fsYlabU, 'Interpreter', 'tex');
drawnow;                                                  % align both y labels
axA.YLabel.Units = 'normalized';  axU.YLabel.Units = 'normalized';
axU.YLabel.Position(1) = axA.YLabel.Position(1);
bx = 0.07/fw;  by = 0.05/fh;                              % break marks
for xx = [POS.a(1), POS.a(1) + POS.a(3)]
    for yy = [POS.a(2) + POS.a(4), POS.u(2)]
        annotation(fig, 'line', xx + [-bx bx], yy + [-by by], 'Color', 'k', 'LineWidth', 1.0);
    end
end
lgA = legend(axA, hB, legD(op.drawOrder), 'FontSize', op.fs.legend, 'Box', 'off', 'NumColumns', op.legCols, ...
    'Location', 'none', 'AutoUpdate', 'off', 'Interpreter', 'tex');
drawnow;
lp = lgA.Position;
lgA.Position = [POS.u(1) + (POS.u(3) - lp(3))/2, POS.u(2) + POS.u(4) + 0.04/fh, lp(3), lp(4)];
axA.Position = POS.a;  axU.Position = POS.u;
text(axU, op.panelPos(1), op.panelPos(2), '(a)', 'Units', 'normalized', 'FontSize', op.fs.panel, ...
    'FontWeight', 'bold', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');
axA.Toolbar.Visible = 'off';  axU.Toolbar.Visible = 'off';

%% 7 panel (b): direction compasses (log radius)
RT = @(r) max(0, log10(r/op.rminLog)/log10(op.rmaxLog/op.rminLog));
rOut = 1;
PAX = gobjects(1, n);
for i = 1:n
    pax = polaraxes(fig, 'Position', POS.c(i, :));  hold(pax, 'on');  PAX(i) = pax;
    pax.ThetaZeroLocation = 'top';  pax.ThetaDir = 'clockwise';
    pax.ThetaTick = 0:45:315;  pax.ThetaTickLabel = {'N', '', 'E', '', 'S', '', 'W', ''};
    pax.RLim = [0 rOut];  pax.RTick = RT(op.rtickLog);  pax.RAxisLocation = 225;
    pax.RTickLabel = op.rtickLogLabel;
    pax.FontSize = op.fs.tick;
    pax.GridColor = [0.55 0.55 0.55];  pax.GridAlpha = 0.35;
    for a = [op.xax op.yax]
        polarplot(pax, deg2rad([a a]), [0 rOut], ':', 'Color', [0.35 0.35 0.35], 'LineWidth', 1.0);
    end
    if i == 1
        text(pax, deg2rad(op.xax + 8), 0.92*rOut, '+x', 'FontSize', op.fs.small, 'Color', [0.3 0.3 0.3], ...
            'HorizontalAlignment', 'center');
        text(pax, deg2rad(op.yax + 11), 0.92*rOut, '+y', 'FontSize', op.fs.small, 'Color', [0.3 0.3 0.3], ...
            'HorizontalAlignment', 'center');
    end
    for p = 1:ns
        s = op.drawOrderC(p);
        th = deg2rad(BRG(i, s));  r = RT(SPD(i, s));
        polarplot(pax, [th th], [0 r], '-', 'Color', op.col(s, :), 'LineWidth', op.lw(p));
        polarplot(pax, th, r, op.mk{s}, 'Color', op.col(s, :), 'MarkerFaceColor', op.col(s, :), 'MarkerSize', 6, ...
            'LineWidth', 1.0);
        ta = deg2rad(linspace(BRGCI(i, s, 1), BRGCI(i, s, 2), 40));   % 95 % direction arc
        polarplot(pax, ta, r*ones(size(ta)), '-', 'Color', op.col(s, :), 'LineWidth', op.arcLW);
    end
    pax.Toolbar.Visible = 'off';
end
for i = 1:n                                                                % record name above each compass
    pc = POS.c(i, :);
    annotation(fig, 'textbox', [pc(1), pc(2) + pc(4) + 1.5*em(f.tick)/fh, pc(3), 1.5*em(f.label)/fh], ...
        'String', op.names{i}, 'FontSize', op.fs.label, 'FontWeight', 'bold', 'FontName', op.font, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'EdgeColor', 'none', 'Margin', 0);
end
annotation(fig, 'textbox', [POS.a(1) + op.panelPos(1)*POS.a(3), POS.c(1, 2) + POS.c(1, 4) + 1.5*em(f.tick)/fh, ...
    0.05, 1.5*em(f.panel)/fh], 'String', '(b)', 'FontSize', op.fs.panel, 'FontWeight', 'bold', ...
    'FontName', op.font, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'EdgeColor', 'none', 'Margin', 0);

%% 8 export
if op.exportFig
    exportgraphics(fig, [op.outName '.png'], 'Resolution', op.dpi);
    exportgraphics(fig, [op.outName '.pdf'], 'ContentType', 'vector');
end
