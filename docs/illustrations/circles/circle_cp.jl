include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=240 margin=20 begin
    C, P = APPoint(0.0, 0.0), APPoint(4.0, 2.0)
    circ = APCircle2(C, P)
end
(; C, P, circ) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple)
path(circ, action=:stroke)
path([C, P])
plot_point(julia_blue)
end)
