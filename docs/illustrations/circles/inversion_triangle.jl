include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=240 margin=20 begin
    o = APPoint(0.0, 0.0)
    circ = APCircle2(o, 1)
    trian = APTriangle(APPoint(1.5, 1.5), APPoint(3.0, 0.5), APPoint(1.0, -1.0))
    cp = invert(trian, o)
end
(; o, circ, trian, cp) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue("gray80")
setdash(:dash)
path(circ, action=:stroke)
setdash(:solid)
sethue(julia_blue)
path(trian, action=:stroke)
sethue(julia_purple)
path(cp, action=:stroke)
path(collect(vertices(trian))); plot_point(julia_blue)
path(circ.center); plot_point(julia_blue)
end)
