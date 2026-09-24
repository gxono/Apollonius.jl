include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=360 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    np = nine_point_circle(t)
    inc = incircle(t)
    ex = excircles(t)
    exc = [ex.A, ex.B, ex.C]
    fp = feuerbach_point(t)
    fps = collect(feuerbach_points(t))
end
(; A, B, C, t, np, inc, ex, exc, fp, fps) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue("gray80")
path([inc; exc], action=:stroke)
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_purple)
path(np, action=:stroke)
sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([fp; fps], action=:fillpreserve); sethue(julia_purple); strokepath()
end)
