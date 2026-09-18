include("../default_config.jl")

sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    P, Q = APPoint(1.0, 1.0), APPoint(6.0, 3.0)
    l = APLine(P, Q)
    C = APPoint(2.0, 6.0)
    foot = projection(C, l)
    Cref = reflection(C, foot)
end

@svg_doc(sz, @__FILE__, begin
    sethue(julia_blue)
    path(l, action=:stroke)

    gsave()
        setdash(:dash)
        sethue(julia_purple)
        path(APSegment(C,Cref),action=:stroke)
    grestore()

    path([P,Q])
    setpoint(julia_red)

    path(C)
    setpoint(julia_green)

    path([foot,Cref])
    setpoint(julia_purple)
end)
