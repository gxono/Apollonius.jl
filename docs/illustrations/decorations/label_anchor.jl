include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=280 margin=40 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    sides = [APSegment(A, B), APSegment(B, C), APSegment(C, A)]
    ang = APAngle2(A, B, C)
end
(; A, B, C, t, sides, ang) = lxo
G = centroid(t)
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(t, action=:stroke)

sethue(julia_purple)
path(marks(ang; count=1, size=40); action=:stroke)

sethue(julia_red)
for (v, n) in zip(vertices(t), ("A", "B", "C"))
    label(n, label_anchor(v, G)...)
end
for (s, n) in zip(sides, ("c", "a", "b"))
    label(n, label_anchor(s; side=:right)...)
end

label("α", label_anchor(ang; dist=20)...)
end)
