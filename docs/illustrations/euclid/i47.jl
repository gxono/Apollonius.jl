include("../default_config.jl")
A, B, C = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 3.0)
t = APTriangle(A, B, C)
sqs = [square_on_segment(A, B; ccw=false), square_on_segment(B, C; ccw=false), square_on_segment(C, A; ccw=false)]
labs = [centroid(s) for s in sqs]
lxm, lxo = @prepare_to_picture width=520 height=360 margin=30 begin
    t
    sqs
    labs
end
(; t, sqs, labs) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_purple)
path(sqs, action=:stroke)
sethue(julia_red)
for (n, p) in zip(("16", "25", "9"), labs)
    Luxor.text(n, Luxor.Point(p[1], p[2]); halign=:center, valign=:middle)
end
end)
