function ef = prolongBilinear(ec)

    nc = size(ec,1);
    nf = 2*(nc-1) + 1;
    ef = zeros(nf,nf);

    % Inject coarse points
    ef(1:2:end,1:2:end) = ec;

    % Interpolate in x-direction
    ef(2:2:end-1,1:2:end) = 0.5 * (ec(1:end-1,:) + ec(2:end,:));

    % Interpolate in y-direction
    ef(1:2:end,2:2:end-1) = 0.5 * (ec(:,1:end-1) + ec(:,2:end));

    % Interpolate cell centres
    ef(2:2:end-1,2:2:end-1) = 0.25 * ( ...
        ec(1:end-1,1:end-1) + ec(2:end,1:end-1) + ...
        ec(1:end-1,2:end)   + ec(2:end,2:end) );

end