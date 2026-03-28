function Results = vortex(n,LidVel,Re,dt,tmax,tol,SOR,MG)

% TIME/SPACE PARAMS
nx = 2^n + 1;
dx = 1 / (nx-1);
i = 2:nx-1;
j = 2:nx-1;

% INITIALISE
vorticity_new = zeros(nx, nx);
stream = vorticity_new;
vorticity = vorticity_new;
u = vorticity_new;
v = vorticity_new;
u(2:nx-1,nx) = LidVel;
u(2:nx-1,1) = -LidVel;
v(1,2:nx-1) = LidVel;
v(nx,2:nx-1) = -LidVel;

% FLAGS
timestep = 0;
divergence = false;

% PRECOMPUTE
nu = LidVel / Re;
dx_sq = dx^2;

a = nu * dt / dx_sq;
cfl = LidVel * dt / dx;

% Stability limits
dt_diff = 0.25 * dx_sq / nu;
dt_conv = dx / LidVel;
dt_max = min(dt_diff, dt_conv);

disp("cfl number = " + cfl)
disp("a = " + a)

if a >= 0.25 || cfl >= 1
    warning("Stability conditions not met. Suggested dt < " + dt_max)
    sf = 3;        % Significant figures
    % Calculate magnitude and resolution
    res = 10^(floor(log10(abs(dt_max))) - (sf - 1));
    % Round down
    dt = floor(dt_max ./ res) .* res;
    warning("Running with dt = " + dt)
else
    disp("Stability conditions met. Max stable dt < " + dt_max)
end

% START TIMERS
start = tic;
tic

for t = dt:dt:tmax
    timestep = timestep + 1;

    % PIN BOUNDARIES
    vorticity(:,nx) = - 2 * stream(1:nx, nx-1) / (dx^2) - LidVel * 2 / dx;
    vorticity(:,1) = - 2 * stream(1:nx, 2) / (dx^2) - LidVel * 2 / dx;
    vorticity(1,:) = -2 * stream(2, 1:nx) / (dx^2) - LidVel * 2 / dx;
    vorticity(nx,:) = -2 * stream(nx - 1, 1:nx) / (dx^2) - LidVel * 2 / dx;
    
    % RESOLVE VORTICITY AND STREAMFUNCTION
    vorticity_new(i,j) = calc_newVorticity(stream,vorticity,dx,dt,nu,dx_sq);
    %stream(i,j) = calc_newStream(vorticity_new, stream,dx_sq,tol,nx,SOR);
    % Poisson RHS: Lap(psi) = -w
    if MG
        stream = multigridSOR(stream, -vorticity_new, dx_sq, SOR, tol);
    else
        stream = smoothSOR(stream,-vorticity_new,dx_sq,SOR,1e9,tol);
    end


    %   Check for convergence or divergence
    err(timestep) = max(max(abs(vorticity_new(i,j) - vorticity(i,j))));

    if any(isnan(vorticity_new), 'all')
        divergence = true;
        break
    end
    if err(timestep) < tol
        break;
    end
    
    % Reassign vorticity of current loop to old value of next loop
    vorticity = vorticity_new;

end
elapsed = toc(start);
x = 0:dx:1;
t_final = t;

% BACK-COMPUTE VELOCITIES
u(2:nx-1, nx) = LidVel;
u(i, j) = (stream(i, j+1) - stream(i, j-1)) / (2 * dx);
v(i, j) = (-stream(i+1, j) + stream(i-1, j)) / (2 * dx);


Results.tmax = tmax;
Results.dx = dx;
Results.x = x;

Results.w = vorticity;
Results.stream = stream;
Results.u = u;
Results.v = v;
Results.timestep = timestep;
Results.t_final = t_final;
Results.t = dt:dt:t;
Results.divergence = divergence;
Results.a = a;
Results.cfl = cfl;
Results.error_w = err;
Results.elapsed = elapsed;

% Display final time to reach steady state
disp("Final Timestep, s: " + t_final)
if t_final < tmax
    if divergence == false
        disp("Simulation has reached steady state after " + timestep + " iterations, taking " + num2str(elapsed) + " seconds")
        disp("Suggested tmax: " + ceil(t_final))
    else
        disp("Solution diverged at " + timestep + " iterations")
    end
elseif divergence == false
    disp("Simulation has not yet reached steady state - increase tmax. Error = "+err(end))
end

end
