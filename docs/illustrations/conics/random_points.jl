include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=260 margin=30 begin
    e = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
    pts = rand(Apollonius.Random.Xoshiro(3), e, 24)
end
(; e, pts) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(e, action=:stroke)
sethue(julia_purple)
path(pts); plot_point(julia_purple)
end)
