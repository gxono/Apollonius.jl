include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=340 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    apo = collect(three_apollonius_circles(t))
    iso1, iso2 = isodynamic_points(t)
end
(; A, B, C, t, apo, iso1, iso2) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_purple)
path(apo, action=:stroke)
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_red)
label("1", :N, iso1); label("2", :N, iso2)
path([A, B, C]); plot_point(julia_blue)
path([iso1, iso2]); plot_point(julia_purple)
end)
