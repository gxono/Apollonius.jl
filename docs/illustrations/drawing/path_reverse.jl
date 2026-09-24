include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=200 margin=50 begin
    s1 = APSegment(APPoint(0.0, 2.0), APPoint(8.0, 2.0))
    s2 = APSegment(APPoint(0.0, 0.0), APPoint(8.0, 0.0))
end
(; s1, s2) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(14)
sethue(julia_blue)
path(s1; as=:arrow, action=:stroke)
sethue(julia_purple)
path(s2; as=:arrow, reverse=true, action=:stroke)
sethue(julia_red)
label("path(s; as=:arrow)", :NE, s1.p1)
label("path(s; as=:arrow, reverse=true)", :NE, s2.p1)
end)
