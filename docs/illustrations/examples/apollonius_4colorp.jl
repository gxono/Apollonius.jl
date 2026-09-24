include("../default_config.jl")

const COLORS = (julia_red, julia_blue, julia_green, julia_purple)

@inline function free_color(c1, c2, c3)
    @inbounds for color in COLORS
        if color != c1 && color != c2 && color != c3
            return color
        end
    end
end

function iteration!(out, itm1, itm2, itm3)
    c1 = itm1[1]
    c2 = itm2[1]
    c3 = itm3[1]

    ic0 = argmin(c -> c.r, tangent_circles(c1, c2, c3))

    color = free_color(itm1[2], itm2[2], itm3[2])

    itmr = (ic0, color)
    push!(out, itmr)

    if ic0.r > 1
        iteration!(out, itmr, itm1, itm2)
        iteration!(out, itmr, itm1, itm3)
        iteration!(out, itmr, itm2, itm3)
    end

    return out
end

function iteration(itm1, itm2, itm3)
    out = typeof(itm1)[]
    iteration!(out, itm1, itm2, itm3)
end


lxm = @prepare_to_picture! width=500 height=500 margin=20 begin
    C1, C2 = APPoint(0.0, 0.0), APPoint(100.0, 0.0)

    t = equilateral_triangle_on_segment(C1, C2)
    three_circles = three_tangent_circles(t)

    outer_circle = argmax(
        c -> c.r,
        tangent_circles(three_circles...)
    )
end

co = (outer_circle, julia_blue)
cr = (three_circles[1], julia_red)
cp = (three_circles[2], julia_purple)
cg = (three_circles[3], julia_green)

all_circles = typeof(co)[]

iteration!(all_circles, co, cr, cp)
iteration!(all_circles, co, cp, cg)
iteration!(all_circles, co, cg, cr)
iteration!(all_circles, cr, cp, cg)

append!(all_circles, (cr, cp, cg))

@svg_doc(lxm, @__FILE__, begin
    for (circle, color) in all_circles
        sethue(color)
        path(circle, action=:fill)
    end
end)