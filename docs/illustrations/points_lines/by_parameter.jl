include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=300 margin=30 begin
    p0 = APPoint(0.0, 0.0)
    p1 = APPoint(4.0, 0.0)
    l = APLine(p0, p1)
    seg = APSegment(point_on(l, -0.5), point_on(l, 1.5))
    tpts = [point_on(l, t) for t in (-0.5, 0.0, 0.5, 1.0, 1.5)]
    c = APCircle2(APPoint(2.0, -4.0), 2.0)
    apts = [point_on(c, a) for a in (0.0, pi / 4, pi / 2, pi)]
end
(; p0, p1, l, seg, tpts, c, apts) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path([seg, c], action=:stroke)
sethue(julia_purple)
sethue(julia_red)
for (t, p) in zip((-0.5, 0.0, 0.5, 1.0, 1.5), tpts)
    label("t = $t", :N, p)
end
for (a, al, p) in zip(("0", "π/4", "π/2", "π"), (:E, :NE, :N, :W), apts)
    label(a, al, p)
end
sethue("white"); path([p0, p1], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([tpts[1], tpts[3], tpts[5]], action=:fillpreserve); sethue(julia_purple); strokepath()
sethue("white"); path(apts, action=:fillpreserve); sethue(julia_purple); strokepath()
end)
