include("../default_config.jl")

lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
  A, B = APPoint(0.0,0.0), APPoint(100.0, 0.0)
  s = APSegment(A, B)
  t = equilateral_triangle_on_segment(s)
  three_circles = three_tangent_circles(t)
  outer_circle = argmax(c -> c.r, tangent_circles(three_circles...))
end


circles = APCircle2[three_circles[1]]

while true
  circles[end].r < 1 && break
  new_circle = argmin(c -> c.r, tangent_circles(outer_circle, three_circles[2], circles[end]))
  push!(circles, new_circle)
end


@svg_doc(lxm, @__FILE__, begin
  @layer begin
    setopacity(0.25)
    sethue(julia_purple)
    path(circles, action=:fill)
    setopacity(1)
    path(circles, action=:stroke)
  end

  @layer begin
    sethue(julia_blue)
    path([outer_circle, three_circles[2]], action=:stroke)
  end

  sethue(julia_red)
  text("three_circles[2]", three_circles[2].center, halign=:center, valign=:middle)
  label("outer_circle", label_anchor(outer_circle, -pi/4)...)

  sethue("white")
  for (i, c) in enumerate(circles)
    fontsize(1.75 * c.r)
    text("$i", c.center, halign=:center, valign=:middle)
  end
end)


