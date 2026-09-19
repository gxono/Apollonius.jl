include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=280 margin=30 begin
    t = APTriangle(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
    t1 = rotate(pi / 2)(t)
    t2 = t |> translate(APVector(2.0, 0.0)) |> rotate(pi / 2)
    c = circumcircle(t)
    c2 = homothety(2.0)(c)
end
(; t, t1, t2, c, c2) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path([t, c], action=:stroke)
sethue(julia_purple)
path([t1, t2, c2], action=:stroke)
end)
