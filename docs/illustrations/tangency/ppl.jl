include("../default_config.jl")
sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    a, b = APPoint(-3.0, 0.0), APPoint(3.0, 0.0)
    l = APLine(APPoint(-5.0, -4.0), APPoint(5.0, -4.0))
    sols = tangent_circles_through_points(a, b, l)
end
@svg_doc(sz, @__FILE__, begin
sethue(julia_purple)
path(sols, action=:stroke)
sethue(julia_blue)
path(l, action=:stroke)
path([a,b])
plot_point(julia_blue)
end)
