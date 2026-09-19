include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=300 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    F1 = fermat_point(t)
    F2 = second_fermat_point(t)
    @unbounded fax = fermat_axis(t)
end
(; A, B, C, t, F1, F2, fax) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(t, action=:stroke)
path([A, B, C]); plot_point(julia_blue)
sethue(julia_purple)
path(fax, action=:stroke, extend=30)
path([F1, F2]); plot_point(julia_purple)
sethue(julia_red)
label("F1", :N, F1); label("F2", :S, F2)
end)
