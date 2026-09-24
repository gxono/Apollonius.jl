include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    @unbounded skew = APAffineMap(2.0, 0.5, -0.3, 1.4, 3.0, -1.0)
    tri = APTriangle(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
    circ = APCircle2(APPoint(1.0, 2.0), 5.0)
    tri_img = skew(tri)
    circ_img = skew(circ)
end
(; skew, tri, circ, tri_img, circ_img) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path([tri, circ], action=:stroke)
sethue(julia_purple)
path([tri_img, circ_img], action=:stroke)
end)
