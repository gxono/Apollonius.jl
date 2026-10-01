include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=700 height=340 margin=30 begin
    segment = APCircularSegment2(APCircle2(APPoint(0.0, 0.0), 4.0), APPoint(4.0, 0.0), APPoint(0.0, 4.0))
    c1 = APCircle2(APPoint(9.0, 0.0), 4.0)
    c2 = APCircle2(APPoint(17.0, 0.0), 4.0)
    c3 = APCircle2(APPoint(13.0, 4.0 * sqrt(3.0)), 4.0)
    interstice = interstices(c1, c2, c3)[1]
    segment_pts = [rand_inside(Apollonius.Random.Xoshiro(k), segment) for k in 1:150]
    interstice_pts = [rand_inside(Apollonius.Random.Xoshiro(k), interstice) for k in 1:70]
end
(; segment, interstice, segment_pts, interstice_pts) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path([segment, interstice], action=:stroke)
sethue(julia_purple)
sethue("white"); path(vcat(segment_pts, interstice_pts), radius=1.0, action=:fillpreserve); sethue(julia_purple); strokepath()
end)
