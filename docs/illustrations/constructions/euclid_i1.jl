include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    A, B = APPoint(0.0, 0.0), APPoint(6.0, 0.0)
    C = argmax(p -> p[2], intersection(APCircle2(A, 6.0), APCircle2(B, 6.0)))
    cA, cB = APCircle2(A, 6.0), APCircle2(B, 6.0)
end
(; A, B, C, cA, cB) = lxo
traces = [compass_trace(A, C; angle=pi / 4), compass_trace(B, C; angle=pi / 4)]
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
@layer begin
setline(0.5); setdash(:dash); sethue("gray80")
path([cA, cB], action=:stroke)
end

@layer begin
setline(1); sethue(julia_green)
path(traces, action=:stroke)
end

sethue(julia_purple)
path(APTriangle(A, B, C), action=:stroke)

sethue(julia_red)
label("A", :SW, A, offset=8)
label("B", :SE, B, offset=8)
label("C", :N , C, offset=8)

sethue("white")
path([A, B], action=:fillpreserve)
sethue(julia_blue); strokepath()
sethue("white")
path([C], action=:fillpreserve)
sethue(julia_purple); strokepath()

end)
