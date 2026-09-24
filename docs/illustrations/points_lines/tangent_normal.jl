include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=260 margin=30 begin
    e = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
    p = point_on(e, 1.0)
    tl = tangent_line(e, p)
    nl = normal_line(e, p)
end
(; e, p, tl, nl) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(e, action=:stroke)
sethue(julia_purple)
path(tl, action=:stroke, extend=15)
gsave()
setdash("dash")
path(nl, action=:stroke, extend=15)
grestore()
sethue(julia_red)
text("tangent", p, halign=:left, valign=:bottom, direction=tl)
text("normal", p, halign=:left, valign=:top, direction=nl)
sethue("white"); path([p], action=:fillpreserve); sethue(julia_blue); strokepath()
end)
