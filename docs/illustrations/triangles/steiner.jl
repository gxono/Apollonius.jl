include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=240 margin=20 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    inell = steiner_inellipse(t)
    circumell = steiner_circumellipse(t)
    ii = reduce(vcat, intersection.(APLine.(sides(t)), inell))
end
(; A, B, C, t, inell, circumell, ii) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple)
path([inell, circumell], action=:stroke)
sethue(julia_blue)
path(t, action=:stroke)
path(vertices(t))
path(ii)
plot_point(julia_purple)
end)
