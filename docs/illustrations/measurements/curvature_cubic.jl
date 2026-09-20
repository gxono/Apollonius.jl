include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=560 height=380 margin=30 begin
    cubic = APParametricCurve2(t -> APPoint(t, t^3), (-1.1, 1.1))
    tl, tr = tangent_at(cubic, -0.6), tangent_at(cubic, 0.6)
    pl, pr = tl.point, tr.point
    cl = APCircle2(pl + orthogonal(tl.vector) / signed_curvature(cubic, -0.6), 1 / curvature(cubic, -0.6))
    cr = APCircle2(pr + orthogonal(tr.vector) / signed_curvature(cubic, 0.6), 1 / curvature(cubic, 0.6))
    rl, rr = APSegment(pl, cl.center), APSegment(pr, cr.center)
end
(; cubic, tl, tr, pl, pr, cl, cr, rl, rr) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
gsave()
setline(1); setdash("dash")
sethue(julia_green)
path([rl, rr], action=:stroke)
grestore()
sethue(julia_blue)
path(cubic, action=:stroke)
sethue(julia_purple)
path([cl, cr], action=:stroke)
sethue(julia_green)
sethue(julia_red)
label("κ < 0", :S, cl.center); label("κ > 0", :N, cr.center)
path([pl, pr]); plot_point(julia_purple)
path([cl.center, cr.center]); plot_point(julia_green)
end)
