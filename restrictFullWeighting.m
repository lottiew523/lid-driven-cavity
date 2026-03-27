function rc = restrictFullWeighting(rf)

    nf = size(rf,1);
    nc = (nf + 1)/2;
    rc = zeros(nc,nc);

    for I = 2:nc-1
        for J = 2:nc-1
            i = 2*I - 1;
            j = 2*J - 1;

            rc(I,J) = ( ...
                4*rf(i,j) + ...
                2*(rf(i+1,j) + rf(i-1,j) + rf(i,j+1) + rf(i,j-1)) + ...
                (rf(i+1,j+1) + rf(i+1,j-1) + rf(i-1,j+1) + rf(i-1,j-1)) ...
                ) / 16;
        end
    end

end