include("../default_config.jl")


sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    P, Q, C = APPoint(1.0, 1.0), APPoint(6.0, 3.0), APPoint(3.0, 6.0)
    l1 = APLine(P,Q)
    l2 = APLine(C,Q)
    lb1, lb2 = angle_bisectors(l1, l2)
end


@svg_doc(sz, @__FILE__, begin
    sethue(julia_blue)
    path([l1, l2], action=:stroke)

    sethue(julia_purple)
    path([lb1, lb2], action=:stroke)

    path([P,Q,C])
    setpoint(julia_red)
end)
