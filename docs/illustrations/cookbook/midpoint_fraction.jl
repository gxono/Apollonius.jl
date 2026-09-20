include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=240 margin=30 begin
    A, B = APPoint(1.0, 2.0), APPoint(7.0, 5.0)
    s = APSegment(A, B)
    mid = midpoint(A, B)
    q = point_on_line(s, 0.25)
end
(; A, B, s, mid, q) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(s, action=:stroke)
sethue(julia_purple)
sethue(julia_red)
label("A", :SW, A); label("B", :NE, B); label("midpoint", :SE, mid); label("point_on_line(s, 0.25)", :NW, q)
path([A, B]); plot_point(julia_blue)
path([mid, q]); plot_point(julia_purple)
end)
