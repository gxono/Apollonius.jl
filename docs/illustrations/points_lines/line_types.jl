include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=280 margin=50 begin
    O = APPoint(0.0, 0.0)
    A = APPoint(3.0, 4.0)
    s = APSegment(O, A)
    @unbounded l = translate(APLine(O, A), APVector(-6.0, 0.0))
    @unbounded r = translate(APRay(O, A), APVector(6.0, 0.0))
    ol, al = l.p1, l.p2
    orr, ar = r.origin, r.through
end
(; O, A, s, l, r, ol, al, orr, ar) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(s, action=:stroke)
path(l, action=:stroke, extend=60)
path(r, action=:stroke, extend=60)
path([O, A, ol, al, orr, ar]); plot_point(julia_blue)
sethue(julia_red)
label("APSegment", :S, O); label("APLine", :SE, ol); label("APRay", :S, orr)
end)
