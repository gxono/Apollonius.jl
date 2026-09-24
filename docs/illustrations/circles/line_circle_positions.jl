include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=560 height=200 margin=30 begin
    cs = [APCircle2(APPoint(8.0 * (i - 1), 0.0), 1.5) for i in 1:3]
    ls = [APSegment(APPoint(8.0 * (i - 1) - 3.0, y), APPoint(8.0 * (i - 1) + 3.0, y)) for (i, y) in zip(1:3, (2.5, 1.5, 0.5))]
    labpts = [APPoint(8.0 * (i - 1), -1.6) for i in 1:3]
end
(; cs, ls, labpts) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(13)
sethue(julia_blue)
path([cs; ls], action=:stroke)
sethue(julia_red)
for (n, p) in zip((":disjoint", ":tangent", ":secant"), labpts)
    label(n, :S, p)
end
end)
