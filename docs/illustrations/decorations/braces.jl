include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=280 margin=30 begin
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
path(brace(s1.p1, s1.p2; height=14, side=:left); action=:stroke)
path(brace(s2.p1, s2.p2; height=14, side=:right); action=:stroke)
path(brace(s3.p1, s3.p2; height=14, side=:right); action=:stroke)
sethue(julia_red)
label("a", brace_anchor(s1.p1, s1.p2; height=14, side=:left)...)
label("b", brace_anchor(s2.p1, s2.p2; height=14, side=:right)...)
label("c", brace_anchor(s3.p1, s3.p2; height=14, side=:right)...)
end)
