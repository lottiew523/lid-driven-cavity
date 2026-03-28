%% Single run - change parameters here and get a contour plot
% NOTE ALSO Re > 500 requires lower dt than stipulated by cfl/a for
% stable solution. Upwind solver may help with this?

% % HIGH RE
% n = 6;          % nx = 2^n + 1
% LidVel = 1;     % default
% Re = 2800;
% dt = .001;
% tmax = 1000;
% tol = 1e-7;
% SOR=1.0;
% Multigrid = true;

n = 6;          % nx = 2^n + 1
LidVel = 1;     % default
Re = 6;
dt = 0.01;
tmax = 500;
tol = 1e-7;
SOR = 1.0;
Multigrid = true;
saveFigs = true;
figFolder = "figs";

if saveFigs && ~exist(figFolder, "dir")
    mkdir(figFolder)
end



% Run both solvers
sols = {
    vs_solver(n, LidVel, Re, dt, tmax, tol, SOR, Multigrid),'Lid-Driven Cavity'
    vortex(n, LidVel, Re, dt, tmax, tol, SOR, Multigrid),   'Vortex'
};

% Large tiled figure
figure('Position', [100, 100, 1400, 650])
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact')

for k = 1:size(sols,1)
    sol = sols{k,1};
    solver_name = sols{k,2};

    x = sol.x;
    u_final = sol.u';
    v_final = sol.v';
    Vel_Magnitude = sqrt(u_final.^2 + v_final.^2);

    nexttile
    hold on

    contourf(x, x, Vel_Magnitude, 20, 'LineColor', 'none')
    h = streamslice(x, x, u_final, v_final);
    set(h, 'Color', 'w')
    colorbar
    axis equal tight

    title(sprintf('%s, Re = %g', solver_name, Re), 'FontSize', 16)

    % Divergence label if applicable
    if isfield(sol, 'diverged') && sol.diverged
        text(0.5, 1.04, 'Solution diverged at next timestep', ...
            'Units', 'normalized', ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', ...
            'Color', 'r', ...
            'FontWeight', 'bold', ...
            'FontSize', 12);
    end

    hold off
end

if saveFigs
    exportgraphics(gcf, fullfile(figFolder, sprintf("Re_%g.png",Re)), 'Resolution', 700)
end
