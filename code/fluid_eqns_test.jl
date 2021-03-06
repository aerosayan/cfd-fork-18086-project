# Unit tests for fluid_eqns.jl
#
# Matt Vernacchia
# 18.086 Project
# Spring 2016

using Base.Test

include("cfd086.jl")
using CFD086

function test_u2e()
    @test u2e([1, 0, 0, 2]) == 2
    @test u2e([1, 2, 4, 0]) == -10
    @test u2e([10, 0, 0, 1]) == 0.1
end

function test_u2p()
    # if u = v = 0, p = (γ - 1) * E
    @test u2p([234, 0, 0, 101e3 / 0.40], air) ≈ 101e3
    @test u2p([33e-4, 0, 0, 1 / 0.40], air) ≈ 1
    @test u2p([33e-4, 0, 0, 1 / (2/3)], helium) ≈ 1

    # E = p/(γ - 1) + ρ/2 (u^2 + v^2)
    @test u2p([2, 2, 2, 1 / (2/3) + 2], helium) ≈ 1
end

function test_u2T()
    @test isapprox(u2T([1.205, 0, 0, 101e3 / 0.40], air), 293.15, atol=3)
    @test isapprox(u2T([0.166, 0, 0, 101e3 / (2/3)], helium), 293.15, atol=3)
    @test isapprox(u2T([0.166, 0.166*2, 0.166*2, 101e3 / (2/3) + 0.166/2*8], helium), 293.15, atol=3)
end

function test_u2vel()
    @test isapprox(u2vel([2, 20, 20, 0]), [10, 10])
end

function test_u2a()
    # Air at room conditions
    @test isapprox(u2a([1.205, 0, 0, 101e3 / 0.40], air), 343.4, rtol=1e-2)
    # Helium at room conditions
    @test isapprox(u2a([0.166, 0, 0, 101e3 / (2/3)], helium), 1008, rtol=1e-2)
end

function test_pTvel2u()
    # Still air at room temp and pressure.
    U = pTvel2u(101e3, 293.15, 0, 0, air)
    @test isapprox(U[1], 1.205, atol=0.05)
    @test U[2] == 0
    @test U[3] == 0
    @test U[4] ≈ 101e3 / 0.4

    # Moving helium
    U = pTvel2u(101e3, 293.15, 100, 10, helium)
    @test isapprox(U[1], 0.166, atol=0.05)
    @test isapprox(U[2], 16.6, rtol=1e-3)
    @test isapprox(U[3], 1.66, rtol=1e-3)
    @test isapprox(U[4], 101e3 / (2/3) + 0.166 / 2 * (100^2 + 10^2), rtol=1e-3)
end

function test_pTM2u()
    # Moving helium
    # speed of sound
    a = ((5/3) * 101e3 / 0.166)^0.5
    U = pTM2u(101e3, 293.15, 100 / a, 10 / a, helium)
    @test isapprox(U[1], 0.166, atol=0.05)
    @test isapprox(U[2], 16.6, rtol=1e-3)
    @test isapprox(U[3], 1.66, rtol=1e-3)
    @test isapprox(U[4], 101e3 / (2/3) + 0.166 / 2 * (100^2 + 10^2), rtol=1e-3)
end

function test_FG_euler()
    srand(634)
    U = rand(4)
    p = (helium.γ - 1) * (U[4] - 0.5 * (U[2]^2 + U[3]^2) / U[1])
    F = [U[2],
        U[2]^2 / U[1] + p,
        U[2] * U[3] / U[1],
        U[2] * (U[4] + p) / U[1]]
    G = [U[3],
        U[2] * U[3] / U[1],
        U[3]^2 / U[1] + p,
        U[3] * (U[4] + p) / U[1]]
    @test F_euler(U, helium) ≈ F
    @test G_euler(U, helium) ≈ G
end

test_u2e()
test_u2p()
test_u2T()
test_u2vel()
test_u2a()
test_pTvel2u()
test_pTM2u()
test_FG_euler()
println("Passed all tests.")
