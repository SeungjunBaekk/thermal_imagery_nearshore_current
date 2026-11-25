% fig15_dispersion_slice.m
% Figure 15. Wavenumber-frequency spectra of the visible video in a square box (15-16 m) centered on the APF
% for D2V2 (non-breaking), D2V3 (breaking) and D1V2 (foam-covered). Each record is one row:
%   left  : wavenumber plane at f = 1.0 Hz (log10 normalized power), alongshore section (white line),
%           wave propagation direction (gray line), dispersion rings and ridge points at 1.0 Hz
%   right : section along +y (+/-10 deg), power normalized at each frequency, with dispersion curves
%
% Data file: data/fig15_dispersion_slice.nc, one group per record (/D2V2, /D2V3, /D1V2)
%   kx, ky          wavenumber axes of the plane [rad m^-1] (energy at +k travels toward +k)
%   plane_power     spectrum averaged over 1.0 +/- 0.04 Hz, (ky, kx) [relative units]
%   f               frequency axis of the section [Hz]
%   k_section       signed wavenumber along +y [rad m^-1]
%   section_power   spectrum along +y, mean over directions 90 +/- 10 deg from +x, (f, k_section) [relative units]
%   ridge_k         ridge wavenumber at 1.0 Hz [rad m^-1]
%   ridge_theta     ridge direction, angle from +x toward +y [deg]
%   ridge_used      1 = used in the inversion (60-120 deg from the wave direction), 0 = other directions
%   h               water depth [m]
%   wave_direction  wave propagation direction, angle from +x toward +y [deg]
%   U_apf, V_apf    APF depth-mean current [m s^-1]
%   U_athive, V_athive          AThIVe surface mean current [m s^-1]
%   U_wind_drift, V_wind_drift  wind drift 0.03 U10 along the KMA wind [m s^-1]
%   breaking        1 = breaking record (no wind-drift curve), 0 = non-breaking
% Frame: x shoreward (119 deg), y alongshore (29 deg from grid north), origin at the APF.
%
% Computed here:
%   plane   : log10(P / P99), P99 = 99th percentile of the plane in the annulus 0.5 k0 < |k| < 1.5 k0,
%             k0 = linear-dispersion wavenumber at 1.0 Hz
%   section : power divided by its maximum at each frequency over |k| >= 0.6 rad m^-1
%   curves  : Doppler-shifted dispersion relation 2*pi*f = sqrt(g k tanh(k h)) + k.U for U = 0, the APF depth mean,
%             the AThIVe mean and the AThIVe mean minus the wind drift (non-breaking records only);
%             on the plane, the ring radius in each direction solves the relation at f = 1.0 Hz
%
% Sections: 0 settings, 1 read data, 2 compute, 3 figure, 4 export
% Run from this folder.

%% 0 settings
op = struct();
op.dataFile  = fullfile('data', 'fig15_dispersion_slice.nc');
op.exportFig = false;
op.outName   = 'fig15_dispersion_slice';
op.recs      = {'D2V2', 'D2V3', 'D1V2'};                  % rows from top
op.recLab    = {'D2V2 (non-breaking)', 'D2V3 (breaking)', 'D1V2 (breaking, foam)'};
op.fPlane    = 1.0;                                       % plane frequency [Hz]
op.secAz     = 90;                                        % section direction from +x [deg]
op.kmaxSec   = 12;   op.fmaxSec = 2.0;                    % section limits [rad m^-1], [Hz]
op.kminNorm  = 0.6;                                       % |k| below this is excluded from the normalization [rad m^-1]
op.ringLim   = 1.75;                                      % plane limits = +/- ringLim * k0
op.climPlane = [-1.5 0];
op.climSec   = [0 1];
op.cmap      = parula(256);
op.cUsed     = [0.90 0.10 0.10];                          % ridge points used in the inversion
op.cDrift    = [1.00 0.55 0.00];                          % AThIVe minus wind drift
op.dirLab    = {'propagation', 'direction'};
op.legLabs   = {'linear dispersion, U = 0', 'APF depth mean', 'AThIVe surface mean', ...
                'AThIVe minus wind drift', 'ridge, crest sector (used)', 'ridge, other directions'};
