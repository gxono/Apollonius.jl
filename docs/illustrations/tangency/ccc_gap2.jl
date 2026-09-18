include("../default_config.jl")
sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    R = 100.0
    big = APCircle2(APPoint(0.0, 0.0), R)
    A = APCircle2(polar_point_deg(R - 25.0, 100.0, big.center), 25.0)
    B_center = intersection(APCircle2(big.center, R - 45.0), APCircle2(A.center, A.r + 45.0))[1]
    B = APCircle2(B_center, 45.0)
    gaps = interstices(big, A, B)
end
@svg_doc(sz, @__FILE__, begin
sethue(julia_green)
path(gaps[2], action=:fill)
sethue(julia_red)
path(gaps[1], action=:fill)
sethue(julia_blue)
path([big, A, B], action=:stroke)
end)
