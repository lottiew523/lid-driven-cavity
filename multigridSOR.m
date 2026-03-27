function u = multigridSOR(u, f, h2, SOR,tol)

    n = size(u,1);

    % Coarsest grid: smooth
    if n <= 5
        u = smoothSOR(u, f, h2, SOR, 30, tol);
        return
    end

    % Pre-smoothing
    u = smoothSOR(u, f, h2, SOR, 3, tol);

    % Residual on fine grid
    r = calc_residual(u, f, h2);

    % Restrict residual to coarse grid
    rc = restrictFullWeighting(r);

    % Zero initial guess for coarse-grid correction
    ec = zeros(size(rc));

    % Coarse-grid error solve: A e = r
    ec = multigridSOR(ec, rc, 4*h2, SOR, tol);

    % Prolongate correction and apply
    ef = prolongBilinear(ec);
    u = u + ef;

    % Post-smoothing
    u = smoothSOR(u, f, h2, SOR, 3, tol);
end