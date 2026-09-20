include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=200 margin=30 begin
    A = APPoint(0.0, 0.0)
    B = APPoint(8.0, 0.0)
    P = APPoint(2.0, 0.0)
    Pgold = golden_ratio_point(A, B)
    Pconj = harmonic_conjugate(A, B, P)
    line = APSegment(APPoint(-5.0, 0.0), APPoint(9.0, 0.0))
end
(; A, B, P, Pgold, Pconj, line) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(line, action=:stroke)
sethue(julia_purple)
sethue(julia_red)
label("A", :N, A); label("B", :N, B); label("P", :N, P)
label("golden", :S, Pgold); label("P'", :N, Pconj)
path([A, B, P]); plot_point(julia_blue)
path([Pgold, Pconj]); plot_point(julia_purple)
end)
