include("../default_config.jl")
lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
    vertex, a, b = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 4.0)
    ang = APAngle2(vertex, a, b)
    l = APLine(APPoint(6.0, 0.0), APPoint(0.0, 6.0))
    hp = APHalfPlane2(l, vertex)
    t = only(intersection(ang, hp))
end
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(APRay(vertex, a), action=:stroke, extend=10)
path(APRay(vertex, b), action=:stroke, extend=10)
gsave()
sethue("gray80"); setdash("dash")
path(l, action=:stroke, extend=10)
grestore()
sethue(julia_purple); setline(3)
path(t, action=:stroke)
end)
