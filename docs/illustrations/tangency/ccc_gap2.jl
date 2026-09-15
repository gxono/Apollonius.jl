begin
using EuclideanGeometry
using Luxor: Drawing, finish, preview, origin,
    sethue, setdash, setopacity, setline,
    fillpreserve, strokepath, 
    julia_blue, julia_green, julia_red, julia_purple,
    gsave, grestore,
    label
import Luxor

setpoint(color) = begin 
    sethue("white"); fillpreserve()
    sethue(color); strokepath() 
end

fmt_name = replace(split(@__FILE__,"\\")[end],".jl" => ".svg")
end

sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    R = 100.0
    big = EGCircle2(EGPoint(0.0, 0.0), R)
    A = EGCircle2(polar_point_deg(R - 25.0, 100.0, big.center), 25.0)
    B_center = intersection(EGCircle2(big.center, R - 45.0), EGCircle2(A.center, A.r + 45.0))[1]
    B = EGCircle2(B_center, 45.0)
    gaps = interstices(big, A, B)
end


begin
Drawing(w, h, "docs/src/assets/img/tangency/$fmt_name")
origin()

sethue(julia_green)
path(gaps[2], action=:fill)

sethue(julia_red)
path(gaps[1], action=:fill)


sethue(julia_blue)
path([big, A, B], action=:stroke)

finish()
preview()
end