op.font      = 'Arial';  op.fs = 7;  op.fsLab = 8;
op.figCm     = [14.0 13.9];
op.lay       = struct('L0', 1.3, 'wP', 3.2, 'gapC', 1.25, 'hR', 3.2, 'gapR', 0.5, 'top', 0.45, 'yCb', 1.6, 'legH', 0.85);  % [cm]
op.dpi       = 300;
g = 9.81;
sig   = @(k, h) sqrt(g*abs(k).*tanh(abs(k)*h));          % intrinsic frequency [rad s^-1]
kdisp = @(w, h) fzero(@(k) sqrt(g*k*tanh(k*h)) - w, [1e-4 200]);

%% 1 read data
nR = numel(op.recs);
D = struct([]);
for i = 1:nR
    gp = ['/' op.recs{i} '/'];
    D(i).kx    = ncread(op.dataFile, [gp 'kx']).';
    D(i).ky    = ncread(op.dataFile, [gp 'ky']).';
    D(i).Pl    = double(ncread(op.dataFile, [gp 'plane_power']));
    D(i).f     = ncread(op.dataFile, [gp 'f']);
    D(i).kk    = ncread(op.dataFile, [gp 'k_section']).';
    D(i).Ps    = double(ncread(op.dataFile, [gp 'section_power']));
    D(i).rk    = ncread(op.dataFile, [gp 'ridge_k']);
    D(i).rth   = ncread(op.dataFile, [gp 'ridge_theta']);
    D(i).rused = ncread(op.dataFile, [gp 'ridge_used']) == 1;
    D(i).h     = ncread(op.dataFile, [gp 'h']);
    D(i).wdir  = ncread(op.dataFile, [gp 'wave_direction']);
    D(i).Uapf  = [ncread(op.dataFile, [gp 'U_apf']), ncread(op.dataFile, [gp 'V_apf'])];
    D(i).Utiv  = [ncread(op.dataFile, [gp 'U_athive']), ncread(op.dataFile, [gp 'V_athive'])];
    D(i).Uwind = [ncread(op.dataFile, [gp 'U_wind_drift']), ncread(op.dataFile, [gp 'V_wind_drift'])];
    D(i).brk   = ncread(op.dataFile, [gp 'breaking']) == 1;
end

%% 2 compute
th = (0:1:360).';                                         % ring directions [deg]
w0 = 2*pi*op.fPlane;
Kg = linspace(0.02, 40, 8000);                            % wavenumber search grid for the rings [rad m^-1]
eSec = [cosd(op.secAz); sind(op.secAz)];
R = struct([]);
for i = 1:nR
    h = D(i).h;
    % currents: U = 0, APF depth mean, AThIVe mean, AThIVe minus wind drift (non-breaking only)
    Ud = D(i).Utiv - D(i).Uwind;
    if D(i).brk, Ud = [NaN NaN]; end
    Uset = [0 0; D(i).Uapf; D(i).Utiv; Ud];
    % plane normalized by the 99th percentile in the annulus around k0
    k0 = kdisp(w0, h);
    [KX, KY] = meshgrid(D(i).kx, D(i).ky);
    ann = hypot(KX, KY) > 0.5*k0 & hypot(KX, KY) < 1.5*k0;
    R(i).planeLog = log10(D(i).Pl/prctile(D(i).Pl(ann), 99));
    R(i).k0 = k0;  R(i).Lp = op.ringLim*k0;
    % ring radius in each direction: first root of sigma(k) + k U_theta - w0
    R(i).kr = nan(numel(th), 4);
    for s = 1:4
        if ~all(isfinite(Uset(s, :))), continue; end
        Ut = Uset(s, 1)*cosd(th) + Uset(s, 2)*sind(th);
        for q = 1:numel(th)
            Fm = sig(Kg, h) + Ut(q)*Kg - w0;  jj = find(Fm >= 0, 1);
            if ~isempty(jj) && jj > 1, R(i).kr(q, s) = interp1(Fm(jj - 1:jj), Kg(jj - 1:jj), 0); end
        end
    end
    % section normalized at each frequency
    nm = abs(D(i).kk) >= op.kminNorm;
    R(i).secN = D(i).Ps./max(D(i).Ps(:, nm), [], 2);
    % dispersion curves along +y
    R(i).Ue = (Uset*eSec).';                              % current component along +y [m s^-1]
    R(i).fc = nan(4, numel(D(i).kk));
    for s = 1:4
        if ~isfinite(R(i).Ue(s)), continue; end
        fc = (sig(D(i).kk, h) + D(i).kk*R(i).Ue(s))/(2*pi);  fc(fc < 0) = NaN;
        R(i).fc(s, :) = fc;
    end
    fprintf('%s: k0 = %.4f rad/m, along +y: APF %+.4f, AThIVe %+.4f, AThIVe - drift %+.4f m/s, ridge points %d (used %d)\n', ...
        op.recs{i}, k0, R(i).Ue(2), R(i).Ue(3), R(i).Ue(4), numel(D(i).rk), nnz(D(i).rused));
