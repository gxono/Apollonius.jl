using EuclideanGeometry, Luxor
using Luxor: julia_blue, julia_green, julia_purple, julia_red

sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    P, Q = EGPoint(1.0, 1.0), EGPoint(6.0, 3.0)
    l = EGLine(P, Q)
    C = EGPoint(2.0, 6.0)
    foot = projection(C, l)
    Cref = reflection(C, foot)
end

setpoint(color) = begin sethue("white"); fillpreserve(); sethue(color); strokepath() end

@svg begin
    sethue(julia_blue)
    path(l, action=:stroke)

    gsave()
        setdash(:dash)
        sethue(julia_purple)
        path(EGSegment(C,Cref),action=:stroke)
    grestore()

    path([P,Q])
    setpoint(julia_red)

    path(C)
    setpoint(julia_green)

    path([foot,Cref])
    setpoint(julia_purple)
end sz.width sz.height "projection_reflection.svg"
