include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    origin_pt, up = APPoint(0.0, 0.0), APPoint(0.0, 4.0)
    l = APLine(origin_pt, up)
    hp1 = APHalfPlane2(l, -1)
    left_pt, right_pt = APPoint(-4.0, 0.0), APPoint(4.0, 0.0)
    l2 = APLine(left_pt, right_pt)
    hp_y0 = APHalfPlane2(l2, APPoint(0.0, 1.0))
    wedge = only(region_union(hp1, hp_y0))
end
(; hp1, hp_y0, wedge) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple); setopacity(0.25)
path(wedge; as=:region, action=:fill, bound=1000.0)
setopacity(1.0)
gsave()
setline(1); setdash("dash")
sethue("gray80")
path([hp1.boundary, hp_y0.boundary], action=:stroke, extend=1000.0)
grestore()
sethue(julia_purple)
path(wedge; as=:region, action=:stroke, bound=1000.0)
end)
