include("../default_config.jl")
sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    p1, p2 = APPoint(0.0, 0.0), APPoint(6.0, 0.0)
    s = APSegment(p1, p2)
    it = isosceles_triangle_on_segment(s, 5.0)
end
@svg_doc(sz, @__FILE__, begin
sethue(julia_purple)
path(it, action=:stroke)
sethue(julia_blue)
path(s, action=:stroke)
path(vertices(it))
setpoint(julia_purple)
end)
