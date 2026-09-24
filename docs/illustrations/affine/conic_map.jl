include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    c = APCircle2(APPoint(1.0, 2.0), 5.0)
    @unbounded skew = APAffineMap(2.0, 0.5, -0.3, 1.4, 3.0, -1.0)
    ell = skew(c)
end
(; c, skew, ell) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(c, action=:stroke)
sethue(julia_purple)
path(ell, action=:stroke)
end)
