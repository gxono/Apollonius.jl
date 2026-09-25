include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    s1 = APSegment(APPoint(0.0, 4.0), APPoint(7.0, 4.0))
    s2 = APSegment(APPoint(0.0, 0.0), APPoint(7.0, 0.0))
    s3 = APSegment(APPoint(10.0, 0.0), APPoint(13.0, 5.0))
end
(; s1, s2, s3) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(14)
sethue(julia_blue)
path([s1, s2, s3], action=:stroke)
sethue(julia_purple)
b1 = APDecorationBrace2(s1.p1, s1.p2; height=14, side=:left)
b2 = APDecorationBrace2(s2.p1, s2.p2; height=14, side=:right)
b3 = APDecorationBrace2(s3.p1, s3.p2; height=14, side=:right)
path(b1; action=:stroke)
path(b2; action=:stroke)
path(b3; action=:stroke)
sethue(julia_red)
label("a", :N, vertices(b1)[2])
label("b", :S, vertices(b2)[2])
label("c", :S, vertices(b3)[2])
end)
