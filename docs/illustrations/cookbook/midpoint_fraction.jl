include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=240 margin=30 begin
    A, B = APPoint(1.0, 2.0), APPoint(7.0, 5.0)
    s = APSegment(A, B)
    mid = midpoint(A, B)
    q = point_on(s, 0.25)
end
(; A, B, s, mid, q) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(s, action=:stroke)
sethue(julia_purple)
sethue(julia_red)
label("A", :SW, A); label("B", :NE, B); label("midpoint", :SE, mid); label("point_on(s, 0.25)", :NW, q)
sethue("white"); path([A, B], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([mid, q], action=:fillpreserve); sethue(julia_purple); strokepath()
end)
