include("../default_config.jl")

lxm = @to_luxor_picture! width=500 height=240 margin=20 begin
    e = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
    c = e.center
    f1, f2 = foci(e)
    v1, v2 = vertices(e)
    p = point_on_ellipse(e, 1.0)
    od = orthoptic(e)
end


@svg_doc(lxm, @__FILE__, begin
fontsize(15)

@layer begin
    setline(1); setdash(:dash)
    sethue("gray80")
    path(od, action=:stroke)
    sethue(julia_green)
    path([APSegment(p, f1), APSegment(p, f2)], action=:stroke)
end

sethue(julia_blue)
path(e, action=:stroke)
sethue(julia_purple)
sethue(julia_red)
label("F1", :SW, f1, offset=8)
label("F2", :SE, f2, offset=8)
label("P", :N, p, offset=8)

sethue("white")
path(c, action=:fillpreserve)
sethue(julia_blue); strokepath()
sethue("white")
path([f1, f2, v1, v2, p], action=:fillpreserve)
sethue(julia_purple); strokepath()
end)
