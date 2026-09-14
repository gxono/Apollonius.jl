using EuclideanGeometry, Luxor
using Luxor: julia_blue, julia_green, julia_purple, julia_red

sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    c1, c2 = EGCircle2(EGPoint(0.0, 0.0), 2.0), EGCircle2(EGPoint(10.0, 0.0), 1.0)
    l1, l2 = external_tangent_lines(c1, c2)
end

@svg begin
    sethue(julia_blue)
    path([c1, c2, l1, l2], action = :stroke)

    path(collect(Iterators.flatten([l1,l2])))
    sethue("white"); fillpreserve()
    sethue(julia_red); strokepath()
end sz.width sz.height "destructuring_tangents.svg"
