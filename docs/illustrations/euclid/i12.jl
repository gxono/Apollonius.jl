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
A, B, C, D = APPoint(-3.0, 0.0), APPoint(9.0, 0.0), APPoint(3.0, 4.0), APPoint(5.0, -2.0)
E, G = intersection(circ(C, D), APLine(A, B))
K = equilateral(E, G)
H = only(intersection(bisect(K, E, G), APSegment(E, G)))
AB = APSegment(A, B)
aids = [APSegment(E, K), APSegment(G, K)]
traces = [compass_trace(C, D; angle=pi / 3), compass_trace(C, E; angle=pi / 8), compass_trace(C, G; angle=pi / 8), compass_trace(E, K; angle=pi / 6), compass_trace(G, K; angle=pi / 6)]
ch = APSegment(C, H)
lxm, lxo = @prepare_to_picture width=500 height=320 margin=30 begin
    A
    B
    C
    D
    E
    G
    K
    H
    AB
    aids
    traces
    ch
end
(; A, B, C, D, E, G, K, H, AB, aids, traces, ch) = lxo
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
path(ch, action=:stroke)
sethue(julia_red)
label("C", :N, C); label("D", :S, D); label("E", :SW, E); label("G", :SE, G); label("H", :SE, H); label("K", :S, K)
sethue("white"); path([A, B, C, D], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([E, G, K], action=:fillpreserve); sethue(julia_green); strokepath()
sethue("white"); path([H], action=:fillpreserve); sethue(julia_purple); strokepath()
end)
