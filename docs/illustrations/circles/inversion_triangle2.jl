include("../default_config.jl")







sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    o = APPoint(0.0, 0.0)
    circ = APCircle2(o, 1)
    trian = APTriangle(APPoint(0.5, 1.5), APPoint(0.5, -0.5), APPoint(2.0, 0.0))
    cp = invert(trian, o)
end





@svg_doc(sz, @__FILE__, begin

sethue("gray80")
setdash(:dash)
path(circ, action=:stroke)
setdash(:solid)

sethue(julia_blue)
path(trian, action=:stroke)

sethue(julia_purple)
path(cp, action=:stroke)

path(collect(vertices(trian)))
setpoint(julia_red)

path(circ.center)
setpoint(julia_red)

end)
