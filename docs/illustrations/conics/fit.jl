include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=300 margin=30 begin
    src = APEllipse2(APPoint(1.0, 2.0), 6.0, 4.0, 0.3)
    pts = [point_on(src, t) for t in (0.1, 1.0, 2.0, 3.0, 4.5)]
    fitted = conic_through_points(pts...)
end
(; src, pts, fitted) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple)
path(fitted, action=:stroke)
sethue(julia_blue)
sethue("white"); path(pts, action=:fillpreserve); sethue(julia_blue); strokepath()
end)
