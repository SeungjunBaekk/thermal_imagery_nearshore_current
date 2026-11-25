% fig06_model_setup.m
% Figure 6: model bathymetry and forcing.
%   (a) Regional bathymetry (SWAN G1) with the nested SWAN grids G2 and G3, the KMA buoy 22307 and the site.
%   (b) Nearshore bathymetry: SWAN G3 bed and, inside the SWASH domain, the SWASH bed (14 July); SfM survey
%       DTM coverage, DfW coverage (acquired) and the part used in the model bed (adopted), SWASH domain with
%       the lateral blending strips (dashed), matching transect x_c and the APF.
%   (c) Bed profile through the instruments (y = 0): SWASH bed landward of x_c and the SWAN reference profile
%       seaward of it, coloured by source, with the still-water level of each record (dashed lines).
%   (d) Significant wave height and wind speed at the buoy 22307, and modeled (KMA LDAPS) 10-m wind speed at
%       the buoy and the APF; vertical lines are the video records (KST).
%
% Data file: data/fig06_model_setup.nc (2-D fields are returned by ncread as [x, y] and transposed here)
%   (a)  g1_easting, g1_northing [m, UTM 52N], g1_bed_elevation [m, MSL];
%        coastline_easting/northing, swan_g2_outline_easting/northing, swan_g3_outline_easting/northing [m];
%        buoy_easting/northing, apf_easting/northing [m]
%   (b)  g3_x, g3_y [m], g3_bed_elevation [m, MSL]; swash_x, swash_y [m], swash_bed_elevation [m, MSL],
%        swash_bed_source [0 filled, 1 SfM DTM, 2 DfW, 3 blend], swash_bed_sfm_weight [-];
%        dfw_x, dfw_y, dfw_coverage [0/1]; sfm_x, sfm_y, sfm_coverage [0/1];
%        swash_domain_x_limits, swash_domain_y_limits, swash_blend_width [m]
%   (c)  reference_profile_X [m, offshore distance X = -x], reference_profile_z [m, MSL],
%        reference_profile_source_breaks [m]
%   (d)  buoy_time, kma_wind_time [h since 2026-07-14 00:00 KST]; buoy_hs [m]; buoy_wind_speed,
%        kma_wind_speed_buoy, kma_wind_speed_apf [m/s]
%   /D1V1 ... /D2V3  still_water_level [m, MSL], video_start_time [h since 2026-07-14 00:00 KST]
%   Local frame: x shoreward toward 119 deg, y alongshore toward 29 deg from grid north, origin at the APF.
%
% Computation: the area where DfW enters the model bed ("adopted") is the DfW coverage between X = 120 m
%   (x_c) and the first source break of the reference profile, plus the SWASH-bed cells whose source is DfW
%   or the blend. The bed profile in (c) is the SWASH bed at y = 0; each point is coloured as SfM DTM where
%   the SfM weight is >= 0.5, as DfW otherwise, and grey where the bed was filled. Each still-water line
%   starts at the landward-most point of the profile below that level.
%
% Sections: 0 settings, 1 read data, 2 compute, 3 panel positions, 4 figure (a), 5 figure (b),
%   6 figure (c), 7 figure (d), 8 export.
% Run from this folder.

%% 0 settings
op = struct();
op.dataFile  = fullfile('data', 'fig06_model_setup.nc');
op.exportFig = false;
op.outName   = 'fig06_model_setup';
op.recName = {'D1V1', 'D1V2', 'D2V1', 'D2V2', 'D2V3'};
op.recCol  = {'#c0392b', '#e08e0b', '#7f8c8d', '#8e44ad', '#2471a3'};
op.tRef    = datetime(2026, 7, 14);                    % time origin of the stored hours (KST)
op.lProfile = 0;                                       % alongshore position of the profile in (c) [m]
% colours
op.c = struct('g2', '#e67e22', 'g3', '#e74c3c', 'swash', '#e74c3c', 'xc', '#8e44ad', 'dfw', '#f39c12', ...
              'dem', '#1a9850', 'eq', '#d73027', 'chart', '#4575b4', 'apf', '#f1c40f', 'buoy', '#c0392b', ...
              'hs', '#2c3e50', 'wind', '#16a085', 'windApf', '#0b5345', 'adopt', '#7CFC00');
