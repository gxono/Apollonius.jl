include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=340 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    kh = kiepert_hyperbola(t)
    G = centroid(t)
    H = orthocenter(t)
end
(; A, B, C, t, kh, G, H) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_purple)
path(kh, action=:stroke)
sethue(julia_red)
label("G", :S, G); label("H", :E, H)
sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([G, H], action=:fillpreserve); sethue(julia_purple); strokepath()
end)
