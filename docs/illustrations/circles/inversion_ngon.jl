include("../default_config.jl")
sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    o = APPoint(0.0, 0.0)
    circ = APCircle2(o, 1)
    pol = APStraightNgon([polar_point_deg(0.6, a, APPoint(0,0)) for a in 0:60:330]) |> translate(APVector(1.25,0))
    cp = invert(pol, o)
end
@svg_doc(sz, @__FILE__, begin
sethue("gray80")
setdash(:dash)
path(circ, action=:stroke)
setdash(:solid)
sethue(julia_blue)
path(pol, action=:stroke)
sethue(julia_purple)
path(cp, action=:stroke)
path(circ.center)
plot_point(julia_blue)
end)
