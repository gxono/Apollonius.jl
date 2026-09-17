include("../default_config.jl")






sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    A, B = APPoint(0.0, 0.0), APPoint(8.0, 0.0)
    ap = apollonius_circle(A, B, 2.0)
    Ptest1, Ptest2 = polar_point_deg.(ap.r, [50.0, 210], ap.center)
end







@svg_doc(sz, @__FILE__, begin
sethue(julia_purple)
    path(ap, action=:stroke)

    setdash(:dash)
    path([
        APSegment(A,Ptest1), APSegment(B,Ptest1),
        APSegment(A,Ptest2), APSegment(B,Ptest2),
        ], action=:stroke)
    setdash(:solid)

    path([A,B])
    setpoint(julia_red)
    path([Ptest1, Ptest2])
    setpoint(julia_purple)
    
    sethue("black")
    label("A", :NW, A)
    label("B", :NW, B)
    label("Ptest1", :NE, Ptest1)
    label("Ptest2", :SW, Ptest2)
end)
