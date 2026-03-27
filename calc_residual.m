function r = calc_residual(u, f, h2)

    r = zeros(size(u));

    Au = ( ...
        u(3:end,2:end-1) + u(1:end-2,2:end-1) + ...
        u(2:end-1,3:end) + u(2:end-1,1:end-2) - ...
        4*u(2:end-1,2:end-1) ) / h2;

    r(2:end-1,2:end-1) = f(2:end-1,2:end-1) - Au;

end