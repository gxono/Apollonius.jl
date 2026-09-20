include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=300 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(1.5, 4.0)
    t = APTriangle(A, B, C)
    cc = circumcircle(t)
    inc = incircle(t)
    O = circumcenter(t)
end
(; A, B, C, t, cc, inc, O) = lxo
@svg_doc(lxm, @__FILE__, begin
fontsize(15)
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_purple)
path([cc, inc], action=:stroke)
sethue(julia_red)
label("A", :SW, A, offset=8) 
label("B", :SE, B, offset=8)
label("C", :N, C, offset=8)
label("O", :S, O, offset=8)
label("I", :W, inc.center, offset=8)

sethue("white")
path([A, B, C], action=:fillpreserve)
sethue(julia_blue); strokepath()
sethue("white")
path([O, inc.center], action=:fillpreserve)
sethue(julia_purple); strokepath()
end)
