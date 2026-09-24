include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=560 height=240 margin=30 begin
    s1 = square_with_center(APPoint(0.0, 0.0), 2.0)
    s2 = square_with_center(APPoint(5.0, 0.0), 2.0)
    s3 = square_with_center(APPoint(10.0, 0.0), 2.0)
    @unbounded m1 = similarity_map(1.4, 0.4, APPoint(0.0, 0.0))
    @unbounded m2 = scaling_map(1.8, 0.6, APPoint(5.0, 0.0))
    @unbounded m3 = shear_map(0.6, 0.0, APPoint(10.0, 0.0))
    i1, i2, i3 = m1(s1), m2(s2), m3(s3)
    labs = [APPoint(0.0, -3.2), APPoint(5.0, -3.2), APPoint(10.0, -3.2)]
end
(; s1, s2, s3, m1, m2, m3, i1, i2, i3, labs) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(14)
sethue(julia_blue)
path([s1, s2, s3], action=:stroke)
sethue(julia_purple)
path([i1, i2, i3], action=:stroke)
sethue(julia_red)
for (n, p) in zip(("similarity_map", "scaling_map", "shear_map"), labs)
    label(n, :S, p)
end
end)
