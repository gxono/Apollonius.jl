include("../default_config.jl")
sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    center = APPoint(0.0, 0.0)
    c = APCircle2(APPoint(10.0, 0.0), 3.0)
    sols = tangent_circles_with_center(center, c)
end
@svg_doc(sz, @__FILE__, begin
sethue(julia_purple)
path(sols, action=:stroke)
sethue(julia_blue)
path(c, action=:stroke)
path(center)
setpoint(julia_red)
end)
