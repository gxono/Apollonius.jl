include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=300 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 4.0)
    t = APCurvilinearTriangle2(APSegment(A, B), APCircularArc2(APCircle2(APPoint(4.0, 2.0), 2.0), B, C), APSegment(C, A))
end
(; A, B, C, t) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_red)
label("45°", :NE, A; offset=16); label("180°", :NW, B; offset=16); label("135°", :SW, C; offset=16)
sethue(julia_blue)
sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
end)
