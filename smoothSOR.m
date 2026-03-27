function u = smoothSOR(u, f, h2, SOR, nSweeps, tol)

    n = size(u,1);
    u_new = u;

    for sweep = 1:nSweeps
        for i = 2:n-1
            for j = 2:n-1
                u_new(i,j) = 0.25 * ( ...
                    u(i+1,j) + u_new(i-1,j) + ...
                    u(i,j+1) + u_new(i,j-1) - ...
                    h2 * f(i,j) );

                u_new(i,j) = SOR * u_new(i,j) + (1 - SOR) * u(i,j);
            end
        end

        err = max(max(abs(u_new(2:n-1,2:n-1) - u(2:n-1,2:n-1))));
        u(2:n-1,2:n-1) = u_new(2:n-1,2:n-1);

        if err < tol
            break
        end
    end

end