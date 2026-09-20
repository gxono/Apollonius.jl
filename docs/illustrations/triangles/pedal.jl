include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=300 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    P = APPoint(4.0, 2.0)
    pt = pedal_triangle(t, P)
    pc = pedal_circle(t, P)
    feet = collect(vertices(pt))
    legs = [APSegment(P, f) for f in feet]
end
(; A, B, C, t, P, pt, pc, feet, legs) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
gsave()
setline(1); setdash("dash")
sethue(julia_green)
path(legs, action=:stroke)
grestore()
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_purple)
path([pt, pc], action=:stroke)
sethue(julia_red)
label("P", :NE, P)
path([A, B, C]); plot_point(julia_blue)
path(feet); plot_point(julia_purple)
path([P]); plot_point(julia_blue)
end)
