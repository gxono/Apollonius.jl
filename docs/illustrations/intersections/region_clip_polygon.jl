include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    tclip = APTriangle(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(2.0, 3.0))
    cclip = APCircle2(APPoint(2.0, 1.0), 1.5)
    clipped = intersection(tclip, cclip; mode=(:boundary, :region))
end
(; tclip, cclip, clipped) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path([tclip, cclip], action=:stroke)
sethue(julia_purple); setline(3)
path(clipped, action=:stroke)
end)
