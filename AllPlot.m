clc
clear
close all

load("dat.mat")          % loads struct: from runAll.m
runs = dat.runs;

%% User choices
saveFigs = true;
figFolder = "figs";

if saveFigs && ~exist(figFolder, "dir")
    mkdir(figFolder)
end

% Pick representative slices for speedup & contour plots
Re_list  = [10 100 1000];          % for plots vs n / speedup
n_list   = 4:6;             % for plots vs Re / omega
SOR_list = [1.0 1.4 1.8];       % highlighted omega values


%% Contour Plots
n0      = 6;            % choose grid level
useMG   = 1;            % 1 = MG, 0 = GS

% Extract matching runs
% (assumes one run per (Re, n, solver, SOR) — if multiple SOR, this picks first)
figure('Position', [100 100 1400 450])   % [left bottom width height]
tiledlayout(1, numel(Re_list), 'TileSpacing','compact','Padding','compact')

for r = 1:numel(Re_list)
    Re0 = Re_list(r);

    % Find matching run
    idx = find([runs.n] == n0 & ...
               [runs.Re] == Re0 & ...
               [runs.MG] == useMG, 1);

    if isempty(idx)
        nexttile
        text(0.5,0.5,'No data','HorizontalAlignment','center')
        title(sprintf('Re = %g', Re0))
        continue
    end

    R = runs(idx).Results;

    x = R.x;
    u = R.u;
    v = R.v;

    Vel_Magnitude = sqrt(u.^2 + v.^2);

    % Plot
    nexttile
    hold on

    contourf(x, x, Vel_Magnitude', 'LineColor','none')
    h = streamslice(x, x, u', v');
    set(h, 'Color','w')

    axis equal tight
    title(sprintf('Re = %g', Re0))

    hold off
end

% Shared colorbar
cb = colorbar;
cb.Layout.Tile = 'east';
title(cb, '|V|')

if saveFigs
    exportgraphics(gcf, fullfile(figFolder, "contours.png"), 'Resolution', 300)
end

%% Plot Convergence - this is a redundant rerun at this stage to allow broader range of grid sizes
nVals = 2:7;
tol = 1e-5;  % raise/lower as intended
dt = 1.5e-4; % match to max nVal
Re = 100;

convergence(nVals, Re, dt, tol)


if saveFigs
    exportgraphics(gcf, fullfile(figFolder, "order_of_accuracy.png"), 'Resolution', 300)
end

%% SpeedUp
% Pull useful data out of the struct
nruns = numel(runs);

n       = zeros(nruns,1);
Re      = zeros(nruns,1);
SOR     = zeros(nruns,1);
MG      = zeros(nruns,1);
elapsed = nan(nruns,1);
iters   = nan(nruns,1);
success = false(nruns,1);

for k = 1:nruns
    n(k)   = runs(k).n;
    Re(k)  = runs(k).Re;
    SOR(k) = runs(k).SOR;
    MG(k)  = runs(k).MG;

    if isfield(runs(k), "Results") && ~isempty(runs(k).Results)
        elapsed(k) = runs(k).Results.elapsed;
        iters(k)   = runs(k).Results.timestep;
        success(k) = true;
    end
end

good = success & ~isnan(elapsed);

% Basic style
set(groot,'defaultAxesFontSize',12)
set(groot,'defaultLineLineWidth',1.5)

gsStyle = '--o';
mgStyle = '-o';

% ============================================================
% 1) Wall time vs n
%    One subplot per Re
%    Colour = omega
%    Line style = solver
% ============================================================
figure('Position', [100 100 1400 450])   % [left bottom width height]
tiledlayout(1, numel(Re_list), 'TileSpacing', 'compact', 'Padding', 'compact')

cols = lines(numel(SOR_list));

