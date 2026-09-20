include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=300 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    P = APPoint(4.0, 2.0)
    Q = isotomic_conjugate(t, P)
    toP = [APSegment(v, P) for v in (A, B, C)]
    toQ = [APSegment(v, Q) for v in (A, B, C)]
end
(; A, B, C, t, P, Q, toP, toQ) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
gsave()
setline(1)
sethue("gray80")
path(toP, action=:stroke)
sethue(julia_purple)
path(toQ, action=:stroke)
grestore()
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_red)
label("P", :NE, P); label("P'", :N, Q)
path([A, B, C]); plot_point(julia_blue)
path([P]); plot_point("gray80")
path([Q]); plot_point(julia_purple)
end)
