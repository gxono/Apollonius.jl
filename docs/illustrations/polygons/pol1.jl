include("../default_config.jl")
sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    pg = APStraightNgon([APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 3.0), APPoint(1.0, 3.0)])
end
@svg_doc(sz, @__FILE__, begin
sethue(julia_blue)
path(pg, action=:stroke)
path(vertices(pg))
plot_point(julia_blue)
path(centroid(pg))
plot_point(julia_purple)
end)