for r = 1:numel(Re_list)
    Re0 = Re_list(r);
    nexttile
    hold on
    grid on
    box on

    madePlot = false;

    for s = 1:numel(SOR_list)
        w = SOR_list(s);
        col = cols(s,:);

        % GS
        idxGS = good & (Re == Re0) & (MG == 0) & abs(SOR - w) < 1e-12;
        if nnz(idxGS) > 1
            [xplot, order] = sort(n(idxGS));
            yplot = elapsed(idxGS);
            yplot = yplot(order);
            plot(xplot, yplot, gsStyle, 'Color', col, 'HandleVisibility','off')
            madePlot = true;
        end

        % MG
        idxMG = good & (Re == Re0) & (MG == 1) & abs(SOR - w) < 1e-12;
        if nnz(idxMG) > 1
            [xplot, order] = sort(n(idxMG));
            yplot = elapsed(idxMG);
            yplot = yplot(order);
            plot(xplot, yplot, mgStyle, 'Color', col, 'HandleVisibility','off')
            madePlot = true;
        end
    end

    title(sprintf('Re = %g', Re0))
    xlabel('n')
    if r == 1
        ylabel('Wall time [s]')
    end
    set(gca, 'YScale', 'log')

    if ~madePlot
        text(0.5, 0.5, 'No useful data', 'HorizontalAlignment','center')
    end
end

% Dummy legend
for s = 1:numel(SOR_list)
    plot(nan, nan, '-o', 'Color', cols(s,:), ...
        'DisplayName', sprintf('\\omega = %.2f', SOR_list(s)))
end
plot(nan, nan, 'k--o', 'DisplayName', 'GS')
plot(nan, nan, 'k-o',  'DisplayName', 'MG')
lgd = legend('Location','southoutside','Orientation','horizontal');
title(lgd, 'Colour = \omega, Style = solver')

sgtitle('Wall time vs n')

if saveFigs
    exportgraphics(gcf, fullfile(figFolder, "walltime_vs_n.png"), 'Resolution', 300)
end

%% ============================================================
% 2) Wall time vs Re
%    One subplot per n
%    Colour = omega
%    Line style = solver
% ============================================================
figure('Position', [100 100 1400 450])   % [left bottom width height]
tiledlayout(1, numel(n_list), 'TileSpacing', 'compact', 'Padding', 'compact')

cols = lines(numel(SOR_list));

for j = 1:numel(n_list)
    n0 = n_list(j);
    nexttile
    hold on
    grid on
    box on

    madePlot = false;

    for s = 1:numel(SOR_list)
        w = SOR_list(s);
        col = cols(s,:);

        % GS
        idxGS = good & (n == n0) & (MG == 0) & abs(SOR - w) < 1e-12;
        if nnz(idxGS) > 1
            [xplot, order] = sort(Re(idxGS));
            yplot = elapsed(idxGS);
            yplot = yplot(order);
            plot(xplot, yplot, gsStyle, 'Color', col, 'HandleVisibility','off')
            madePlot = true;
        end

        % MG
        idxMG = good & (n == n0) & (MG == 1) & abs(SOR - w) < 1e-12;
        if nnz(idxMG) > 1
            [xplot, order] = sort(Re(idxMG));
            yplot = elapsed(idxMG);
            yplot = yplot(order);
            plot(xplot, yplot, mgStyle, 'Color', col, 'HandleVisibility','off')
            madePlot = true;
        end
    end

    title(sprintf('n = %d', n0))
    xlabel('Re')
    if j == 1
        ylabel('Wall time [s]')
    end
    set(gca, 'XScale', 'log', 'YScale', 'log')

    if ~madePlot
        text(0.5, 0.5, 'No useful data', 'HorizontalAlignment','center')
    end
end

% Dummy legend
for s = 1:numel(SOR_list)
    plot(nan, nan, '-o', 'Color', cols(s,:), ...
        'DisplayName', sprintf('\\omega = %.2f', SOR_list(s)))
end
plot(nan, nan, 'k--o', 'DisplayName', 'GS')
plot(nan, nan, 'k-o',  'DisplayName', 'MG')
lgd = legend('Location','southoutside','Orientation','horizontal');
title(lgd, 'Colour = \omega, Style = solver')

sgtitle('Wall time vs Re')

if saveFigs
    exportgraphics(gcf, fullfile(figFolder, "walltime_vs_Re.png"), 'Resolution', 300)
end

%% ============================================================
% 3) Wall time vs omega
%    One subplot per n
%    Colour = Re
%    Line style = solver
% ============================================================
figure('Position', [100 100 1400 450])   % [left bottom width height]
tiledlayout(1, numel(n_list), 'TileSpacing', 'compact', 'Padding', 'compact')

