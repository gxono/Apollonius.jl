include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=560 height=260 margin=30 begin
    p1 = [APSegment(APPoint(0.0, 0.0), APPoint(5.0, 1.0)), APSegment(APPoint(0.0, 2.0), APPoint(5.0, 3.0))]
    p2 = [APSegment(APPoint(8.0, 0.0), APPoint(13.0, 0.0)), APSegment(APPoint(10.0, -2.0), APPoint(10.0, 3.0))]
    cl = [APPoint(16.0, 0.0), APPoint(18.0, 1.0), APPoint(21.0, 2.5)]
    cn = APPoint(19.0, -1.5)
    cline = APSegment(APPoint(15.5, -0.25), APPoint(21.5, 2.75))
    lab = [APPoint(2.5, -1.0), APPoint(10.0, -3.5), APPoint(18.0, -3.5)]
end
(; p1, p2, cl, cn, cline, lab) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path([p1; p2; cline], action=:stroke)
sethue("gray80")
sethue(julia_red)
for (n, p) in zip(("is_parallel", "is_perpendicular", "is_collinear"), lab)
    label(n, :S, p)
end
sethue("white"); path(cl, action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([cn], action=:fillpreserve); sethue("gray80"); strokepath()
end)
