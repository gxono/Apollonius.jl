include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    c1 = APCircle2(APPoint(0.0, 0.0), 3.0)
    c2 = APCircle2(APPoint(4.0, 0.0), 3.0)
    lens = only(intersection(c1, c2; mode=:region))
end
(; c1, c2, lens) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple); setopacity(0.25)
path(lens; action=:fill)
setopacity(1.0)
sethue(julia_blue)
path([c1, c2], action=:stroke)
sethue(julia_purple)
path(lens; action=:stroke)
end)
