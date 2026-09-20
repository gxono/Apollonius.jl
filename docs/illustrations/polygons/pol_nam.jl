include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=240 margin=20 begin
    a, b, c = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(5.0, 2.0)
    d = APPoint(1.0, 0.0)
    pa = parallelogram(a, b, c)
    ps = square_on_segment(a, b)
    pr = rectangle_on_segment(a, b, 2.0)
    pp = regular_polygon(a, d, 6)
end
(; a, b, c, d, pa, ps, pr, pp) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple)
path([pa, ps, pr, pp], action=:stroke)
path([a, b, c, d]); plot_point(julia_blue)
end)
