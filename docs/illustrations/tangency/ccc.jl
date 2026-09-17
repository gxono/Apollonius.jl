include("../default_config.jl")


sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    R = 3.0
    centers = [APPoint(R * cos(pi / 2 + 2pi * k / 3), R * sin(pi / 2 + 2pi * k / 3)) for k in 0:2]
    given = [APCircle2(centers[k+1], 1.0) for k in 0:2]

    sols3 = tangent_circles(given[1], given[2], given[3])
end



@svg_doc(sz, @__FILE__, begin

sethue(julia_purple)
path(sols3, action=:stroke)

sethue(julia_blue)
path(given, action=:stroke)

end)
