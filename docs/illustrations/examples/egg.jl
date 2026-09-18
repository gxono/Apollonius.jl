include("../default_config.jl")

radius = 80
O = APPoint(0.0, 0.0)
A = APPoint(-radius, 0.0)
B = reflection(A, O)
c = APCircle2(O, radius)
cl = APCircle2(A, B)
pl = perpendicular_bisector(A, B)
_,C1 = intersection(pl, c)
ip2 = only(intersection(APRay(A, C1), cl))
ip1 = reflection(ip2, pl)
egg = APCurvilinearQuadrilateral2(
    APCircularArc2(C1, ip2, ip1),
    APCircularArc2(B, ip1, A),
    APCircularArc2(O, A, B),
    APCircularArc2(A, B, ip2)
)

sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    egg
end


@svg_doc(sz, @__FILE__, begin
    setline(5); setdash("solid")
    path(egg, action=:strokepreserve)
    setopacity(0.8); sethue("ivory"); fillpath()
end)
