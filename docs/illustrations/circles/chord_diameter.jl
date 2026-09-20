include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=300 margin=30 begin
    c = APCircle2(APPoint(0.0, 0.0), 3.0)
    out = offset_circle(c, 1.0)
    inn = offset_circle(c, -1.0)
    ch = chord(c, 0.5, 2.4)
    di = diameter(c, 5.0)
end
(; c, out, inn, ch, di) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
gsave()
setline(1); setdash("dash")
sethue("gray80")
path([out, inn], action=:stroke)
grestore()
sethue(julia_blue)
path(c, action=:stroke)
sethue(julia_purple)
path([ch, di], action=:stroke)
sethue(julia_red)
text("chord", midpoint(ch.p1, ch.p2), direction=-direction(ch), valign=:top)
text("diameter", midpoint(di), direction=-direction(di), halign=:center)
label("offset_circle(c, 1)", :S, APPoint(-100, 120))
path([ch.p1, ch.p2, di.p1, di.p2]); plot_point(julia_purple)
end)

