%% Single run - change parameters here and get a contour plot

n = 4;          % nx = 2^n + 1
LidVel = 1;     % default
Re = 10;
dt = .2;
tmax = 10;
tol = 1e-8;
SOR=1.95;

sol = vs_solver(n,LidVel,Re,dt,tmax,tol,SOR,0);

x = sol.x;
t_final = sol.t(end);

u_final = sol.u(:,:);
v_final = sol.v(:,:);
u_final = u_final';
v_final = v_final';

Vel_Magnitude = (u_final.^2 + v_final.^2).^(1/2);
t=sol.t;

% Velocity profile
figure(1)
hold on
contourf(x, x, Vel_Magnitude, 'LineColor', 'none')
h = streamslice(x, x, u_final, v_final);
set(h, 'Color', 'w')
colorbar
axis("equal")
hold off