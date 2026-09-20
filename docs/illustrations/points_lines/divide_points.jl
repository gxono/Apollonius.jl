include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=560 height=200 margin=30 begin
    A, B = APPoint(0.0, 0.0), APPoint(8.0, 0.0)
    s = APSegment(A, B)
    quarters = divide_segment(s, 4)
    third = divide_segment(s, 1, 2)
    away = point_at_distance(s, 6.5)
    ext = divide_segment(s, 3, -1)
end
(; A, B, s, quarters, third, away, ext) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(14)
sethue(julia_blue)
path(s, action=:stroke)
sethue(julia_purple)
sethue(julia_red)
label("n = 4", :N, quarters[1]); label("1 : 2", :S, third); label("d = 6.5", :S, away); label("3 : -1", :N, ext)
path([A, B]); plot_point(julia_blue)
path(quarters); plot_point(julia_purple)
path([third, away, ext]); plot_point(julia_purple)
end)
