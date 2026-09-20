include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=280 margin=30 begin
    @unbounded l = APLine(APPoint(0.0, 0.0), APPoint(4.0, 1.0))
    q = [APPoint(0.0, 0.0), APPoint(4.0, 1.0)]
    p = APPoint(3.0, 4.0)
    foot = projection(p, APLine(q[1], q[2]))
    leg = APSegment(p, foot)
end
(; l, q, p, foot, leg) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(l, action=:stroke, extend=400)
path([q; p]); plot_point(julia_blue)
sethue(julia_purple)
path(leg, action=:stroke)
path([foot]); plot_point(julia_purple)
sethue(julia_red)
label("p", :NE, p); label("foot", :SE, foot)
end)