cols = lines(numel(Re_list));

for j = 1:numel(n_list)
    n0 = n_list(j);
    nexttile
    hold on
    grid on
    box on

    madePlot = false;

    for r = 1:numel(Re_list)
        Re0 = Re_list(r);
        col = cols(r,:);

        % GS
        idxGS = good & (n == n0) & (Re == Re0) & (MG == 0);
        if nnz(idxGS) > 1
            [xplot, order] = sort(SOR(idxGS));
            yplot = elapsed(idxGS);
            yplot = yplot(order);
            plot(xplot, yplot, gsStyle, 'Color', col, 'HandleVisibility','off')
            madePlot = true;
        end

        % MG
        idxMG = good & (n == n0) & (Re == Re0) & (MG == 1);
        if nnz(idxMG) > 1
            [xplot, order] = sort(SOR(idxMG));
            yplot = elapsed(idxMG);
            yplot = yplot(order);
            plot(xplot, yplot, mgStyle, 'Color', col, 'HandleVisibility','off')
            madePlot = true;
        end
    end

    title(sprintf('n = %d', n0))
    xlabel('\omega')
    if j == 1
        ylabel('Wall time [s]')
    end

    if ~madePlot
        text(0.5, 0.5, 'No useful data', 'HorizontalAlignment','center')
    end
end

% Dummy legend
for r = 1:numel(Re_list)
    plot(nan, nan, '-o', 'Color', cols(r,:), ...
        'DisplayName', sprintf('Re = %g', Re_list(r)))
end
plot(nan, nan, 'k--o', 'DisplayName', 'GS')
plot(nan, nan, 'k-o',  'DisplayName', 'MG')
lgd = legend('Location','southoutside','Orientation','horizontal');
title(lgd, 'Colour = Re, Style = solver')

sgtitle('Wall time vs \omega')

if saveFigs
    exportgraphics(gcf, fullfile(figFolder, "walltime_vs_omega.png"), 'Resolution', 300)
end

%% ============================================================
% 4) MG speedup vs n
%    speedup = t_GS / t_MG
%    One subplot per Re
%    Colour = omega
% ============================================================
figure('Position', [100 100 1400 450])   % [left bottom width height]
tiledlayout(1, numel(Re_list), 'TileSpacing', 'compact', 'Padding', 'compact')

cols = lines(numel(SOR_list));

for r = 1:numel(Re_list)
    Re0 = Re_list(r);
    nexttile
    hold on
    grid on
    box on

    madePlot = false;

    for s = 1:numel(SOR_list)
        w = SOR_list(s);
        col = cols(s,:);

        nvals = unique(n(good & Re == Re0));
        sp = nan(size(nvals));

        for q = 1:numel(nvals)
            n0 = nvals(q);

            idxGS = good & (Re == Re0) & (n == n0) & (MG == 0) & abs(SOR - w) < 1e-12;
            idxMG = good & (Re == Re0) & (n == n0) & (MG == 1) & abs(SOR - w) < 1e-12;

            if any(idxGS) && any(idxMG)
                sp(q) = elapsed(find(idxGS,1)) / elapsed(find(idxMG,1));
            end
        end

        valid = ~isnan(sp);
        if nnz(valid) > 1
            plot(nvals(valid), sp(valid), '-o', 'Color', col, ...
                'HandleVisibility','off')
            madePlot = true;
        end
    end

    yline(1, 'k:', 'HandleVisibility','off')

    title(sprintf('Re = %g', Re0))
    xlabel('n')
    if r == 1
        ylabel('Speedup = t_{GS} / t_{MG}')
    end

    if ~madePlot
        text(0.5, 0.5, 'No useful data', 'HorizontalAlignment','center')
    end
end

% Dummy legend
for s = 1:numel(SOR_list)
    plot(nan, nan, '-o', 'Color', cols(s,:), ...
        'DisplayName', sprintf('\\omega = %.2f', SOR_list(s)))
end
lgd = legend('Location','southoutside','Orientation','horizontal');
title(lgd, 'Colour = \omega')

sgtitle('Multigrid speedup vs n')

if saveFigs
    exportgraphics(gcf, fullfile(figFolder, "speedup_vs_n.png"), 'Resolution', 300)
end