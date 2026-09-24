include("../default_config.jl")

lxm = @prepare_to_picture! width=500 height=300 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    l = APLine(APPoint(-2.0, -1.0), APPoint(10.0, 6.0))

    projA = projection(A, l)
    projB = projection(B, l)
    projC = projection(C, l)

    lA = perpendicular_through(APLine(B, C), projA)
    lB = perpendicular_through(APLine(C, A), projB)
    lC = perpendicular_through(APLine(A, B), projC)

    op = orthopole(l, t)
end

@svg_doc(lxm, @__FILE__, begin
fontsize(15)

gsave()
setline(1); setdash("dash")
sethue(julia_green)
path([APSegment(A, projA), APSegment(B, projB), APSegment(C, projC)], action=:stroke)
path([lA, lB, lC], action=:stroke)
grestore()

sethue(julia_blue)
path(t, action=:stroke)
path(l, action=:stroke)

sethue(julia_red)
label("l", :N, l.p2)
label("orthopole", :SE, op)

sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([projA, projB, projC], action=:fillpreserve); sethue(julia_green); strokepath()
sethue("white"); path([op], action=:fillpreserve); sethue(julia_purple); strokepath()
end)
