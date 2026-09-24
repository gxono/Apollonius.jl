include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=560 height=300 margin=30 begin
    e = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
    f1, f2 = foci(e)
    major = APSegment(e.center, point_on(e, 0.0))
    minor = APSegment(e.center, point_on(e, pi / 2))
    lin = APSegment(e.center, f2)
end
(; e, f1, f2, major, minor, lin) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(e, action=:stroke)
sethue(julia_purple)
path([major, minor], action=:stroke)
sethue(julia_green)
path(lin, action=:stroke)
sethue(julia_blue)
sethue(julia_red)
label("semi_major", :N, midpoint(major.p1, major.p2)); label("semi_minor", :E, midpoint(minor.p1, minor.p2))
label("linear_eccentricity", :S, midpoint(lin.p1, lin.p2))
sethue("white"); path([f1, f2], action=:fillpreserve); sethue(julia_green); strokepath()
sethue("white"); path([e.center], action=:fillpreserve); sethue(julia_blue); strokepath()
end)
