include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=340 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    np_tri = napoleon_triangle(t)
    mor = morley_triangle(t)
end
(; A, B, C, t, np_tri, mor) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_purple)
path([np_tri, mor], action=:stroke)
path([A, B, C]); plot_point(julia_blue)
end)
