include("../default_config.jl")

lxm = @to_luxor_picture! width=500 height=240 margin=20 begin
    c = APPoint(0.0, 0.0)
    @unbounded h = APHyperbola2(c, 3.0, 4.0)
    arc1 = APHyperbolicArc2(h, point_on_hyperbola(h, -1.2), point_on_hyperbola(h, 1.2))
    arc2 = reflection(arc1, APLine(c, APPoint(0.0,1.0)))
    asy1, asy2 = asymptotes(h)
    f1, f2 = foci(h)
    v1, v2 = vertices(h)
end


lp(p::APPoint) = Point(p[1],p[2])



@svg_doc(lxm, @__FILE__, begin
fontsize(15)

@layer begin
    setline(1); setdash(:dash)
    sethue(julia_green)
    path([asy1, asy2], action=:stroke)
end

@layer begin
    sethue(julia_blue)
    path([arc1, arc2], action=:stroke)
    setline(1); setdash(:dash)
    rect(lp(c), h.a, -h.b, action=:stroke)
end

sethue(julia_red)
label("F1", :E, f1, offset=8)
label("F2", :W, f2, offset=8)

sethue("white")
path(c, action=:fillpreserve)
sethue(julia_blue); strokepath()

sethue("white")
path([f1, f2, v1, v2], action=:fillpreserve) 
sethue(julia_purple); strokepath()
end)
