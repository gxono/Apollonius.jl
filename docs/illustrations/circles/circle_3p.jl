include("../default_config.jl")
sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 3.0)
    circ = APCircle2(A, B, C)
end
@svg_doc(sz, @__FILE__, begin
sethue(julia_purple)
path(circ, action=:stroke)
path([A,B,C])
setpoint(julia_red)
end)
