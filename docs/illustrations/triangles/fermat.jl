include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=300 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    F1 = fermat_point(t)
    F2 = second_fermat_point(t)
    fax = fermat_axis(t)
end
(; A, B, C, t, F1, F2, fax) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_purple)
path(fax, action=:stroke, extend=30)
sethue(julia_red)
label("F1", :N, F1); label("F2", :S, F2)
sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([F1, F2], action=:fillpreserve); sethue(julia_purple); strokepath()
end)
