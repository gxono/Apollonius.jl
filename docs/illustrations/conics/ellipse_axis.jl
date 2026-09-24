include("../default_config.jl")

lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
    c = APPoint(0.0, 0.0)
    v = APPoint(5.0, 0.0)
    p = APPoint(3.0, 2.4)
    e = ellipse_with_axis(c, v, p)
    ax = APSegment(c, v)
end

@svg_doc(lxm, @__FILE__, begin
fontsize(15)
sethue(julia_blue)
path(ax, action=:stroke)
sethue(julia_purple)
path(e, action=:stroke)
sethue(julia_red)
label("center", :W, c, offset=8)
label("vertex", :E, v, offset=8)
label("p", :NE, p, offset=8)

sethue("white")
path([c, v, p], action=:fillpreserve)
sethue(julia_blue); strokepath()
end)
