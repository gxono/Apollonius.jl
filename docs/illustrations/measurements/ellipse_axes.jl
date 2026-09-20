include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=560 height=300 margin=30 begin
    e = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
    f1, f2 = foci(e)
    major = APSegment(e.center, point_on_ellipse(e, 0.0))
    minor = APSegment(e.center, point_on_ellipse(e, pi / 2))
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
path([f1, f2]); plot_point(julia_green)
path([e.center]); plot_point(julia_blue)
end)
