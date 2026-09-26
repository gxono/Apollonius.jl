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
lxm, lxo = @prepare_to_picture width=560 height=300 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(6.0, 1.0), APPoint(2.0, 5.0)
    D, E = APPoint(10.0, 0.0), APPoint(16.0, -1.0)
    X, Y = A + 0.6 * (B - A), A + 0.6 * (C - A)
    E2 = only(intersection(APCircle2(D, distance(A, X)), APRay(D, E)))
    F = first(intersection(APCircle2(D, distance(A, Y)), APCircle2(E2, distance(X, Y))))
    given = [APSegment(A, B), APSegment(A, C), APSegment(D, E)]
    aids = [APSegment(X, Y), APSegment(E2, F)]
    traces = [compass_trace(D, E2; angle=pi / 6), compass_trace(D, F; angle=pi / 6), compass_trace(E2, F; angle=pi / 6)]
    dup = APSegment(D, F)
    angs = [APAngle2(A, B, C), APAngle2(D, E2, F)]
end
(; A, B, C, D, E, X, Y, E2, F, given, aids, traces, dup, angs) = lxo
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
path(given, action=:stroke)
sethue(julia_green)
sethue(julia_purple)
path(dup, action=:stroke)
path(marks(angs[1]; size=40); action=:stroke)
path(marks(angs[2]; size=40); action=:stroke)
sethue(julia_red)
label("A", :SW, A); label("B", :E, B); label("C", :N, C); label("D", :SW, D); label("E", :E, E); label("F", :N, F)
sethue("white"); path([A, B, C, D, E], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([X, Y, E2], action=:fillpreserve); sethue(julia_green); strokepath()
sethue("white"); path([F], action=:fillpreserve); sethue(julia_purple); strokepath()
end)
