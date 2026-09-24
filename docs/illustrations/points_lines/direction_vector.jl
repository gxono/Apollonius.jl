include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=240 margin=20 begin
    A = APPoint(5.0, 4.0)
    O = APPoint(0.0, 0.0)
    l = APLine(A, O)
    d = APEquipollentVector(direction(l))
    v = normalize(d)
end
(; A, O, l, d, v) = lxo
@svg_doc(lxm, @__FILE__, begin
    sethue(julia_blue)
    path(l, action = :stroke)
    sethue(julia_green)
    path(d, action=:stroke, as=:arrow)
    sethue(julia_purple)
    path(v, action=:stroke, as=:arrow)
    sethue("white"); path([A,O], action=:fillpreserve); sethue(julia_blue); strokepath()
end)
