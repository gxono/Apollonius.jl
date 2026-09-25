include("../default_config.jl")
lxm = @prepare_to_picture! width=500 height=260 margin=30 begin
    p1, p2 = APPoint(0.0, 3.0), APPoint(1.0, 3.0)
    p3, p4 = APPoint(0.0, 0.0), APPoint(1.0, 0.0)
    ray1 = APRay(p1, p2)
    ray2 = APRay(p3, p4)
    u = APUnboundedPolygon2(ray1, APPoint{2,Float64}[], ray2)
    corner1, corner2 = APPoint(-2.0, -1.0), APPoint(8.0, 4.0)
end
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple); setopacity(0.25)
path(u; action=:fill, bound=1000.0)
setopacity(1.0)
sethue(julia_blue)
path(u; action=:stroke, extend=1000.0)
end)
