include("../default_config.jl")

lxm = @prepare_to_picture! width=500 height=300 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    Cl = clawson_point(t)
end

@svg_doc(lxm, @__FILE__, begin
fontsize(15)
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_red)
label("Cl", :N, Cl)
sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([Cl], action=:fillpreserve); sethue(julia_purple); strokepath()
end)
