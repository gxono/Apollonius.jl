include("../default_config.jl")



sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    C, P = APPoint(0.0, 0.0), APPoint(4.0, 2.0)
    circ = APCircle2(C, P)
end


@svg_doc(sz, @__FILE__, begin

sethue(julia_purple)
path(circ, action=:stroke)

path([C, P])
setpoint(julia_red)

end)
