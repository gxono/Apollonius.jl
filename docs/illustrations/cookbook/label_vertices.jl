include("../default_config.jl")
lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
    pg = APStraightNgon([APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(9.0, 5.0), APPoint(4.0, 7.0), APPoint(-1.0, 4.0)])
    G = centroid(pg)
end
names = string.(collect('A':'E'))
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(pg, action=:stroke)
sethue(julia_red)
for (v, name) in zip(vertices(pg), names)
    label(name, label_anchor(v, G)...)
end
sethue("white"); path(collect(vertices(pg)), action=:fillpreserve); sethue(julia_blue); strokepath()
end)
