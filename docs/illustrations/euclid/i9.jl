include("../default_config.jl")
circ(center, through) = APCircle2(center, distance(center, through))
far(points, from) = argmax(p -> distance(p, from), points)
equilateral(A, B; left=true) = (pts = intersection(circ(A, B), circ(B, A)); left ? first(pts) : last(pts))
function bisect(V, P, Q)
    r = min(distance(V, P), distance(V, Q)) / 2
    D = only(intersection(APCircle2(V, r), APSegment(V, P)))
    E = only(intersection(APCircle2(V, r), APSegment(V, Q)))
    F = far(intersection(circ(D, E), circ(E, D)), V)
    return APLine(V, F)
end
lxm, lxo = @prepare_to_picture width=500 height=320 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(7.0, 1.0), APPoint(2.0, 6.0)
    r = min(distance(A, B), distance(A, C)) / 2
    D = only(intersection(APCircle2(A, r), APSegment(A, B)))
    E = only(intersection(APCircle2(A, r), APSegment(A, C)))
    F = far(intersection(circ(D, E), circ(E, D)), A)
    rays = [APSegment(A, B), APSegment(A, C)]
    bis = APSegment(A, F)
    aids = [APSegment(D, E), APSegment(D, F), APSegment(E, F)]
    traces = [APCircularArc2(circ(A, D), D, E), compass_trace(D, F; angle=pi / 6), compass_trace(E, F; angle=pi / 6)]
end
(; A, B, C, D, E, F, rays, bis, aids, traces) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
gsave()
setline(1); setdash("dash")
sethue(julia_green)
path(aids, action=:stroke)
setdash("solid")
path(traces, action=:stroke)
grestore()
sethue(julia_blue)
path(rays, action=:stroke)
sethue(julia_green)
sethue(julia_purple)
path(bis, action=:stroke)
sethue(julia_red)
label("A", :SW, A); label("B", :E, B); label("C", :N, C); label("D", :S, D); label("E", :W, E); label("F", :N, F)
sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([D, E, F], action=:fillpreserve); sethue(julia_green); strokepath()
end)
