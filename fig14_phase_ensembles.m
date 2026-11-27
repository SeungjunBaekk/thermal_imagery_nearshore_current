% fig14_phase_ensembles.m
% Figure 14: wave-phase ensembles at the APF (crest at 0 deg) for the five records (columns).
%   (a) U and (b) V from AThIVe (squares), the APF depth mean (circles) and the SWASH top layer; shading = 95%
%       block-bootstrap intervals; dotted orange = AThIVe minus 0.03 U10 along the KMA wind (non-breaking records).
%       Delta-phi = phase shift applied to AThIVe.
%   (c), (d) Spectra S_UU and S_VV; dotted lines = peak frequency f_p and its harmonics.
%
% Data: data/fig14_phase_ensembles.nc, one group per record (/D1V1, /D1V2, /D2V1, /D2V2, /D2V3), attributes
%   date and regime. Frame: x shoreward toward 119 deg, y alongshore toward 29 deg (grid north), origin at the APF.
%   athive_time (s since 2026-07-14 00:00:00 KST), athive_U, athive_V (m/s)   AThIVe at the APF, video clock
%   apf_time (s, same reference), apf_eta (m)       APF water level (pressure head anomaly)
%   apf_U, apf_V (m/s)                              APF depth mean (screened cells below the side-lobe limit; NaN = rejected)
%   swash_time (s, model time), swash_y (m)         SWASH output times and the five alongshore points at the APF
%   swash_eta (m), swash_U, swash_V (m/s)           SWASH (KMA wind run) surface elevation and top-layer velocity
%   kma_U10_x, kma_U10_y (m/s)                      KMA 10-m wind at the APF averaged over the AThIVe interval
%
% Computation:
%   Phase: APF water level band-passed at 0.07-0.35 Hz (3rd-order Butterworth, zero phase), Hilbert phase,
%   interpolated to the AThIVe times; 12 phase bins, crest = 0 deg.
%   AThIVe phase shift: the AThIVe phase is shifted so that the phase of the fundamental harmonic of AThIVe U
%   (regression u = c0 + a cos(phi) + b sin(phi)) matches that of the APF (+ = AThIVe lags).
%   Ensembles: bin means; 95% intervals from 1000 bootstrap resamples of 16-s blocks (same blocks for both series).
%   Wind drift: 0.03 U10 along the KMA wind, subtracted from every AThIVe bin.
%   SWASH: phase from its own surface elevation (series resampled to 4 Hz), ensembles and spectra averaged over
%   the five alongshore points.
%   Spectra: Welch, 64-s Hann windows, 50% overlap (APF gaps filled by linear interpolation).
%   f_p: peak of the APF water-level spectrum between 0.05 and 0.3 Hz.
%
% Sections: 0 settings, 1 read data, 2 observations, 3 SWASH, 4 layout and axis ranges, 5 figure, 6 export.
% Run from this folder.

%% 0 settings
op = struct();
op.dataFile  = fullfile('data', 'fig14_phase_ensembles.nc');
op.exportFig = false;
op.outName   = 'fig14_phase_ensembles';
op.names     = {'D1V1', 'D1V2', 'D2V1', 'D2V2', 'D2V3'};
op.band    = [0.07 0.35];     % phase band (Hz)
op.nb      = 12;              % phase bins
op.blk     = 16;              % bootstrap block (s), about two wave periods
op.nboot   = 1000;
op.nwin    = 64;              % Welch window (s)
op.fsS     = 4;               % SWASH resampling rate (Hz)
op.alpha   = 0.03;            % wind drift factor (x U10)
op.windRec = {'D2V1', 'D2V2'};   % records with the drift-subtracted AThIVe curve
op.fmax    = 1.0;  op.nHarm = 4;  op.ylimS = [1e-4 1e1];
op.padTop  = [0.22 0.06];     % top margin of the U and V rows (fraction of range)
op.cT = [0.09 0.63 0.52];  op.cA = [0 0 0];  op.cS = [0.10 0.35 0.75];  op.cW = [0.84 0.37 0.00];
op.mkT = 's';  op.mkA = 'o';  op.ms = 5;
op.lw = struct('T', 1.6, 'A', 1.4, 'S', 1.6, 'W', 2.0, 'spec', 1.2);
op.ciAlpha = struct('T', 0.22, 'A', 0.13);
op.legend = {'AThIVe, surface', ['AThIVe ' char(8722) ' 0.03\itU\rm_{10} (KMA)'], 'APF, depth mean', 'SWASH, top layer'};
op.rowTags = {'(a)', '(b)', '(c)', '(d)'};
op.boxIn   = [1.85 1.62];     % panel box (in)
op.font    = 'Arial';
op.fs      = struct('panel', 19, 'label', 19, 'tick', 19, 'legend', 16, 'head', 19, 'small', 15);
op.dpi     = 300;

