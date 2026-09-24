include("../default_config.jl")

lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
  A, B = APPoint(0.0,0.0), APPoint(100.0, 0.0)
  s = APSegment(A, B)
  t = equilateral_triangle_on_segment(s)
  three_circles = three_tangent_circles(t)
  outer_circle = argmax(c -> c.r, tangent_circles(three_circles...))
end

C = circumcenter(t)
Δr = 0.05 * distance(C, A)
circles = APCircle2[three_circles[1]]
while true
  new_circle = argmin(c -> c.r, tangent_circles(outer_circle, three_circles[2], circles[end]))
  new_circle.r > Δr ? push!(circles, new_circle) : break
end
map!(c -> APCircle2(c.center, c.r - Δr), circles)

@svg_doc(lxm, @__FILE__, begin
  for (i, color) in enumerate([julia_red, julia_purple, julia_green])
    rot_copy = rotate.(circles, deg2rad((i-1) * 120), C)
    
    sethue(color)
    path(rot_copy, action=:fill)
  end
end)