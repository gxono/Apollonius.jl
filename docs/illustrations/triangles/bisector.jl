include("../default_config.jl")
sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
end
@svg_doc(sz, @__FILE__, begin
sethue(julia_purple)
path(bisector.(t, 1:3), action=:stroke)
sethue(julia_blue)
path(t, action=:stroke)
path(vertices(t))
setpoint(julia_red)
end)
