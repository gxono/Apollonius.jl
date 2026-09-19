include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=300 margin=30 begin
    src = APEllipse2(APPoint(1.0, 2.0), 6.0, 4.0, 0.3)
    pts = [point_on_ellipse(src, t) for t in (0.1, 1.0, 2.0, 3.0, 4.5)]
    fitted = conic_through_points(pts...)
end
(; src, pts, fitted) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple)
path(fitted, action=:stroke)
sethue(julia_blue)
path(pts); plot_point(julia_blue)
end)
