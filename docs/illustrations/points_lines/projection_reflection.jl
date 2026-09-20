include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=240 margin=20 begin
    P, Q = APPoint(1.0, 1.0), APPoint(6.0, 3.0)
    l = APLine(P, Q)
    C = APPoint(2.0, 6.0)
    foot = projection(C, l)
    Cref = reflection(C, foot)
end
(; P, Q, l, C, foot, Cref) = lxo
@svg_doc(lxm, @__FILE__, begin
    sethue(julia_blue)
    path(l, action=:stroke)
    gsave()
        setdash(:dash)
        sethue(julia_purple)
        path(APSegment(C,Cref),action=:stroke)
    grestore()
    path([P,Q]); plot_point(julia_blue)
    path(C); plot_point(julia_green)
    path([foot,Cref]); plot_point(julia_purple)
end)
