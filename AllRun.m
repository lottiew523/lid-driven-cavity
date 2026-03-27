clc
clear
close all

%% =========================
%  USER INPUTS
%  =========================
LidVel = 1.0;
tmax   = 200;
tol    = 1e-8;

% Sweep values
ReVals  = [10, 100,1000];
nVals   = 4:6;
SORVals = [1.0 1.4 1.8];
Switch  = [0 1];   % 0 = smoothSOR, 1 = multigridSOR
dt = 6e-4;

% Output file
saveName = 'dat.mat';

%% =========================
%  PREALLOC / SETUP
%  =========================
nRe   = numel(ReVals);
nn    = numel(nVals);
nSOR  = numel(SORVals);
nMG   = numel(Switch);
nRuns = nRe * nn * nSOR * nMG;

dat = struct();
dat.meta.created = datestr(now);
dat.meta.LidVel = LidVel;
dat.meta.tmax = tmax;
dat.meta.tol = tol;
dat.meta.ReVals = ReVals;
dat.meta.nVals = nVals;
dat.meta.SORVals = SORVals;
dat.meta.MGVals = Switch;
dat.meta.totalRuns = nRuns;

% Preallocate run struct array
emptyRun = struct( ...
    'runID', [], ...
    'n', [], ...
    'nx', [], ...
    'Re', [], ...
    'SOR', [], ...
    'MG', [], ...
    'solverName', "", ...
    'success', [], ...
    'message', "", ...
    'Results', [] ...
    );

dat.runs = repmat(emptyRun, nRuns, 1);

%% =========================
%  MAIN SWEEP
%  =========================
runID = 0;

for iRe = 1:nRe
    Re = ReVals(iRe);

    for in = 1:nn
        n = nVals(in);

        nx = 2^n + 1;
        dx = 1 / (nx - 1);
        nu = LidVel / Re;

        for iSOR = 1:nSOR
            SOR = SORVals(iSOR);

            for iMG = 1:nMG
                MG = Switch(iMG);

                runID = runID + 1;

                fprintf('\n========================================\n')
                fprintf('Run %d / %d\n', runID, nRuns)
                fprintf('Re = %-6g | n = %-2d | nx = %-4d | SOR = %-4.2f | MG = %d\n', ...
                    Re, n, nx, SOR, MG)

                dat.runs(runID).runID = runID;
                dat.runs(runID).n = n;
                dat.runs(runID).nx = nx;
                dat.runs(runID).Re = Re;
                dat.runs(runID).SOR = SOR;
                dat.runs(runID).MG = MG;
                dat.runs(runID).solverName = string(ternary(MG, 'Multigrid', 'SOR'));
                dat.runs(runID).dt_input = dt;

                try
                    Results = vs_solver(n, LidVel, Re, dt, tmax, tol, SOR, MG);

                    dat.runs(runID).Results = Results;
                    dat.runs(runID).success = true;

                    if Results.divergence
                        dat.runs(runID).message = "Solver returned divergence flag";
                    elseif Results.t_final >= tmax
                        dat.runs(runID).message = "Reached tmax before steady state";
                    else
                        dat.runs(runID).message = "Converged";
                    end

                catch ME
                    dat.runs(runID).Results = [];
                    dat.runs(runID).success = false;
                    dat.runs(runID).message = "Error: " + string(ME.message);

                    warning('Run %d failed: %s', runID, ME.message)
                end

                % Save progressively so you do not lose long sweeps
                save(saveName, 'dat', '-v7.3');
            end
        end
    end
end

fprintf('\nAll runs completed and saved to %s\n', saveName)

%% =========================
%  QUICK SUMMARY TABLE
%  =========================
summary = struct2table(rmfield(dat.runs, 'Results'));
disp(summary)

%% =========================
%  HELPER
%  =========================
function out = ternary(cond, a, b)
    if cond
        out = a;
    else
        out = b;
    end
end