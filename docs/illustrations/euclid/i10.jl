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
A, B = APPoint(0.0, 0.0), APPoint(6.0, 2.0)
C = equilateral(A, B)
M = only(intersection(bisect(C, A, B), APSegment(A, B)))
AB = APSegment(A, B)
aids = [APSegment(A, C), APSegment(B, C)]
traces = [compass_trace(A, C; angle=pi / 6), compass_trace(B, C; angle=pi / 6)]
cm = APSegment(C, M)
lxm, lxo = @to_luxor_picture width=500 height=300 margin=30 begin
    A
    B
    C
    M
    AB
    aids
    traces
    cm
end
(; A, B, C, M, AB, aids, traces, cm) = lxo
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
path([A, B]); plot_point(julia_blue)
sethue(julia_green)
path([C]); plot_point(julia_green)
sethue(julia_purple)
path(cm, action=:stroke)
path([M]); plot_point(julia_purple)
sethue(julia_red)
label("A", :SW, A); label("B", :SE, B); label("C", :N, C); label("M", :S, M)
end)
