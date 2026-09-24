include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=300 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    K = symmedian_point(t)
    c1 = first_lemoine_circle(t)
    c2 = second_lemoine_circle(t)
    c3 = symmedial_circle(t)
    p1 = collect(first_lemoine_points(t))
end
(; A, B, C, t, K, c1, c2, c3, p1) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_purple)
path([c1, c2, c3], action=:stroke)
sethue(julia_red)
label("K", :N, K)
sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path(p1, action=:fillpreserve); sethue(julia_purple); strokepath()
sethue("white"); path([K], action=:fillpreserve); sethue(julia_purple); strokepath()
end)
