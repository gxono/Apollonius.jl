include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=280 margin=30 begin
    c = APCircle2(APPoint(0.0, 0.0), 4.0)
    edge = rand(Apollonius.Random.Xoshiro(7), c, 14)
    inner = [rand_inside(Apollonius.Random.Xoshiro(k), c) for k in 1:40]
end
(; c, edge, inner) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(c, action=:stroke)
sethue(julia_purple)
path(edge); plot_point(julia_purple)
path(inner, radius=2); plot_point(julia_purple)
end)
