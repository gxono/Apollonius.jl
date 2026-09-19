include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=280 margin=30 begin
    pg = APStraightNgon([APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(6.0, 1.0), APPoint(1.0, 1.0), APPoint(1.0, 4.0), APPoint(0.0, 4.0)])
    vs = collect(vertices(pg))
    avg = APPoint(sum(p[1] for p in vs) / length(vs), sum(p[2] for p in vs) / length(vs))
    cen = centroid(pg)
end
(; pg, vs, avg, cen) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(pg, action=:stroke)
sethue("gray80")
path([avg]); plot_point("gray80")
sethue(julia_purple)
path([cen]); plot_point(julia_purple)
sethue(julia_red)
label("centroid", :NE, cen); label("vertex average", :E, avg)
end)
