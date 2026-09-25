include("../default_config.jl")
lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
    vertex, a, b = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 4.0)
    ang = APAngle2(vertex, a, b)
    c = APCircle2(vertex, 2.0)
    piece = only(intersection(ang, c))
end
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(APRay(vertex, a), action=:stroke, extend=10)
path(APRay(vertex, b), action=:stroke, extend=10)
path(c, action=:stroke)
sethue(julia_purple); setline(3)
path(piece, action=:stroke)
sethue("white"); path([vertex], action=:fillpreserve); sethue(julia_blue); strokepath()
end)
