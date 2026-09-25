include("../default_config.jl")
lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
    l1 = APLine(APPoint(-6.0, 0.0), APPoint(6.0, 0.0))
    l2 = APLine(APPoint(-6.0, 3.0), APPoint(6.0, 3.0))
    s = APStrip2(l1, l2)
    l3 = APLine(APPoint(0.0, -5.0), APPoint(0.0, 5.0))
    l4 = APLine(APPoint(4.0, -5.0), APPoint(4.0, 5.0))
    s2 = APStrip2(l3, l4)
    q = intersection(s, s2)
end
@svg_doc(lxm, @__FILE__, begin
gsave()
sethue("gray80"); setdash("dash")
path([l1, l2, l3, l4], action=:stroke, extend=10)
grestore()
sethue(julia_purple); setline(3)
path(q, action=:stroke)
end)