%% 1 read data
nc = numel(op.names);
D = struct();
for i = 1:nc
    g = ['/' op.names{i} '/'];
    for v = {'athive_time', 'athive_U', 'athive_V', 'apf_time', 'apf_eta', 'apf_U', 'apf_V', 'swash_time', ...
             'swash_eta', 'swash_U', 'swash_V', 'kma_U10_x', 'kma_U10_y'}
        D(i).(v{1}) = double(ncread(op.dataFile, [g v{1}]));
    end
end
ctr  = -180 + (0.5:op.nb) * 360 / op.nb;                         % bin centres (deg)
binOf = @(ph) min(op.nb, 1 + floor((ph + pi) / (2 * pi) * op.nb));
wrap = @(ph) angle(exp(1i * ph));

%% 2 observations: phase, ensembles, bootstrap intervals, phase shift, spectra
R = struct();
for i = 1:nc
    tT = D(i).athive_time;  uT = D(i).athive_U;  vT = D(i).athive_V;
    ta = D(i).apf_time;  eta = D(i).apf_eta;  uCol = D(i).apf_U;  vCol = D(i).apf_V;
    fsA = 1 / median(diff(ta));  fsT = 1 / median(diff(tT));
    inW = ta >= tT(1) & ta <= tT(end);
    [bb, aa] = butter(3, op.band / (fsA / 2));
    phu = unwrap(angle(hilbert(filtfilt(bb, aa, eta - mean(eta)))));
    phT = wrap(interp1(ta, phu, tT));  phA = wrap(phu);
    kA = inW & isfinite(uCol);
    uA = uCol(kA);  vA = vCol(kA);  pA = phA(kA);  tA = ta(kA);
    % peak frequency of the APF water level
    nwA = 2 * round(op.nwin * fsA / 2);
    [Pp, fp_] = pwelch(detrend(eta(inW)), hann(nwA), nwA / 2, [], fsA);
    [~, ip] = max(Pp .* (fp_ >= 0.05 & fp_ <= 0.3));
    % fundamental-harmonic regression and phase alignment of AThIVe to the APF
    XT = [ones(size(phT)) cos(phT) sin(phT)];  XA = [ones(size(pA)) cos(pA) sin(pA)];
    cTu = XT \ uT;  cAu = XA \ uA;
    shiftU = wrap(atan2(cTu(3), cTu(2)) - atan2(cAu(3), cAu(2)));
    phTa   = wrap(phT - shiftU);
    bTi = binOf(phTa);  bAi = binOf(pA);
    % 16-s block bootstrap of the bin means
    nbk = max(2, floor((tT(end) - tT(1)) / op.blk));
    bT  = min(nbk, 1 + floor((tT - tT(1)) / op.blk));  bA = min(nbk, 1 + floor((tA - tT(1)) / op.blk));
    iT  = accumarray(bT, (1:numel(bT))', [nbk 1], @(q) {q});  iA = accumarray(bA, (1:numel(bA))', [nbk 1], @(q) {q});
    rng(200 + i, 'twister');
    ciT = nan(op.nboot, op.nb, 2);  ciA = nan(op.nboot, op.nb, 2);
    for r = 1:op.nboot
        sel = randi(nbk, nbk, 1);  jt = vertcat(iT{sel});  ja = vertcat(iA{sel});
        ciT(r, :, 1) = accumarray(bTi(jt), uT(jt), [op.nb 1], @mean, NaN)';
        ciT(r, :, 2) = accumarray(bTi(jt), vT(jt), [op.nb 1], @mean, NaN)';
        if numel(ja) >= 20
            ciA(r, :, 1) = accumarray(bAi(ja), uA(ja), [op.nb 1], @mean, NaN)';
            ciA(r, :, 2) = accumarray(bAi(ja), vA(ja), [op.nb 1], @mean, NaN)';
        end
    end
    % spectra
    wT  = hann(2 * round(op.nwin * fsT / 2));  wA = hann(2 * round(op.nwin * fsA / 2));
    [SuT, fT] = pwelch(detrend(uT), wT, numel(wT) / 2, [], fsT);
    [SvT, ~ ] = pwelch(detrend(vT), wT, numel(wT) / 2, [], fsT);
    tw  = ta(inW);
    uAi = interp1(ta(kA), uCol(kA), tw, 'linear', 'extrap');  vAi = interp1(ta(kA), vCol(kA), tw, 'linear', 'extrap');
    [SuA, fA] = pwelch(detrend(uAi), wA, numel(wA) / 2, [], fsA);
    [SvA, ~ ] = pwelch(detrend(vAi), wA, numel(wA) / 2, [], fsA);
    % store
    R(i).name  = op.names{i};  R(i).shift = rad2deg(shiftU);  R(i).fp = fp_(ip);
    R(i).uT_b  = accumarray(bTi, uT, [op.nb 1], @mean, NaN);  R(i).vT_b = accumarray(bTi, vT, [op.nb 1], @mean, NaN);
    R(i).uA_b  = accumarray(bAi, uA, [op.nb 1], @mean, NaN);  R(i).vA_b = accumarray(bAi, vA, [op.nb 1], @mean, NaN);
    R(i).uT_ci = prctile(ciT(:, :, 1), [2.5 97.5], 1);  R(i).vT_ci = prctile(ciT(:, :, 2), [2.5 97.5], 1);
    R(i).uA_ci = prctile(ciA(:, :, 1), [2.5 97.5], 1);  R(i).vA_ci = prctile(ciA(:, :, 2), [2.5 97.5], 1);
    R(i).Uw    = op.alpha * [D(i).kma_U10_x D(i).kma_U10_y];                 % wind drift (x, y)
    R(i).uW_b  = R(i).uT_b - R(i).Uw(1);  R(i).vW_b = R(i).vT_b - R(i).Uw(2);
    R(i).spec  = struct('fT', fT, 'SuT', SuT, 'SvT', SvT, 'fA', fA, 'SuA', SuA, 'SvA', SvA);
