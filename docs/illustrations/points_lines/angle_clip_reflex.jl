include("../default_config.jl")
lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
    vertex, a, b = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, -4.0)
    reflex = APAngle2(vertex, a, b)
    p1, p2 = APPoint(-6.0, -6.0), APPoint(16.0, 5.0)
    input = APLine(p1, p2)
    pieces = intersection(reflex, input)
end
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(APRay(vertex, a), action=:stroke, extend=10)
path(APRay(vertex, b), action=:stroke, extend=10)
path(input, action=:stroke, extend=10)
sethue(julia_purple); setline(3)
path(pieces, action=:stroke, extend=10)
sethue("white"); path([vertex], action=:fillpreserve); sethue(julia_blue); strokepath()
end)
