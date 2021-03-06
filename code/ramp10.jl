"""
10 degree ramp with M=1.5 flow.

Replicates an example problem from D. Lobao 'NUMERICAL SIMULATIONS
OF NAVIER STOKES FOR TRANSIENT FLOWS IN 2D'.

Matt Vernacchia
18.086 Project
Spring 2016
"""

# I need to have a line in between the top docstring and include
# because of a language bug.
# See https://github.com/JuliaArchive/Markdown.jl/issues/25
unused = 0

include("cfd086.jl")
using CFD086
using PyPlot

# Inlet conditions
T = 300.
p  = 101e3
Mx = 1.5
My = 0
U_inlet = pTM2u(p, T, Mx, My, air)

# Boundary conditions.
# Top: solid wall.
function top_bound(U, i, j, ps)
    n = [ps.dy_dξ(i * ps.Δx, j * ps.Δy), -1]
    n = n / norm(n)
    return ghost_wall(U, n)
end
# Right: blank outlet.
function right_bound(U, i, j, ps)
    return U
end
# Bottom: solid wall.
function bottom_bound(U, i, j, ps)
    n = [-ps.dy_dξ(i * ps.Δx, j * ps.Δy), 1]
    n = n / norm(n)
    return ghost_wall(U, n)
end
# Left: Full-state inlet.
function left_bound(U, i, j, ps)
    return U_inlet
end

# Grid size
Nx = 120
Ny = 40

# Step sizes
Δx = 10 / Nx
Δy = 10 / Nx
Δt = 0.4 * Δt_cfl(U_inlet[2] / U_inlet[1], U_inlet[3] / U_inlet[1], 340, Δx, Δy)

println(Δt)

# Grid shape
x_ramp = 1.0
m = tan(deg2rad(10.1))
function y(ξ, η)
    if ξ > x_ramp
        return η + m * (ξ - x_ramp)
    else
        return η
    end
end

function dy_dξ(ξ, η)
    if ξ > x_ramp
        return m
    else
        return 0
    end
end

ps = ProblemSpec(air, Δt, Δx, Δy, top_bound, right_bound, bottom_bound,
    left_bound,
    (ξ, η) -> ξ, # x(ξ, η)
    y,
    (ξ, η) -> 1, # dx_dξ
    (ξ, η) -> 0, # dx_dη
    dy_dξ, # dy_dξ
    (ξ, η) -> 1, # dy_dη
    )

# initial conditions
U = zeros(Nx, Ny, 4)
for i in 1:Nx
    for j in 1:Ny
        U[i, j, :] = U_inlet
    end
end

dump(U)

figure(figsize=(16,8))
plot_U(U, ps)
savefig("results/ramp10/t=00000.000us.svg")

tic()
for it in 1:2200
    U = MacCormack_step(U, ps, use_ad=true)
    if it % 10 == 0
        clf()
        plot_U(U, ps)
        suptitle(@sprintf("10 deg ramp, M=1.5, t=%5.3fus.svg", it * Δt * 1e6))
        savefig(@sprintf("results/ramp10/t=%5.3fus.svg", it * Δt * 1e6))
    end
end
toc()

dump(U)
show()