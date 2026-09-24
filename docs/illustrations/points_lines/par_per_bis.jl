include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=240 margin=20 begin
    P, Q, C = APPoint(1.0, 1.0), APPoint(6.0, 3.0), APPoint(3.0, 6.0)
    s = APSegment(P, Q)
    l = APLine(s)
    M = midpoint(s)
    lpa = parallel_through(l, C)
    lpe = perpendicular_through(l, C)
    lpb = perpendicular_bisector(s)
end
(; P, Q, C, s, l, M, lpa, lpe, lpb) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
    path(l, action=:stroke)
    sethue(julia_purple)
    path([lpa, lpe, lpb], action=:stroke)
    sethue(julia_red)
    label("Q", :NW ,Q)
    label("P", :NW ,P)
    label("C", :SW ,C)
sethue("white"); path([P,Q,C], action=:fillpreserve); sethue(julia_blue); strokepath()
end)
