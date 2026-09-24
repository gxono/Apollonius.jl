include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    sine = APParametricCurve2(x -> APPoint(x, sin(x)), (0.0, 2pi))
    shifted = translate(sine, APVector(0.0, 2.0))
end
(; sine, shifted) = lxo
@svg_doc(lxm, @__FILE__, begin
box = APBoundingBox(sine)
gsave()
setline(1); setdash("dash")
sethue("gray80")
path(box, action=:stroke)
grestore()
sethue(julia_blue)
path(sine, action=:stroke)
sethue(julia_purple)
path(shifted, action=:stroke)
end)
