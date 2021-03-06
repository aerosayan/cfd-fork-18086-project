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

# Inlet conditions
T = 300.
p  = 101e3
u = 100.
v = 0.
U_inlet = pTvel2u(p, T, u, v, air)

# Boundary conditions.
# Top: solid wall.
function top_bound(U, i, j, ps)
    return ghost_wall(U, [0., -1.])
end
# Right: blank outlet.
function right_bound(U, i, j, ps)
    # return ghost_p(U, 101e3 - 50, air)
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
Δx = 1e-2
Δy = 1e-2
Δt = 0.1 * Δt_cfl(u, v, 340, Δx, Δy)

# Grid size
Nx = 100
Ny = 10

ps = ProblemSpec(air, Δt, Δx, Δy, top_bound, right_bound, bottom_bound,
    left_bound)

# initial conditions
U = zeros(Nx, Ny, 4)
for i in 1:Nx
    for j in 1:Ny
        if i < 30
            U[i, j, :] = pTvel2u(101e3, 300, 100, 0, air)
        # elseif i < 70
        #     U[i, j, :] = pTvel2u(101e3, 300 - 100*(i-30)/40, 100, 0, air)
        else
            U[i, j, :] = pTvel2u(101e3, 200, 100, 0, air)
        end
    end
end

dump(U)

tic()
for it in 1:1000
    U = MacCormack_step(U, ps, use_ad=true)
end
toc()

dump(U)


plot_U(U, ps)
show()