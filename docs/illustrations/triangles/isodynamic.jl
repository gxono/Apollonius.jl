include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=340 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    apo = collect(three_apollonius_circles(t))
    iso1, iso2 = isodynamic_points(t)
end
(; A, B, C, t, apo, iso1, iso2) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_purple)
path(apo, action=:stroke)
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_red)
label("1", :N, iso1); label("2", :N, iso2)
sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([iso1, iso2], action=:fillpreserve); sethue(julia_purple); strokepath()
end)
