include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=240 margin=20 begin
    u1 = APCircle2(APPoint(0.0, 0.0), 1.0)
    u2 = APCircle2(APPoint(2.0, 0.0), 1.0)
    u3 = APCircle2(APPoint(1.0, sqrt(3)), 1.0)
    gap = only(interstices(u1, u2, u3))
end
(; u1, u2, u3, gap) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_red)
path(u1, action=:stroke)
sethue(julia_purple)
path(u2, action=:stroke)
sethue(julia_green)
path(u3, action=:stroke)
sethue(julia_blue)
path(gap, action=:fill)
end)
