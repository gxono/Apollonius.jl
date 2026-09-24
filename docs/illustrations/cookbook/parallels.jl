include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    l = APLine(APPoint(0.0, 0.0), APPoint(4.0, 1.0))
    q = [APPoint(0.0, 0.0), APPoint(4.0, 1.0)]
    p = APPoint(0.0, 3.0)
    par = parallel_through(APLine(APPoint(0.0, 0.0), APPoint(4.0, 1.0)), p)
    off = offset_line(APLine(APPoint(0.0, 0.0), APPoint(4.0, 1.0)), 2.0)
end
(; l, q, p, par, off) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(l, action=:stroke, extend=400)
sethue(julia_purple)
path([par, off], action=:stroke, extend=400)
sethue(julia_red)
label("parallel_through", :SE, p + APVector(1.0, 0.0)); label("offset_line", :NW, off.p2)
sethue("white"); path([p; q], action=:fillpreserve); sethue(julia_blue); strokepath()
end)
