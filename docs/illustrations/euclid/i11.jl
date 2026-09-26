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
lxm, lxo = @prepare_to_picture width=500 height=300 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 0.0)
    D, E = intersection(APCircle2(C, 2.0), APLine(A, B))
    F = equilateral(D, E)
    AB = APSegment(A, B)
    aids = [APSegment(D, F), APSegment(E, F)]
    traces = [compass_trace(C, D; angle=pi / 4), compass_trace(C, E; angle=pi / 4), compass_trace(D, F; angle=pi / 6), compass_trace(E, F; angle=pi / 6)]
    cf = APSegment(C, F)
end
(; A, B, C, D, E, F, AB, aids, traces, cf) = lxo
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
path(AB, action=:stroke)
sethue(julia_green)
sethue(julia_purple)
path(cf, action=:stroke)
sethue(julia_red)
label("A", :SW, A); label("B", :SE, B); label("C", :S, C); label("D", :S, D); label("E", :S, E); label("F", :N, F)
sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([D, E, F], action=:fillpreserve); sethue(julia_green); strokepath()
end)
