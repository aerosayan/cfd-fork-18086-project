"""
Main script.

Define a problem and run the solver.

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
p  = 800e3
M_x = 10 * cos(deg2rad(30))
M_y = - 10 * sin(deg2rad(30))
U_inlet = pTM2u(p, T, M_x, M_y, air)

U_outlet = pTM2u(p / 4, T, 0, 0, air)

# Boundary conditions.
# Top: blank.
function top_bound(U, i, j, ps)
    u = U[2] / U[1]
    if u > 1000
        return U_inlet
    else
        return U_outlet
    end
end
# Right: blank outlet.
function right_bound(U, i, j, ps)
    return U
end
# Bottom: solid wall.
function bottom_bound(U, i, j, ps)
    return ghost_wall(U, [0., 1.])
end
# Left: Full-state inlet.
function left_bound(U, i, j, ps)
    return U_inlet
end

# Step sizes
Δx = 0.5e-2
Δy = 0.5e-2
Δt = 0.1 * Δt_cfl(U_inlet[2] / U_inlet[1], U_inlet[3] / U_inlet[1], 340, Δx, Δy)

# Grid size
Nx = 100
Ny = 25

ps = ProblemSpec(air, Δt, Δx, Δy, top_bound, right_bound, bottom_bound,
    left_bound)

# initial conditions
U = zeros(Nx, Ny, 4)
for i in 1:Nx
    for j in 1:Ny
        if j * Δy < 3^0.5 * (i-2) * Δx
            U[i, j, :] = U_outlet
        elseif isapprox(j * Δy, 3^0.5 * (i-2) * Δx, atol=2*Δy)
            U[i, j, :] = pTM2u(p, T,
                5 * cos(deg2rad(30)),
                -5 * sin(deg2rad(30)),
                air)
        else
            U[i, j, :] = U_inlet
        end
    end
end

dump(U)

figure(figsize=(16,8))
plot_U(U, ps)
savefig("results/double_mach/t=0s.svg")

tic()
for it in 1:200
    U = MacCormack_step(U, ps, use_ad=true)
    if it % 10 == 0
        clf()
        plot_U(U, ps)
        savefig(@sprintf("results/double_mach/t=%3.3fus.svg", it * Δt * 1e6))
    end
end
toc()

dump(U)
show()