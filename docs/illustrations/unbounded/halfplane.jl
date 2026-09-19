include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=260 margin=30 begin
    @unbounded l = APLine(APPoint(0.0, 0.0), APPoint(0.0, 4.0))
    q = APPoint(1.0, 0.0)
    @unbounded hp = APHalfPlane2(l, q)
    pts = [APPoint(x, y) for x in (-3.0, -1.0, 1.0, 3.0) for y in (-2.0, 0.0, 2.0)]
    far = APPoint(-3.0, 1.0)
    foot = projection(far, l)
end
(; l, q, hp, pts, far, foot) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
inside = [p for p in pts if p in hp]
outside = [p for p in pts if !(p in hp)]
sethue(julia_blue)
path(l, action=:stroke)
gsave()
setline(1); setdash("dash")
sethue(julia_green)
path(APSegment(far, foot), action=:stroke)
grestore()
sethue("gray80")
path([outside; far]); plot_point("gray80")
sethue(julia_purple)
path(inside); plot_point(julia_purple)
path([q]); plot_point(julia_blue)
sethue(julia_red)
label("q", :N, q)
end)
