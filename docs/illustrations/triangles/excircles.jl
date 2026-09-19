include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=240 margin=20 begin
    A, B, C = APPoint(0.0,0), APPoint(10,0), APPoint(7,5)
    t = APTriangle(A, B, C)
    l = APLine.(sides(t))
    ex = collect(excenters(t))
    exc = collect(excircles(t))
    pp = projection.(ex, [l[2], l[3], l[1]])
    rangles = APAngle2.(pp, ex, getproperty.(l, :p2))
end
(; A, B, C, t, l, ex, exc, pp, rangles) = lxo
@svg_doc(lxm, @__FILE__, begin
gsave()
sethue("gray80")
setdash(:dash)
setline(1)
path(l, action=:stroke)
path(APTriangle(ex...), action=:stroke)
sethue(julia_green)
setdash(:solid)
path(APSegment.(ex, pp), action=:stroke)
grestore()
sethue(julia_purple)
path(exc, action=:stroke)
sethue(julia_green)
path(reverse.(rangles),
    action=:fill,
    radius=7,
    as=:rsector)
sethue(julia_blue)
path(t, action=:stroke)
path(ex)
plot_point(julia_purple)
path(vertices(t))
plot_point(julia_blue)
path(pp)
plot_point(julia_green)
end)
