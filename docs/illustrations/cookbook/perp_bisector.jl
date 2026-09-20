include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=300 margin=30 begin
    A, B = APPoint(0.0, 0.0), APPoint(6.0, 2.0)
    @unbounded m = perpendicular_bisector(A, B)
    M = midpoint(A, B)
    Q = point_on_line(perpendicular_bisector(A, B), 0.6)
    AB = APSegment(A, B)
    eq = [APSegment(Q, A), APSegment(Q, B)]
end
(; A, B, m, M, Q, AB, eq) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
gsave()
setline(1); setdash("dash")
sethue(julia_green)
path(eq, action=:stroke)
grestore()
sethue(julia_blue)
path(AB, action=:stroke)
path([A, B]); plot_point(julia_blue)
sethue(julia_purple)
path(m, action=:stroke, extend=400)
path([M, Q]); plot_point(julia_purple)
sethue(julia_red)
label("A", :SW, A); label("B", :SE, B); label("M", :SE, M); label("Q", :NE, Q)
end)
