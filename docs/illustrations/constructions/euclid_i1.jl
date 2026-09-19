include("../default_config.jl")
sz = @to_luxor_picture! width=500 height=280 margin=30 begin
    A, B = APPoint(0.0, 0.0), APPoint(6.0, 0.0)
    C = argmax(p -> p[2], intersection(APCircle2(A, 6.0), APCircle2(B, 6.0)))
    cA, cB = APCircle2(A, 6.0), APCircle2(B, 6.0)
end
traces = [compass_trace(A, C; angle=pi / 4), compass_trace(B, C; angle=pi / 4)]
@svg_doc(sz, @__FILE__, begin
Luxor.fontsize(15)
sethue("gainsboro"); Luxor.setline(1)
path([cA, cB], action=:stroke)
sethue(julia_purple); Luxor.setline(2.5)
path(traces, action=:stroke)
sethue(julia_blue); Luxor.setline(1.8)
path(APTriangle(A, B, C), action=:stroke)
path([A, B, C])
setpoint(julia_red)
sethue("black")
label("A", :SW, A)
label("B", :SE, B)
label("C", :N, C)
end)
