include("../default_config.jl")
lxm = @prepare_to_picture! width=500 height=260 margin=30 begin
    vertex, a, b = APPoint(0.0, 0.0), APPoint(0.0, 4.0), APPoint(4.0, 0.0)
    reflex = APAngle2(vertex, a, b)
end
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple); setopacity(0.25)
path(reflex; as=:region, action=:fill, bound=1000.0)
setopacity(1.0)
sethue(julia_blue)
path(reflex; as=:region, action=:stroke, bound=1000.0)
end)
