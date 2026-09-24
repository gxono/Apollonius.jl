include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    l1 = APLine(APPoint(0.0, 0.0), APPoint(4.0, 2.0))
    l2 = APLine(APPoint(0.0, 3.0), APPoint(4.0, 1.0))
    off = offset_line(APLine(APPoint(0.0, 0.0), APPoint(4.0, 2.0)), 1.0)
    q = [APPoint(0.0, 0.0), APPoint(4.0, 2.0), APPoint(0.0, 3.0), APPoint(4.0, 1.0)]
    x = only(intersection(APLine(q[1], q[2]), APLine(q[3], q[4])))
end
(; l1, l2, off, q, x) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
gsave()
setline(1); setdash("dash")
sethue("gray80")
path(off, action=:stroke, extend=400)
grestore()
sethue(julia_blue)
path([l1, l2], action=:stroke, extend=400)
sethue(julia_purple)
sethue(julia_red)
label("[x]", :NE, x)
sethue("white"); path(q, action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([x], action=:fillpreserve); sethue(julia_purple); strokepath()
end)
