include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=260 margin=30 begin
    @unbounded l1 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
    @unbounded l2 = APLine(APPoint(0.0, 3.0), APPoint(1.0, 3.0))
    @unbounded s = APStrip2(l1, l2)
    pts = [APPoint(x, y) for x in (-3.0, 0.0, 3.0) for y in (-1.5, 1.5, 4.5)]
    far = APPoint(1.0, 4.5)
    foot = projection(far, l2)
end
(; l1, l2, s, pts, far, foot) = lxo
@svg_doc(lxm, @__FILE__, begin
inside = [p for p in pts if p in s]
outside = [p for p in pts if !(p in s)]
sethue(julia_blue)
path([l1, l2], action=:stroke)
gsave()
setline(1); setdash("dash")
sethue(julia_green)
path(APSegment(far, foot), action=:stroke)
grestore()
sethue("gray80")
path([outside; far]); plot_point("gray80")
sethue(julia_purple)
path(inside); plot_point(julia_purple)
end)
