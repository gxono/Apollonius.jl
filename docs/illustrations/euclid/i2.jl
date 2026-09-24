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
A, B, C = APPoint(1.0, 4.0), APPoint(6.0, 1.0), APPoint(9.0, 3.0)
D = equilateral(A, B)
G = far(intersection(APRay(D, B), circ(B, C)), D)
L = only(intersection(APRay(D, A), circ(D, G)))
BC = APSegment(B, C); AL = APSegment(A, L)
aids = [APSegment(D, G), APSegment(D, L), APSegment(A, D), APSegment(D, B), APSegment(A, B)]
traces = [compass_trace(B, G; angle=pi / 5), compass_trace(D, L; angle=pi / 6)]
lxm, lxo = @prepare_to_picture width=500 height=320 margin=30 begin
    A
    B
    C
    D
    G
    L
    BC
    AL
    aids
    traces
end
(; A, B, C, D, G, L, BC, AL, aids, traces) = lxo
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
path(BC, action=:stroke)
sethue(julia_green)
sethue(julia_purple)
path(AL, action=:stroke)
sethue(julia_red)
label("A", :NW, A); label("B", :S, B); label("C", :E, C); label("D", :N, D); label("G", :S, G); label("L", :W, L)
sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([D, G], action=:fillpreserve); sethue(julia_green); strokepath()
sethue("white"); path([L], action=:fillpreserve); sethue(julia_purple); strokepath()
end)
