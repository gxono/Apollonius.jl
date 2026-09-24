include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=240 margin=20 begin
    p1, p2 = APPoint(0.0, 0.0), APPoint(6.0, 0.0)
    s = APSegment(p1, p2)
    it = cheops_triangle_on_segment(s)
end
(; p1, p2, s, it) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple)
path(it, action=:stroke)
sethue(julia_blue)
path(s, action=:stroke)
sethue("white"); path(vertices(it), action=:fillpreserve); sethue(julia_purple); strokepath()
end)
