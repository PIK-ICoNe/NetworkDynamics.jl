using LightGraphs
using OrdinaryDiffEq
using NetworkDynamics
using Plots

N = 100 # number of nodes
k = 10  # average degree
g = barabasi_albert(N, k)

#=
  Berner, Rico, Eckehard Schöll, and Serhiy Yanchuk.
  "Multiclusters in Networks of Adaptively Coupled Phase Oscillators."
  SIAM Journal on Applied Dynamical Systems 18.4 (2019): 2227-2266.
=#


@inline function kuramoto_plastic_edge!(de, e, v_s, v_d, p, t)
    # Source to Destination coupling

    # The coupling function is modeled by a differential algebraic equation with mass matrix 0
    # 0 * de[1] = e[2] * sin(v_s[1] - v_d[1] + α) / N - e[1] is equivalent to e[1] = e[2] * sin(v_s[1] - v_d[1] + α) / N

    de[1] =  e[2] * sin(v_s[1] - v_d[1] + α) / N - e[1]
    de[2] = - ϵ * (sin(v_s[1] - v_d[1] + β) + e[2])

    # Destination to source coupling
    # since the coupling function is not symmetric we have to compute the other direction as well

    de[3] =  e[4] * sin(v_d[1] - v_s[1] + α) / N - e[3]
    de[4] = - ϵ * (sin(v_d[1] - v_s[1] + β) + e[4])
    nothing
end

@inline function kuramoto_plastic_vertex!(dv, v, e_s, e_d, p, t)
    dv .= 0
    for e in e_s
        dv .-= e[1]
    end
    for e in e_d
        dv .-= e[3]
    end
end


    # Parameter definitions
ϵ = 0.1
α = .2π
β = -.95π

# NetworkDynamics Setup
plasticvertex = ODEVertex(f! = kuramoto_plastic_vertex!, dim =1)
mass_matrix_plasticedge = zeros(4,4)
mass_matrix_plasticedge[1,1] = 1.
mass_matrix_plasticedge[3,3] = 1.

plasticedge   = ODEEdge(f! = kuramoto_plastic_edge!, dim=4, sym=[:es, :ks,:ed,:kd]);
kuramoto_plastic! = network_dynamics(plasticvertex, plasticedge, g)

# ODE Setup & Solution
x0_plastic        = randn(N + 4 * ne(g))
tspan_plastic     = (0., 500.)
params_plastic    = (nothing, nothing)
prob_plastic      = ODEProblem(kuramoto_plastic!, x0_plastic, tspan_plastic, params_plastic);
sol_plastic       = solve(prob_plastic, Tsit5());

# Plotting
v_idx = idx_containing(kuramoto_plastic!, :v)
e_idx = idx_containing(kuramoto_plastic!, :e)
plot(sol_plastic, vars=v_idx, legend=false)

using LaTeXStrings

plot!(sol_plastic, vars=e_idx, legend=false, color=:black, linewidth=0.1, ylabel=L"\theta")