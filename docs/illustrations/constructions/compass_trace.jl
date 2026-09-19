include("../default_config.jl")
sz = @to_luxor_picture! width=500 height=240 margin=40 begin
    O, P = APPoint(0.0, 0.0), APPoint(5.0, 0.0)
end
trace = compass_trace(O, P; angle=pi / 3)
@svg_doc(sz, @__FILE__, begin
Luxor.fontsize(15)
sethue("gray"); setdash("dash"); Luxor.setline(1)
path(APSegment(O, P), action=:stroke)
setdash("solid")
sethue(julia_purple); Luxor.setline(2.5)
path(trace, action=:stroke)
path([O, P])
setpoint(julia_red)
sethue("black")
label("O", :W, O)
label("P", :E, P)
end)
