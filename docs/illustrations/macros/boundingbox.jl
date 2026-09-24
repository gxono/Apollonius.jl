include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    t = APTriangle(APPoint(0.0, 0.0), APPoint(5.0, 1.0), APPoint(2.0, 4.0))
    circ = APCircle2(APPoint(-2.0, -1.0), 1.5)
end
(; t, circ) = lxo
@svg_doc(lxm, @__FILE__, begin
box = bbox_union(APBoundingBox(t), APBoundingBox(circ))
gsave()
setline(1); setdash("dash")
sethue(julia_purple)
path(box, action=:stroke)
grestore()
sethue(julia_blue)
path([t, circ], action=:stroke)
end)
