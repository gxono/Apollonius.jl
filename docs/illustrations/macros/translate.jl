include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    t = APTriangle(APPoint(0.0, 0.0), APPoint(5.0, 1.0), APPoint(2.0, 4.0))
    circ = APCircle2(APPoint(-2.0, -1.0), 1.5)
    s = APSegment(APPoint(0.0, 0.0), APPoint(4.0, 0.0))
    v = APVector(2.0, -1.0)
    T1 = translate(v)(t)
    S1 = translate(v)(s)
end
(; t, circ, s, v, T1, S1) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path([t, s], action=:stroke)
sethue(julia_purple)
path([T1, S1], action=:stroke)
end)
