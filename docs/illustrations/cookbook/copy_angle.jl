include("../default_config.jl")
lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
    O, P1, P2 = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(1.0, 4.0)
    ang = APAngle2(O, P1, P2)
    O2, ray_pt = APPoint(9.0, -1.0), APPoint(13.0, -1.0)
    copied = angle_with_measure(O2, ray_pt, measure(ang))
end
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(ang, action=:stroke, as=:rays, radius=20)
sethue(julia_purple)
path(copied, action=:stroke, as=:rays, radius=20)
sethue("white"); path([O, P1, P2], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([O2, ray_pt], action=:fillpreserve); sethue(julia_purple); strokepath()
end)
