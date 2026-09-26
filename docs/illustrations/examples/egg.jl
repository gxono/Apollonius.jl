include("../default_config.jl")

lxm, lxo = @prepare_to_picture width=500 height=240 margin=20 begin
    radius = 80
    @unbounded O = APPoint(0.0, 0.0)
    @unbounded A = APPoint(-radius, 0.0)
    @unbounded B = reflection(A, O)
    @unbounded c = APCircle2(O, radius)
    @unbounded cl = APCircle2(A, B)
    @unbounded pl = perpendicular_bisector(A, B)
    @unbounded _, C1 = intersection(pl, c)
    @unbounded ip2 = only(intersection(APRay(A, C1), cl))
    @unbounded ip1 = reflection(ip2, pl)
    egg = APCurvilinearQuadrilateral2(
        APCircularArc2(C1, ip2, ip1),
        APCircularArc2(B, ip1, A),
        APCircularArc2(O, A, B),
        APCircularArc2(A, B, ip2)
    )
end
(; egg) = lxo


@svg_doc(lxm, @__FILE__, begin
    setline(5); setdash("solid")
    path(egg, action=:strokepreserve)
    setopacity(0.8); sethue("ivory"); fillpath()
end)
