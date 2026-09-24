include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=300 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    ct = contact_triangle(t)
    et = extouch_triangle(t)
    Na = nagel_point(t)
    Ge = gergonne_point(t)
    gcev = [APSegment(v, p) for (v, p) in zip((A, B, C), vertices(ct))]
    ncev = [APSegment(v, p) for (v, p) in zip((A, B, C), vertices(et))]
end
(; A, B, C, t, ct, et, Na, Ge, gcev, ncev) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
gsave()
setline(1); setdash("dash")
sethue(julia_green)
path(gcev, action=:stroke)
grestore()
gsave()
setline(1); setdash("dash")
sethue("gray80")
path(ncev, action=:stroke)
grestore()
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_purple)
sethue(julia_red)
label("Ge", :N, Ge); label("Na", :S, Na)
sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([Ge, Na], action=:fillpreserve); sethue(julia_purple); strokepath()
end)
