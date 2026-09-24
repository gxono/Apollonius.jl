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
  new_circle = argmin(c -> c.r, tangent_circles(outer_circle, three_circles[2], circles[end]))
  new_circle.r > 1 ? push!(circles, new_circle) : break
end


@svg_doc(lxm, @__FILE__, begin
  @layer begin
    sethue(julia_blue); setdash(:dash); setline(1)
    path([outer_circle, three_circles...], action=:stroke)
  end

  sethue(julia_red)
  path(circles, action=:fill)
end)