end
disp(table(string(op.names(:)), round([R.shift]', 1), round([R.fp]', 4), ...
    'VariableNames', {'record', 'dphi_deg', 'fp_Hz'}));

%% 3 SWASH: top-layer ensembles from the model's own surface phase, averaged over the five alongshore points
fsS = op.fsS;
[bS, aS] = butter(3, op.band / (fsS / 2));
wS = hann(2 * round(op.nwin * fsS / 2));
SW = struct();
for i = 1:nc
    tS0 = D(i).swash_time;  ny = size(D(i).swash_eta, 2);
    tS  = (ceil(tS0(1) * fsS) / fsS : 1 / fsS : floor(tS0(end) * fsS) / fsS)';   % uniform 0.25-s times
    Bu = zeros(op.nb, ny);  Bv = Bu;  Sps = zeros(numel(wS) / 2 + 1, 2, ny);
    for j = 1:ny
        eta = interp1(tS0, D(i).swash_eta(:, j), tS);
        b   = binOf(angle(hilbert(filtfilt(bS, aS, eta - mean(eta)))));
        Uk  = interp1(tS0, D(i).swash_U(:, j), tS);  Vk = interp1(tS0, D(i).swash_V(:, j), tS);
        Bu(:, j) = accumarray(b(isfinite(Uk)), Uk(isfinite(Uk)), [op.nb 1], @mean, NaN);
        Bv(:, j) = accumarray(b(isfinite(Vk)), Vk(isfinite(Vk)), [op.nb 1], @mean, NaN);
        [Sps(:, 1, j), fS] = pwelch(detrend(Uk), wS, numel(wS) / 2, [], fsS);
        Sps(:, 2, j) = pwelch(detrend(Vk), wS, numel(wS) / 2, [], fsS);
    end
    SW(i).ut_b = mean(Bu, 2);  SW(i).vt_b = mean(Bv, 2);
    SW(i).fS = fS;  SW(i).S = mean(Sps, 3);                    % columns: S_UU, S_VV
end

