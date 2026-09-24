include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    e = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
    h = APHyperbola2(APPoint(0.0, 0.0), 3.0, 4.0)
    xs = intersection(e, h)
end
(; e, h, xs) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(e, action=:stroke)
path(h, action=:stroke, trange=(-1.5, 1.5))
path(h, action=:stroke, trange=(-1.5, 1.5), branch=-1)
sethue(julia_purple)
sethue("white"); path(xs, action=:fillpreserve); sethue(julia_purple); strokepath()
end)
