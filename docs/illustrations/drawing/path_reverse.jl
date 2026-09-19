include("../default_config.jl")
sz = @to_luxor_picture! width=500 height=200 margin=50 begin
    s1 = APSegment(APPoint(0.0, 2.0), APPoint(8.0, 2.0))
    s2 = APSegment(APPoint(0.0, 0.0), APPoint(8.0, 0.0))
    names = [APPoint(-1.0, 2.0), APPoint(-1.0, 0.0)]
end
@svg_doc(sz, @__FILE__, begin
Luxor.fontsize(14)
sethue(julia_blue); Luxor.setline(2)
path(s1; as=:arrow, action=:stroke)
sethue(julia_purple)
path(s2; as=:arrow, reverse=true, action=:stroke)
sethue("black")
label("path(s; as=:arrow)", :NE, s1.p1 + APVector(0.0, 0.0))
label("path(s; as=:arrow, reverse=true)", :NE, s2.p1 + APVector(0.0, 0.0))
end)
