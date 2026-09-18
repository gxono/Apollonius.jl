begin
using Apollonius
using Luxor: Drawing, finish, preview, origin,
    sethue, julia_blue, julia_green, julia_red, julia_purple, gsave, grestore, setopacity
import Luxor
end

colors = [julia_red, julia_purple, julia_green]

begin
Δr = 5
p1, p2 = polar_point_deg.(100, [30, 30+120])
t = equilateral_triangle_on_segment(p1, p2)
three_circles = APCircle2.(vertices(t), distance(p1, p2) / 2)
outer_circle = argmax(c -> c.r, tangent_circles(three_circles...))
circles = [three_circles[2]]

while true
    tc = argmin(c -> c.r, tangent_circles(outer_circle, three_circles[1], circles[end]))
    tc.r > Δr ? push!(circles, tc) : break
end

map!(c -> APCircle2(c.center, c.r - Δr), circles)

end

begin
Drawing(500, 500, "docs/src/assets/img/examples/logo.svg")
origin()

for (i, color) in enumerate(colors)
    sethue(color)
    path(rotate(circles, deg2rad((i-1)*(-120))), action=:fill)
end

finish()
preview()
end
