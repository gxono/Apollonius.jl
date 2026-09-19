include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=240 margin=20 begin
    t = APTriangle(APPoint(2.0, -5.0), APPoint(9.0, 3.0), APPoint(-1.0, 6.0))
    circ = APCircle2(APPoint(4.0, 1.0), 4.0)
end
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(lxo.t; action=:stroke)
path(lxo.circ; action=:stroke)
end)
