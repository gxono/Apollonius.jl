include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=300 margin=30 begin
    c = APCircle2(APPoint(0.0, 0.0), 3.0)
    l = APSegment(APPoint(-6.0, 1.0), APPoint(6.0, 1.0))
    r = APRay(APPoint(0.0, -1.0), APPoint(1.0, -1.0))
    s = APSegment(APPoint(-6.0, -2.0), APPoint(0.0, -2.0))
    @unbounded rl = APLine(APPoint(0.0, -1.0), APPoint(1.0, -1.0))
    @unbounded sl = APLine(APPoint(-6.0, -2.0), APPoint(0.0, -2.0))
    kept = [intersection(l, c); intersection(r, c); intersection(s, c)]
    dropped = [intersection(rl, c)[1]; intersection(sl, c)[2]]
end
(; c, l, r, s, rl, sl, kept, dropped) = lxo
@svg_doc(lxm, @__FILE__, begin
gsave()
setline(1); setdash("dash")
sethue("gray80")
path([rl, sl], action=:stroke, extend=200)
grestore()
sethue(julia_blue)
path([c, l, s], action=:stroke)
path(r, action=:stroke, extend=200)
sethue(julia_purple)
path(kept); plot_point(julia_purple)
sethue("gray80")
path(dropped); plot_point("gray80")
end)
