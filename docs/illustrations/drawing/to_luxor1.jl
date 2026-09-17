include("../default_config.jl")


t = APTriangle(APPoint(2.0, -5.0), APPoint(9.0, 3.0), APPoint(-1.0, 6.0))
circ = APCircle2(APPoint(4.0, 1.0), 4.0)

sz, (t2, circ2) = @to_luxor_picture width=500 height=240 margin=20 begin
    t
    circ
end



@svg_doc(sz, @__FILE__, begin

sethue(julia_blue)
path(t2; action=:stroke)
path(circ2; action=:stroke)

end)
