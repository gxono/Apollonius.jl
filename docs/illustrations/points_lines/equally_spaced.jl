include("../default_config.jl")

lxm = @prepare_to_picture! width=500 height=300 margin=30 begin
    seg = APSegment(APPoint(0.0, 0.0), APPoint(8.0, 0.0))
    seg_pts = equally_spaced_points(seg, 5)

    circ = APCircle2(APPoint(3.0, -5.0), 2.0)
    circ_pts = equally_spaced_points(circ, 6)
end

@svg_doc(lxm, @__FILE__, begin
fontsize(15)
sethue(julia_blue)
path([seg, circ], action=:stroke)
sethue(julia_red)
label("n = 5", :N, midpoint(seg))
label("n = 6", :S, circ_pts[1])
sethue("white"); path(seg_pts, action=:fillpreserve); sethue(julia_purple); strokepath()
sethue("white"); path(circ_pts, action=:fillpreserve); sethue(julia_purple); strokepath()
end)
