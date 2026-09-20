include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=560 height=220 margin=30 begin
    eq = equilateral_triangle_on_segment(APPoint(0.0, 0.0), APPoint(4.0, 0.0))
    sq = square_on_segment(APPoint(6.0, 0.0), APPoint(10.0, 0.0))
    rc = rectangle_on_segment(APPoint(12.0, 0.0), APPoint(16.0, 0.0), 2.0)
    bases = [APSegment(APPoint(0.0, 0.0), APPoint(4.0, 0.0)), APSegment(APPoint(6.0, 0.0), APPoint(10.0, 0.0)), APSegment(APPoint(12.0, 0.0), APPoint(16.0, 0.0))]
    labs = [APPoint(2.0, -1.0), APPoint(8.0, -1.0), APPoint(14.0, -1.0)]
end
(; eq, sq, rc, bases, labs) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_purple)
path([eq, sq, rc], action=:stroke)
sethue(julia_blue)
path(bases, action=:stroke)
sethue(julia_red)
for (n, p) in zip(("equilateral triangle", "square", "rectangle"), labs)
    label(n, :S, p)
end
path(vcat([[b.p1, b.p2] for b in bases]...)); plot_point(julia_blue)
end)
