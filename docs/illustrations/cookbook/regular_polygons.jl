include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=300 margin=30 begin
    O = APPoint(0.0, 0.0)
    v = APPoint(3.0, 0.0)
    c = APCircle2(O, 3.0)
    hexagon = regular_polygon(O, v, 6)
    pentagon = regular_polygon(O, v, 5)
end
(; O, v, c, hexagon, pentagon) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(c, action=:stroke)
path([O, v]); plot_point(julia_blue)
sethue(julia_purple)
path([hexagon, pentagon], action=:stroke)
path([collect(vertices(hexagon)); collect(vertices(pentagon))]); plot_point(julia_purple)
end)
