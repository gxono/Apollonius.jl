include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=280 margin=30 begin
    pg = APStraightNgon([APPoint(0.0, 0.0), APPoint(5.0, 0.0), APPoint(6.0, 3.0), APPoint(2.0, 4.0), APPoint(-1.0, 2.0)])
    @unbounded l = APLine(APPoint(-2.0, 1.0), APPoint(7.0, 2.5))
    pts = reduce(vcat, [intersection(s, l) for s in sides(pg)])
end
(; pg, l, pts) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(pg, action=:stroke)
path(l, action=:stroke, extend=200)
sethue(julia_purple)
path(pts); plot_point(julia_purple)
end)
