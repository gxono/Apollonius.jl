include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=240 margin=20 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 3.0)
    circ = APCircle2(A, B, C)
end
(; A, B, C, circ) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple)
path(circ, action=:stroke)
path([A,B,C])
plot_point(julia_blue)
end)
