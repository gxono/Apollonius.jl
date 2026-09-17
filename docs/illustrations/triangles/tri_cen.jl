begin
using Apollonius
using Luxor: @drawsvg, @svg,
    Drawing, finish, preview, origin, newsubpath,
    background, RGBA,
    sethue, setdash, setopacity, setline,
    fillpreserve, strokepath, 
    julia_blue, julia_green, julia_red, julia_purple,
    gsave, grestore,
    label
import Luxor

setpoint(color) = begin sethue("white"); fillpreserve(); sethue(color); strokepath() end

fmt_name = replace(split(@__FILE__,"\\")[end],".jl" => ".svg")
end


sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    A, B, C = APPoint(0.0,0), APPoint(10,0), APPoint(7,5)
    triangle =  APTriangle(A, B, C)
    G = centroid(triangle)
    O = circumcenter(triangle)
    I = incenter(triangle)
    H = orthocenter(triangle)
    l = euler_line(triangle)
    lados = APLine.(sides(triangle))
    @unbounded cc = circumcircle(triangle)
    ic = incircle(triangle)
    iv = projection.(I, lados)
    npc = nine_point_circle(triangle)
    npc_c = nine_point_center(triangle)
    ep = collect(euler_points(triangle))
    ips = reduce(vcat, intersection.(npc, lados))
end



begin
Drawing(sz.width, sz.height, "docs/src/assets/img/triangles/$fmt_name")
origin()

sethue("gray80")
gsave()
setline(1)
setdash(:dash)
path([cc, ic], action=:stroke)
path(APSegment(O, A), action=:stroke)
path(APSegment(I, iv[2]), action=:stroke)
grestore()

sethue(julia_purple)
path([l, npc], action=:stroke)
path([G,O,I,H])
setpoint(julia_purple)

sethue(julia_blue)
path(triangle, action=:stroke)

path([A,B,C])
setpoint(julia_red)

path(iv)
path(ips)
newsubpath()
path(npc_c)
setpoint("gray80")
path(ep)
setpoint(julia_purple)

finish()
preview()
end
