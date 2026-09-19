include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=260 margin=30 begin
    pg = APStraightNgon([APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 3.0), APPoint(1.0, 3.0)])
    inner = APPoint(2.0, 1.0)
    outer = APPoint(6.0, 1.0)
    s_in = sides(pg)[argmin([distance(inner, s) for s in sides(pg)])]
    s_out = sides(pg)[argmin([distance(outer, s) for s in sides(pg)])]
    foot_in = projection(inner, APLine(s_in.p1, s_in.p2))
    foot_out = projection(outer, APLine(s_out.p1, s_out.p2))
end
(; pg, inner, outer, s_in, s_out, foot_in, foot_out) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(pg, action=:stroke)
path([inner, outer]); plot_point(julia_blue)
sethue(julia_purple)
path([APSegment(inner, foot_in), APSegment(outer, foot_out)], action=:stroke)
path([foot_in, foot_out]); plot_point(julia_purple)
end)
