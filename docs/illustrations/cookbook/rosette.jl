include("../default_config.jl")
lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
    center = APPoint(0.0, 0.0)
    petal = APCircle2(APPoint(3.0, 0.0), 1.2)
    copies = rotate.(petal, (1:5) .* (2pi / 6), center)
end
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(petal, action=:stroke)
sethue(julia_purple)
path(copies, action=:stroke)
sethue("white"); path(center, action=:fillpreserve); sethue(julia_blue); strokepath()
end)