op.cFill = [0.6 0.6 0.6];  op.cCoast = [0.25 0.25 0.25];  op.cContour = [0.3 0.3 0.3];  op.cTag = [0.35 0.35 0.35];
op.gridAlpha = 0.1;
op.topoPos = [0 0.28 0.45 0.55 0.58 0.72 1];           % bathymetry colormap nodes
op.topoHex = {'#08306b', '#2171b5', '#6baed6', '#c6dbef', '#f2efe2', '#d8c69a', '#8c7b5a'};
% (a)
op.limA = [190.1 248.75];                              % easting range [km]; northing range follows the box ratio
op.cyA  = 4074.45;                                     % northing centre [km]
op.climA = [-70 25];
op.legendA = {'SWAN G2', 'SWAN G3', 'Buoy (KMA 22307)', 'Survey site'};
% (b)
op.limB = [-560 230];                                  % x range [m]; y range follows the box ratio
op.cyB  = 0;
op.climB = [-10 4];
op.contourLev   = -12:0.5:6;                           % bed contours [m]
op.contourMajor = 2;                                   % multiples drawn thicker
op.adoptAlpha = 0.3;  op.adoptEdge = 1.0;
op.legendB = {'SWASH domain', 'matching transect \itx_c', 'DfW DTM: acquired', 'DfW DTM: adopted', 'SfM survey DTM', 'APF'};
% (c)
op.limC = [-200 1000; -13.5 5];                        % [X; z] limits
op.levLabelX = 800;  op.levLabelY0 = 0.35;  op.levLabelDY = 0.95;   % still-water level labels
op.tagY = 3.35;  op.xcLabelY = 0.4;
op.legendC = {'SfM DTM', 'DfW DTM', 'equilibrium profile', 'KHOA soundings'};
% (d)
op.ylimD = [0 10];  op.ylimW = [0 20];
op.windLW = [1.0 1.3 1.6];                             % buoy observed, model at buoy, model at APF
op.legendD = {'\itH_s\rm  buoy', 'wind, buoy', 'wind forecast, buoy', 'wind forecast, APF'};
op.tokenSizeD = [14 10];
op.recLineWidth = 1.2;
op.recLabelY0 = 1.5;  op.recLabelDY = 0.45;  op.recLabelOff = hours(2);
op.recGroups = {[1 2], [3 4 5]};                       % record names stacked left of the first line of each day
% layout: four equal panel boxes, margins from the font sizes
op.boxIn = [4.9 3.95];                                 % panel box [width height] [in]
op.cbGapIn = 0.10;  op.cbWIn = 0.15;                   % colorbar gap and width [in]
op.tokenSize = [18 10];
% fonts
op.font = 'Arial';
op.fs = struct('panel', 16, 'label', 14, 'tick', 14, 'legend', 11, 'legendB', 12, 'small', 10, 'cb', 14, 'xc', 14);
op.panelLabel = {'(a)', '(b)', '(c)', '(d)'};
op.panelPos = [-0.1 1.1];                              % panel label position (axes fraction)

%% 1 read data
rd  = @(v) ncread(op.dataFile, v);
rd2 = @(v) rd(v).';                                    % 2-D field as [y, x]
D = struct();
for v = {'g1_easting', 'g1_northing', 'coastline_easting', 'coastline_northing', 'swan_g2_outline_easting', ...
         'swan_g2_outline_northing', 'swan_g3_outline_easting', 'swan_g3_outline_northing', 'buoy_easting', ...
         'buoy_northing', 'apf_easting', 'apf_northing', 'g3_x', 'g3_y', 'swash_x', 'swash_y', 'dfw_x', 'dfw_y', ...
         'sfm_x', 'sfm_y', 'swash_domain_x_limits', 'swash_domain_y_limits', 'swash_blend_width', ...
         'reference_profile_X', 'reference_profile_z', 'reference_profile_source_breaks', 'buoy_time', 'buoy_hs', ...
         'buoy_wind_speed', 'kma_wind_time', 'kma_wind_speed_buoy', 'kma_wind_speed_apf'}
    D.(v{1}) = rd(['/' v{1}]);
end
for v = {'g1_bed_elevation', 'g3_bed_elevation', 'swash_bed_elevation', 'swash_bed_source', 'swash_bed_sfm_weight', ...
         'dfw_coverage', 'sfm_coverage'}
    D.(v{1}) = rd2(['/' v{1}]);
