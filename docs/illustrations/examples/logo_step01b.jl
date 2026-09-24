include("../default_config.jl")

lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
  A, B = APPoint(0.0,0.0), APPoint(100.0, 0.0)
  s = APSegment(A, B)
  t = equilateral_triangle_on_segment(s)
  three_circles = three_tangent_circles(t)
  outer_circle = argmax(c -> c.r, tangent_circles(three_circles...))
end


@svg_doc(lxm, @__FILE__, begin
  sethue(julia_blue)
  path(three_circles, action=:stroke)
  path(outer_circle, action=:stroke)

  sethue(julia_red)
  for (i, c) in enumerate(three_circles)
    text("three_circles[$i]", c.center, halign=:center, valign=:center)
  end
  
  label("outer_circle", label_anchor(outer_circle, -pi/4)...)
end)


