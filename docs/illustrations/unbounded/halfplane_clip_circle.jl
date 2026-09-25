include("../default_config.jl")
lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
    l = APLine(APPoint(0.0, -5.0), APPoint(0.0, 5.0))
    hp = APHalfPlane2(l, APPoint(1.0, 0.0))
    c = APCircle2(APPoint(0.0, 0.0), 3.0)
    clipped = intersection(hp, c)
end
@svg_doc(lxm, @__FILE__, begin
gsave()
sethue("gray80"); setdash("dash")
path(l, action=:stroke, extend=10)
grestore()
sethue(julia_blue)
path(c, action=:stroke)
sethue(julia_purple); setline(3)
path(clipped, action=:stroke)
end)
