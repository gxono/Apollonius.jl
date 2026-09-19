include("../default_config.jl")
sz = @to_luxor_picture! width=500 height=280 margin=40 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    sides = [APSegment(A, B), APSegment(B, C), APSegment(C, A)]
    ang = APAngle2(A, B, C)
end
G = centroid(t)
@svg_doc(sz, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue); Luxor.setline(1.5)
path(t, action=:stroke)
sethue(julia_purple)
path(marks(ang; count=1, size=24); action=:stroke)
sethue(julia_red)
for (v, n) in zip(vertices(t), ("A", "B", "C"))
    label(n, label_anchor(v, G)...)
end
for (s, n) in zip(sides, ("c", "a", "b"))
    label(n, label_anchor(s; side=:right)...)
end
label("α", label_anchor(ang; dist=48)...)
end)
