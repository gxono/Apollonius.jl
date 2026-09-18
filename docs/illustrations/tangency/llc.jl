include("../default_config.jl")
sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    l1 = APLine(APPoint(0.0, 0.0), APPoint(0.0, 1.0))
    l2 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
    c_cll = APCircle2(APPoint(6.0, 6.0), 2.0)
    sols_cll = tangent_circles(l1, l2, c_cll)
end
@svg_doc(sz, @__FILE__, begin
sethue(julia_purple)
path(sols_cll, action=:stroke)
sethue(julia_blue)
path([l1, l2, c_cll], action=:stroke)
end)
