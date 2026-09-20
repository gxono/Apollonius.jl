include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=320 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(1.5, 4.0)
    t = APTriangle(A, B, C)
    inc = incircle(t)
    ct = contact_triangle(t)
end
(; A, B, C, t, inc, ct) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
tp = collect(vertices(ct))
pieces = [(A, tp[3], 1), (A, tp[2], 1), (B, tp[3], 2), (B, tp[1], 2), (C, tp[1], 3), (C, tp[2], 3)]
sethue(julia_blue)
path([t, inc], action=:stroke)
sethue(julia_purple)
for (p, q, k) in pieces
    path(marks(APSegment(p, q); count=k), action=:stroke)
end
sethue(julia_red)
for (n, v) in zip(("A", "B", "C"), (A, B, C))
    label(n, label_anchor(v, centroid(t))...)
end
path([A, B, C]); plot_point(julia_blue)
path(tp); plot_point(julia_purple)
end)
