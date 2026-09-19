include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=240 margin=20 begin
    c1_ccl = APCircle2(APPoint(0.0, 0.0), 2.0)
    c2_ccl = APCircle2(APPoint(6.0, 0.0), 2.0)
    l_ccl = APLine(APPoint(0.0, -3.0), APPoint(1.0, -3.0))
    sols_ccl = tangent_circles(c1_ccl, c2_ccl, l_ccl)
end
(; c1_ccl, c2_ccl, l_ccl, sols_ccl) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple)
path(sols_ccl, action=:stroke)
sethue(julia_blue)
path([c1_ccl, c2_ccl, l_ccl], action=:stroke)
end)
