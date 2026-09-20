include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=560 height=280 margin=30 begin
    p = APPoint(0.0, 0.0)
    v = APVector(2.0, 1.0)
    vec = APEquipollentVector(v, p)
    @unbounded l = APLine(p, v)
    lp = [p, p + v]
    q = APPoint(5.0, -1.0)
    seg = APSegment(q, 3.0, 2pi / 3)
    r0 = APPoint(-3.0, 3.0)
    @unbounded ray = APRay(r0, -pi / 4)
    rp = [r0, r0 + APVector(1.0, -1.0)]
end
(; p, v, vec, l, lp, q, seg, r0, ray, rp) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(vec; as=:arrow, action=:stroke)
path([p, q, r0]); plot_point(julia_blue)
sethue(julia_purple)
path(l, action=:stroke, extend=300)
path(ray, action=:stroke, extend=300)
path(seg, action=:stroke)
sethue(julia_red)
label("line", :SE, p + APVector(0.5, -0.4)); label("segment", :E, seg.p2); label("ray", :N, r0)
end)
