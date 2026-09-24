include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    e = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
    onp = [point_on(e, t) for t in (0.4, 2.0, 4.0)]
    inside = APPoint(1.0, 0.5)
    outside = APPoint(4.0, 3.0)
end
(; e, onp, inside, outside) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(e, action=:stroke)
sethue(julia_purple)
sethue("gray80")
sethue("white"); path(onp, action=:fillpreserve); sethue(julia_purple); strokepath()
sethue("white"); path([inside, outside], action=:fillpreserve); sethue("gray80"); strokepath()
end)
