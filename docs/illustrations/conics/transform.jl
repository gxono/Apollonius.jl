include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=300 margin=30 begin
    e = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
    er = rotate(e, pi / 6)
    eh = homothety(e, -0.5)
end
(; e, er, eh) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(e, action=:stroke)
sethue(julia_purple)
path([er, eh], action=:stroke)
end)
