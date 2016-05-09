# Unit tests for solver.jl
#
# Matt Vernacchia
# 18.086 Project
# Spring 2016

using Base.Test

include("cfd086.jl")
using CFD086

function test_unif_open()
    # A uniform grid with open bounds should remain uniform and constant.
    srand(24324)
    U = 100 * rand() * ones(8, 8, 4)
    U_original = copy(U)
    ps = ProblemSpec(air, 1., 1., 1.,
        x -> x,
        x -> x,
        x -> x,
        x -> x)

    @test U ≈ MacCormack_step(U, ps)

    for i in 1:100
        U = MacCormack_step(U, ps)
        @test U ≈ U_original
    end
end

function test_unif_wall()
    # A uniform grid with walls should remain uniform and constant,
    # if the velocity is zero.
    srand(337)
    U = 100 * rand() * ones(8, 8, 4)
    U[:, :, 2:3] = 0
    U_original = copy(U)

    ps = ProblemSpec(air, 1., 1., 1.,
        x -> ghost_wall(x, [0, -1.]), # top
        x -> ghost_wall(x, [-1., 0.]), # right
        x -> ghost_wall(x, [0, 1.]), # bottom
        x -> ghost_wall(x, [1.0, 0.])) # left

    @test U ≈ MacCormack_step(U, ps)

    for i in 1:100
        U = MacCormack_step(U, ps)
        @test U ≈ U_original
    end
end

function test_stationary_T_discont()
    # The fluid has uniform pressure and uniformly zero
    # velocity. There is a temperature discontinuity. No
    # changes in the fluid state should occur.
    U = zeros(8, 8, 4)
    for i in 1:8
        for j in 1:8
            if i <= 4
                U[i, j, :] = pTvel2u(101e3, 300, 0, 0, air)
            else
                U[i, j, :] = pTvel2u(101e3, 200, 0, 0, air)
            end
        end
    end
    U_original = copy(U)

    ps = ProblemSpec(air, 1., 1., 1.,
        x -> x,
        x -> x,
        x -> x,
        x -> x)

    @test U ≈ MacCormack_step(U, ps)

    for i in 1:100
        U = MacCormack_step(U, ps)
        @test U ≈ U_original
    end
end


function test_unif_open_ad()
    # A uniform grid with open bounds should remain uniform and constant,
    # even with artifical diffusion.
    srand(24324)
    U = ones(8, 8, 4)
    U[:, :, 1] *= rand()
    U[:, :, 2] *= 10 * rand()
    U[:, :, 3] *= 10 * rand()
    U[:, :, 4] *= 1e5 * rand()

    U_original = copy(U)
    ps = ProblemSpec(air, 1., 1., 1.,
        x -> x,
        x -> x,
        x -> x,
        x -> x)

    @test U ≈ MacCormack_step(U, ps, use_ad=true)

    for i in 1:100
        U = MacCormack_step(U, ps, use_ad=true)
        @test U ≈ U_original
    end
end


function test_unif_wall_ad()
    # A uniform grid with walls should remain uniform and constant,
    # if the velocity is zero, even with artificial diffusion.
    srand(337)
    U = ones(8, 8, 4)
    U[:, :, 1] *= rand()
    U[:, :, 2] *= 0
    U[:, :, 3] *= 0
    U[:, :, 4] *= 1e5 * rand()
    U_original = copy(U)

    ps = ProblemSpec(air, 1., 1., 1.,
        x -> ghost_wall(x, [0, -1.]), # top
        x -> ghost_wall(x, [-1., 0.]), # right
        x -> ghost_wall(x, [0, 1.]), # bottom
        x -> ghost_wall(x, [1.0, 0.])) # left

    @test U ≈ MacCormack_step(U, ps, use_ad=true)

    for i in 1:100
        U = MacCormack_step(U, ps, use_ad=true)
        @test U ≈ U_original
    end
end


test_unif_open()
test_unif_wall()
test_stationary_T_discont()
test_unif_open_ad()
test_unif_wall_ad()
println("Passed all tests.")
