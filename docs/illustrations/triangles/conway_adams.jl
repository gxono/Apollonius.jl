include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=340 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    inc = incircle(t)
    cwc = conway_circle(t)
    cwp = collect(conway_points(t))
    adc = adams_circle(t)
    adp = collect(adams_points(t))
end
(; A, B, C, t, inc, cwc, cwp, adc, adp) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue("gray80")
path(inc, action=:stroke)
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_purple)
path([cwc, adc], action=:stroke)
sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path(cwp, action=:fillpreserve); sethue(julia_purple); strokepath()
sethue("white"); path(adp, action=:fillpreserve); sethue(julia_purple); strokepath()
end)
