function newStream=calc_newStream(vorticity_new, stream,dx_sq,tol,nx,SOR)
    err = 1;
    newStream=stream;
    while err > tol
        for i = 2:nx-1
            for j = 2:nx-1
                newStream(i,j) = 1/4 * (vorticity_new(i,j)*dx_sq + stream(i+1,j) + newStream(i-1,j) + stream(i, j+1) + newStream(i,j-1));
                newStream(i,j) = SOR*newStream(i,j) + (1-SOR)*stream(i,j);
            end
        end

        % Stopping Criteria
        err = max(max(abs(newStream(2:nx-1,2:nx-1) - stream(2:end-1,2:end-1))));
        
        % Reassign
        stream(2:end-1,2:end-1) = newStream(2:nx-1,2:nx-1);
    end
    newStream = newStream(2:nx-1,2:nx-1);
end