%% 4 layout (in) and axis ranges
em = @(pt) pt / 72;
f  = op.fs;
boxW = op.boxIn(1);  boxH = op.boxIn(2);
M = struct();
M.left   = (4 * 0.56 + 0.4) * em(f.tick) + 2 * 1.25 * em(f.label) + 0.10 + 3 * 0.62 * em(f.panel) + 0.08;
M.tagX   = 0.04;
M.gapX   = (4 * 0.56 + 0.4) * em(f.tick) + 0.12;
M.right  = 0.18;
M.legend = 1.6 * em(f.legend) + 0.12;
M.head   = 1.3 * em(f.head) + 0.08;
M.top    = M.legend + M.head;
M.gapIn  = 0.12;
M.gapMid = 1.4 * em(f.tick) + 1.5 * em(f.label) + 0.22;
M.bottom = 1.4 * em(f.tick) + 1.5 * em(f.label) + 0.10;
fw = M.left + 5 * boxW + 4 * M.gapX + M.right;
fh = M.bottom + 4 * boxH + 2 * M.gapIn + M.gapMid + M.top;
yRow = zeros(1, 4);
yRow(4) = M.bottom;  yRow(3) = yRow(4) + boxH + M.gapIn;
yRow(2) = yRow(3) + boxH + M.gapMid;  yRow(1) = yRow(2) + boxH + M.gapIn;
xCol = M.left + (0:4) * (boxW + M.gapX);
% y range of each phase panel: all curves and intervals of the record, rounded to 0.1 m/s
padR = @(rg, pt) [floor(10 * (rg(1) - 0.06 * diff(rg))) ceil(10 * (rg(2) + pt * diff(rg)))] / 10;
ylPr = {zeros(nc, 2), zeros(nc, 2)};
fT_ = {'uT_b', 'vT_b'};  fA_ = {'uA_b', 'vA_b'};  fS_ = {'ut_b', 'vt_b'};  fW_ = {'uW_b', 'vW_b'};
ciF = {{'uT_ci', 'vT_ci'}, {'uA_ci', 'vA_ci'}};
for i = 1:nc
    for p = 1:2
        y_ = [R(i).(fT_{p})(:); R(i).(fA_{p})(:); SW(i).(fS_{p})(:); R(i).(ciF{1}{p})(:); R(i).(ciF{2}{p})(:)];
        if ismember(op.names{i}, op.windRec), y_ = [y_; R(i).(fW_{p})(:)]; end %#ok<AGROW>
        ylPr{p}(i, :) = padR([min(y_) max(y_)], op.padTop(p));
    end
end
niceStep = @(yl) 0.1 * (diff(yl) <= 0.5) + 0.2 * (diff(yl) > 0.5 && diff(yl) <= 1.0) + 0.5 * (diff(yl) > 1.0);

%% 5 figure
fig = figure;
set(fig, 'Units', 'inches', 'Position', [0.2 0.2 fw fh], 'Color', 'w', 'Name', op.outName, ...
    'DefaultAxesFontName', op.font, 'DefaultTextFontName', op.font, 'DefaultLegendFontName', op.font);
drawnow;
AX = gobjects(4, nc);  HL = gobjects(1, 4);
ylab = {{'\itU\rm (m s^{-1})'}, {'\itV\rm (m s^{-1})'}, {'\itS_{UU}\rm', '(m^2 s^{-2} Hz^{-1})'}, ...
        {'\itS_{VV}\rm', '(m^2 s^{-2} Hz^{-1})'}};
