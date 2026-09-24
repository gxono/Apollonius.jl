include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=560 height=300 margin=30 begin
    cs = [c for (i, (r1, r2, d)) in enumerate([(1.5, 1.0, 4.0), (1.5, 1.0, 2.5), (1.5, 1.0, 1.8), (1.5, 0.75, 0.75), (1.5, 0.5, 0.4), (1.5, 1.0, 0.0)]) for c in (APCircle2(APPoint(8.0 * mod(i - 1, 3), -6.0 * fld(i - 1, 3)), r1), APCircle2(APPoint(8.0 * mod(i - 1, 3) + d, -6.0 * fld(i - 1, 3)), r2))]
    labpts = [APPoint(8.0 * mod(i - 1, 3) + 1.5, -6.0 * fld(i - 1, 3) - 2.4) for i in 1:6]
end
(; cs, labpts) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(13)
sethue(julia_blue)
path(cs, action=:stroke)
sethue(julia_red)
for (n, p) in zip((":disjoint_ext", ":tangent_ext", ":secant", ":tangent_int", ":disjoint_int", ":concentric"), labpts)
    label(n, :S, p)
end
end)
