include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=240 margin=20 begin
    s = APSegment(APPoint(-80.0, 0.0), APPoint(80.0, 0.0))
    l = APLine(APPoint(0.0, -60.0), APPoint(0.0, 60.0))
end
(; s, l) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(s, as=:arrow)
path(l, extend=0.0, as=:arrow, arrowheadlength=15)
end)
