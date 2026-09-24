include("../default_config.jl")
lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
    l = APLine(APPoint(0.0, -5.0), APPoint(0.0, 5.0))
    hp = APHalfPlane2(l, APPoint(1.0, 0.0))
    p1, p2 = APPoint(-6.0, -3.0), APPoint(6.0, 3.0)
    input = APLine(p1, p2)
    clipped = intersection(hp, input)
end
@svg_doc(lxm, @__FILE__, begin
gsave()
sethue("gray80"); setdash("dash")
path(l, action=:stroke, extend=10)
grestore()
sethue(julia_blue)
path(input, action=:stroke, extend=10)
sethue(julia_purple); setline(3)
path(clipped, action=:stroke, extend=10)
end)
