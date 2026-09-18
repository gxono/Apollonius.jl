include("../default_config.jl")
sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    p1, p2 = APPoint(0.0, 0.0), APPoint(6.0, 0.0)
    s = APSegment(p1, p2)
    et = equilateral_triangle_on_segment(s)
end
@svg_doc(sz, @__FILE__, begin
sethue(julia_purple)
path(et, action=:stroke)
sethue(julia_blue)
path(s, action=:stroke)
path(vertices(et))
setpoint(julia_purple)
end)
