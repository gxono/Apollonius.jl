```@meta
CurrentModule = Apollonius
```

# Tangency: Interstices

## Interstices: the gap between three tangent circles

Three *mutually* tangent circles (each pair, not just each with a third
common circle) leave a curvilinear-triangle-shaped gap between them,
called an **interstice** in this context (the same term used for the gaps
of an [Apollonian gasket](https://en.wikipedia.org/wiki/Apollonian_gasket)).
[`interstices`](@ref) returns it (or them, see below) as a `Vector{APInterstice2}`,
each one bounded by three [`APCircularArc2`](@ref)s, one per circle:

```@example geo
using Apollonius

c1 = APCircle2(APPoint(0.0, 0.0), 40.0)
c2 = APCircle2(APPoint(90.0, 0.0), 50.0)   # tangent to c1: distance 90 == 40 + 50
c3_center = intersection(APCircle2(c1.center, c1.r + 35.0), APCircle2(c2.center, c2.r + 35.0))[1]
c3 = APCircle2(c3_center, 35.0)            # tangent to both c1 and c2

gaps = interstices(c1, c2, c3)
length(gaps)   # 1: an externally tangent "chain" of 3 has exactly one gap
```

```@raw html
<img src="../assets/img/tangency/ccc_gap.svg" alt="" style="width:100%;">
```

It's built by reusing `tangent_circles(c1, c2, c3)` above: every genuine
interstice has an inscribed circle tangent to all three (one of the `CCC`
solutions) that never *encloses* any of them. Unlike the "big" solution
of a chain like this one, which contains all three and isn't a curvilinear
triangle of these three circles at all (see [`soddy_circles`](@ref) for
that pairing, inner and outer, given a name).

A **second** kind of configuration is possible: if one circle contains the
other two (each internally tangent to it, and externally tangent to each
other), the two inner circles' own tangency point splits the gap into
**two** separate interstices instead of one:

```@example geo
R = 100.0
big = APCircle2(APPoint(0.0, 0.0), R)
A = APCircle2(polar_point_deg(R - 25.0, 100.0, big.center), 25.0) # inside big, tangent to it
B_center = intersection(APCircle2(big.center, R - 45.0), APCircle2(A.center, A.r + 45.0))[1]
B = APCircle2(B_center, 45.0)                                       # inside big, tangent to it and to A

length(interstices(big, A, B))   # 2
```

```@raw html
<img src="../assets/img/tangency/ccc_gap2.svg" alt="" style="width:100%;">
```

[`interstices`](@ref) figures out which of these two cases applies (and in
the second case, correctly splits the gap in two) on its own. The order
`c1`, `c2`, `c3` are given in never matters. It throws an `ArgumentError`
if the three circles aren't all pairwise tangent to begin with.

An `APInterstice2`'s [`area`](@ref) is computed via a Green's-theorem line
integral around its three arcs rather than a "straight triangle plus or
minus circular segments" formula: the latter needs an extra inside/outside
decision per arc that breaks down for very unequal arc sizes (as in the
nested case above), while the line integral doesn't:

```@example geo
area(gaps[1])
perimeter(gaps[1])   # the three arcs' arc_length, summed
```

`rotate`, `reflection` and `homothety` all work on an `APInterstice2` too:
each of the three arcs transforms on its own, and (since each does so
correctly regardless of orientation, see [`reflection(::APCircularArc2, _)`](@ref)
above) they still connect end to end afterward into the transformed gap.
