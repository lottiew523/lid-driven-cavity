# Lid-Driven Cavity Solver (Vorticity–Streamfunction, MATLAB)

A 2D incompressible flow solver for the classical lid-driven cavity problem using the vorticity–streamfunction formulation.  

This project focuses on **numerical accuracy, convergence behaviour, and solver performance**, including comparison between standard SOR and multigrid acceleration.

---

##  Overview

The solver computes steady-state flow in a square cavity driven by a moving lid.

Key features:
- Finite difference discretisation (2nd order central schemes)
- Explicit time stepping (Euler forward)
- Poisson equation for streamfunction
- Two solvers:
  - Gauss–Seidel SOR
  - Multigrid-accelerated SOR

Includes:
- Parameter sweeps (Re, grid size, relaxation factor)
- Convergence analysis
- Performance benchmarking

---

## Governing Equations

The solver uses the **vorticity–streamfunction formulation**:

Velocity recovery:
u = dψ/dy  
v = -dψ/dx  

---

##  Features

- Structured grid: `nx = 2^n + 1`
- Automatic Stability timestep handling
- Divergence detection
- Multigrid accellerated solver
- Parameter sweeps:
  - Reynolds number (Re)
  - Grid resolution (n)
  - Relaxation factor (SOR)
- Performance analysis:
  - Wall time scaling
  - Multigrid speedup
- Automated plotting script :)

---

## 📂 Project Structure

### Core Solver
- `vs_solver.m` – main simulation engine

### Run Scripts
- `run.m` – single simulation + contour plot
- `AllRun.m` – parameter sweep + data storage

### Post-Processing
- `AllPlot.m` – generates:
  - velocity contours
  - convergence plots
  - performance scaling plots

---

## ▶️ Usage

### Single Run

Edit parameters inside `run.m`:

```matlab
n = 4;
Re = 10;
dt = 0.2;
SOR = 1.95;
```


### Full Results

```matlab
AllRun
```

Reults are saved to

```matlab
dat.mat
```

Then run:
```matlab
AllPlot
```

To view plots.

UPDATE 28/03:
- Stable parameters for Re 2800 can be found in `run.m`
- Vortex function (call using `vortex(n,LidVel,Re,dt,tmax,tol,SOR,MG)`. Duplicate function, generalised to 4 moving walls.
