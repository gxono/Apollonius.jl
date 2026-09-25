include("../default_config.jl")

lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
    p = APPoint(-1.0, -1.0)
    v = APVector(2.0, 1.0)
    vec = APEquipollentVector(v, p)
    l = APLine(p, v)

    q = APPoint(5.0, -1.0)
    seg = APSegment(q, 3.0, 2pi / 3)
    ang_seg = APAngle2(q, q + APVector(1.0, 0), seg.p2)

    r0 = APPoint(-3.0, 3.0)
    ray = APRay(r0, -pi / 4)
    ang_ray = reverse(APAngle2(r0, r0 + APVector(1.0, 0), ray.through))
end

@svg_doc(lxm, @__FILE__, begin
fontsize(15)

arc_seg = only(marks(ang_seg; size=50))
arc_ray = only(marks(ang_ray; size=50))
@layer begin
    sethue(julia_blue); setopacity(0.25)
    path(APCircularSector2(arc_seg), action=:fill)
    path(APCircularSector2(arc_ray), action=:fill)
    setopacity(1)
    path(arc_seg, action=:stroke)
    path(arc_ray, action=:stroke)
end

sethue(julia_purple)
path(l, action=:stroke)
path(ray, action=:stroke)
path(seg, action=:stroke)

sethue(julia_blue)
path(vec; as=:arrow, action=:stroke)

sethue(julia_red)
text("line", p + APVector(-5.0, -5.0), halign=:right, direction=l, valign=:bottom)
text("segment", midpoint(seg) + APVector(3,0), direction=-direction(seg), halign=:right, valign=:bottom)
text("ray", r0 + APVector(-8.0,5.0), direction=ray, valign=:top)

sethue("white")
path([p, q, r0], action=:fillpreserve)
sethue(julia_blue); strokepath()

end)
