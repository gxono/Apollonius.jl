include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=320 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    ext = excentral_triangle(t)
    bc = circumcircle(ext)
    Be = bevan_point(t)
end
(; A, B, C, t, ext, bc, Be) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue("gray80")
path(ext, action=:stroke)
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_purple)
path(bc, action=:stroke)
sethue(julia_red)
label("Be", :N, Be)
sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([Be], action=:fillpreserve); sethue(julia_purple); strokepath()
end)
