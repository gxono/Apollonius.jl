include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    origin_pt, up = APPoint(0.0, 0.0), APPoint(0.0, 4.0)
    l = APLine(origin_pt, up)
    hp1 = APHalfPlane2(l, -1)
    p1, p2 = APPoint(-4.0, 0.0), APPoint(4.0, 0.0)
    p3, p4 = APPoint(-4.0, 3.0), APPoint(4.0, 3.0)
    l1, l2 = APLine(p1, p2), APLine(p3, p4)
    s = APStrip2(l1, l2)
    @unbounded pieces = region_difference(hp1, s)
end
(; hp1, s, pieces) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple); setopacity(0.25)
for piece in pieces
    path(piece; as=:region, action=:fill, bound=1000.0)
end
setopacity(1.0)
gsave()
setline(1); setdash("dash")
sethue("gray80")
path([hp1.boundary, s.line1, s.line2], action=:stroke, extend=1000.0)
grestore()
sethue(julia_purple)
for piece in pieces
    path(piece; as=:region, action=:stroke, bound=1000.0)
end
end)
