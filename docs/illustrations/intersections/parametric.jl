include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=300 margin=30 begin
    sine = APParametricCurve2(x -> APPoint(x, sin(x)), (0.0, 6.0))
    c = APCircle2(APPoint(3.0, 0.0), 1.0)
    @unbounded l = APLine(APPoint(0.0, 0.5), APPoint(1.0, 0.5))
    lseg = APSegment(APPoint(0.0, 0.5), APPoint(6.0, 0.5))
    pts = [intersection(sine, l); intersection(sine, c)]
end
(; sine, c, l, lseg, pts) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path([sine, c, lseg], action=:stroke)
sethue(julia_purple)
path(pts); plot_point(julia_purple)
end)
