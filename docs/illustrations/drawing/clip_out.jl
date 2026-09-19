include("../default_config.jl")
sz = @to_luxor_picture! width=500 height=260 margin=30 begin
    shapes = [APCircle2(APPoint(0.0, 0.0), 2.0), APCircle2(APPoint(4.0, 0.0), 2.0), APTriangle(APPoint(1.0, 3.0), APPoint(3.0, 3.0), APPoint(2.0, -3.0))]
end
@svg_doc(sz, @__FILE__, begin
gsave()
clip_out(shapes)
sethue(julia_purple); setopacity(0.25)
Luxor.paint()
grestore()
sethue(julia_blue); Luxor.setline(1.8)
path(shapes, action=:stroke)
end)
