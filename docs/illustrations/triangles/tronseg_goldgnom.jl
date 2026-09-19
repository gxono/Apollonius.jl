include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=240 margin=20 begin
    p1, p2 = APPoint(0.0, 0.0), APPoint(6.0, 0.0)
    s = APSegment(p1, p2)
    it = golden_gnomon_on_segment(s)
end
(; p1, p2, s, it) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple)
path(it, action=:stroke)
sethue(julia_blue)
path(s, action=:stroke)
path(vertices(it))
plot_point(julia_purple)
end)