ciC = {op.cT, op.cA};  ciK = {'T', 'A'};
for i = 1:nc
    for p = 1:2                                            % phase rows
        ax = axes(fig, 'Units', 'inches', 'Position', [xCol(i) yRow(p) boxW boxH]);  hold(ax, 'on');  AX(p, i) = ax;
        yl_ = ylPr{p}(i, :);
        if p == 1, yline(ax, 0, '-', 'Color', [0.75 0.75 0.75], 'HandleVisibility', 'off'); end
        xline(ax, 0, ':', 'Color', [0.45 0.45 0.45], 'HandleVisibility', 'off');
        for q_ = 1:2                                       % 95% bootstrap bands: AThIVe, APF
            ci_ = R(i).(ciF{q_}{p});  okc = all(isfinite(ci_), 1);
            if nnz(okc) >= 3
                patch(ax, [ctr(okc) fliplr(ctr(okc))], [ci_(1, okc) fliplr(ci_(2, okc))], ciC{q_}, ...
                      'FaceAlpha', op.ciAlpha.(ciK{q_}), 'EdgeColor', 'none', 'HandleVisibility', 'off');
            end
        end
        s1 = plot(ax, ctr, SW(i).(fS_{p}), '-', 'Color', op.cS, 'LineWidth', op.lw.S);
        a1 = plot(ax, ctr, R(i).(fA_{p}), [op.mkA '-'], 'Color', op.cA, 'MarkerFaceColor', op.cA, 'MarkerSize', op.ms, ...
                  'LineWidth', op.lw.A);
        t1 = plot(ax, ctr, R(i).(fT_{p}), [op.mkT '-'], 'Color', op.cT, 'MarkerFaceColor', op.cT, 'MarkerSize', op.ms, ...
                  'LineWidth', op.lw.T);
        if ismember(op.names{i}, op.windRec)               % AThIVe minus wind drift
            w1 = plot(ax, ctr, R(i).(fW_{p}), ':', 'Color', op.cW, 'LineWidth', op.lw.W);
        else                                               % legend entry only
            w1 = plot(ax, NaN, NaN, ':', 'Color', op.cW, 'LineWidth', op.lw.W);
        end
        if i == 1 && p == 1, HL = [t1 w1 a1 s1]; end
        st_ = niceStep(yl_);
        yt_ = ceil(round(yl_(1) / st_, 6)) * st_ : st_ : yl_(2) - 0.12 * diff(yl_);
        set(ax, 'XLim', [-180 180], 'XTick', -180:90:180, 'YLim', yl_, 'YTick', yt_);
        if p == 1
            set(ax, 'XTickLabel', []);
            text(ax, 0.97, 0.96, ['\Delta\phi ' sprintf('%+.0f', R(i).shift) char(176)], ...
                 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
                 'FontSize', f.small, 'Color', [0.3 0.3 0.3]);
        else
            set(ax, 'XTickLabel', {'', '-90', '0', '90', ''}, 'XTickLabelRotation', 0);
            xlabel(ax, ['wave phase (' char(176) ')'], 'FontSize', f.label);
        end
    end
    for p = 3:4                                            % spectrum rows
        ax = axes(fig, 'Units', 'inches', 'Position', [xCol(i) yRow(p) boxW boxH]);  hold(ax, 'on');  AX(p, i) = ax;
        sp = R(i).spec;
        if p == 3, yT_ = sp.SuT; yA_ = sp.SuA; q0 = 1; else, yT_ = sp.SvT; yA_ = sp.SvA; q0 = 2; end
        for hh = 1:op.nHarm
            xl_ = xline(ax, hh * R(i).fp, ':', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.8, 'HandleVisibility', 'off');
            if p == 3 && hh == 1
                xl_.Label = 'f_p';  xl_.FontSize = f.small;  xl_.LabelVerticalAlignment = 'bottom';
                xl_.LabelHorizontalAlignment = 'right';  xl_.LabelOrientation = 'horizontal';
            end
        end
        plot(ax, SW(i).fS, SW(i).S(:, q0), '-', 'Color', op.cS, 'LineWidth', op.lw.spec);
        plot(ax, sp.fA, yA_, '-', 'Color', op.cA, 'LineWidth', op.lw.spec + 0.2);
        plot(ax, sp.fT, yT_, '-', 'Color', op.cT, 'LineWidth', op.lw.spec + 0.2);
        set(ax, 'YScale', 'log', 'XLim', [0 op.fmax], 'YLim', op.ylimS, 'XTick', 0:0.25:op.fmax, ...
            'YTick', 10.^(-4:2:0), 'YMinorTick', 'on');
        if p == 3
            set(ax, 'XTickLabel', []);
        else
            xt_ = arrayfun(@(v) sprintf('%g', v), 0:0.25:op.fmax, 'UniformOutput', false);  xt_(2:2:end) = {''};
            set(ax, 'XTickLabel', xt_, 'XTickLabelRotation', 0);
            xlabel(ax, 'frequency (Hz)', 'FontSize', f.label);
        end
    end
    text(AX(1, i), 0.5, 1.03, sprintf('\\fontsize{%d}\\bf%s', f.head, op.names{i}), 'Units', 'normalized', ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
end
for p = 1:4
    for i = 1:nc
        ax = AX(p, i);
        set(ax, 'FontSize', f.tick, 'TickDir', 'in', 'Layer', 'top', 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on', ...
            'GridAlpha', 0.12, 'XMinorGrid', 'off', 'YMinorGrid', 'off');
        ax.XLabel.FontSize = f.label;  ax.YLabel.FontSize = f.label;
        if i == 1
            ylabel(ax, ylab{p}, 'FontSize', f.label);
            text(ax, M.tagX - xCol(1), boxH, op.rowTags{p}, 'Units', 'inches', 'HorizontalAlignment', 'left', ...
                 'VerticalAlignment', 'top', 'FontSize', f.panel, 'FontWeight', 'bold', 'Clipping', 'off');
        elseif p >= 3                                      % spectra share one range: tick labels on the left only
            set(ax, 'YTickLabel', []);
        end
        ax.Toolbar.Visible = 'off';
    end
end
lg = legend(AX(1, 1), HL, op.legend, 'Orientation', 'horizontal', 'NumColumns', 4, 'FontSize', f.legend, ...
            'Box', 'off', 'AutoUpdate', 'off');
lg.Units = 'inches';  drawnow;
lg.Position(1:2) = [M.left + (5 * boxW + 4 * M.gapX - lg.Position(3)) / 2, fh - M.legend + 0.02];

%% 6 export
if op.exportFig
    exportgraphics(fig, [op.outName '.png'], 'Resolution', op.dpi);
    exportgraphics(fig, [op.outName '.pdf'], 'ContentType', 'vector');
end
