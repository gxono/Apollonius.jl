include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=560 height=220 margin=30 begin
    pent = regular_polygon_on_segment(APPoint(0.0, 0.0), APPoint(3.0, 0.0), 5)
    hexa = regular_polygon_on_segment(APPoint(7.0, 0.0), APPoint(10.0, 0.0), 6)
    tri = regular_polygon_on_segment(APPoint(13.0, 0.0), APPoint(16.0, 0.0), 3; ccw=false)
    star = star_polygon(APPoint(20.0, 2.0), APPoint(20.0, 4.0), 5, 2)
    bases = [APSegment(APPoint(0.0, 0.0), APPoint(3.0, 0.0)), APSegment(APPoint(7.0, 0.0), APPoint(10.0, 0.0)), APSegment(APPoint(13.0, 0.0), APPoint(16.0, 0.0))]
end
(; pent, hexa, tri, star, bases) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(bases, action=:stroke)
sethue(julia_purple)
path([pent, hexa, tri, star], action=:stroke)
end)
