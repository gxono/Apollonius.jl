include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=380 margin=30 begin
    vs = [APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(2.0, 1.0), APPoint(1.0, 1.0), APPoint(1.0, 2.0), APPoint(0.0, 2.0)]
    pg = APStraightNgon(vs)
    angs = interior_angles(pg)
end
(; vs, pg, angs) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(pg, action=:stroke)
sethue(julia_purple)
for a in angs
    path(marks(a; size=26); action=:stroke)
end
sethue(julia_red)
for (a, d) in zip(angs, round.(Int, rad2deg.(normalized_measure.(angs))))
    label("$(d)°", label_anchor(a; dist=40)...)
end
sethue(julia_blue)
path(vs); plot_point(julia_blue)
end)
