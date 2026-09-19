include("../default_config.jl")
sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    c = APCircle2(APPoint(0.0, 0.0), 5.0)
    l = APLine(APPoint(0.0, 3), APPoint(1.0, 4))
    t1, t2 = tangent_parallel(c, l)
end
@svg_doc(sz, @__FILE__, begin
sethue(julia_purple)
path([t1,t2], action=:stroke)
sethue(julia_blue)
path([c, l], action=:stroke)
path(c.center)
plot_point(julia_blue)
path([t1[1], t2[1]])
plot_point(julia_purple)
end)
