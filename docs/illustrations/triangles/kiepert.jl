include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=340 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    @unbounded kh = kiepert_hyperbola(t)
    G = centroid(t)
    H = orthocenter(t)
end
(; A, B, C, t, kh, G, H) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_purple)
path(kh, action=:stroke)
sethue(julia_red)
label("G", :S, G); label("H", :E, H)
path([A, B, C]); plot_point(julia_blue)
path([G, H]); plot_point(julia_purple)
end)