end
nR  = numel(op.recName);
REC = struct('name', op.recName, 'col', op.recCol);
for i = 1:nR
    REC(i).lev = rd(['/' REC(i).name '/still_water_level']);
    REC(i).t   = op.tRef + hours(rd(['/' REC(i).name '/video_start_time']));
end

%% 2 compute
hx  = @(h) sscanf(h(2:end), '%2x%2x%2x', [1 3]) / 255;   % '#rrggbb' -> [r g b]
mix = @(c, a) a*c + (1 - a)*[1 1 1];                     % colour mixed with white (opaque)
topo = interp1(op.topoPos, cell2mat(cellfun(hx, op.topoHex', 'UniformOutput', false)), linspace(0, 1, 256)');
for i = 1:nR, REC(i).rgb = hx(REC(i).col); end
sw = struct('x', D.swash_domain_x_limits, 'y', D.swash_domain_y_limits, 'blend', D.swash_blend_width);
XC = -sw.x(1);                                         % offshore distance of the matching transect x_c
inDom = @(x, y) x >= sw.x(1) & x <= sw.x(2) & y >= sw.y(1) & y <= sw.y(2);
bt = op.tRef + hours(D.buoy_time);
kt = op.tRef + hours(D.kma_wind_time);
% (c) bed profile at y = op.lProfile (X = -x, positive offshore)
[~, jl] = min(abs(D.swash_y - op.lProfile));
PROF = struct();
PROF.X    = -D.swash_x.';
PROF.z    = D.swash_bed_elevation(jl, :);
PROF.src  = double(D.swash_bed_source(jl, :));
PROF.wdem = D.swash_bed_sfm_weight(jl, :);
PROF.key  = repmat({'dfw'}, size(PROF.X));            % blended cells take the larger source
PROF.key(PROF.wdem >= 0.5) = {'dem'};
PROF.key(PROF.src == 0) = {'fill'};
for i = 1:nR                                           % still-water line starts at the shoreline of the profile
    wet = find(PROF.z < REC(i).lev);
    if isempty(wet), REC(i).xShore = PROF.X(end); else, REC(i).xShore = PROF.X(max(wet)); end
end
zAPF = interp1(fliplr(PROF.X), fliplr(PROF.z), 0);
fprintf('bed elevation at the APF %.3f m; x_c at X = %.0f m\n', zAPF, XC);
fprintf('%-5s %8s %10s\n', 'name', 'level', 'shore X');
for i = 1:nR, fprintf('%-5s %8.3f %10.1f\n', REC(i).name, REC(i).lev, REC(i).xShore); end

%% 3 panel positions: margins [in] from the font sizes, figure = 2 x 2 boxes + margins
em = @(pt) pt/72;                                      % pt -> in
f  = op.fs;
M  = struct();
M.left   = (4*0.56 + 0.4)*em(f.tick) + 1.5*em(f.label) + 0.10;
M.cbar   = op.cbGapIn + op.cbWIn + (3*0.56 + 0.4)*em(f.tick) + 1.5*em(f.cb) + 0.10;
M.gapX   = M.cbar + M.left;
M.right  = max(M.cbar, (2*0.56 + 0.4)*em(f.tick) + 1.5*em(f.label) + 0.15);
boxW = op.boxIn(1);  boxH = op.boxIn(2);
tagUp    = max(0, op.panelPos(2) - 1)*boxH + 1.4*em(f.panel);
M.top    = tagUp + 0.10;
M.gapY   = 1.4*em(f.tick) + 1.5*em(f.label) + tagUp + 0.25;
M.bottom = 1.4*em(f.tick) + 1.5*em(f.label) + 0.15;
asp = boxH/boxW;
fw = M.left + boxW + M.gapX + boxW + M.right;
fh = M.bottom + boxH + M.gapY + boxH + M.top;
xL = M.left;  xR = M.left + boxW + M.gapX;  yB = M.bottom;  yT = M.bottom + boxH + M.gapY;
POS = struct();
POS.a  = [xL yT boxW boxH] ./ [fw fh fw fh];
POS.b  = [xR yT boxW boxH] ./ [fw fh fw fh];
POS.c  = [xL yB boxW boxH] ./ [fw fh fw fh];
POS.d  = [xR yB boxW boxH] ./ [fw fh fw fh];
POS.cA = [xL + boxW + op.cbGapIn, yT, op.cbWIn, boxH] ./ [fw fh fw fh];
POS.cB = [xR + boxW + op.cbGapIn, yT, op.cbWIn, boxH] ./ [fw fh fw fh];
LIM = struct();                                        % map limits (equal axes)
LIM.a = [op.limA; op.cyA + [-0.5 0.5]*diff(op.limA)*asp];
LIM.b = [op.limB; op.cyB + [-0.5 0.5]*diff(op.limB)*asp];
fprintf('figure %.2f x %.2f in\n', fw, fh);
panelTag = @(ax, s) text(ax, op.panelPos(1), op.panelPos(2), s, 'Units', 'normalized', 'HorizontalAlignment', 'center', ...
                         'VerticalAlignment', 'bottom', 'FontSize', op.fs.panel, 'FontWeight', 'bold');
axSet = @(ax) set(ax, 'FontSize', op.fs.tick, 'TickDir', 'out', 'Layer', 'top', 'Box', 'on', ...
                  'XGrid', 'on', 'YGrid', 'on', 'GridAlpha', op.gridAlpha);
fig = figure('Units', 'inches', 'Position', [-0.2 0.1 fw fh], 'Color', 'w', 'Name', op.outName, ...
             'DefaultAxesFontName', op.font, 'DefaultTextFontName', op.font, 'DefaultLegendFontName', op.font);
drawnow;

%% 4 figure (a): regional bathymetry and SWAN grids
axA = axes(fig, 'Position', POS.a);  hold(axA, 'on');
imagesc(axA, D.g1_easting/1e3, D.g1_northing/1e3, D.g1_bed_elevation, 'AlphaData', double(~isnan(D.g1_bed_elevation)));
colormap(axA, topo);  axA.CLim = op.climA;
plot(axA, D.coastline_easting/1e3, D.coastline_northing/1e3, '-', 'Color', op.cCoast, 'LineWidth', 0.35);
hG2 = plot(axA, D.swan_g2_outline_easting/1e3, D.swan_g2_outline_northing/1e3, '-', 'Color', hx(op.c.g2), 'LineWidth', 1.3);
hG3 = plot(axA, D.swan_g3_outline_easting/1e3, D.swan_g3_outline_northing/1e3, '-', 'Color', hx(op.c.g3), 'LineWidth', 1.3);
hBuoy = plot(axA, D.buoy_easting/1e3, D.buoy_northing/1e3, 'p', 'MarkerSize', 13, 'MarkerFaceColor', hx(op.c.buoy), ...
             'MarkerEdgeColor', 'k', 'LineWidth', 0.6);
hSite = plot(axA, D.apf_easting/1e3, D.apf_northing/1e3, '^', 'MarkerSize', 7, 'MarkerFaceColor', hx(op.c.apf), ...
             'MarkerEdgeColor', 'k', 'LineWidth', 0.6);
axSet(axA);
set(axA, 'YDir', 'normal', 'XLim', LIM.a(1, :), 'YLim', LIM.a(2, :), 'DataAspectRatio', [1 1 1]);
xlabel(axA, 'UTM 52N easting [km]', 'FontSize', op.fs.label);
ylabel(axA, 'northing [km]', 'FontSize', op.fs.label);
panelTag(axA, op.panelLabel{1});
lgA = legend(axA, [hG2 hG3 hBuoy hSite], op.legendA, 'Location', 'southwest', 'FontSize', op.fs.legend, 'AutoUpdate', 'off');
lgA.ItemTokenSize = op.tokenSize;
cbA = colorbar(axA, 'Position', POS.cA, 'FontSize', op.fs.tick, 'FontName', op.font);
axA.Position = POS.a;                                  % keep the box size after adding the colorbar
cbA.Label.String = '\itz\rm [m]';  cbA.Label.FontSize = op.fs.cb;

%% 5 figure (b): nearshore bathymetry, SWASH domain and bed sources
axB = axes(fig, 'Position', POS.b);  hold(axB, 'on');
[S3, L3] = meshgrid(D.g3_x, D.g3_y);
Z3 = D.g3_bed_elevation;
imagesc(axB, D.g3_x, D.g3_y, Z3, 'AlphaData', double(~isnan(Z3)));
ZW = D.swash_bed_elevation;                            % SWASH bed inside the SWASH domain
imagesc(axB, D.swash_x, D.swash_y, ZW);
colormap(axB, topo);  axB.CLim = op.climB;
% DfW adopted in the model bed: DfW part of the reference profile seaward of x_c + DfW/blend cells of the SWASH bed
sg = LIM.b(1, 1):2:LIM.b(1, 2);  lg = LIM.b(2, 1):2:LIM.b(2, 2);
[SG, LG] = meshgrid(sg, lg);
cov  = interp2(D.dfw_x, D.dfw_y, double(D.dfw_coverage), SG, LG, 'linear', 0) >= 0.5;
srcI = interp2(D.swash_x, D.swash_y, double(D.swash_bed_source), SG, LG, 'nearest', 0);
dfwBand = [-D.reference_profile_source_breaks(1), sw.x(1)];
ADOPT = (cov & SG >= dfwBand(1) & SG <= dfwBand(2)) | (ismember(srcI, [2 3]) & inDom(SG, LG));
image(axB, sg, lg, repmat(reshape(hx(op.c.adopt), 1, 1, 3), size(ADOPT)), 'AlphaData', op.adoptAlpha*double(ADOPT));
% bed contours (SWAN G3 only outside the SWASH domain); multiples of op.contourMajor thicker
isMaj = abs(mod(op.contourLev, op.contourMajor)) < 1e-9;
levs  = {op.contourLev(~isMaj), op.contourLev(isMaj)};  lwC = [0.3 0.7];
Z3c = Z3;  Z3c(inDom(S3, L3)) = NaN;
for q = 1:2
    contour(axB, D.g3_x, D.g3_y, Z3c, levs{q}, 'LineColor', op.cContour, 'LineWidth', lwC(q));
    contour(axB, D.swash_x, D.swash_y, ZW, levs{q}, 'LineColor', op.cContour, 'LineWidth', lwC(q));
end
contour(axB, sg, lg, double(ADOPT), [0.5 0.5], 'LineColor', hx(op.c.adopt), 'LineWidth', op.adoptEdge);
contour(axB, D.dfw_x, D.dfw_y, double(D.dfw_coverage), [0.5 0.5], 'LineStyle', '--', 'LineColor', hx(op.c.dfw), 'LineWidth', 1.4);
contour(axB, D.sfm_x, D.sfm_y, double(D.sfm_coverage), [0.5 0.5], 'LineColor', hx(op.c.dem), 'LineWidth', 1.7);
plot(axB, sw.x([1 2 2 1 1]), sw.y([1 1 2 2 1]), '-', 'Color', hx(op.c.swash), 'LineWidth', 1.4);
for yt = [sw.y(1) + sw.blend, sw.y(2) - sw.blend]       % lateral blending strips
    plot(axB, sw.x, [yt yt], '--', 'Color', hx(op.c.swash), 'LineWidth', 0.7);
end
plot(axB, sw.x([1 1]), sw.y, '-', 'Color', hx(op.c.xc), 'LineWidth', 2.2);
plot(axB, 0, 0, '^', 'MarkerSize', 8, 'MarkerFaceColor', hx(op.c.apf), 'MarkerEdgeColor', 'k', 'LineWidth', 0.7);
hLB = [patch(axB, NaN, NaN, 'w', 'FaceColor', 'none', 'EdgeColor', hx(op.c.swash), 'LineWidth', 1.4), ...
       plot(axB, NaN, NaN, '-', 'Color', hx(op.c.xc), 'LineWidth', 2.2), ...
       plot(axB, NaN, NaN, '--', 'Color', hx(op.c.dfw), 'LineWidth', 1.4), ...
       patch(axB, NaN, NaN, hx(op.c.adopt), 'FaceAlpha', op.adoptAlpha, 'EdgeColor', hx(op.c.adopt), 'LineWidth', op.adoptEdge), ...
       plot(axB, NaN, NaN, '-', 'Color', hx(op.c.dem), 'LineWidth', 1.7), ...
       plot(axB, NaN, NaN, '^', 'MarkerSize', 7, 'MarkerFaceColor', hx(op.c.apf), 'MarkerEdgeColor', 'k')];
axSet(axB);
set(axB, 'YDir', 'normal', 'XLim', LIM.b(1, :), 'YLim', LIM.b(2, :), 'DataAspectRatio', [1 1 1]);
xlabel(axB, '$x\,\mathrm{[m]\,\,(+\,S61^\circ E)}$', 'FontSize', op.fs.label, 'Interpreter', 'latex');
ylabel(axB, '$y\,\mathrm{[m]\,\,(+\,N29^\circ E)}$', 'FontSize', op.fs.label, 'Interpreter', 'latex');
panelTag(axB, op.panelLabel{2});
lgB = legend(axB, hLB, op.legendB, 'Location', 'southwest', 'FontSize', op.fs.legendB, 'AutoUpdate', 'off');
lgB.ItemTokenSize = op.tokenSize;
cbB = colorbar(axB, 'Position', POS.cB, 'FontSize', op.fs.tick, 'FontName', op.font);
axB.Position = POS.b;
cbB.Label.String = '\itz\rm [m, MSL]';  cbB.Label.FontSize = op.fs.cb;

%% 6 figure (c): bed profile through the instruments and still-water levels
axC = axes(fig, 'Position', POS.c);  hold(axC, 'on');
PCOL = struct('dem', hx(op.c.dem), 'dfw', hx(op.c.dfw), 'eq', hx(op.c.eq), 'chart', hx(op.c.chart), 'fill', op.cFill);
br = D.reference_profile_source_breaks;
patch(axC, br([1 2 2 1]), op.limC(2, [1 1 2 2]), mix(hx(op.c.eq), 0.07), 'EdgeColor', 'none');   % equilibrium-profile range
segEnd = [br; max(D.reference_profile_X)];  segKey = {'dfw', 'eq', 'chart'};
x0 = XC;                                               % reference profile seaward of x_c, by source
for q = 1:3
    m = D.reference_profile_X >= x0 & D.reference_profile_X <= segEnd(q);
    plot(axC, D.reference_profile_X(m), D.reference_profile_z(m), '-', 'Color', PCOL.(segKey{q}), 'LineWidth', 1.9);
    x0 = segEnd(q);
end
i0 = 1;                                                % SWASH bed by source (segments share their end points)
for i = 2:numel(PROF.key) + 1
    if i > numel(PROF.key) || ~strcmp(PROF.key{i}, PROF.key{i0})
        seg = i0:min(i, numel(PROF.key));
        plot(axC, PROF.X(seg), PROF.z(seg), '-', 'Color', PCOL.(PROF.key{i0}), 'LineWidth', 1.9);
        i0 = i;
    end
end
for i = 1:nR                                           % still-water levels from the shoreline to the offshore end
    plot(axC, [REC(i).xShore op.limC(1, 2)], REC(i).lev*[1 1], '--', 'Color', REC(i).rgb, 'LineWidth', 1.0);
end
[~, ord] = sort([REC.lev], 'descend');
for r = 1:nR
    i = ord(r);
    text(axC, op.levLabelX, op.levLabelY0 - op.levLabelDY*(r - 1), sprintf('%s  %.2f m', REC(i).name, REC(i).lev), ...
         'Color', REC(i).rgb, 'FontSize', op.fs.small, 'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
         'VerticalAlignment', 'top');
end
xline(axC, XC, '-', 'Color', hx(op.c.xc), 'LineWidth', 1.6);
text(axC, XC - 14, op.xcLabelY, '\itx_c', 'Color', hx(op.c.xc), 'FontSize', op.fs.xc, 'HorizontalAlignment', 'left');
text(axC, XC - 20, op.tagY, 'SWASH', 'Color', op.cTag, 'FontSize', op.fs.small + 0.2, 'HorizontalAlignment', 'left');
text(axC, XC + 20, op.tagY, 'SWAN', 'Color', op.cTag, 'FontSize', op.fs.small + 0.2, 'HorizontalAlignment', 'right');
plot(axC, 0, zAPF, '^', 'MarkerSize', 7, 'MarkerFaceColor', hx(op.c.apf), 'MarkerEdgeColor', 'k', 'LineWidth', 0.6);
axSet(axC);
set(axC, 'XLim', op.limC(1, :), 'YLim', op.limC(2, :), 'XDir', 'reverse');   % drawn in X = -x, offshore to the left
for h_ = axC.Children.'                              % express the panel in x = -X (shoreward positive, as in (b))
    if isa(h_, 'matlab.graphics.primitive.Text')
        if strcmp(h_.Units, 'data'), h_.Position(1) = -h_.Position(1); end
    elseif isa(h_, 'matlab.graphics.chart.decoration.ConstantLine')
        h_.Value = -h_.Value;
    elseif isprop(h_, 'XData')
        h_.XData = -h_.XData;
    end
end
set(axC, 'XLim', -fliplr(op.limC(1, :)), 'XDir', 'normal');
xlabel(axC, 'cross-shore distance \itx\rm from APF [m]', 'FontSize', op.fs.label);
ylabel(axC, 'bed elevation \itz\rm [m, MSL]', 'FontSize', op.fs.label);
panelTag(axC, op.panelLabel{3});
kk = {'dem', 'dfw', 'eq', 'chart'};
hLC = gobjects(1, 4);
for q = 1:4, hLC(q) = plot(axC, NaN, NaN, '-', 'Color', PCOL.(kk{q}), 'LineWidth', 1.9); end
lgC = legend(axC, hLC, op.legendC, 'Location', 'southeast', 'FontSize', op.fs.legend, 'AutoUpdate', 'off');
lgC.ItemTokenSize = op.tokenSize;

%% 7 figure (d): buoy waves and wind, modeled wind, record times
axD = axes(fig, 'Position', POS.d);  hold(axD, 'on');
yyaxis(axD, 'left');  hold(axD, 'on');
hHs = plot(axD, bt, D.buoy_hs, '-', 'Color', hx(op.c.hs), 'LineWidth', 1.3);
for i = 1:nR
    xline(axD, REC(i).t, '-', 'Color', REC(i).rgb, 'LineWidth', op.recLineWidth);
end
for g = 1:numel(op.recGroups)                          % record names left of the first line of each group
    ii = op.recGroups{g};
    for r = 1:numel(ii)
        text(axD, REC(ii(1)).t - op.recLabelOff, op.recLabelY0 - op.recLabelDY*(r - 1), REC(ii(r)).name, ...
             'Color', REC(ii(r)).rgb, 'FontSize', op.fs.small, 'FontWeight', 'bold', 'HorizontalAlignment', 'right', ...
             'VerticalAlignment', 'top');
    end
end
ylim(axD, op.ylimD);
ylabel(axD, 'wave height [m]', 'FontSize', op.fs.label);
axD.YColor = [0.15 0.15 0.15];
yyaxis(axD, 'right');  hold(axD, 'on');
hW  = plot(axD, bt, D.buoy_wind_speed, '-', 'Color', hx(op.c.wind), 'LineWidth', op.windLW(1));
hWb = plot(axD, kt, D.kma_wind_speed_buoy, ':', 'Color', hx(op.c.wind), 'LineWidth', op.windLW(2));
hWa = plot(axD, kt, D.kma_wind_speed_apf, '--', 'Color', hx(op.c.windApf), 'LineWidth', op.windLW(3));
ylim(axD, op.ylimW);
ylabel(axD, 'wind speed [m s^{-1}]', 'FontSize', op.fs.label);
axD.YColor = hx(op.c.wind);
yyaxis(axD, 'left');
axSet(axD);
axD.XLim = [min(bt) max(bt)];
axD.XAxis.TickValues = dateshift(min(bt), 'start', 'day'):hours(12):max(bt);
axD.XAxis.TickLabelFormat = 'dd HH''h''';
xsecondarylabel(axD, 'Visible', 'off');
xlabel(axD, '2026 July (KST)', 'FontSize', op.fs.label);
panelTag(axD, op.panelLabel{4});
lgD = legend(axD, [hHs hW hWb hWa], op.legendD, 'Location', 'northeast', 'FontSize', op.fs.legend, 'AutoUpdate', 'off');
lgD.ItemTokenSize = op.tokenSizeD;
for ax = [axA axB axC axD], ax.Toolbar.Visible = 'off'; end

%% 8 export
if op.exportFig
    exportgraphics(fig, [op.outName '.png'], 'Resolution', 300);
    exportgraphics(fig, [op.outName '.pdf'], 'ContentType', 'vector');
end
