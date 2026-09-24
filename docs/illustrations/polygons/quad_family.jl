include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=560 height=320 margin=30 begin
    rh = rhombus_on_segment(APPoint(0.0, 0.0), APPoint(3.0, 0.0), pi / 3)
    sq = square_from_diagonal(APPoint(5.0, 0.0), APPoint(8.0, 3.0))
    re = rectangle_from_diagonal(APPoint(10.0, 0.0), APPoint(15.0, 3.0), 0.5)
    it = isosceles_trapezoid_on_segment(APPoint(0.0, -5.0), APPoint(4.0, -5.0), 2.0, 2.5)
    rt = right_trapezoid_on_segment(APPoint(6.0, -5.0), APPoint(10.0, -5.0), 2.0, 2.5)
    kt = kite_on_diagonal(APPoint(13.0, -5.0), APPoint(13.0, -1.0), 0.6, 1.5)
    rc = rectangle_with_center(APPoint(16.5, -3.0), 3.0, 1.5; angle=0.6)
end
(; rh, sq, re, it, rt, kt, rc) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple)
path([rh, sq, re, it, rt, kt, rc], action=:stroke)
end)
