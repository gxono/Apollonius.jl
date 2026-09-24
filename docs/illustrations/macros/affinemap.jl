include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=300 margin=30 begin
    t = APTriangle(APPoint(0.0, 0.0), APPoint(5.0, 1.0), APPoint(2.0, 4.0))
    circ = APCircle2(APPoint(-2.0, -1.0), 1.5)
    @unbounded m = APAffineMap(1.3, 0.4, -0.2, 0.9, 0.0, 0.0)
    T7 = m(t)
    C7 = m(circ)
end
(; t, circ, m, T7, C7) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path([t, circ], action=:stroke)
sethue(julia_purple)
path([T7, C7], action=:stroke)
end)
