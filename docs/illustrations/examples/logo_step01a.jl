include("../default_config.jl")


lxm = @to_luxor_picture! width=500 height=240 margin=20 begin
  A, B = APPoint(0.0,0.0), APPoint(100.0, 0.0)
  s = APSegment(A, B)
  t = equilateral_triangle_on_segment(s)
  three_circles = three_tangent_circles(t)
  outer_circle = argmax(c -> c.r, tangent_circles(three_circles...))
end


@svg_doc(lxm, @__FILE__, begin
  @layer begin
    sethue(julia_green); setdash(:dash)
    path(t, action=:stroke)
  end

  sethue(julia_blue)
  path(s, action=:stroke)

  sethue(julia_purple)
  path(three_circles, action=:stroke)
  path(outer_circle, action=:stroke)

  sethue("white")
  path(vertices(t), action=:fillpreserve)
  sethue(julia_green); strokepath()
end)


