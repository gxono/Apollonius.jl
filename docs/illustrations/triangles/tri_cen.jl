begin
using EuclideanGeometry
using Luxor: @drawsvg, @svg,
    Drawing, finish, preview, origin, newsubpath,
    background, RGBA,
    sethue, setdash, setopacity,
    fillpreserve, strokepath, 
    julia_blue, julia_green, julia_red, julia_purple,
    gsave, grestore,
    label
import Luxor

setpoint(color) = begin sethue("white"); fillpreserve(); sethue(color); strokepath() end

fmt_name = replace(split(@__FILE__,"\\")[end],".jl" => ".svg")
end


sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    A, B, C = EGPoint(0.0,0), EGPoint(10,0), EGPoint(7,5)
    triangle =  EGTriangle(A, B, C)
    G = centroid(triangle)
    O = circumcenter(triangle)
    I = incenter(triangle)
    H = orthocenter(triangle)
    l = euler_line(triangle)
    l1, l2, l3 = EGLine(B, C), EGLine(C, A), EGLine(A, B)
    @unbounded cc = circumcircle(triangle)
    ic = incircle(triangle)
    i1 = projection(I, l1)
    i2 = projection(I, l2)
    i3 = projection(I, l3)
    npc = nine_point_circle(triangle)
    npc_c = nine_point_center(triangle)
    ep = euler_points(triangle) |> collect
    ips = [intersection(npc, l1)
    intersection(npc, l2)
    intersection(npc, l3)]
end



begin
Drawing(sz.width, sz.height, "docs/src/assets/img/triangles/$fmt_name")
origin()

sethue("gray80")
gsave()
setline(1)
setdash(:dash)
path([cc, ic], action=:stroke)
path(EGSegment(O, A), action=:stroke)
path(EGSegment(I, i1), action=:stroke)
grestore()

sethue(julia_purple)
path([l, npc], action=:stroke)
path([G,O,I,H])
setpoint(julia_purple)

sethue(julia_blue)
path(triangle, action=:stroke)

path([A,B,C])
setpoint(julia_red)

path([i1 i2 i3])
path(ips)
newsubpath()
path(npc_c)
setpoint("gray80")
path(ep)
setpoint(julia_purple)

finish()
preview()
end