end

%% 3 figure
fig = figure('Color', 'w', 'Units', 'centimeters', 'Position', [1 1 op.figCm]);
set(fig, 'DefaultAxesFontName', op.font, 'DefaultTextFontName', op.font, 'DefaultAxesFontSize', op.fs);
L0 = op.lay.L0;  wP = op.lay.wP;  gapC = op.lay.gapC;  hR = op.lay.hR;  gapR = op.lay.gapR;
wS = op.figCm(1) - L0 - wP - gapC - 0.3;
yRow = op.figCm(2) - op.lay.top - hR - (0:nR - 1)*(hR + gapR);
lineSty = {'-', '--', ':', '-.'};                         % U = 0, APF, AThIVe, AThIVe minus wind drift
pan = 'abcdef';
AXp = gobjects(1, nR);  AXs = gobjects(1, nR);
for i = 1:nR
    Lp = R(i).Lp;
    % ---- wavenumber plane at 1.0 Hz
    ax = axes(fig, 'Units', 'centimeters', 'Position', [L0, yRow(i), wP, hR]);  AXp(i) = ax;  hold(ax, 'on');
    ax.Toolbar.Visible = 'off';
    imagesc(ax, D(i).kx, D(i).ky, R(i).planeLog);  set(ax, 'YDir', 'normal');
    colormap(ax, op.cmap);  clim(ax, op.climPlane);
    plot(ax, [0 0.97*Lp*cosd(op.secAz)], [0 0.97*Lp*sind(op.secAz)], '-', 'Color', 'w', 'LineWidth', 1.0);
    aw = D(i).wdir;
    plot(ax, [0 0.97*Lp*cosd(aw)], [0 0.97*Lp*sind(aw)], '-', 'Color', [0.80 0.80 0.80], 'LineWidth', 0.8);
    text(ax, 0.97*Lp*cosd(aw), 0.97*Lp*sind(aw) - 0.07*Lp, op.dirLab, 'Color', [0.95 0.95 0.95], 'FontSize', op.fs - 1, ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'BackgroundColor', [0 0 0 0.5], 'Margin', 0.5);
    for s = 1:4
        if all(isnan(R(i).kr(:, s))), continue; end
        kr = R(i).kr(:, s);
        plot(ax, kr.*cosd(th), kr.*sind(th), '-', 'Color', 'k', 'LineWidth', 1.5);
        if s == 4, cLn = op.cDrift; else, cLn = 'w'; end
        plot(ax, kr.*cosd(th), kr.*sind(th), lineSty{s}, 'Color', cLn, 'LineWidth', 0.8 + 0.3*(s == 4));
    end
    o = ~D(i).rused;  c = D(i).rused;
    plot(ax, D(i).rk(o).*cosd(D(i).rth(o)), D(i).rk(o).*sind(D(i).rth(o)), 'o', 'MarkerSize', 2.4, ...
        'MarkerFaceColor', [0.6 0.6 0.6], 'MarkerEdgeColor', 'k', 'LineWidth', 0.3);
    plot(ax, D(i).rk(c).*cosd(D(i).rth(c)), D(i).rk(c).*sind(D(i).rth(c)), 'o', 'MarkerSize', 2.8, ...
        'MarkerFaceColor', op.cUsed, 'MarkerEdgeColor', 'k', 'LineWidth', 0.4);
    plot(ax, 0, 0, '+', 'Color', 'w', 'MarkerSize', 4);
    axis(ax, 'equal');  xlim(ax, [-Lp Lp]);  ylim(ax, [-Lp Lp]);
    set(ax, 'Layer', 'top', 'TickDir', 'out', 'XTick', -6:3:6, 'YTick', -6:3:6);  box(ax, 'on');
    ylabel(ax, 'k_y (rad m^{-1})');
    if i == nR, xlabel(ax, 'k_x (rad m^{-1})'); else, set(ax, 'XTickLabel', []); end
    text(ax, 0.03, 0.97, sprintf('f = %.1f Hz', op.fPlane), 'Units', 'normalized', 'Color', 'w', 'FontSize', op.fs, ...
        'VerticalAlignment', 'top');
    text(ax, -0.27, 1.03, sprintf('(%s)', pan(2*i - 1)), 'Units', 'normalized', 'FontWeight', 'bold', 'FontSize', op.fsLab + 1, ...
        'VerticalAlignment', 'bottom');
    text(ax, -0.12, 1.03, op.recLab{i}, 'Units', 'normalized', 'FontWeight', 'bold', 'FontSize', op.fsLab, ...
        'VerticalAlignment', 'bottom');
    % ---- section along +y
    ax = axes(fig, 'Units', 'centimeters', 'Position', [L0 + wP + gapC, yRow(i), wS, hR]);  AXs(i) = ax;  hold(ax, 'on');
    ax.Toolbar.Visible = 'off';
    imagesc(ax, D(i).kk, D(i).f, R(i).secN);  set(ax, 'YDir', 'normal');  colormap(ax, op.cmap);  clim(ax, op.climSec);
    yline(ax, op.fPlane, ':', 'Color', [1 1 1], 'LineWidth', 0.6, 'Alpha', 0.8);
    for s = 1:4
        if ~isfinite(R(i).Ue(s)), continue; end
        plot(ax, D(i).kk, R(i).fc(s, :), '-', 'Color', 'k', 'LineWidth', 1.5);
        if s == 4, cLn = op.cDrift; else, cLn = 'w'; end
        plot(ax, D(i).kk, R(i).fc(s, :), lineSty{s}, 'Color', cLn, 'LineWidth', 0.8 + 0.3*(s == 4));
    end
    cTxt = {sprintf('APF %+.2f m s^{-1}', R(i).Ue(2)), sprintf('AThIVe %+.2f m s^{-1}', R(i).Ue(3))};
    yTxt = 0.03;
    if isfinite(R(i).Ue(4))
        text(ax, 0.98, 0.03, sprintf(['AThIVe ' char(8722) ' drift %+.2f m s^{-1}'], R(i).Ue(4)), 'Units', 'normalized', ...
            'Color', op.cDrift, 'FontSize', op.fs - 0.5, 'FontWeight', 'bold', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom');
        yTxt = 0.13;
    end
    text(ax, 0.98, yTxt, cTxt, 'Units', 'normalized', ...
        'Color', 'w', 'FontSize', op.fs - 0.5, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom');
    text(ax, 0.02, 0.97, 'toward -y', 'Units', 'normalized', 'Color', 'w', 'FontSize', op.fs - 0.5, 'VerticalAlignment', 'top');
    text(ax, 0.98, 0.97, 'toward +y', 'Units', 'normalized', 'Color', 'w', 'FontSize', op.fs - 0.5, ...
        'VerticalAlignment', 'top', 'HorizontalAlignment', 'right');
    xlim(ax, [-op.kmaxSec op.kmaxSec]);  ylim(ax, [0 op.fmaxSec]);
    set(ax, 'Layer', 'top', 'TickDir', 'out', 'Color', op.cmap(1, :));  box(ax, 'on');
    ylabel(ax, 'f (Hz)');
    if i == nR, xlabel(ax, 'k_y (rad m^{-1}), along y \pm 10\circ'); else, set(ax, 'XTickLabel', []); end
    text(ax, -0.14, 1.03, sprintf('(%s)', pan(2*i)), 'Units', 'normalized', 'FontWeight', 'bold', 'FontSize', op.fsLab + 1, ...
        'VerticalAlignment', 'bottom');
end
% colorbars below each column
yCb = op.lay.yCb;
cb1 = colorbar(AXp(end), 'southoutside');  cb1.Units = 'centimeters';  cb1.Position = [L0, yCb, wP, 0.22];
cb1.Label.String = 'log_{10} normalized power';  cb1.FontSize = op.fs;
cb2 = colorbar(AXs(end), 'southoutside');  cb2.Units = 'centimeters';  cb2.Position = [L0 + wP + gapC, yCb, wS, 0.22];
cb2.Label.String = 'power normalized at each frequency';  cb2.FontSize = op.fs;
set(AXp(end), 'Units', 'centimeters', 'Position', [L0, yRow(end), wP, hR]);
set(AXs(end), 'Units', 'centimeters', 'Position', [L0 + wP + gapC, yRow(end), wS, hR]);
% legend drawn with the same line styles as the panels
axL = axes(fig, 'Units', 'centimeters', 'Position', [L0, 0.0, op.figCm(1) - L0 - 0.3, op.lay.legH], 'Visible', 'off');
hold(axL, 'on');  axL.Toolbar.Visible = 'off';
set(axL, 'XLim', [0 1], 'YLim', [0 1]);
legX = [0.00 0.37 0.70];  legY = [0.70 0.25];  segW = 0.06;
LE = struct('sty', {'-', '--', ':', '-.', 'o', 'o'}, 'col', {1, 1, 2, 2, 3, 3}, 'row', {1, 2, 1, 2, 1, 2}, ...
    'face', {[], [], [], [], op.cUsed, [0.6 0.6 0.6]}, 'lab', op.legLabs);
for q = 1:numel(LE)
    x0 = legX(LE(q).col);  y0 = legY(LE(q).row);
    if strcmp(LE(q).sty, 'o')
        plot(axL, x0 + segW/2, y0, 'o', 'MarkerSize', 3, 'MarkerFaceColor', LE(q).face, 'MarkerEdgeColor', 'k', 'LineWidth', 0.4);
    else
        plot(axL, x0 + [0 segW], [y0 y0], '-', 'Color', 'k', 'LineWidth', 1.5);
        if strcmp(LE(q).sty, '-.'), cLn = op.cDrift; else, cLn = 'w'; end
        plot(axL, x0 + [0 segW], [y0 y0], LE(q).sty, 'Color', cLn, 'LineWidth', 0.8 + 0.3*strcmp(LE(q).sty, '-.'));
    end
    text(axL, x0 + segW + 0.012, y0, LE(q).lab, 'FontSize', op.fs, 'VerticalAlignment', 'middle');
end

%% 4 export
if op.exportFig
    exportgraphics(fig, [op.outName '.png'], 'Resolution', op.dpi);
    exportgraphics(fig, [op.outName '.pdf'], 'ContentType', 'vector');
end
