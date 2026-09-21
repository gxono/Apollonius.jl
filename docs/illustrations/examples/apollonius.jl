include("../default_config.jl")

function iteration(c1, c2, c3)
    ic0 = argmin(c -> c.r, tangent_circles(c1, c2, c3))

    if ic0.r <= 1
      return [ic0]
		else
			return vcat(
					ic0,
					iteration(ic0, c1, c2),
					iteration(ic0, c1, c3),
					iteration(ic0, c2, c3),
			)
		end
end

lxm = @to_luxor_picture! width=500 height=240 margin=20 begin
  C1, C2 = APPoint(0.0,0.0), APPoint(100.0, 0.0)
  t = equilateral_triangle_on_segment(C1, C2)
  three_circles = three_tangent_circles(t)
  outer_circle = argmax(c -> c.r, tangent_circles(three_circles...))
end

outer_circles = iteration(outer_circle, three_circles[1], three_circles[2])
inner_circles = iteration(three_circles[1], three_circles[2], three_circles[3])


@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue); setline(1)
path(outer_circle)
path(three_circles)
path(inner_circles)

for i in [0, 120, 240]
	path(rotate.(outer_circles, deg2rad(i), outer_circle.center))
end

strokepath()
end)


