```@meta
CurrentModule = Apollonius
```

# Examples

Two complete, worked examples that combine several pages of this manual into
one figure: an Apollonian gasket colored with four colors, and the
construction behind the package's own logo.

## An Apollonian gasket in four colors

Start from three mutually tangent circles and repeatedly fill every gap
between three already-placed circles with [`tangent_circles`](@ref)'s
smallest solution. The result is an
[Apollonian gasket](https://en.wikipedia.org/wiki/Apollonian_gasket): every
new circle touches exactly three older ones, and the gaps it leaves behind
are filled the same way, recursively, down to whatever size cutoff you
choose.

That "touches exactly three others" property is also what makes the gasket
easy to color: pick any four colors, and give each new circle whichever one
isn't already used by its three neighbors. Since a circle only ever has
three neighbors at the moment it is colored, there is always at least one
color left over. This is a direct, constructive instance of the
[four color theorem](https://en.wikipedia.org/wiki/Four_color_theorem),
for the friendliest possible case.

```julia
using Apollonius, Luxor
import Luxor: julia_red, julia_blue, julia_green, julia_purple

const COLORS = (julia_red, julia_blue, julia_green, julia_purple)

free_color(c1, c2, c3) = only(c for c in COLORS if c ∉ (c1, c2, c3))

function iteration!(out, itm1, itm2, itm3)
    c1, c2, c3 = itm1[1], itm2[1], itm3[1]
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
```

Each circle is carried around together with its color, as a `(circle,
color)` pair. `iteration!` finds the smallest circle tangent to three given
ones, colors it, and recurses into the three new triples it just created
with its neighbors, stopping once a circle gets smaller than radius `1`.

Starting the recursion from a triangle's three tangent circles and their
common outer tangent, then coloring the whole gasket:

```julia
C1, C2 = APPoint(0.0, 0.0), APPoint(100.0, 0.0)
t = equilateral_triangle_on_segment(C1, C2)
three_circles = three_tangent_circles(t)
outer_circle = argmax(c -> c.r, tangent_circles(three_circles...))

co = (outer_circle, julia_blue)
cr, cp, cg = zip(three_circles, (julia_red, julia_purple, julia_green))

all_circles = typeof(co)[]
iteration!(all_circles, co, cr, cp)
iteration!(all_circles, co, cp, cg)
iteration!(all_circles, co, cg, cr)
iteration!(all_circles, cr, cp, cg)
append!(all_circles, (cr, cp, cg))
```

```@raw html
<img src="../assets/img/examples/apollonius_4colorp.svg" alt="An Apollonian gasket of circles colored with four colors so that no two tangent circles share a color" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple

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

    Drawing(lxm.width, lxm.height, :svg)
    origin()

    for (circle, color) in all_circles
        sethue(color)
        path(circle, action=:fill)
    end

    finish()
    ```

## Building the package logo

The package logo is an Apollonian gasket with most of its circles removed,
one of its three symmetric arms kept, rotated into place and colored:

```@raw html
<img src="../assets/img/examples/logo.svg" alt="The package logo: three colored arms of circles shrinking towards the center, arranged with three-fold symmetry" style="width:60%; max-width: 320px;">
```

The strategy is to build one arm iteratively, then make two rotated copies
of it and color the three arms.

Start with the big outer circle and the three central ones: fix a segment,
build the equilateral triangle on it, get the three circles tangent to its
sides and centered at its vertices, and take the one tangent circle that
encloses all three (the `tangent_circles` solution with the largest
radius):

```julia
A, B = APPoint(0.0, 0.0), APPoint(100.0, 0.0)
s = APSegment(A, B)
t = equilateral_triangle_on_segment(s)
three_circles = three_tangent_circles(t)
outer_circle = argmax(c -> c.r, tangent_circles(three_circles...))
```

```@raw html
<img src="../assets/img/examples/logo_step01a.svg" alt="A triangle inscribed between three tangent circles, with a fourth circle enclosing them" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    include("../default_config.jl")

    lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
      A, B = APPoint(0.0,0.0), APPoint(100.0, 0.0)
      s = APSegment(A, B)
      t = equilateral_triangle_on_segment(s)
      three_circles = three_tangent_circles(t)
      outer_circle = argmax(c -> c.r, tangent_circles(three_circles...))
    end

    Drawing(lxm.width, lxm.height, :svg)
    origin()
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
    finish()
    ```

```@raw html
<img src="../assets/img/examples/logo_step01b.svg" alt="The same figure with outer_circle and the three central circles labeled" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    include("../default_config.jl")

    lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
      A, B = APPoint(0.0,0.0), APPoint(100.0, 0.0)
      s = APSegment(A, B)
      t = equilateral_triangle_on_segment(s)
      three_circles = three_tangent_circles(t)
      outer_circle = argmax(c -> c.r, tangent_circles(three_circles...))
    end

    Drawing(lxm.width, lxm.height, :svg)
    origin()
    sethue(julia_blue)
    path(three_circles, action=:stroke)
    path(outer_circle, action=:stroke)

    sethue(julia_red)
    for (i, c) in enumerate(three_circles)
      text("three_circles[$i]", c.center, halign=:center, valign=:center)
    end

    label("outer_circle", label_anchor(outer_circle, -pi/4)...)
    finish()
    ```

Now build one arm: a chain of circles, each tangent to `outer_circle`,
`three_circles[2]` and the previous circle in the chain. Starting from
`three_circles[1]` and repeatedly taking the smallest tangent solution
traces out a chain that shrinks towards the gap between `outer_circle` and
`three_circles[2]`:

```@raw html
<img src="../assets/img/examples/logo_step02a.svg" alt="A chain of shrinking circles wedged between outer_circle and three_circles[2]" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
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

    Drawing(lxm.width, lxm.height, :svg)
    origin()
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
    finish()
    ```

Each circle in the chain is tangent to three others, so
[`tangent_circles`](@ref) returns two solutions: the previous circle in the
chain, and the next one. `argmin` always picks the next, smaller one, so the
chain keeps shrinking instead of doubling back on itself. Stop once a
circle's radius drops to `1` or below:

```julia
circles = APCircle2[three_circles[1]]

while true
  new_circle = argmin(c -> c.r, tangent_circles(outer_circle, three_circles[2], circles[end]))
  new_circle.r > 1 ? push!(circles, new_circle) : break
end
```

```@raw html
<img src="../assets/img/examples/logo_step02b.svg" alt="The finished chain of tangent circles, filled in solid red" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
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

    Drawing(lxm.width, lxm.height, :svg)
    origin()
    @layer begin
      sethue(julia_blue); setdash(:dash); setline(1)
      path([outer_circle, three_circles...], action=:stroke)
    end

    sethue(julia_red)
    path(circles, action=:fill)
    finish()
    ```

Now copy the chain, rotate two copies by 120° and 240° around
`outer_circle`'s center, and color the three arms:

```julia
c = outer_circle.center

for (i, color) in enumerate([julia_red, julia_purple, julia_green])
  rot_copy = rotate.(circles, deg2rad((i-1) * 120), c)

  sethue(color)
  path(rot_copy, action=:fill)
end
```

```@raw html
<img src="../assets/img/examples/logo_step03a.svg" alt="Three colored arms of circles arranged with three-fold symmetry around the center" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
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

    Drawing(lxm.width, lxm.height, :svg)
    origin()
    c = outer_circle.center

    for (i, color) in enumerate([julia_red, julia_purple, julia_green])
      rot_copy = rotate.(circles, deg2rad((i-1) * 120), c)

      sethue(color)
      path(rot_copy, action=:fill)
    end
    finish()
    ```

The last step shrinks every circle by a fixed amount `Δr`, so the finished
logo has a visible gap between neighboring circles instead of tangent ones
touching edge to edge. In the package logo this is 5% of `t`'s circumradius.
Shrinking only makes sense once every circle in the chain is already past
that size, so the loop's cutoff changes from a fixed radius of `1` to `Δr`
itself:

```julia
C = circumcenter(t)
Δr = 0.05 * distance(C, A)
circles = APCircle2[three_circles[1]]
while true
  new_circle = argmin(c -> c.r, tangent_circles(outer_circle, three_circles[2], circles[end]))
  new_circle.r > Δr ? push!(circles, new_circle) : break
end
map!(c -> APCircle2(c.center, c.r - Δr), circles)
```

```@raw html
<img src="../assets/img/examples/logo_step04a.svg" alt="The same three arms with a visible gap between adjacent circles" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
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

    Drawing(lxm.width, lxm.height, :svg)
    origin()
    c = outer_circle.center

    for (i, color) in enumerate([julia_red, julia_purple, julia_green])
      rot_copy = rotate.(circles, deg2rad((i-1) * 120), c)

      sethue(color)
      path(rot_copy, action=:fill)
    end
    finish()
    ```

This is exactly the construction the real logo uses, only starting from a
polar layout instead of a segment on the x-axis:

!!! details "See script"
    ```julia
    using Apollonius
    using Luxor: Drawing, finish, origin,
        sethue, julia_blue, julia_green, julia_red, julia_purple

    colors = [julia_red, julia_purple, julia_green]

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

    Drawing(500, 500, "docs/src/assets/img/examples/logo.svg")
    origin()

    for (i, color) in enumerate(colors)
        sethue(color)
        path(rotate(circles, (1-i)*2pi/3), action=:fill)
    end

    finish()
    ```
