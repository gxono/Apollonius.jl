include("../default_config.jl")
lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
    l1 = APLine(APPoint(-6.0, 0.0), APPoint(6.0, 0.0))
    l2 = APLine(APPoint(-6.0, 3.0), APPoint(6.0, 3.0))
    st = APStrip2(l1, l2)
    c = APCircle2(APPoint(3.0, 1.5), 4.0)
    pieces = intersection(st, c)
end
@svg_doc(lxm, @__FILE__, begin
gsave()
sethue("gray80"); setdash("dash")
path([l1, l2], action=:stroke, extend=10)
grestore()
sethue(julia_blue)
path(c, action=:stroke)
sethue(julia_purple); setline(3)
foreach(pc -> path(pc, action=:stroke), pieces)
end)
