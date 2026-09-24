```@meta
CurrentModule = Apollonius
```

# Tangency & Apollonius Problems

The classical **problem of Apollonius** asks: given three objects, each
either a point, a line or a circle, find the circle(s) tangent to all
three (a point counts as a "circle" of radius zero to be tangent to, i.e.
passing through it). There are ten combinations up to symmetry (PPP, LPP,
LLP, CPP, CLP, CCP, LLL, CLL, CCL, CCC); this package covers the ones that
involve at least one circle or line (PPP is just
[`circumcircle`](@ref) of an `APTriangle`, and LLL is
[`incenter`](@ref)/[`excenters`](@ref)).

The functions are named by what role the *points* among the three objects
play:

* [`tangent_circles`](@ref): two of the three objects are
  points the circle must pass *through*; the third is a line or a circle
  it must be tangent to.
* [`tangent_circles`](@ref): one point to pass through, and
  two lines/circles to be tangent to.
* [`tangent_circles`](@ref), no points at all: two or three lines/circles,
  all to be tangent to.

Every one of these can return **multiple** solutions (up to 8, for three
circles), so they all return a `Vector{APCircle2}`, never a single `APCircle2`.
The given circles themselves are always excluded from the result, even
when the configuration is symmetric enough that one of them would
otherwise satisfy the tangency equations too (a circle is degenerately
"tangent" to itself in that sense).

## Through two points, tangent to a line

In general there are up to two such circles, but whenever `a` and `b` are
placed symmetrically about the perpendicular from their midpoint to `l`
(as here), one of the two degenerates to infinite radius (a straight line),
leaving exactly one genuine circle:

```@example geo
using Apollonius

a, b = APPoint(-3.0, 0.0), APPoint(3.0, 0.0)
l = APLine(APPoint(-5.0, -4.0), APPoint(5.0, -4.0))

sols = tangent_circles(a, b, l)
length(sols)   # exactly 1, in this symmetric case
```

```@raw html
<img src="../assets/img/tangency/ppl.svg" alt="" style="width:100%;">
```

The circle's center lies on the perpendicular bisector of `[a,b]` and it
touches the line from above. A less symmetric choice of `a`, `b` and `l`
generally gives two such circles, often of very different sizes, since
one tends to hug the line closely while the other bulges around to reach
it from the far side.

The same function also takes a circle instead of a line as the third,
tangent-to object:

```@example geo
a2, b2 = APPoint(-2.0, 1.0), APPoint(2.0, 1.0)
given_c = APCircle2(APPoint(0.0, -3.0), 2.0)

sols_c = tangent_circles(a2, b2, given_c)
length(sols_c)   # 2 here: one tangent externally, one internally
```

```@raw html
<img src="../assets/img/tangency/ppc.svg" alt="" style="width:100%;">
```

## Tangent to two or three circles/lines

`tangent_circles` covers every "no points, ≥2 circles/lines" combination:
two lines and a circle (`CLL`), two circles and a line (`CCL`), or three
circles (`CCC`, Apollonius' original problem, below):

```@example geo
l1 = APLine(APPoint(0.0, 0.0), APPoint(0.0, 1.0))   # the y-axis
l2 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))   # the x-axis
c_cll = APCircle2(APPoint(6.0, 6.0), 2.0)

sols_cll = tangent_circles(l1, l2, c_cll)
length(sols_cll)   # 4
```

```@raw html
<img src="../assets/img/tangency/llc.svg" alt="" style="width:100%;">
```


```@example geo
c1_ccl = APCircle2(APPoint(0.0, 0.0), 2.0)
c2_ccl = APCircle2(APPoint(6.0, 0.0), 2.0)
l_ccl = APLine(APPoint(0.0, -3.0), APPoint(1.0, -3.0))

sols_ccl = tangent_circles(c1_ccl, c2_ccl, l_ccl)
length(sols_ccl)   # 6
```

```@raw html
<img src="../assets/img/tangency/ccl.svg" alt="" style="width:100%;">
```

## Tangent to three circles

With three circles and no points at all, this is Apollonius' original
problem: up to 8 solutions, since each of the three tangencies can
independently be internal or external.

```@example geo
R = 3.0
centers = [APPoint(R * cos(pi / 2 + 2pi * k / 3), R * sin(pi / 2 + 2pi * k / 3)) for k in 0:2]
given = [APCircle2(centers[k+1], 1.0) for k in 0:2]

sols3 = tangent_circles(given[1], given[2], given[3])
length(sols3)   # 8 solutions
```

```@raw html
<img src="../assets/img/tangency/ccc.svg" alt="" style="width:100%;">
```

Two of those eight happen to be concentric with the given configuration by
symmetry here: a small one nested between the three circles, and a large
one enclosing all of them:

```@example geo
small = sols3[argmin(s.r for s in sols3)]
big = sols3[argmax(s.r for s in sols3)]
```

```@raw html
<img src="../assets/img/tangency/ccc_bs.svg" alt="" style="width:100%;">
```
