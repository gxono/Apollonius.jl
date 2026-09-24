include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=520 height=300 margin=30 begin
    l = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
    r = APRay(APPoint(0.0, -3.0), APPoint(1.0, -3.0))
    s = APSegment(APPoint(0.0, -6.0), APPoint(6.0, -6.0))
    tl = [APPoint(x, y) for (x, y) in ((-2.0, 0.0), (3.0, 0.0), (8.0, 0.0), (3.0, 1.0))]
    tr = [APPoint(x, y) for (x, y) in ((-2.0, -3.0), (3.0, -3.0), (8.0, -3.0), (3.0, -2.0))]
    ts = [APPoint(x, y) for (x, y) in ((-2.0, -6.0), (3.0, -6.0), (8.0, -6.0), (3.0, -5.0))]
end
(; l, r, s, tl, tr, ts) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(l, action=:stroke, extend=500)
path(r, action=:stroke, extend=500)
path(s, action=:stroke)
sethue(julia_purple)
sethue("gray80")
sethue(julia_red)
label("is_on_line", :NW, tl[1]); label("is_on_ray", :NW, tr[1]); label("is_on_segment", :NW, ts[1])
sethue("white"); path([[p for p in tl if p in l]; [p for p in tr if p in r]; [p for p in ts if p in s]], action=:fillpreserve); sethue(julia_purple); strokepath()
sethue("white"); path([[p for p in tl if !(p in l)]; [p for p in tr if !(p in r)]; [p for p in ts if !(p in s)]], action=:fillpreserve); sethue("gray80"); strokepath()
end)
