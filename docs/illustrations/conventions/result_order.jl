include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=560 height=260 margin=30 begin
    c1 = APCircle2(APPoint(0.0, 0.0), 2.5)
    @unbounded l = APLine(APPoint(-4.0, -1.0), APPoint(4.0, 1.0))
    lp = intersection(l, c1)
    d1 = APCircle2(APPoint(9.0, 0.0), 2.5)
    d2 = APCircle2(APPoint(12.0, 0.0), 2.5)
    cp = intersection(d1, d2)
end
(; c1, l, lp, d1, d2, cp) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path([c1, d1, d2], action=:stroke)
path(l, action=:stroke, extend=40)
sethue(julia_purple)
path(lp); plot_point(julia_purple)
path(cp); plot_point(julia_purple)
sethue(julia_red)
for (k, p) in enumerate(lp)
    label("$k", :N, p)
end
for (k, p) in enumerate(cp)
    label("$k", :E, p)
end
end)
