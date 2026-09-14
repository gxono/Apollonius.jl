using EuclideanGeometry, Luxor
using Luxor: julia_blue, julia_green, julia_purple, julia_red

sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    A = EGPoint(5.0, 4.0)
    O = EGPoint(0.0, 0.0)
    l = EGLine(A, O)
    d = EGEquipollentVector(direction(l))
    v = normalize(d)
end

@svg begin
    sethue(julia_blue)
    path(l, action = :stroke)

    sethue(julia_green)
    path(d, action=:stroke, as=:arrow)

    sethue(julia_purple)
    path(v, action=:stroke, as=:arrow)

    path([A,O])
    sethue("white"); fillpreserve()
    sethue(julia_red); strokepath()
end sz.width sz.height "direction_vector.svg"
