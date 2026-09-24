include("../default_config.jl")

lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
    c = APCircle2(APPoint(0.0, 0.0), 5.0)
    p = APPoint(13.0, 0.0)
    pts = tangent_points(c, p)
    pl = polar_line(c, p)

    l2 = APLine(APPoint(-6.0, 6.0), APPoint(4.0, 6.0))
    q = pole(c, l2)
end

@svg_doc(lxm, @__FILE__, begin
fontsize(15)

gsave()
setline(1); setdash("dash")
sethue(julia_green)
path([APSegment(p, pts[1]), APSegment(p, pts[2])], action=:stroke)
grestore()

sethue(julia_blue)
path(c, action=:stroke)
path(l2, action=:stroke)

sethue(julia_purple)
path(pl, action=:stroke)

sethue(julia_red)
label("p", :E, p)
label("polar of p", :N, midpoint(pts...))
label("l", :N, l2.p2)
label("pole of l", :S, q)

sethue("white"); path(pts, action=:fillpreserve); sethue(julia_green); strokepath()
sethue("white"); path([p], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([q], action=:fillpreserve); sethue(julia_purple); strokepath()
end)
