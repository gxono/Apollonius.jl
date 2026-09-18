include("../default_config.jl")
sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    A = APPoint(5.0, 4.0)
    O = APPoint(0.0, 0.0)
    l = APLine(A, O)
    d = APEquipollentVector(direction(l))
    v = normalize(d)
end
@svg_doc(sz, @__FILE__, begin
    sethue(julia_blue)
    path(l, action = :stroke)
    sethue(julia_green)
    path(d, action=:stroke, as=:arrow)
    sethue(julia_purple)
    path(v, action=:stroke, as=:arrow)
    path([A,O])
    sethue("white"); fillpreserve()
    sethue(julia_red); strokepath()
end)
