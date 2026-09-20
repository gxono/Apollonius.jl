include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=320 margin=30 begin
    c = APCircle2(APPoint(0.0, 0.0), 1.0)
    ps = [point_on_circle(c, a) for a in (0.5, 2.5, 4.5)]
    t = circumscribed_triangle(c, ps...)
end
(; c, ps, t) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(c, action=:stroke)
sethue(julia_purple)
path(t, action=:stroke)
path(ps); plot_point(julia_blue)
end)
