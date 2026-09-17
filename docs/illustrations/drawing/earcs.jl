include("../default_config.jl")



sz = @to_luxor_picture! flip=false width=500 height=240 margin=20 begin
    e = APEllipse2(APPoint(0.0, 0.0), 40.0, 20.0, pi / 6)
earc = APEllipticArc2(e, point_on_ellipse(e, 0.2), point_on_ellipse(e, 2.0))

end




@svg_doc(sz, @__FILE__, begin

sethue(julia_blue)
path(e; action=:stroke)

sethue(julia_green)
path(earc; action=:stroke)

path([earc.p1, earc.p2])
setpoint(julia_green)

end)
