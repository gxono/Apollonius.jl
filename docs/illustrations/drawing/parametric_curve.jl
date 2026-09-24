include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=240 margin=20 begin
    curve = APParametricCurve2(t -> APPoint(t, t^2), (-2.0, 2.0))
end
(; curve) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(curve, action=:stroke)
end)
