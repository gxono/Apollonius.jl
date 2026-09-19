include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=280 margin=30 begin
    t = APTriangle(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
    @unbounded tm = translation_map(APVector(3.0, -2.0))
    @unbounded rm = rotation_map(pi / 2, APPoint(1.0, 1.0))
    t_moved = tm(t)
    t_composed = (rm ∘ tm)(t)
end
(; t, tm, rm, t_moved, t_composed) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(t, action=:stroke)
gsave()
setline(1); setdash("dash")
sethue("gray80")
path(t_moved, action=:stroke)
grestore()
sethue(julia_purple)
path(t_composed, action=:stroke)
end)
