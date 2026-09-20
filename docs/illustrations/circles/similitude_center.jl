include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=240 margin=20 begin
    c1 = APCircle2(APPoint(0.0, 0.0), 3.0)
    c2 = APCircle2(APPoint(8.0, 0.0), 2.0)
    ec = external_similitude_center(c1, c2)
    ic = internal_similitude_center(c1, c2)
    ext = external_tangent_lines(c1, c2)
    int = internal_tangent_lines(c1, c2)
end
(; c1, c2, ec, ic, ext, int) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple)
path([ext..., int...], action=:stroke)
sethue(julia_blue)
path([c1,c2], action=:stroke)
path([c1.center, c2.center]); plot_point(julia_blue)
path([ec, ic]); plot_point(julia_purple)
end)
