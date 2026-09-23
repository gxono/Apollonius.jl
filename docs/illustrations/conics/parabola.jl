include("../default_config.jl")

lxm = @to_luxor_picture! width=500 height=240 margin=20 begin
    focus = APPoint(0.0, 1.0)
    dl = APSegment(APPoint(-6.0, -1.0), APPoint(6.0, -1.0))
    @unbounded par = APParabola2(focus, APLine(dl.p1, dl.p2))
    arc = APParabolicArc2(par, point_on_parabola(par, -5.0), point_on_parabola(par, 5.0))
    p = point_on_parabola(par, 3.0)
    foot = projection(p, APLine(dl.p1, dl.p2))
    vtx = vertex(par)
end

@svg_doc(lxm, @__FILE__, begin
fontsize(15)
sethue(julia_blue)
path(dl, action=:stroke)

@layer begin
    setline(1); setdash("dash")
    sethue(julia_green)
    path([APSegment(p, focus), APSegment(p, foot)], action=:stroke)
end

sethue(julia_purple)
path(arc, action=:stroke)

sethue(julia_red)
label("F", :N, focus, offset=8)
label("P", :NE, p, offset=8)
text("directrix", dl.p2 + APVector(0.0,5.0), halign=:right, valign=:top)

sethue("white")
path([vtx, p, foot], action=:fillpreserve)
sethue(julia_purple); strokepath()

sethue("white")
path(focus, action=:fillpreserve)
sethue(julia_blue); strokepath()
end)
