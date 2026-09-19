include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=260 margin=30 begin
    q = APQuadrilateral(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(5.0, 3.0), APPoint(1.0, 3.0))
    diags = collect(diagonals(q))
    cross_pt = diagonal_intersection(q)
end
(; q, diags, cross_pt) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(q, action=:stroke)
path(collect(vertices(q))); plot_point(julia_blue)
sethue(julia_purple)
path(diags, action=:stroke)
path([cross_pt]); plot_point(julia_purple)
sethue(julia_red)
for (n, v) in zip(("a", "b", "c", "d"), vertices(q))
    label(n, label_anchor(v, centroid(q))...)
end
end)
