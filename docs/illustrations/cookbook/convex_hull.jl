include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=300 margin=30 begin
    pts = [rand_inside(Apollonius.Random.Xoshiro(k), APBoundingBox(APPoint(0.0, 0.0), APPoint(10.0, 6.0))) for k in 1:30]
    hull = convex_hull(pts)
end
(; pts, hull) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue("gray80")
sethue(julia_purple)
path(hull, action=:stroke)
sethue("white"); path(pts, action=:fillpreserve); sethue("gray80"); strokepath()
sethue("white"); path(collect(vertices(hull)), action=:fillpreserve); sethue(julia_purple); strokepath()
end)
