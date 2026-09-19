include("../default_config.jl")
sz = @to_luxor_picture! width=500 height=240 margin=30 begin
    l = APLine(APPoint(0.0, 0.0), APPoint(6.0, 2.0))
    longer = extend_line(l, 0.5)
    l2 = APLine(APPoint(0.0, -3.0), APPoint(6.0, -1.0))
    shorter = extend_line(l2, 0.0, -0.3)
end
@svg_doc(sz, @__FILE__, begin
sethue(julia_red); Luxor.setline(3)
path(longer, action=:stroke)
path(shorter, action=:stroke)
sethue(julia_blue); Luxor.setline(1.5)
path(APSegment(l.p1, l.p2), action=:stroke)
path(APSegment(l2.p1, l2.p2), action=:stroke)
path([l.p1, l.p2, l2.p1, l2.p2])
setpoint(julia_blue)
end)
