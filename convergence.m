function [pMG, pGS] = convergence(nVals, Re, dt, tol)

    % Case settings
    LidVel = 1.0;
    tmax = 1000;

    % Preallocate
    velMG = nan(size(nVals));
    velGS = nan(size(nVals));

    % Solver styles (same idea as section 5)
    mgStyle = '-o';
    gsStyle = '--o';

    % Run both solvers on each grid
    for k = 1:length(nVals)
        n = nVals(k);

        solMG = vs_solver(n, LidVel, Re, dt, tmax, tol, 1.0, 1);
        solGS = vs_solver(n, LidVel, Re, dt, tmax, tol, 1.0, 0);

        mid = 2^(n-1) + 1;

        uMG = solMG.u;
        vMG = solMG.v;
        velMG(k) = sqrt(uMG(mid,mid)^2 + vMG(mid,mid)^2);

        uGS = solGS.u;
        vGS = solGS.v;
        velGS(k) = sqrt(uGS(mid,mid)^2 + vGS(mid,mid)^2);
    end

    % Successive-grid difference
    errMG = velMG(2:end) - velMG(1:end-1);
    errGS = velGS(2:end) - velGS(1:end-1);

    % Observed order from divided differences
    pMG = log(errMG(1:end-1) ./ errMG(2:end)) / log(2);
    pGS = log(errGS(1:end-1) ./ errGS(2:end)) / log(2);

    %% Plot 1: successive-grid difference
    figure
    hold on
    box on
    grid on

    plot(nVals(2:end), abs(errMG), mgStyle, 'LineWidth', 1.5, ...
        'DisplayName', 'MG')
    plot(nVals(2:end), abs(errGS), gsStyle, 'LineWidth', 1.5, ...
        'DisplayName', 'GS')

    xlabel('$n$', 'Interpreter', 'latex')
    ylabel('$|V_n - V_{n-1}|$', 'Interpreter', 'latex')
    title('Centre-point successive-grid difference', 'Interpreter', 'latex')
    legend('Location', 'best')
    set(gca, 'YScale', 'log')

    %% Plot 2: observed order
    figure
    hold on
    box on
    grid on

    plot(nVals(3:end), pMG, mgStyle, 'LineWidth', 1.5, ...
        'DisplayName', 'MG')
    plot(nVals(3:end), pGS, gsStyle, 'LineWidth', 1.5, ...
        'DisplayName', 'GS')

    xlabel('$n$ (fine grid in divided difference)', 'Interpreter', 'latex')
    ylabel('Observed order $p$', 'Interpreter', 'latex')
    title('Observed convergence order at cavity centre', 'Interpreter', 'latex')
    legend('Location', 'best')

    % Optional reference line
    yline(2, 'k:', 'HandleVisibility', 'off')

    %% Display
    disp('Observed order, MG:')
    disp(pMG)

    disp('Observed order, GS:')
    disp(pGS)
end