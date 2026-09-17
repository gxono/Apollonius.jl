using Apollonius
using Test
using Base.MathConstants: golden

@testset "Apollonius.jl" begin

    @testset "APPoint / APVector" begin
        @testset "construction and Dim inference" begin
            p2 = APPoint(1.0, 2.0)
            p3 = APPoint(1.0, 2.0, 3.0)
            @test p2 isa APPoint{2,Float64}
            @test p3 isa APPoint{3,Float64}
            @test p2[1] == 1.0 && p2[2] == 2.0

            # mixed Int/Float promotes like the rest of the package expects
            pmix = APPoint(1, 2.0)
            @test pmix isa APPoint{2,Float64}

            # all-Int stays Int (matches existing Point2(1,2) behavior)
            pint = APPoint(1, 2)
            @test pint isa APPoint{2,Int}

            v2 = APVector(3.0, 4.0)
            @test v2 isa APVector{2,Float64}
        end

        @testset "indexing, iteration, destructuring" begin
            p = APPoint(3.0, 4.0)
            @test p[1] == 3.0 && p[2] == 4.0
            @test length(p) == 2
            x, y = p
            @test x == 3.0 && y == 4.0
            @test collect(p) == [3.0, 4.0]
        end

        @testset "equality / isapprox / show" begin
            @test APPoint(1.0, 2.0) == APPoint(1.0, 2.0)
            @test APPoint(1.0, 2.0) != APPoint(1.0, 2.1)
            @test isapprox(APPoint(1.0, 2.0), APPoint(1.0 + 1e-12, 2.0))
            @test !isapprox(APPoint(0.0, 0.0), APPoint(1e-3, 0.0); atol=1e-9)
            @test sprint(show, APPoint(1.0, 2.0)) == "[1.0, 2.0]"
            @test sprint(show, APVector(1.0, 2.0)) == "⟨1.0, 2.0⟩"
        end

        @testset "Point - Point -> APVector, Point + Point undefined (CGAL-style)" begin
            A, B = APPoint(0.0, 0.0), APPoint(4.0, 0.0)
            @test A - B isa APVector
            @test A - B == APVector(-4.0, 0.0)
            @test_throws MethodError A + B

            @test 2.0 * B isa APPoint
            @test 2.0 * B == APPoint(8.0, 0.0)
            @test B * 2.0 == 2.0 * B
            @test B / 2.0 == APPoint(2.0, 0.0)
            @test -B == APPoint(-4.0, 0.0)

            # point arithmetic goes through a reference point + vector displacements
            about = APPoint(1.0, 1.0)
            reflect_like = about + (about - A)
            @test reflect_like isa APPoint
            @test reflect_like == APPoint(2.0, 2.0)
        end

        @testset "Vector/Vector arithmetic" begin
            u, v = APVector(1.0, 0.0), APVector(0.0, 1.0)
            @test u + v == APVector(1.0, 1.0)
            @test u - v == APVector(1.0, -1.0)
            @test 3.0 * u == APVector(3.0, 0.0)
            @test -u == APVector(-1.0, 0.0)
        end

        @testset "Point/Vector cross arithmetic" begin
            p = APPoint(1.0, 1.0)
            v = APVector(2.0, 3.0)
            @test p + v isa APPoint
            @test p + v == APPoint(3.0, 4.0)
            @test v + p == p + v
            @test p - v isa APPoint
            @test p - v == APPoint(-1.0, -2.0)
        end

        @testset "APPoint <-> APVector conversion" begin
            p = APPoint(3.0, 4.0)
            v = APVector(p)
            @test v isa APVector
            @test v[1] == 3.0 && v[2] == 4.0
            @test APPoint(v) == p
        end

        @testset "dot / norm / normalize" begin
            p1, p2 = APPoint(0.0, 0.0), APPoint(3.0, 4.0)
            @test norm(p2) == 5.0
            @test norm(p2 - p1) == 5.0
            @test dot(APVector(1.0, 0.0), APVector(0.0, 1.0)) == 0.0
            @test dot(p2, p2) == 25.0
            n = normalize(p2)
            @test isapprox(norm(n), 1.0)
            @test isapprox(n, APPoint(0.6, 0.8))

            v = APVector(3.0, 4.0)
            @test norm(v) == 5.0
            @test isapprox(normalize(v), APVector(0.6, 0.8))
        end

        @testset "3D works too (forward-compat check)" begin
            p1, p2 = APPoint(0.0, 0.0, 0.0), APPoint(1.0, 2.0, 2.0)
            @test norm(p2 - p1) == 3.0
            @test length(p1) == 3
        end
    end

    @testset "APSegment / APLine / APRay / APBoundingBox" begin
        p1, p2 = APPoint(0.0, 0.0), APPoint(4.0, 0.0)
        s = APSegment(p1, p2)
        l = APLine(p1, p2)
        r = APRay(p1, p2)

        @test direction(s) == APVector(4.0, 0.0)
        @test direction(l) == APVector(4.0, 0.0)
        @test direction(r) == APVector(4.0, 0.0)
        @test direction(s) isa APVector   # the motivating use case for APVector

        @test s[1] == p1 && s[2] == p2
        @test collect(s) == [p1, p2]

        # APLine/APRay support the same [i]/iteration/destructuring
        # protocol as APSegment -- e.g. to flatten a collection of lines
        # into their defining points via Iterators.flatten
        @test l[1] == p1 && l[2] == p2
        @test collect(l) == [p1, p2]
        a, b = l
        @test a == p1 && b == p2
        @test r[1] == p1 && r[2] == p2
        @test collect(r) == [p1, p2]
        l2 = APLine(APPoint(5.0, 5.0), APPoint(6.0, 6.0))
        @test collect(Iterators.flatten([l, l2])) == [p1, p2, APPoint(5.0, 5.0), APPoint(6.0, 6.0)]

        @test midpoint(s.p1, s.p2) == APPoint(2.0, 0.0)
        @test distance(s) == 4.0
        @test distance(p1, p2) == 4.0

        @test l == APLine(p1, p2)
        @test l != APLine(p1, APPoint(4.0, 1.0))
        @test APLine(s) == l

        @test s == APSegment(p1, p2)
        @test isapprox(s, APSegment(p1 + APVector(1e-12, 0.0), p2); atol=1e-9)

        @test sprint(show, s) == "APSegment([0.0, 0.0] -> [4.0, 0.0])"

        @testset "isapprox: APLine (defining points don't matter, only the line does)" begin
            # same infinite line, defining points nowhere near each other --
            # a real regression risk if isapprox ever went back to comparing
            # p1/p2 directly instead of is_parallel + on_line
            far1 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
            far2 = APLine(APPoint(1000.0, 1000.0), APPoint(1005.0, 1005.0))
            @test isapprox(far1, far2)

            # same line, opposite parametrization direction
            @test isapprox(far1, APLine(APPoint(1.0, 1.0), APPoint(0.0, 0.0)))

            # parallel but distinct lines must NOT compare equal
            @test !isapprox(far1, APLine(APPoint(0.0, 1.0), APPoint(1.0, 2.0)))

            # crossing (non-parallel) lines must NOT compare equal
            @test !isapprox(far1, APLine(APPoint(0.0, 1.0), APPoint(1.0, 0.0)))
        end

        @testset "isapprox: APRay (same origin AND same direction, not just parallel)" begin
            # this used to throw UndefVarError: same_direction not defined --
            # every case below is a regression test against that
            base = APRay(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
            @test isapprox(base, APRay(APPoint(0.0, 0.0), APPoint(2.0, 2.0)))  # same ray, different `through`

            # opposite direction from the same origin is a DIFFERENT ray
            @test !isapprox(base, APRay(APPoint(0.0, 0.0), APPoint(-1.0, -1.0)))

            # same direction, different origin is also a different ray
            @test !isapprox(base, APRay(APPoint(1.0, 0.0), APPoint(2.0, 1.0)))
        end

        @testset "projection, distance to a line, reflection" begin
            off = APPoint(2.0, 3.0)
            @test projection(off, l) == APPoint(2.0, 0.0)
            @test distance(off, l) == 3.0
            @test distance(l, off) == distance(off, l)
            @test reflection(off, l) == APPoint(2.0, -3.0)

            # angle=pi/2 is the same ordinary orthogonal projection, explicit
            @test projection(off, l; angle=pi / 2) == projection(off, l)
            # oblique projection at 45 degrees from l's own direction
            @test isapprox(projection(off, l; angle=pi / 4), APPoint(-1.0, 0.0); atol=1e-9)
            # angle strictly between 0 and pi -- either end is parallel to l
            @test_throws ArgumentError projection(off, l; angle=0.0)
            @test_throws ArgumentError projection(off, l; angle=pi)
            @test_throws ArgumentError projection(off, l; angle=-0.1)
        end

        @testset "rotate / homothety / reflection on Segment/Line/Ray" begin
            center = APPoint(0.0, 0.0)
            rot = rotate(s, pi / 2, center)
            @test isapprox(rot.p1, APPoint(0.0, 0.0); atol=1e-9)
            @test isapprox(rot.p2, APPoint(0.0, 4.0); atol=1e-9)

            hom = homothety(s, 2.0, center)
            @test hom.p1 == APPoint(0.0, 0.0) && hom.p2 == APPoint(8.0, 0.0)

            refl = reflection(s, APPoint(1.0, 1.0))
            @test refl.p1 == APPoint(2.0, 2.0) && refl.p2 == APPoint(-2.0, 2.0)

            rot_l = rotate(l, pi / 2, center)
            @test isapprox(rot_l.p1, APPoint(0.0, 0.0); atol=1e-9) && isapprox(rot_l.p2, APPoint(0.0, 4.0); atol=1e-9)
            rot_r = rotate(r, pi / 2, center)
            @test isapprox(rot_r.origin, APPoint(0.0, 0.0); atol=1e-9) && isapprox(rot_r.through, APPoint(0.0, 4.0); atol=1e-9)
        end

        @testset "APBoundingBox" begin
            bb = APBoundingBox([APPoint(0.0, 0.0), APPoint(4.0, 3.0), APPoint(-1.0, 2.0)])
            @test bb.min == APPoint(-1.0, 0.0) && bb.max == APPoint(4.0, 3.0)
            @test bbox_width(bb) == 5.0
            @test bbox_height(bb) == 3.0
            @test bbox_center(bb) == APPoint(1.5, 1.5)
            @test bbox_diagonal(bb) == distance(bb.min, bb.max)
            @test bbox_aspect_ratio(bb) == 5.0 / 3.0

            @test APPoint(0.0, 0.0) in bb
            @test !(APPoint(-2.0, 0.0) in bb)

            shifted = bb + APVector(1.0, 1.0)
            @test shifted.min == APPoint(0.0, 1.0)
            @test (shifted - APVector(1.0, 1.0)) == bb

            scaled = bb * 2.0
            @test scaled.min == APPoint(-2.0, 0.0) && scaled.max == APPoint(8.0, 6.0)

            bb2 = APBoundingBox(APPoint(2.0, 1.0), APPoint(6.0, 5.0))
            @test bboxes_intersect(bb, bb2)
            inter = bbox_intersection(bb, bb2)
            @test inter.min == APPoint(2.0, 1.0) && inter.max == APPoint(4.0, 3.0)

            far = APBoundingBox(APPoint(100.0, 100.0), APPoint(200.0, 200.0))
            @test !bboxes_intersect(bb, far)
            @test bbox_intersection(bb, far) === nothing

            @test APBoundingBox(s) == APBoundingBox([p1, p2])
        end

        @testset "APBoundingBox: empty box (neutral element) and APPoint's own box" begin
            # a bare point gets a real, degenerate (zero-size) box at its own
            # location -- it's a position, so it can grow a union like any shape
            p = APPoint(3.0, -2.0)
            @test APBoundingBox(p) == APBoundingBox(p, p)
            @test bbox_width(APBoundingBox(p)) == 0.0 && bbox_height(APBoundingBox(p)) == 0.0

            # non-positional values -- a number, a direction, unbounded shapes --
            # get the empty box instead: nothing to report, and (for a number)
            # not even something translate/homothety know how to move
            @test isempty(APBoundingBox(5))
            @test isempty(APBoundingBox(5.0))
            @test isempty(APBoundingBox(APVector(1.0, 0.0)))
            l = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
            r = APRay(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
            ang = APAngle2(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
            hp = APHalfPlane2(l, 1)
            strip = APStrip2(l, APLine(APPoint(1.0, 0.0), APPoint(2.0, 1.0)))
            @test isempty(APBoundingBox(l))
            @test isempty(APBoundingBox(r))
            @test isempty(APBoundingBox(ang))
            @test isempty(APBoundingBox(hp))
            @test isempty(APBoundingBox(strip))
            @test !isempty(APBoundingBox(APCircle2(APPoint(0.0, 0.0), 1.0)))  # sanity check

            # the empty box is the identity element for bbox_union, both ways,
            # and empty `union` empty stays empty
            bb = APBoundingBox(APPoint(1.0, 2.0), APPoint(4.0, 6.0))
            empty1, empty2 = APBoundingBox(5), APBoundingBox(APVector(0.0, 0.0))
            @test bbox_union(empty1, bb) == bb
            @test bbox_union(bb, empty1) == bb
            @test isempty(bbox_union(empty1, empty2))

            # APBoundingBox on a Vector{<:APObject}: unions each element's own
            # box, empty (not an error) for an empty vector -- unlike
            # APBoundingBox(::AbstractVector{<:APPoint}), which still throws
            l1 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
            l2 = APLine(APPoint(5.0, 5.0), APPoint(6.0, 6.0))
            @test isempty(APBoundingBox([l1, l2]))  # both unbounded -> still empty
            mixed = [l1, APCircle2(APPoint(0.0, 0.0), 2.0)]
            @test APBoundingBox(mixed) == APBoundingBox(mixed[2])  # the line contributes nothing
            @test isempty(APBoundingBox(APLine{2,Float64}[]))
            @test_throws ArgumentError APBoundingBox(APPoint{2,Float64}[])

            # any-shaped array of points (not just a Vector) -- what
            # `reduce(hcat, intersection.(ll, circshift(ll, 1)))` produces
            pts_matrix = [APPoint(0.0, 0.0) APPoint(1.0, 0.0); APPoint(0.0, 1.0) APPoint(1.0, 1.0)]
            @test APBoundingBox(pts_matrix) == APBoundingBox(APPoint(0.0, 0.0), APPoint(1.0, 1.0))

            # Tuple/NamedTuple of shapes -- what euler_points/excenters/
            # excircles/soddy_circles return -- work directly, no `collect` needed
            @test APBoundingBox((APPoint(0.0, 0.0), APPoint(2.0, 3.0))) ==
                  APBoundingBox(APPoint(0.0, 0.0), APPoint(2.0, 3.0))
            named = (A=APPoint(-1.0, 0.0), B=APPoint(1.0, 4.0))
            @test APBoundingBox(named) == APBoundingBox(APPoint(-1.0, 0.0), APPoint(1.0, 4.0))
            # a NamedTuple of plain numbers (e.g. exradii) still correctly
            # contributes nothing, exactly like a bare number would
            @test isempty(APBoundingBox((A=1.0, B=2.0, C=3.0)))
        end

        @testset "3D construction works (forward-compat check)" begin
            s3 = APSegment(APPoint(0.0, 0.0, 0.0), APPoint(1.0, 2.0, 2.0))
            @test distance(s3) == 3.0
        end

        @testset "every APObject/APTransform broadcasts as a scalar" begin
            # without a `Broadcast.broadcastable` override, Julia's default
            # fallback `collect`s any type it doesn't recognize -- silently
            # wrong for types that define `iterate`/`length` purely for
            # destructuring convenience (APPoint/APVector, APSegment,
            # APTriangle, ...), and a confusing MethodError from inside
            # `collect` for every other type (APLine, APCircle2, ...)
            p = APPoint(1.0, 2.0)
            vs = [APVector(1.0, 0.0), APVector(0.0, 1.0)]
            @test translate.(p, vs) == [translate(p, vs[1]), translate(p, vs[2])]

            t = APTriangle(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
            @test translate.(t, vs) == [translate(t, vs[1]), translate(t, vs[2])]

            l = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
            cs = [APCircle2(APPoint(0.0, 0.0), 1.0), APCircle2(APPoint(5.0, 0.0), 1.0)]
            @test intersection.(l, cs) == [intersection(l, cs[1]), intersection(l, cs[2])]

            m = rotation_map(pi / 2, APPoint(0.0, 0.0))
            @test m.(vs) == [m(vs[1]), m(vs[2])]
        end

        @testset "translate/rotate/homothety/reflection/invert/invert_neg on a Vector of shapes" begin
            # lets a plain Vector -- what intersection/tangent_points return,
            # since they can give 0/1/2 points depending on the geometry --
            # work as a single named item inside e.g. a @translate/
            # @to_luxor_picture block, instead of needing to be unwrapped
            v = APVector(1.0, -2.0)
            pts = [APPoint(0.0, 0.0), APPoint(3.0, 4.0)]
            @test translate(pts, v) == translate.(pts, v)
            @test rotate(pts, pi / 2) == rotate.(pts, pi / 2)
            @test homothety(pts, 2.0) == homothety.(pts, 2.0)
            @test reflection(pts, APPoint(1.0, 1.0)) == reflection.(pts, APPoint(1.0, 1.0))

            # invert/invert_neg aren't defined for a bare APPoint (only for
            # APLine/APCircle2/APSegment/APTriangle/APStraightNgon), so
            # exercise them -- and the "Vector of a non-point APObject"
            # case -- with APLine instead
            center = APPoint(0.0, 0.0)
            lines = [APLine(APPoint(2.0, 0.0), APPoint(2.0, 1.0)), APLine(APPoint(3.0, 0.0), APPoint(3.0, 1.0))]
            @test translate(lines, v) == translate.(lines, v)
            @test invert(lines, center; k=2.0) == invert.(lines, center; k=2.0)
            @test invert_neg(lines, center; k=2.0) == invert_neg.(lines, center; k=2.0)

            # empty vector: nothing to transform, no error
            @test translate(APPoint[], v) == APPoint[]
        end
    end

    @testset "APTriangle / APQuadrilateral / APStraightNgon" begin
        @testset "APTriangle" begin
            A, B, C = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 3.0)
            t = APTriangle(A, B, C)
            @test vertices(t) == (A, B, C)
            @test t[1] == A && t[2] == B && t[3] == C
            @test collect(t) == [A, B, C]
            @test area(t) ≈ 6.0
            @test perimeter(t) ≈ 4.0 + 5.0 + 3.0
            @test centroid(t) ≈ A + ((B - A) + (C - A)) / 3
            @test is_convex(t)
            @test APPoint(1.0, 1.0) in t
            @test !(APPoint(10.0, 10.0) in t)

            rot = rotate(t, pi / 2, APPoint(0.0, 0.0))
            @test isapprox(rot.a, APPoint(0.0, 0.0); atol=1e-9)
            @test isapprox(rot.b, APPoint(0.0, 4.0); atol=1e-9)
            hom = homothety(t, 2.0)
            @test area(hom) ≈ 4 * area(t)
            refl = reflection(t, APPoint(1.0, 1.0))
            @test area(refl) ≈ area(t)

            bb = APBoundingBox(t)
            @test bb.min == APPoint(0.0, 0.0) && bb.max == APPoint(4.0, 3.0)
        end

        @testset "APQuadrilateral" begin
            a, b, c, d = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 3.0), APPoint(1.0, 3.0)
            q = APQuadrilateral(a, b, c, d)

            @test vertices(q) == (a, b, c, d)
            @test q[1] == a && q[4] == d
            @test collect(q) == [a, b, c, d]

            s = sides(q)
            @test length(s) == 4
            @test s[1] == APSegment(a, b)

            diags = diagonals(q)
            @test diags[1] == APSegment(a, c) && diags[2] == APSegment(b, d)

            @test centroid(q) ≈ a + ((b - a) + (c - a) + (d - a)) / 4   # plain average, NOT area-weighted
            @test area(q) ≈ 10.5
            @test perimeter(q) ≈ distance(a, b) + distance(b, c) + distance(c, d) + distance(d, a)
            @test is_convex(q)

            @test APPoint(2.0, 1.5) in q
            @test !(APPoint(10.0, 10.0) in q)

            bb = APBoundingBox(q)
            @test bb.min == APPoint(0.0, 0.0) && bb.max == APPoint(4.0, 3.0)

            # non-convex (dart)
            dart = APQuadrilateral(APPoint(0.0, 0.0), APPoint(2.0, 1.0), APPoint(0.0, 2.0), APPoint(0.5, 1.0))
            @test !is_convex(dart)

            rot = rotate(q, pi / 6, APPoint(1.0, 1.0))
            @test area(rot) ≈ area(q) atol = 1e-9
            hom = homothety(q, -2.0)
            @test area(hom) ≈ 4 * area(q) atol = 1e-9
            refl = reflection(q, APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)))
            @test area(refl) ≈ area(q) atol = 1e-9
        end

        @testset "APStraightNgon" begin
            square = APStraightNgon([APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(2.0, 2.0), APPoint(0.0, 2.0)])
            @test area(square) == 4.0
            @test perimeter(square) == 8.0
            @test centroid(square) == APPoint(1.0, 1.0)
            @test is_convex(square)
            @test APPoint(1.0, 1.0) in square
            @test !(APPoint(3.0, 1.0) in square)

            dart = APStraightNgon([APPoint(0.0, 0.0), APPoint(2.0, 1.0), APPoint(0.0, 2.0), APPoint(0.5, 1.0)])
            @test !is_convex(dart)

            rot = rotate(square, pi / 2, APPoint(1.0, 1.0))
            @test area(rot) ≈ area(square) atol = 1e-9
            hom = homothety(square, -2.0)
            @test area(hom) ≈ 4 * area(square) atol = 1e-9
            refl = reflection(square, APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)))
            @test area(refl) ≈ area(square) atol = 1e-9

            pts = [APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(2.0, 2.0), APPoint(0.0, 2.0), APPoint(1.0, 1.0)]
            hull = convex_hull(pts)
            @test length(vertices(hull)) == 4
            @test area(hull) == 4.0
        end
    end

    @testset "APConic2 / APConicArc2" begin
        @testset "APCircle2" begin
            c = APCircle2(APPoint(1.0, 2.0), 5.0)
            @test area(c) ≈ pi * 25
            @test perimeter(c) ≈ 2pi * 5
            @test APPoint(1.0, 2.0) in c
            @test !(APPoint(100.0, 2.0) in c)
            @test rotate(c, pi / 4, APPoint(0.0, 0.0)).r == c.r
            @test homothety(c, -2.0).r ≈ 2 * c.r
            @test reflection(c, APPoint(0.0, 0.0)).r == c.r

            # center + a point on the circumference, as an alternative to center + r
            c2 = APCircle2(APPoint(1.0, 2.0), APPoint(4.0, 6.0))
            @test c2 == APCircle2(APPoint(1.0, 2.0), 5.0)

            # the circle through 3 points -- same as circumcircle(APTriangle(...))
            p1, p2, p3 = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 3.0)
            c3 = APCircle2(p1, p2, p3)
            @test c3 ≈ circumcircle(APTriangle(p1, p2, p3))
            @test_throws ArgumentError APCircle2(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(2.0, 0.0))  # collinear
        end

        @testset "APEllipse2" begin
            e = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0, 0.4)
            for t in (0.0, 0.7, 2.1, 4.4)
                @test is_on_ellipse(point_on_ellipse(e, t), e; atol=1e-9)
            end
            @test area(e) ≈ pi * 5 * 3
            f1, f2 = foci(e)
            p = point_on_ellipse(e, 0.4)
            @test distance(p, f1) + distance(p, f2) ≈ 2 * e.a atol = 1e-9

            circle_e = APEllipse2(APPoint(0.0, 0.0), 3.0, 3.0)
            @test perimeter(circle_e) ≈ 2 * pi * 3.0 atol = 1e-9

            rot = rotate(e, pi / 6, APPoint(1.0, 1.0))
            @test is_on_ellipse(rotate(p, pi / 6, APPoint(1.0, 1.0)), rot; atol=1e-6)
            hom = homothety(e, -1.5, APPoint(1.0, 1.0))
            @test hom.a ≈ 1.5 * e.a && hom.b ≈ 1.5 * e.b
            @test hom.angle ≈ e.angle
            refl_pt = reflection(e, APPoint(2.0, -3.0))
            @test refl_pt.angle ≈ e.angle
            l = APLine(APPoint(0.0, 0.0), APPoint(1.0, 2.0))
            refl_l = reflection(e, l)
            φ = atan(direction(l)[2], direction(l)[1])
            @test refl_l.angle ≈ 2φ - e.angle
            @test is_on_ellipse(reflection(p, l), refl_l; atol=1e-6)
        end

        @testset "APHyperbola2" begin
            h = APHyperbola2(APPoint(0.0, 0.0), 2.0, 1.0, 0.3)
            for t in (0.5, 1.2), branch in (1, -1)
                @test is_on_hyperbola(point_on_hyperbola(h, t; branch=branch), h; atol=1e-9)
            end
            a1, a2 = asymptotes(h)
            @test distance(h.center, a1) < 1e-9 && distance(h.center, a2) < 1e-9
            @test_throws ArgumentError orthoptic(APHyperbola2(APPoint(0.0, 0.0), 2.0, 5.0))

            rot = rotate(h, pi / 5, APPoint(1.0, 0.0))
            @test rot.angle ≈ h.angle + pi / 5
            hom = homothety(h, -1.5)
            @test hom.a ≈ 1.5 * h.a && hom.angle ≈ h.angle
        end

        @testset "APParabola2" begin
            par = APParabola2(APPoint(0.0, 1.0), APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0)))
            v = vertex(par)
            @test v == APPoint(0.0, 0.0)
            @test focal_parameter(par) == 2.0
            @test is_on_parabola(v, par)
            p = point_on_parabola(par, 3.0)
            @test is_on_parabola(p, par)
            @test orthoptic(par) == par.directrix

            rot = rotate(par, pi / 4, APPoint(1.0, 0.0))
            @test is_on_parabola(rotate(p, pi / 4, APPoint(1.0, 0.0)), rot; atol=1e-6)
        end

        @testset "APCircularArc2" begin
            circ = APCircle2(APPoint(1.0, 2.0), 5.0)
            p1 = circ.center + APVector(5.0, 0.0)
            p2 = circ.center + APVector(0.0, 5.0)
            arc = APCircularArc2(circ, p1, p2)
            @test measure(arc) ≈ pi / 2 atol = 1e-9
            @test arc_length(arc) ≈ 5.0 * pi / 2 atol = 1e-9
            @test point_on_arc(arc, 0.0) ≈ p1
            @test point_on_arc(arc, 1.0) ≈ p2

            # p1/p2 need not lie exactly on circ -- only their angle from
            # circ.center matters, so the constructor projects each onto
            # circ (same angle, radius circ.r). Otherwise anything built
            # directly from the raw arc.p1/arc.p2 (e.g. APCircularSector2's
            # own radii) would visibly disagree with the arc curve itself.
            off_circle_p2 = circ.center + APVector(0.0, 3.0)   # angle 90°, but at distance 3, not 5
            off_arc = APCircularArc2(circ, p1, off_circle_p2)
            @test off_arc.p2 ≈ p2   # snapped onto the circle, same angle as p2 above
            @test distance(circ.center, off_arc.p2) ≈ circ.r
            off_sec = APCircularSector2(off_arc)
            sds = sides(off_sec)
            @test distance(sds[3].p1, sds[3].p2) ≈ circ.r   # the p2-side radius, now the correct length

            about_pt = APPoint(3.0, -1.0)
            refl_pt = reflection(arc, about_pt)
            @test measure(refl_pt) ≈ measure(arc) atol = 1e-9  # point reflection: no swap
            about_line = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
            refl_line = reflection(arc, about_line)
            @test measure(refl_line) ≈ measure(arc) atol = 1e-9  # line reflection: swap restores the sweep
        end

        @testset "APEllipticArc2 (new)" begin
            e2 = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0, 0.2)
            pa = point_on_ellipse(e2, 0.3)
            pb = point_on_ellipse(e2, 1.7)
            earc = APEllipticArc2(e2, pa, pb)
            @test isapprox(point_on_arc(earc, 0.0), pa; atol=1e-6)
            @test isapprox(point_on_arc(earc, 1.0), pb; atol=1e-6)
            for t in (0.0, 0.3, 0.6, 1.0)
                @test is_on_ellipse(point_on_arc(earc, t), e2; atol=1e-6)
            end

            about_pt = APPoint(1.0, 1.0)
            refl_pt = reflection(earc, about_pt)
            @test measure(refl_pt) ≈ measure(earc) atol = 1e-6  # point reflection: no swap

            line_eg = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
            refl_l = reflection(earc, line_eg)
            @test measure(refl_l) ≈ measure(earc) atol = 1e-6
            # like APCircularArc2, a line reflection swaps p1/p2, so the
            # reflected arc's own t corresponds to the ORIGINAL arc's (1-t)
            for t in (0.0, 0.25, 0.5, 0.75, 1.0)
                expected = reflection(point_on_arc(earc, 1 - t), line_eg)
                @test isapprox(point_on_arc(refl_l, t), expected; atol=1e-6)
            end

            rev = reverse(earc)
            @test rev == APEllipticArc2(e2, pb, pa)
            @test reverse(rev) == earc
        end

        @testset "APParabolicArc2 (new)" begin
            par = APParabola2(APPoint(0.0, 1.0), APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0)))
            pa = point_on_parabola(par, -2.0)
            pb = point_on_parabola(par, 3.0)
            parc = APParabolicArc2(par, pa, pb)
            @test isapprox(point_on_arc(parc, 0.0), pa; atol=1e-6)
            @test isapprox(point_on_arc(parc, 1.0), pb; atol=1e-6)

            # open curve: reflection never needs to swap p1/p2 (no complementary
            # arc ambiguity the way a closed conic has)
            about_l = APLine(APPoint(0.0, 0.0), APPoint(1.0, 2.0))
            refl = reflection(parc, about_l)
            for t in (0.0, 0.3, 0.6, 1.0)
                expected = reflection(point_on_arc(parc, t), about_l)
                @test isapprox(point_on_arc(refl, t), expected; atol=1e-6)
            end

            # reverse: same point set, parametrization direction flipped
            # (no complementary-arc ambiguity for an open curve)
            rev = reverse(parc)
            @test rev == APParabolicArc2(par, pb, pa)
            @test isapprox(point_on_arc(rev, 0.0), pb; atol=1e-6)
            @test isapprox(point_on_arc(rev, 1.0), pa; atol=1e-6)
            @test reverse(rev) == parc
        end

        @testset "APHyperbolicArc2 (new)" begin
            h = APHyperbola2(APPoint(0.0, 0.0), 2.0, 1.0, 0.1)
            pa = point_on_hyperbola(h, 0.2; branch=1)
            pb = point_on_hyperbola(h, 1.5; branch=1)
            harc = APHyperbolicArc2(h, pa, pb)
            @test isapprox(point_on_arc(harc, 0.0), pa; atol=1e-6)
            @test isapprox(point_on_arc(harc, 1.0), pb; atol=1e-6)

            # same open-curve argument as the parabolic arc: no swap needed
            about_l = APLine(APPoint(0.0, 0.0), APPoint(1.0, 2.0))
            refl = reflection(harc, about_l)
            for t in (0.0, 0.3, 0.6, 1.0)
                expected = reflection(point_on_arc(harc, t), about_l)
                @test isapprox(point_on_arc(refl, t), expected; atol=1e-6)
            end

            rev = reverse(harc)
            @test rev == APHyperbolicArc2(h, pb, pa)
            @test reverse(rev) == harc
        end
    end

    @testset "APPolygon curved regions" begin
        @testset "APCircularSector2" begin
            circ = APCircle2(APPoint(2.0, -1.0), 5.0)
            p1 = circ.center + APVector(5.0, 0.0)
            θ = 2.3
            p2 = circ.center + APVector(5.0 * cos(θ), 5.0 * sin(θ))
            arc = APCircularArc2(circ, p1, p2)
            sec = APCircularSector2(arc)
            @test area(sec) ≈ 0.5 * 25 * θ atol = 1e-9
            @test perimeter(sec) ≈ 2 * 5 + 5 * θ atol = 1e-9
            @test circ.center in sec
            @test !(circ.center + APVector(20.0, 0.0) in sec)
            @test area(rotate(sec, pi / 3, APPoint(1.0, 1.0))) ≈ area(sec) atol = 1e-6
            @test area(homothety(sec, 2.0)) ≈ 4 * area(sec) atol = 1e-6
            @test area(reflection(sec, APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)))) ≈ area(sec) atol = 1e-6

            # centroid: dedicated closed form (the generic APPolygon one needs
            # `vertices`, which this curved-sided type doesn't implement),
            # verified against a fine-grid numerical centroid in the sanity
            # pass -- here just check it's on the bisector, inside the
            # sector, and closer to the center than the radius.
            cen = centroid(sec)
            @test cen in sec
            @test distance(cen, circ.center) < circ.r
        end

        @testset "APCircularSegment2" begin
            circ = APCircle2(APPoint(2.0, -1.0), 5.0)
            p1 = circ.center + APVector(5.0, 0.0)
            θ = 2.3
            p2 = circ.center + APVector(5.0 * cos(θ), 5.0 * sin(θ))
            arc = APCircularArc2(circ, p1, p2)
            seg = APCircularSegment2(arc)
            @test area(seg) ≈ 0.5 * 25 * (θ - sin(θ)) atol = 1e-9
            @test centroid(seg) in seg
        end

        @testset "APAnnularSector2 (new)" begin
            circ = APCircle2(APPoint(2.0, -1.0), 5.0)
            p1 = circ.center + APVector(5.0, 0.0)
            θ = 2.3
            p2 = circ.center + APVector(5.0 * cos(θ), 5.0 * sin(θ))
            arc = APCircularArc2(circ, p1, p2)
            asec = APAnnularSector2(arc, 2.0)
            @test area(asec) ≈ 0.5 * 25 * θ - 0.5 * 4 * θ atol = 1e-9
            @test perimeter(asec) ≈ (5 * θ) + (2 * θ) + 2 * (5.0 - 2.0) atol = 1e-9
            @test_throws ArgumentError APAnnularSector2(arc, 6.0)
            @test area(rotate(asec, pi / 4, APPoint(0.0, 0.0))) ≈ area(asec) atol = 1e-6

            # annular sector's centroid is farther from the center than the
            # full sector's own (removing the inner mass shifts it outward)
            full_sec = APCircularSector2(arc)
            @test distance(centroid(asec), circ.center) > distance(centroid(full_sec), circ.center)
        end

        @testset "APInterstice2" begin
            # 3 mutually externally tangent unit circles (equilateral centers,
            # side 2 = r_i + r_j), so tangency points and facing minor arcs
            # are exact and independently checkable.
            c1 = APCircle2(APPoint(0.0, 0.0), 1.0)
            c2 = APCircle2(APPoint(2.0, 0.0), 1.0)
            c3 = APCircle2(APPoint(1.0, sqrt(3)), 1.0)
            t12 = APPoint(1.0, 0.0)
            t23 = APPoint(1.5, sqrt(3) / 2)
            t31 = APPoint(0.5, sqrt(3) / 2)
            arc1 = APCircularArc2(c1, t12, t31)
            arc2 = APCircularArc2(c3, t31, t23)
            arc3 = APCircularArc2(c2, t23, t12)
            gap = APInterstice2(arc1, arc2, arc3)
            @test length(sides(gap)) == 3
            expected_area = sqrt(3) - 3 * (0.5 * 1 * (pi / 3))
            @test area(gap) ≈ expected_area atol = 1e-9
            @test perimeter(gap) ≈ 3 * (pi / 3) atol = 1e-9
            @test area(rotate(gap, pi / 5, APPoint(2.0, 3.0))) ≈ area(gap) atol = 1e-9
            @test area(reflection(gap, APPoint(1.0, 1.0))) ≈ area(gap) atol = 1e-9
        end

        @testset "APCurvilinearTriangle2 (new, mixed sides)" begin
            A = APPoint(0.0, 0.0)
            B = APPoint(10.0, 0.0)
            arcAB = APCircularArc2(APCircle2(APPoint(5.0, -8.0), sqrt(5^2 + 8^2)), A, B)
            C = APPoint(5.0, 12.0)
            mixedtri = APCurvilinearTriangle2(APSegment(B, C), APSegment(C, A), arcAB)
            @test length(sides(mixedtri)) == 3
            @test area(mixedtri) > 0
            @test area(rotate(mixedtri, pi / 6, APPoint(0.0, 0.0))) ≈ area(mixedtri) atol = 1e-6
        end

        @testset "APCurvilinearQuadrilateral2 (new, mixed sides)" begin
            A = APPoint(0.0, 0.0)
            B = APPoint(10.0, 0.0)
            C = APPoint(10.0, 10.0)
            D = APPoint(0.0, 10.0)
            arcAB = APCircularArc2(APCircle2(APPoint(5.0, -8.0), sqrt(5^2 + 8^2)), A, B)
            quad = APCurvilinearQuadrilateral2(arcAB, APSegment(B, C), APSegment(C, D), APSegment(D, A))
            @test length(sides(quad)) == 4
            @test area(quad) > 0
            @test area(rotate(quad, pi / 7, APPoint(1.0, 1.0))) ≈ area(quad) atol = 1e-6
        end

        @testset "APCurvilinearNgon2" begin
            circ = APCircle2(APPoint(0.0, 0.0), 5.0)
            p1 = circ.center + APVector(5.0, 0.0)
            p2 = circ.center + APVector(0.0, 5.0)
            arc = APCircularArc2(circ, p1, p2)
            A = APPoint(-5.0, -5.0)
            ngon = APCurvilinearNgon2([APSegment(A, p1), arc, APSegment(p2, A)])
            @test length(sides(ngon)) == 3
            @test area(ngon) > 0
        end

        @testset "APPolyline2" begin
            p0, p1, p2 = APPoint(0.0, 0.0), APPoint(3.0, 0.0), APPoint(3.0, 4.0)
            pl = APPolyline2(p0, p1, p2)
            @test pl == APPolyline2([p0, p1, p2])
            @test vertices(pl) == [p0, p1, p2]
            @test length(pl) == 3
            @test collect(pl) == [p0, p1, p2]
            @test_throws ArgumentError APPolyline2([p0])   # needs >= 2 vertices

            s = sides(pl)
            @test length(s) == 2   # n-1 sides, no closing side
            @test s[1] == APSegment(p0, p1) && s[2] == APSegment(p1, p2)
            @test arc_length(pl) ≈ 3.0 + 4.0

            bb = APBoundingBox(pl)
            @test bb.min == APPoint(0.0, 0.0) && bb.max == APPoint(3.0, 4.0)

            @test reverse(pl) == APPolyline2([p2, p1, p0])
            @test reverse(reverse(pl)) == pl

            rot = rotate(pl, pi / 2, APPoint(0.0, 0.0))
            @test isapprox(rot[1], APPoint(0.0, 0.0); atol=1e-9)
            @test isapprox(rot[2], APPoint(0.0, 3.0); atol=1e-9)
            @test area(APTriangle(p0, p1, p2)) ≈ area(APTriangle(rotate.([p0, p1, p2], pi / 2, APPoint(0.0, 0.0))...))   # sanity: rotate preserves shape
            hom = homothety(pl, 2.0, APPoint(0.0, 0.0))
            @test hom[3] == APPoint(6.0, 8.0)
            refl = reflection(pl, APPoint(0.0, 0.0))
            @test refl[3] == APPoint(-3.0, -4.0)
            tr = translate(pl, APVector(1.0, 1.0))
            @test tr[1] == APPoint(1.0, 1.0)

            @test APPoint(1.5, 0.0) in pl   # midpoint of the first side
            @test APPoint(3.0, 2.0) in pl   # midpoint of the second side
            @test !(APPoint(10.0, 10.0) in pl)
            @test distance(APPoint(0.0, 4.0), pl) ≈ 3.0   # nearest to side 2 (x=3), not side 1
            @test distance(p0, pl) == 0.0
            @test distance(pl, APPoint(-1.0, 0.0)) ≈ 1.0
        end

        @testset "APCurvilinearPolyline2" begin
            circ = APCircle2(APPoint(0.0, 0.0), 5.0)
            p1 = circ.center + APVector(5.0, 0.0)
            p2 = circ.center + APVector(0.0, 5.0)
            arc = APCircularArc2(circ, p1, p2)
            p3 = APPoint(-5.0, 5.0)
            seg = APSegment(p2, p3)
            cpl = APCurvilinearPolyline2([arc, seg])
            @test cpl == APCurvilinearPolyline2([arc, seg])
            @test length(cpl) == 2
            @test collect(cpl) == [arc, seg]
            @test_throws ArgumentError APCurvilinearPolyline2(APCurve[])   # needs >= 1 side
            @test_throws ArgumentError APCurvilinearPolyline2([APSegment(APPoint(0.0, 0.0), APPoint(1.0, 0.0)), APSegment(APPoint(5.0, 5.0), APPoint(6.0, 6.0))])   # sides must connect

            @test arc_length(cpl) ≈ arc_length(arc) + distance(p2, p3)

            bb = APBoundingBox(cpl)
            @test bb.min ≈ APPoint(-5.0, 0.0) atol = 1e-9
            @test bb.max ≈ APPoint(5.0, 5.0) atol = 1e-9

            rcpl = reverse(cpl)
            @test rcpl[1] == reverse(seg) && rcpl[2] == reverse(arc)
            @test reverse(rcpl) == cpl

            tr = translate(cpl, APVector(1.0, 1.0))
            @test tr[1] == translate(arc, APVector(1.0, 1.0))

            @test midpoint(arc) in cpl
            @test !(APPoint(100.0, 100.0) in cpl)
            @test distance(midpoint(seg), cpl) == 0.0
        end
    end

    @testset "APSet unbounded regions" begin
        @testset "APAngle2" begin
            vertex = APPoint(1.0, 1.0)
            a = APPoint(3.0, 1.0)
            b = APPoint(1.0, 3.0)
            ang = APAngle2(vertex, a, b)
            @test measure(ang) ≈ pi / 2 atol = 1e-9
            @test normalized_measure(ang) ≈ pi / 2 atol = 1e-9
            @test abs(ang) ≈ pi / 2 atol = 1e-9
            @test is_direct(ang)

            # rotate(obj, ang::APAngle2, ...) == rotate(obj, measure(ang), ...)
            # -- lets ang's own measure drive a rotation directly, without
            # unwrapping it by hand; not to be confused with
            # rotate(ang::APAngle2, angle::Real, center), which rotates ang
            # itself as a shape (tested separately below via `rot`)
            @test rotate(APPoint(5.0, 5.0), ang, APPoint(2.0, 3.0)) ==
                  rotate(APPoint(5.0, 5.0), measure(ang), APPoint(2.0, 3.0))
            @test rotate(APPoint(5.0, 5.0), ang) == rotate(APPoint(5.0, 5.0), measure(ang))   # default center
            axis = APLine(APPoint(0.0, 0.0, 0.0), APPoint(0.0, 0.0, 1.0))
            @test rotate(APPoint(5.0, 5.0, 1.0), ang, axis) == rotate(APPoint(5.0, 5.0, 1.0), measure(ang), axis)
            @test (vertex + APVector(1.0, 1.0)) in ang
            @test !((vertex + APVector(-1.0, 0.0)) in ang)

            l = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
            refl_l = reflection(ang, l)
            @test measure(refl_l) ≈ measure(ang) atol = 1e-9  # swap convention: sign preserved
            refl_p = reflection(ang, APPoint(0.0, 0.0))
            @test measure(refl_p) ≈ measure(ang) atol = 1e-9

            # the invariant that actually matters for a *region*: point
            # membership must commute with every transform.
            pts = [vertex + APVector(dx, dy) for dx in -2:0.5:2 for dy in -2:0.5:2]
            rot = rotate(ang, 0.7, APPoint(2.0, 3.0))
            @test all(p -> (p in ang) == (rotate(p, 0.7, APPoint(2.0, 3.0)) in rot), pts)
            hom = homothety(ang, -1.5, APPoint(2.0, 3.0))
            @test all(p -> (p in ang) == (homothety(p, -1.5, APPoint(2.0, 3.0)) in hom), pts)
            @test all(p -> (p in ang) == (reflection(p, l) in refl_l), pts)
            @test all(p -> (p in ang) == (reflection(p, APPoint(0.0, 0.0)) in refl_p), pts)
        end

        @testset "APHalfPlane2" begin
            l2 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
            hp = APHalfPlane2(l2, 1)
            @test APPoint(0.0, 1.0) in hp
            @test !(APPoint(0.0, -1.0) in hp)
            @test APPoint(5.0, 0.0) in hp  # boundary counts as inside
            @test APHalfPlane2(l2, APPoint(3.0, 5.0)) == hp
            @test_throws ArgumentError APHalfPlane2(l2, APPoint(3.0, 0.0))  # on the boundary

            grid = [APPoint(x, y) for x in -3.0:0.5:3.0 for y in -3.0:0.5:3.0]
            rot = rotate(hp, pi / 2, APPoint(0.0, 0.0))
            @test all(p -> (p in hp) == (rotate(p, pi / 2, APPoint(0.0, 0.0)) in rot), grid)
            hom_pos = homothety(hp, 2.0, APPoint(1.0, 1.0))
            @test all(p -> (p in hp) == (homothety(p, 2.0, APPoint(1.0, 1.0)) in hom_pos), grid)
            hom_neg = homothety(hp, -1.0, APPoint(0.0, 0.0))
            @test all(p -> (p in hp) == (homothety(p, -1.0, APPoint(0.0, 0.0)) in hom_neg), grid)
            mirror = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
            refl_l = reflection(hp, mirror)
            @test all(p -> (p in hp) == (reflection(p, mirror) in refl_l), grid)
            refl_p = reflection(hp, APPoint(2.0, 2.0))
            @test all(p -> (p in hp) == (reflection(p, APPoint(2.0, 2.0)) in refl_p), grid)
        end

        @testset "APStrip2" begin
            lineA = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
            lineB = APLine(APPoint(0.0, 3.0), APPoint(1.0, 3.0))
            strip = APStrip2(lineA, lineB)
            @test strip_width(strip) ≈ 3.0 atol = 1e-9
            @test APPoint(0.0, 1.5) in strip
            @test !(APPoint(0.0, -1.0) in strip)
            @test !(APPoint(0.0, 4.0) in strip)
            @test APPoint(0.0, 0.0) in strip  # boundary counts as inside
            @test_throws ArgumentError APStrip2(lineA, APLine(APPoint(0.0, 0.0), APPoint(0.0, 1.0)))

            grid = [APPoint(x, y) for x in -3.0:0.5:3.0 for y in -3.0:0.5:3.0]
            rot = rotate(strip, pi / 2, APPoint(0.0, 0.0))
            @test all(p -> (p in strip) == (rotate(p, pi / 2, APPoint(0.0, 0.0)) in rot), grid)
            hom = homothety(strip, -1.0, APPoint(0.0, 0.0))
            @test all(p -> (p in strip) == (homothety(p, -1.0, APPoint(0.0, 0.0)) in hom), grid)
            mirror = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
            refl_l = reflection(strip, mirror)
            @test all(p -> (p in strip) == (reflection(p, mirror) in refl_l), grid)
            refl_p = reflection(strip, APPoint(1.0, 1.0))
            @test all(p -> (p in strip) == (reflection(p, APPoint(1.0, 1.0)) in refl_p), grid)
            @test strip_width(rotate(strip, 0.4, APPoint(0.0, 0.0))) ≈ strip_width(strip) atol = 1e-9
            @test strip_width(homothety(strip, 2.0, APPoint(0.0, 0.0))) ≈ 2 * strip_width(strip) atol = 1e-9
        end
    end

    @testset "APAffineMap" begin
        src = (APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
        dst = (APPoint(2.0, 3.0), APPoint(5.0, 3.0), APPoint(2.0, 7.0))
        m = affine_map(src, dst)
        for (s, d) in zip(src, dst)
            @test isapprox(m(s), d; atol=1e-9)
        end
        p1, p2, p3 = APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(1.0, 0.0)
        @test_throws ArgumentError affine_map((p1, p2, p3), (p1, p2, p3))  # collinear source

        v = APVector(3.0, -2.0)
        p = APPoint(1.0, 1.0)
        tmap = translation_map(v)
        @test isapprox(tmap(p), p + v; atol=1e-9)

        rmap = rotation_map(pi / 3, APPoint(1.0, 1.0))
        @test isapprox(rmap(p), rotate(p, pi / 3, APPoint(1.0, 1.0)); atol=1e-9)

        hmap = homothety_map(2.5, APPoint(1.0, 1.0))
        @test isapprox(hmap(p), homothety(p, 2.5, APPoint(1.0, 1.0)); atol=1e-9)

        l = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
        rfmap = reflection_map(l)
        @test isapprox(rfmap(p), reflection(p, l); atol=1e-9)

        comp = rmap ∘ tmap
        @test isapprox(comp(p), rmap(tmap(p)); atol=1e-9)

        seg = APSegment(APPoint(0.0, 0.0), APPoint(2.0, 0.0))
        @test isapprox(rmap(seg), APSegment(rmap(seg.p1), rmap(seg.p2)); atol=1e-9)
        tri = APTriangle(APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(0.0, 2.0))
        @test area(hmap(tri)) ≈ 2.5^2 * area(tri) atol = 1e-6
        ang = APAngle2(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
        @test isapprox(rmap(ang), APAngle2(rmap(ang.vertex), rmap(ang.a), rmap(ang.b)); atol=1e-9)

        # circle -> ellipse (only conformal affine maps keep a circle a circle)
        c = APCircle2(APPoint(0.0, 0.0), 1.0)
        shear = APAffineMap(1.0, 0.5, 0.0, 1.0, 0.0, 0.0)
        ell = shear(c)
        @test ell isa APEllipse2
        circle_as_ellipse = APEllipse2(c.center, c.r, c.r, 0.0)
        for t in (0.0, 0.3, 1.1, 2.5, 4.0)
            @test is_on_ellipse(shear(point_on_ellipse(circle_as_ellipse, t)), ell; atol=1e-6)
        end

        # APVector transforms by the linear part only, no translation
        vec = APVector(1.0, 0.0)
        @test isapprox(rmap(vec), APVector(cos(pi / 3), sin(pi / 3)); atol=1e-9)
        @test isapprox(tmap(vec), vec; atol=1e-9)

        # translation_map also accepts an APVector directly now, not just APPoint
        vvec = APVector(3.0, -2.0)
        @test isapprox(translation_map(vvec)(p), translation_map(v)(p); atol=1e-9)
    end

    # Single-argument ("curried") forms, for `|>`/`∘`/`map`/`filter`
    # composition without needing a shape to already be in hand. Two
    # deliberately distinct families, same tradeoff explained on
    # translate(::APVector)'s own docstring:
    #   - translate/rotate/homothety/reflection (1-arg): plain functions,
    #     each just `shape -> translate(shape, v)` etc. -- preserve
    #     whatever specific type the direct 2-/3-arg call already returns
    #     (a circle stays a circle), but composing two with `∘` builds
    #     another plain function (a chain of exact calls), not one
    #     combined, reusable object.
    #   - translation_map/rotation_map/homothety_map/reflection_map:
    #     genuine APAffineMap values -- composable into ONE combined map
    #     (computed once, reapplied cheaply), but necessarily generic, so
    #     e.g. a circle piped through one always comes back as an
    #     APEllipse2, never APCircle2 (nothing in the map's own type says
    #     it happens to be conformal).
    # invert/invert_neg return a plain closure too (same family as
    # translate/rotate/etc. here), since circle inversion isn't an affine
    # map at all -- there's no APAffineMap-based alternative for it.
    @testset "curried transform/predicate forms" begin
        t = APTriangle(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 3.0))
        O = APPoint(0.0, 0.0)
        c = APCircle2(APPoint(1.0, 2.0), 5.0)

        # type-preserving 1-arg forms: exact match with the direct call,
        # and crucially preserve APCircle2 (unlike the *_map versions below)
        v = APVector(3.0, -1.0)
        @test translate(v)(t) == translate(t, v)
        @test translate(v)(c) == translate(c, v)
        @test translate(v)(c) isa APCircle2

        @test rotate(pi / 2)(t) == rotate(t, pi / 2)
        @test rotate(pi / 3, APPoint(1.0, 1.0))(t) == rotate(t, pi / 3, APPoint(1.0, 1.0))
        @test rotate(pi / 2)(c) isa APCircle2

        @test homothety(2.0)(t) == homothety(t, 2.0)
        @test homothety(2.0, APPoint(1.0, 1.0))(t) == homothety(t, 2.0, APPoint(1.0, 1.0))
        @test homothety(2.0)(c) isa APCircle2

        about_pt = APPoint(2.0, 2.0)
        @test reflection(about_pt)(t) == reflection(t, about_pt)
        l = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
        @test reflection(l)(t) == reflection(t, l)
        @test reflection(about_pt)(c) isa APCircle2

        # composing type-preserving forms with ∘ builds a plain Function
        # (a chain of exact calls), not an APAffineMap
        composed = rotate(pi / 2) ∘ translate(v)
        @test composed isa Function && !(composed isa APAffineMap)
        @test composed(t) == rotate(translate(t, v), pi / 2)
        @test t |> translate(v) |> rotate(pi / 2) == composed(t)
        @test composed(c) isa APCircle2   # exact through the whole chain
        mapped = map(translate(v), [t, t])
        @test mapped[1] == translate(t, v) && mapped[2] == translate(t, v)

        # isapprox, not ==: APAffineMap application and the direct per-type
        # rotate/homothety/etc. use different (both correct) arithmetic
        # sequences, so results can differ in the last bit or two.
        @test isapprox(rotation_map(pi / 2, O)(t), rotate(t, pi / 2); atol=1e-9)
        @test rotation_map(pi / 2, O) isa APAffineMap
        @test isapprox(rotation_map(pi / 3, APPoint(1.0, 1.0))(t), rotate(t, pi / 3, APPoint(1.0, 1.0)); atol=1e-9)

        @test isapprox(homothety_map(2.0, O)(t), homothety(t, 2.0); atol=1e-9)
        @test homothety_map(2.0, O) isa APAffineMap
        @test isapprox(homothety_map(2.0, APPoint(1.0, 1.0))(t), homothety(t, 2.0, APPoint(1.0, 1.0)); atol=1e-9)

        @test isapprox(translation_map(v)(t), translate(t, v); atol=1e-9)
        @test translation_map(v) isa APAffineMap

        @test isapprox(reflection_map(about_pt)(t), reflection(t, about_pt); atol=1e-9)
        @test reflection_map(about_pt) isa APAffineMap
        @test isapprox(reflection_map(l)(t), reflection(t, l); atol=1e-9)

        # composition: a single combined APAffineMap, not a chain of closures
        composed_map = rotation_map(pi / 2, O) ∘ translation_map(v)
        @test composed_map isa APAffineMap
        @test isapprox(composed_map(t), rotate(translate(t, v), pi / 2); atol=1e-9)
        @test isapprox(t |> translation_map(v) |> rotation_map(pi / 2, O), composed_map(t); atol=1e-9)
        @test translation_map(v)(c) isa APEllipse2   # the generic-map tradeoff, unlike translate(v)(c) above
        mapped_map = map(rotation_map(pi / 2, O), [t, t])
        @test isapprox(mapped_map[1], rotate(t, pi / 2); atol=1e-9) && isapprox(mapped_map[2], rotate(t, pi / 2); atol=1e-9)

        center = APPoint(0.0, 0.0)
        l_offset = APLine(APPoint(2.0, 0.0), APPoint(2.0, 1.0))  # doesn't pass through center
        @test invert(center; k=3.0)(l_offset) == invert(l_offset, center; k=3.0)
        @test invert(center) isa Function && !(invert(center) isa APAffineMap)
        @test invert_neg(center; k=3.0)(l_offset) == invert_neg(l_offset, center; k=3.0)

        p_off = APPoint(2.0, 3.0)
        lx = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
        @test projection(lx)(p_off) == projection(p_off, lx)
        @test projection(lx; angle=pi / 4)(p_off) == projection(p_off, lx; angle=pi / 4)

        s = APSegment(APPoint(0.0, 0.0), APPoint(4.0, 0.0))
        r = APRay(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
        mid = APPoint(2.0, 0.0)
        @test on_line(lx)(mid) == on_line(mid, lx)
        @test on_segment(s)(mid) == on_segment(mid, s)
        @test on_ray(r)(mid) == on_ray(mid, r)
        @test filter(on_line(lx), [mid, APPoint(1.0, 1.0)]) == [mid]

        # Base's own generic Fix2 currying already covers `in` for free --
        # no code of ours needed for `in(shape)` to work
        @test in(t) isa Base.Fix2
        @test in(t)(APPoint(1.0, 1.0)) == (APPoint(1.0, 1.0) in t)
    end

    @testset "AP predicates" begin
        a, b, c = APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(1.0, 0.0)
        @test is_collinear(a, b, c)
        @test !is_collinear(a, b, APPoint(1.0, 1.0))

        l = APLine(APPoint(0.0, 0.0), APPoint(2.0, 0.0))
        @test on_line(APPoint(5.0, 0.0), l)
        @test !on_line(APPoint(5.0, 1.0), l)

        s = APSegment(APPoint(0.0, 0.0), APPoint(2.0, 0.0))
        @test on_segment(APPoint(1.0, 0.0), s)
        @test !on_segment(APPoint(5.0, 0.0), s)

        @test side_of_line(APPoint(1.0, 1.0), l) == 1
        @test side_of_line(APPoint(1.0, -1.0), l) == -1
        @test side_of_line(APPoint(1.0, 0.0), l) == 0

        t = APTriangle(a, b, c)
        @test is_degenerate(t)
        @test !is_degenerate(APTriangle(a, b, APPoint(1.0, 1.0)))

        circ = APCircle2(APPoint(0.0, 0.0), 5.0)
        @test line_circle_position(APLine(APPoint(0.0, 10.0), APPoint(1.0, 10.0)), circ) == :disjoint
        @test line_circle_position(APLine(APPoint(0.0, 5.0), APPoint(1.0, 5.0)), circ) == :tangent
        @test line_circle_position(l, circ) == :secant

        c2 = APCircle2(APPoint(10.0, 0.0), 5.0)
        @test circles_position(circ, c2) == :tangent_ext
        @test circles_position(circ, APCircle2(APPoint(0.0, 0.0), 5.0)) == :identical
        @test circles_position(circ, APCircle2(APPoint(0.0, 0.0), 3.0)) == :concentric
        @test circles_position(circ, APCircle2(APPoint(100.0, 0.0), 5.0)) == :disjoint_ext
        @test circles_position(circ, APCircle2(APPoint(2.0, 0.0), 3.0)) == :tangent_int
        @test circles_position(circ, APCircle2(APPoint(1.0, 0.0), 1.0)) == :disjoint_int

        # is_parallel/is_perpendicular need no new methods (already
        # untyped/duck-typed in predicates.jl, dispatching via `direction`)
        @test is_parallel(APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0)), APLine(APPoint(0.0, 1.0), APPoint(1.0, 1.0)))
        @test is_perpendicular(APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0)), APLine(APPoint(0.0, 0.0), APPoint(0.0, 1.0)))
    end

    @testset "AP intersections" begin
        l1 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
        l2 = APLine(APPoint(0.0, -1.0), APPoint(0.0, 1.0))
        @test intersection(l1, l2) == [APPoint(0.0, 0.0)]
        l3 = APLine(APPoint(0.0, 1.0), APPoint(1.0, 1.0))
        @test isempty(intersection(l1, l3))  # parallel

        circ = APCircle2(APPoint(0.0, 0.0), 5.0)
        lsecant = APLine(APPoint(-10.0, 0.0), APPoint(10.0, 0.0))
        pts = intersection(lsecant, circ)
        @test length(pts) == 2
        @test all(p -> isapprox(distance(p, circ.center), 5.0; atol=1e-9), pts)
        ltangent = APLine(APPoint(-10.0, 5.0), APPoint(10.0, 5.0))
        @test intersection(ltangent, circ) == [APPoint(0.0, 5.0)]
        ldisjoint = APLine(APPoint(-10.0, 10.0), APPoint(10.0, 10.0))
        @test isempty(intersection(ldisjoint, circ))
        @test intersection(circ, lsecant) == intersection(lsecant, circ)

        s1 = APSegment(APPoint(0.0, -1.0), APPoint(0.0, 1.0))
        s2 = APSegment(APPoint(-1.0, 0.0), APPoint(1.0, 0.0))
        @test intersection(s1, s2) == [APPoint(0.0, 0.0)]
        s3 = APSegment(APPoint(2.0, -1.0), APPoint(2.0, 1.0))
        @test isempty(intersection(s2, s3))  # would cross as lines, not as segments

        c1 = APCircle2(APPoint(0.0, 0.0), 5.0)
        c2 = APCircle2(APPoint(8.0, 0.0), 5.0)
        cpts = intersection(c1, c2)
        @test length(cpts) == 2
        @test all(p -> isapprox(distance(p, c1.center), 5.0; atol=1e-9) && isapprox(distance(p, c2.center), 5.0; atol=1e-9), cpts)

        c3 = APCircle2(APPoint(10.0, 0.0), 5.0)
        @test length(intersection(c1, c3)) == 1  # externally tangent

        c4 = APCircle2(APPoint(0.0, 0.0), 3.0)
        @test isempty(intersection(c1, c4))  # concentric

        sq = APQuadrilateral(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 4.0), APPoint(0.0, 4.0))
        @test isapprox(diagonal_intersection(sq), APPoint(2.0, 2.0); atol=1e-9)
        degenerate = APQuadrilateral(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(3.0, 0.0), APPoint(1.0, 0.0))
        @test diagonal_intersection(degenerate) === nothing
    end

    @testset "AP constructions and tangency" begin
        @test isapprox(polar_point(5.0, pi / 2, APPoint(1.0, 1.0)), APPoint(1.0, 6.0); atol=1e-9)
        @test isapprox(polar_point_deg(5.0, 90.0, APPoint(1.0, 1.0)), APPoint(1.0, 6.0); atol=1e-9)

        pts = [APPoint(0.0, 0.0), APPoint(4.0, 0.0)]
        @test isapprox(barycenter(pts, [1.0, 1.0]), APPoint(2.0, 0.0); atol=1e-9)

        l = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
        p = APPoint(3.0, 3.0)
        pl = parallel_through(l, p)
        @test is_parallel(pl, l)
        pp = perpendicular_through(l, p)
        @test is_perpendicular(pp, l)

        pb = perpendicular_bisector(APPoint(0.0, 0.0), APPoint(4.0, 0.0))
        @test on_line(APPoint(2.0, 0.0), pb)
        @test is_perpendicular(pb, APLine(APPoint(0.0, 0.0), APPoint(4.0, 0.0)))
        @test perpendicular_bisector(APSegment(APPoint(0.0, 0.0), APPoint(4.0, 0.0))) == pb

        l1 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
        l2 = APLine(APPoint(0.0, 0.0), APPoint(0.0, 1.0))
        bisectors = angle_bisectors(l1, l2)
        @test length(bisectors) == 2
        @test all(b -> isapprox(abs(angle_between(direction(l1), direction(b))), pi / 4; atol=1e-6) ||
                       isapprox(abs(angle_between(direction(l1), direction(b))), 3pi / 4; atol=1e-6), bisectors)

        tris = angle_trisectors(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
        @test length(tris) == 2

        gr = golden_ratio_point(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
        @test gr[1] ≈ 1 / Base.MathConstants.golden atol = 1e-9
        @test golden_ratio_point(APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))) == gr

        a, b = APPoint(0.0, 0.0), APPoint(4.0, 0.0)
        q = harmonic_conjugate(a, b, APPoint(1.0, 0.0))
        cr = ((1.0 - a[1]) / (1.0 - b[1])) / ((q[1] - a[1]) / (q[1] - b[1]))
        @test cr ≈ -1.0 atol = 1e-6
        @test_throws ArgumentError harmonic_conjugate(a, b, midpoint(a, b))

        ac = apollonius_circle(APPoint(0.0, 0.0), APPoint(4.0, 0.0), 2.0)
        testpt = point_on_ellipse(APEllipse2(ac.center, ac.r, ac.r, 0.0), 0.7)
        @test distance(testpt, APPoint(0.0, 0.0)) / distance(testpt, APPoint(4.0, 0.0)) ≈ 2.0 atol = 1e-6
        @test_throws ArgumentError apollonius_circle(APPoint(0.0, 0.0), APPoint(4.0, 0.0), 1.0)

        c = APCircle2(APPoint(0.0, 0.0), 5.0)
        extp = APPoint(13.0, 0.0)
        @test tangent_length(c, extp) ≈ 12.0 atol = 1e-9
        tps = tangent_points(c, extp)
        @test length(tps) == 2
        @test all(pt -> isapprox(distance(pt, c.center), 5.0; atol=1e-9), tps)
        @test all(pt -> isapprox(dot(pt - extp, pt - c.center), 0.0; atol=1e-6), tps)

        tls = tangent_lines(c, extp)
        @test length(tls) == 2

        lhoriz = APLine(APPoint(-10.0, 3.0), APPoint(10.0, 3.0))
        tpar = tangent_parallel(c, lhoriz)
        @test all(tl -> is_parallel(tl, lhoriz), tpar)
        @test all(tl -> line_circle_position(tl, c) == :tangent, tpar)

        c1 = APCircle2(APPoint(0.0, 0.0), 3.0)
        c2 = APCircle2(APPoint(10.0, 0.0), 2.0)
        esc = external_similitude_center(c1, c2)
        @test is_collinear(c1.center, c2.center, esc)
        isc = internal_similitude_center(c1, c2)
        @test on_segment(isc, APSegment(c1.center, c2.center))
        @test_throws ArgumentError external_similitude_center(APCircle2(APPoint(0.0, 0.0), 3.0), APCircle2(APPoint(1.0, 0.0), 3.0))

        etl = external_tangent_lines(c1, c2)
        @test length(etl) == 2
        @test all(l -> line_circle_position(l, c1) == :tangent && line_circle_position(l, c2) == :tangent, etl)

        itl = internal_tangent_lines(c1, c2)
        @test length(itl) == 2
        @test all(l -> line_circle_position(l, c1) == :tangent && line_circle_position(l, c2) == :tangent, itl)

        ol = offset_line(APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0)), 3.0)
        @test distance(APPoint(0.0, 0.0), ol) ≈ 3.0 atol = 1e-9

        # non-parallel lines: 4 solutions expected (parallel lines are a
        # documented degenerate case returning empty, not tested here)
        tcr = tangent_circles_with_radius(l1, l2, 3.0)
        @test length(tcr) == 4
        @test all(cc -> isapprox(cc.r, 3.0; atol=1e-9) &&
                        line_circle_position(l1, cc) == :tangent && line_circle_position(l2, cc) == :tangent, tcr)

        lc_case = tangent_circles_with_radius(l1, c, 1.0)
        @test all(cc -> isapprox(cc.r, 1.0; atol=1e-9) &&
                        line_circle_position(l1, cc) == :tangent && circles_position(c, cc) in (:tangent_ext, :tangent_int), lc_case)

        cc_case = tangent_circles_with_radius(c1, c2, 1.0)
        @test all(cc -> isapprox(cc.r, 1.0; atol=1e-9) &&
                        circles_position(c1, cc) in (:tangent_ext, :tangent_int) &&
                        circles_position(c2, cc) in (:tangent_ext, :tangent_int), cc_case)
    end

    @testset "AP radical axis and inversion" begin
        c1 = APCircle2(APPoint(0.0, 0.0), 5.0)
        c2 = APCircle2(APPoint(8.0, 0.0), 5.0)
        @test power_of_point(APPoint(5.0, 0.0), c1) ≈ 0.0 atol = 1e-9
        @test power_of_point(c1.center, c1) ≈ -25.0 atol = 1e-9

        ra = radical_axis(c1, c2)
        @test all(p -> on_line(p, ra; atol=1e-6), intersection(c1, c2))
        @test is_perpendicular(ra, APLine(c1.center, c2.center))
        @test_throws ArgumentError radical_axis(c1, APCircle2(APPoint(0.0, 0.0), 2.0))

        c3 = APCircle2(APPoint(4.0, 10.0), 3.0)
        rc = radical_center(c1, c2, c3)
        @test power_of_point(rc, c1) ≈ power_of_point(rc, c2) atol = 1e-6
        @test power_of_point(rc, c2) ≈ power_of_point(rc, c3) atol = 1e-6

        c4 = APCircle2(APPoint(4.0, 20.0), 3.0)
        rcirc = radical_circle(c1, c2, c4)
        @test rcirc.r^2 ≈ power_of_point(radical_center(c1, c2, c4), c1) atol = 1e-6

        c = APCircle2(APPoint(0.0, 0.0), 5.0)
        p = APPoint(10.0, 0.0)
        pinv = inversion(p, c)
        @test distance(p, c.center) * distance(pinv, c.center) ≈ 25.0 atol = 1e-9
        @test isapprox(pinv, APPoint(2.5, 0.0); atol=1e-9)
        @test isapprox(inversion(pinv, c), p; atol=1e-9)  # involution
        @test_throws ArgumentError inversion(c.center, c)

        l = APLine(APPoint(10.0, -5.0), APPoint(10.0, 5.0))
        circ_img = invert(l, APPoint(0.0, 0.0); k=5.0)
        @test circ_img isa APCircle2
        @test isapprox(distance(APPoint(0.0, 0.0), circ_img.center), circ_img.r; atol=1e-6)
        testp_inv = inversion(APPoint(10.0, 3.0), c)
        @test isapprox(distance(testp_inv, circ_img.center), circ_img.r; atol=1e-6)
        @test_throws ArgumentError invert(APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)), APPoint(0.0, 0.0))

        ccirc = APCircle2(APPoint(10.0, 0.0), 5.0)
        @test invert(ccirc, APPoint(0.0, 0.0); k=5.0) isa APCircle2
        ccirc2 = APCircle2(APPoint(5.0, 0.0), 5.0)  # passes through center
        @test invert(ccirc2, APPoint(0.0, 0.0); k=5.0) isa APLine

        seg_through = APSegment(APPoint(1.0, 1.0), APPoint(-1.0, -1.0))
        @test invert(seg_through, APPoint(0.0, 0.0); k=5.0) isa APSegment
        seg_off = APSegment(APPoint(10.0, -2.0), APPoint(10.0, 2.0))
        arcimg = invert(seg_off, APPoint(0.0, 0.0); k=5.0)
        @test arcimg isa APCircularArc2
        @test !Apollonius._arc_sweep_contains(arcimg, APPoint(0.0, 0.0))

        pneg = inversion_neg(p, c)
        @test isapprox(pneg, reflection(pinv, c.center); atol=1e-9)
        @test invert_neg(l, APPoint(0.0, 0.0); k=5.0) isa APCircle2

        pl = polar_line(c, APPoint(10.0, 0.0))
        @test is_perpendicular(pl, APLine(c.center, APPoint(10.0, 0.0)))
        @test on_line(inversion(APPoint(10.0, 0.0), c), pl)
        @test polar_line(c, c.center) === nothing

        pole_pt = pole(c, pl)
        @test isapprox(pole_pt, APPoint(10.0, 0.0); atol=1e-6)
        @test_throws ArgumentError pole(c, APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)))
    end

    @testset "AP Apollonius and interstices" begin
        tangent_to_line(c, l; atol=1e-6) = isapprox(distance(c.center, l), c.r; atol=atol)
        function tangent_to_circle(c, other; atol=1e-6)
            d = distance(c.center, other.center)
            isapprox(d, c.r + other.r; atol=atol) || isapprox(d, abs(c.r - other.r); atol=atol)
        end

        a, b = APPoint(0.0, 0.0), APPoint(4.0, 0.0)
        l = APLine(APPoint(0.0, -5.0), APPoint(1.0, -5.0))
        sols = tangent_circles_through_points(a, b, l)
        @test length(sols) >= 1
        @test all(s -> isapprox(distance(s.center, a), s.r; atol=1e-6) &&
                       isapprox(distance(s.center, b), s.r; atol=1e-6) && tangent_to_line(s, l), sols)
        @test tangent_circles_through_points(l, a, b) == sols

        cpp = APCircle2(APPoint(10.0, 0.0), 3.0)
        sols2 = tangent_circles_through_points(a, b, cpp)
        @test all(s -> isapprox(distance(s.center, a), s.r; atol=1e-6) &&
                       isapprox(distance(s.center, b), s.r; atol=1e-6) && tangent_to_circle(s, cpp), sols2)

        l1 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
        l2 = APLine(APPoint(0.0, 0.0), APPoint(0.0, 1.0))
        p = APPoint(3.0, 3.0)
        sols3 = tangent_circles_through_point(l1, l2, p)
        @test length(sols3) == 2
        @test all(s -> isapprox(distance(s.center, p), s.r; atol=1e-6) &&
                       tangent_to_line(s, l1) && tangent_to_line(s, l2), sols3)

        c1 = APCircle2(APPoint(0.0, 0.0), 3.0)
        c2 = APCircle2(APPoint(10.0, 0.0), 3.0)
        p2 = APPoint(5.0, 5.0)
        sols4 = tangent_circles_through_point(c1, c2, p2)
        @test length(sols4) == 4
        @test all(s -> isapprox(distance(s.center, p2), s.r; atol=1e-6) &&
                       tangent_to_circle(s, c1) && tangent_to_circle(s, c2), sols4)
        @test tangent_circles_through_point(c2, c1, p2) isa Vector

        sols5 = tangent_circles_through_point(l1, c1, p2)
        @test all(s -> isapprox(distance(s.center, p2), s.r; atol=1e-6) &&
                       tangent_to_line(s, l1) && tangent_to_circle(s, c1), sols5)
        @test tangent_circles_through_point(c1, l1, p2) == sols5

        cbig = APCircle2(APPoint(3.0, 3.0), 1.0)
        sols6 = tangent_circles(l1, l2, cbig)
        @test length(sols6) == 4
        @test all(s -> tangent_to_line(s, l1) && tangent_to_line(s, l2) && tangent_to_circle(s, cbig), sols6)
        @test tangent_circles(cbig, l1, l2) == sols6

        cc1 = APCircle2(APPoint(0.0, 3.0), 1.0)
        cc2 = APCircle2(APPoint(10.0, 3.0), 1.0)
        lbase = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
        sols7 = tangent_circles(cc1, cc2, lbase)
        @test length(sols7) == 6
        @test all(s -> tangent_to_circle(s, cc1) && tangent_to_circle(s, cc2) && tangent_to_line(s, lbase), sols7)
        @test tangent_circles(lbase, cc1, cc2) == sols7

        ca = APCircle2(APPoint(0.0, 0.0), 2.0)
        cb = APCircle2(APPoint(6.0, 0.0), 2.0)
        cc = APCircle2(APPoint(3.0, 5.0), 2.0)
        sols8 = tangent_circles(ca, cb, cc)
        @test length(sols8) == 8
        @test all(s -> tangent_to_circle(s, ca) && tangent_to_circle(s, cb) && tangent_to_circle(s, cc), sols8)

        # interstices: chain of 3 mutually externally tangent unit circles
        u1 = APCircle2(APPoint(0.0, 0.0), 1.0)
        u2 = APCircle2(APPoint(2.0, 0.0), 1.0)
        u3 = APCircle2(APPoint(1.0, sqrt(3)), 1.0)
        gaps = interstices(u1, u2, u3)
        @test length(gaps) == 1
        @test area(gaps[1]) ≈ sqrt(3) - 3 * (0.5 * 1 * (pi / 3)) atol = 1e-6

        # interstices: one circle enclosing the other two (2 gaps)
        R, r1, r2 = 10.0, 3.0, 4.0
        D1, D2 = R - r1, R - r2
        θ = acos((D1^2 + D2^2 - (r1 + r2)^2) / (2 * D1 * D2))
        big = APCircle2(APPoint(0.0, 0.0), R)
        small1 = APCircle2(APPoint(D1, 0.0), r1)
        small2 = APCircle2(APPoint(D2 * cos(θ), D2 * sin(θ)), r2)
        gaps2 = interstices(big, small1, small2)
        @test length(gaps2) == 2
        @test all(g -> area(g) > 0, gaps2)

        @test_throws ArgumentError interstices(
            APCircle2(APPoint(0.0, 0.0), 1.0), APCircle2(APPoint(5.0, 0.0), 1.0), APCircle2(APPoint(0.0, 5.0), 1.0))
    end

    @testset "AP named polygons, triangle-on-segment, conic fit" begin
        a, b, c = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(5.0, 3.0)
        pg = parallelogram(a, b, c)
        @test isapprox(pg.d, a + (c - b); atol=1e-9)
        @test is_parallel(APSegment(pg.a, pg.b), APSegment(pg.d, pg.c))

        sq = square_on_segment(a, b)
        @test all(s -> isapprox(distance(s.p1, s.p2), 4.0; atol=1e-9), sides(sq))
        @test area(sq) ≈ 16.0 atol = 1e-9
        @test sq != square_on_segment(a, b; ccw=false)

        rect = rectangle_on_segment(a, b, 2.0)
        @test area(rect) ≈ 8.0 atol = 1e-9

        pent = regular_polygon(APPoint(0.0, 0.0), APPoint(1.0, 0.0), 5)
        ss = [distance(s.p1, s.p2) for s in sides(pent)]
        @test all(l -> isapprox(l, ss[1]; atol=1e-6), ss)
        @test all(v -> isapprox(norm(v), 1.0; atol=1e-9), vertices(pent))
        @test_throws ArgumentError regular_polygon(APPoint(0.0, 0.0), APPoint(1.0, 0.0), 2)

        p1, p2 = APPoint(0.0, 0.0), APPoint(4.0, 0.0)
        eqt = equilateral_triangle_on_segment(p1, p2)
        @test isapprox(distance(p2, eqt.c), 4.0; atol=1e-6) && isapprox(distance(eqt.c, p1), 4.0; atol=1e-6)

        iso = isosceles_triangle_on_segment(p1, p2, 5.0)
        @test isapprox(distance(p1, iso.c), 5.0; atol=1e-6) && isapprox(distance(p2, iso.c), 5.0; atol=1e-6)
        @test_throws ArgumentError isosceles_triangle_on_segment(p1, p2, 1.0)

        t306090 = triangle_30_60_90_on_segment(p1, p2)
        @test isapprox(angle_at(p1, p2, t306090.c), pi / 6; atol=1e-6)
        @test isapprox(angle_at(p2, p1, t306090.c), pi / 3; atol=1e-6)

        isoright = isosceles_right_triangle_on_segment(p1, p2)
        @test isapprox(distance(p1, isoright.c), distance(p2, isoright.c); atol=1e-6)
        @test isapprox(angle_at(isoright.c, p1, p2), pi / 2; atol=1e-6)

        golden = golden_triangle_on_segment(p1, p2)
        @test isapprox(angle_at(p1, p2, golden.c), 72 * pi / 180; atol=1e-6)
        @test isapprox(angle_at(p2, p1, golden.c), 72 * pi / 180; atol=1e-6)

        gnomon = golden_gnomon_on_segment(p1, p2)
        @test isapprox(angle_at(p1, p2, gnomon.c), 36 * pi / 180; atol=1e-6)
        @test isapprox(angle_at(p2, p1, gnomon.c), 36 * pi / 180; atol=1e-6)

        egy = egyptian_triangle_on_segment(p1, p2)
        @test isapprox(distance(p2, egy.c), 0.75 * 4.0; atol=1e-9)
        @test isapprox(angle_at(p2, p1, egy.c), pi / 2; atol=1e-6)
        @test isapprox(distance(p1, egy.c), 5.0; atol=1e-6)

        e0 = APEllipse2(APPoint(1.0, 2.0), 5.0, 3.0, 0.4)
        pts5 = [point_on_ellipse(e0, t) for t in (0.0, 1.0, 2.0, 3.0, 4.0)]
        fitted = conic_through_points(pts5...)
        @test fitted isa APEllipse2
        @test isapprox(fitted.a, e0.a; atol=1e-6) && isapprox(fitted.b, e0.b; atol=1e-6)
        @test isapprox(fitted.center, e0.center; atol=1e-6)
        @test all(p -> is_on_ellipse(p, fitted; atol=1e-6), pts5)

        h0 = APHyperbola2(APPoint(0.0, 0.0), 4.0, 2.0, 0.2)
        ptsh = [point_on_hyperbola(h0, t; branch=1) for t in (-1.0, -0.5, 0.0, 0.5, 1.0)]
        fittedh = conic_through_points(ptsh...)
        @test fittedh isa APHyperbola2
        @test all(p -> is_on_hyperbola(p, fittedh; atol=1e-5), ptsh)

        @test_throws ArgumentError conic_through_points(
            APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(2.0, 0.0), APPoint(3.0, 0.0), APPoint(4.0, 0.0))
    end

    @testset "primitives" begin
        p1, p2 = APPoint(0.0, 0.0), APPoint(4.0, 0.0)
        s = APSegment(p1, p2)
        l = APLine(p1, p2)
        r = APRay(p1, p2)

        @test direction(s) == APVector(4.0, 0.0)
        @test direction(l) == APVector(4.0, 0.0)
        @test direction(r) == APVector(4.0, 0.0)
        @test slope_angle(l) == 0.0
        @test APLine(s) == l
    end

    @testset "constructions" begin
        p1, p2 = APPoint(0.0, 0.0), APPoint(4.0, 0.0)
        s = APSegment(p1, p2)

        @test midpoint(p1, p2) == APPoint(2.0, 0.0)
        @test midpoint(s) == APPoint(2.0, 0.0)
        @test distance(p1, p2) == 4.0
        @test distance(s) == 4.0

        l = APLine(p1, p2)
        @test distance(APPoint(2.0, 3.0), l) == 3.0
        @test projection(APPoint(2.0, 5.0), l) == APPoint(2.0, 0.0)

        @test reflection(APPoint(1.0, 1.0), APPoint(0.0, 0.0)) == APPoint(-1.0, -1.0)
        @test reflection(APPoint(2.0, 3.0), l) == APPoint(2.0, -3.0)

        # reflection(::APCircle2, about) works for both a point and a line
        # (only the point case was reachable before)
        circ = APCircle2(APPoint(2.0, 3.0), 4.0)
        @test reflection(circ, APPoint(0.0, 0.0)) == APCircle2(APPoint(-2.0, -3.0), 4.0)
        @test reflection(circ, l) == APCircle2(APPoint(2.0, -3.0), 4.0)

        @test rotate(APPoint(1.0, 0.0), pi / 2) ≈ APPoint(0.0, 1.0) atol = 1e-12
        @test homothety(APPoint(1.0, 1.0), 2.0) == APPoint(2.0, 2.0)

        @test barycenter([p1, p2], [1.0, 1.0]) == APPoint(2.0, 0.0)

        # barycenter also accepts Tuples, not just Vectors -- needed since
        # vertices(::APTriangle)/vertices(::APQuadrilateral) return a Tuple
        # rather than a Vector (unlike vertices(::APStraightNgon))
        tri_bary = APTriangle(APPoint(1.0, 1.0), APPoint(6.0, 3.0), APPoint(2.0, 6.0))
        @test barycenter(vertices(tri_bary), [1.0, 1.0, 2.0]) ≈ APPoint(2.75, 4.0)
        @test barycenter([p1, p2], (1.0, 1.0)) == APPoint(2.0, 0.0)   # Tuple weights too

        pb = perpendicular_bisector(p1, p2)
        @test on_line(APPoint(2.0, 7.0), pb)

        # Apollonius circle: locus of points with distance(p,a)/distance(p,b) == k
        a_ap, b_ap = APPoint(0.0, 0.0), APPoint(6.0, 0.0)
        apc = apollonius_circle(a_ap, b_ap, 2.0)
        for t in (0.0, 1.3, 3.0)
            p = apc.center + apc.r * APVector(cos(t), sin(t))
            @test distance(p, a_ap) / distance(p, b_ap) ≈ 2.0 atol = 1e-9
        end
        @test_throws ArgumentError apollonius_circle(a_ap, b_ap, 1.0)
        @test_throws ArgumentError apollonius_circle(a_ap, b_ap, -1.0)

        pt = parallel_through(l, APPoint(0.0, 5.0))
        @test is_parallel(pt, l)

        pp = perpendicular_through(l, APPoint(1.0, 0.0))
        @test is_perpendicular(pp, l)
    end

    @testset "predicates" begin
        a, b, c = APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(2.0, 0.0)
        @test is_collinear(a, b, c)
        @test !is_collinear(a, b, APPoint(0.0, 1.0))

        l1 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
        l2 = APLine(APPoint(0.0, 1.0), APPoint(1.0, 1.0))
        l3 = APLine(APPoint(0.0, 0.0), APPoint(0.0, 1.0))
        @test is_parallel(l1, l2)
        @test is_perpendicular(l1, l3)

        s = APSegment(a, c)
        @test on_segment(b, s)
        @test !on_segment(APPoint(3.0, 0.0), s)

        @test side_of_line(APPoint(0.5, 1.0), l1) == 1
        @test side_of_line(APPoint(0.5, -1.0), l1) == -1
        @test side_of_line(APPoint(0.5, 0.0), l1) == 0

        circ = APCircle2(APPoint(0.0, 0.0), 5.0)
        on_circ(t) = circ.center + circ.r * APVector(cos(t), sin(t))
        @test is_concyclic(on_circ(0.1), on_circ(1.5), on_circ(3.0), on_circ(4.5))
        @test !is_concyclic(on_circ(0.1), on_circ(1.5), on_circ(3.0), APPoint(100.0, 100.0))
        @test is_concyclic(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(2.0, 0.0), APPoint(3.0, 0.0))  # collinear
        @test !is_concyclic(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(2.0, 0.0), APPoint(3.0, 1.0))
    end

    @testset "intersections" begin
        l1 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
        l2 = APLine(APPoint(0.0, -1.0), APPoint(0.0, 1.0))
        @test only(intersection(l1, l2)) ≈ APPoint(0.0, 0.0)

        l_parallel = APLine(APPoint(0.0, 1.0), APPoint(1.0, 1.0))
        @test isempty(intersection(l1, l_parallel))

        c = APCircle2(APPoint(0.0, 0.0), 1.0)
        pts = intersection(l1, c)
        @test length(pts) == 2
        @test APPoint(-1.0, 0.0) in pts
        @test APPoint(1.0, 0.0) in pts

        tangent = APLine(APPoint(-1.0, 1.0), APPoint(1.0, 1.0))
        @test only(intersection(tangent, c)) ≈ APPoint(0.0, 1.0)

        far = APLine(APPoint(-1.0, 5.0), APPoint(1.0, 5.0))
        @test isempty(intersection(far, c))

        c1 = APCircle2(APPoint(0.0, 0.0), 1.0)
        c2 = APCircle2(APPoint(1.0, 0.0), 1.0)
        cc = intersection(c1, c2)
        @test length(cc) == 2
        for p in cc
            @test distance(p, c1.center) ≈ 1.0 atol = 1e-9
            @test distance(p, c2.center) ≈ 1.0 atol = 1e-9
        end
    end

    @testset "triangle" begin
        t = APTriangle(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 3.0))

        @test area(t) == 6.0
        @test perimeter(t) == 3 + 4 + 5
        @test centroid(t) ≈ APPoint(4 / 3, 1.0)
        @test !is_degenerate(t)

        flat = APTriangle(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(2.0, 0.0))
        @test is_degenerate(flat)

        cc = circumcenter(t)
        @test distance(cc, t[1]) ≈ distance(cc, t[2]) atol = 1e-9
        @test distance(cc, t[2]) ≈ distance(cc, t[3]) atol = 1e-9
        @test circumradius(t) ≈ distance(cc, t[1])

        ic = incenter(t)
        l12 = APLine(t[1], t[2])
        l23 = APLine(t[2], t[3])
        l31 = APLine(t[3], t[1])
        @test distance(ic, l12) ≈ inradius(t) atol = 1e-9
        @test distance(ic, l23) ≈ inradius(t) atol = 1e-9
        @test distance(ic, l31) ≈ inradius(t) atol = 1e-9

        # Euler line: O, G, H collinear
        @test is_collinear(circumcenter(t), centroid(t), orthocenter(t); atol=1e-9)

        # excenters / exradii / excircles
        ec = excenters(t)
        er = exradii(t)
        exc = excircles(t)
        for (vname, opp) in ((:A, t[1]), (:B, t[2]), (:C, t[3]))
            center = getfield(ec, vname)
            r = getfield(er, vname)
            l1 = APLine(t[1], t[2])
            l2 = APLine(t[2], t[3])
            l3 = APLine(t[3], t[1])
            @test distance(center, l1) ≈ r atol = 1e-9
            @test distance(center, l2) ≈ r atol = 1e-9
            @test distance(center, l3) ≈ r atol = 1e-9
            @test getfield(exc, vname) == APCircle2(center, r)
        end

        # Euler line passes through O, G, H
        el = euler_line(t)
        @test on_line(orthocenter(t), el)

        # nine-point circle radius is half the circumradius
        @test distance(nine_point_center(t), circumcenter(t)) ≈ distance(orthocenter(t), circumcenter(t)) / 2 atol = 1e-9
        @test nine_point_circle(t).r ≈ circumradius(t) / 2 atol = 1e-9

        # barycentric coordinates: round-trip and known special cases
        @test barycentric_coordinates(t, t[1]) == (1.0, 0.0, 0.0)
        α, β, γ = barycentric_coordinates(t, centroid(t))
        @test α ≈ 1 / 3 && β ≈ 1 / 3 && γ ≈ 1 / 3
        p = APPoint(1.0, 1.0)
        α, β, γ = barycentric_coordinates(t, p)
        @test α + β + γ ≈ 1.0
        @test barycentric_point(t, α, β, γ) ≈ p

        # trilinear coordinates: the incenter is always (1:1:1), and its
        # actual distances to the 3 sides are each exactly the inradius
        x, y, z = trilinear_coordinates(t, incenter(t))
        @test x ≈ inradius(t) && y ≈ inradius(t) && z ≈ inradius(t)
        @test trilinear_point(t, 1.0, 1.0, 1.0) ≈ incenter(t)
        x2, y2, z2 = trilinear_coordinates(t, p)
        @test trilinear_point(t, x2, y2, z2) ≈ p  # round-trip

        # vertex-indexed lines: each passes through the classical center
        # that's defined as their concurrency point
        for i in 1:3
            @test on_line(orthocenter(t), altitude(t, i); atol=1e-9)
            @test on_line(centroid(t), median(t, i); atol=1e-9)
            @test on_line(incenter(t), bisector(t, i); atol=1e-9)
            @test on_line(circumcenter(t), mediator(t, i); atol=1e-9)
            @test is_perpendicular(bisector(t, i), bisector_ext(t, i))
        end
        # the external bisector from vertex 1 passes through the excenters
        # opposite the *other* two vertices, not the one opposite vertex 1
        ext1 = bisector_ext(t, 1)
        ec_local = excenters(t)
        @test on_line(ec_local.B, ext1; atol=1e-9)
        @test on_line(ec_local.C, ext1; atol=1e-9)
        @test !on_line(ec_local.A, ext1; atol=1e-9)

        # angle trisectors at each vertex split the interior angle into 3 equal parts
        others = ((2, 3), (1, 3), (1, 2))
        for i in 1:3
            j, k = others[i]
            full = angle_at(t[i], t[j], t[k])
            rays = trisector(t, i)
            @test length(rays) == 2
            r1, r2 = rays
            @test r1.origin == t[i] && r2.origin == t[i]
            @test angle_at(t[i], t[j], r1.through) ≈ full / 3 atol = 1e-9
            @test angle_at(t[i], r1.through, r2.through) ≈ full / 3 atol = 1e-9
            @test angle_at(t[i], r2.through, t[k]) ≈ full / 3 atol = 1e-9
        end

        # Spieker center is the midpoint of the incenter and the Nagel point
        @test spieker_center(t) ≈ midpoint(incenter(t), nagel_point(t))

        # Mittenpunkt: concurrence of lines from each excenter to the opposite side's midpoint
        ec = excenters(t)
        lA = APLine(ec.A, midpoint(t[2], t[3]))
        lB = APLine(ec.B, midpoint(t[1], t[3]))
        @test only(intersection(lA, lB)) ≈ mittenpunkt(t)

        # Equilateral triangle: every classical center coincides with the centroid
        eq = APTriangle(APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(1.0, sqrt(3.0)))
        g = centroid(eq)
        for center in (circumcenter(eq), incenter(eq), orthocenter(eq),
                       nagel_point(eq), gergonne_point(eq), spieker_center(eq),
                       symmedian_point(eq), mittenpunkt(eq))
            @test center ≈ g atol = 1e-9
        end

        # Simson line: feet of perpendiculars from a point on the circumcircle are collinear
        p_on_circ = t[1]
        sl = simson_line(t, p_on_circ)
        f3 = projection(p_on_circ, APLine(t[3], t[1]))
        @test on_line(f3, sl; atol=1e-9)

        # Euler points lie on the nine-point circle
        npc = nine_point_circle(t)
        for ep in euler_points(t)
            @test distance(ep, npc.center) ≈ npc.r atol = 1e-9
        end

        # orthic axis: radical axis of circumcircle/nine-point circle,
        # perpendicular to the Euler line
        oax = orthic_axis(t)
        @test is_perpendicular(oax, euler_line(t))
        cc = circumcircle(t)
        @test power_of_point(oax.p1, cc) ≈ power_of_point(oax.p1, npc) atol = 1e-6

        # Brocard axis passes through O and K; Lemoine axis is the polar of K
        bax = brocard_axis(t)
        @test on_line(circumcenter(t), bax; atol=1e-9)
        @test on_line(symmedian_point(t), bax; atol=1e-9)
        @test lemoine_axis(t) ≈ polar_line(cc, symmedian_point(t))

        # Steiner line: reflections of a circumcircle point across the 3
        # sides are collinear and pass through the orthocenter
        r1 = reflection(p_on_circ, APLine(t[1], t[2]))
        r2 = reflection(p_on_circ, APLine(t[2], t[3]))
        r3 = reflection(p_on_circ, APLine(t[3], t[1]))
        stl = steiner_line(t, p_on_circ)
        @test is_collinear(r1, r2, r3; atol=1e-9)
        @test on_line(r3, stl; atol=1e-9)
        @test on_line(orthocenter(t), stl; atol=1e-9)
    end

    @testset "more triangle centers and derived triangles" begin
        t = APTriangle(APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(2.0, 4.0))

        # de Longchamps point: lies on the Euler line, and O is its midpoint with H
        dl = de_longchamps_point(t)
        @test on_line(dl, euler_line(t))
        @test midpoint(orthocenter(t), dl) ≈ circumcenter(t)

        # Bevan point: circumcenter of the excentral triangle, equidistant from the 3 excenters
        bp = bevan_point(t)
        ec = excenters(t)
        @test distance(bp, ec.A) ≈ distance(bp, ec.B) atol = 1e-9
        @test distance(bp, ec.B) ≈ distance(bp, ec.C) atol = 1e-9

        # Feuerbach point: incircle and nine-point circle are internally tangent there
        fp = feuerbach_point(t)
        @test distance(fp, incenter(t)) ≈ inradius(t) atol = 1e-9
        @test distance(fp, nine_point_center(t)) ≈ circumradius(t) / 2 atol = 1e-9

        # Fermat point: concurrence of vertex-to-opposite-outward-apex segments
        A, B, C = t[1], t[2], t[3]
        apex(P, Q, other) = begin
            cand = rotate(Q, pi / 3, P)
            side_of_line(cand, APLine(P, Q)) == side_of_line(other, APLine(P, Q)) ? rotate(Q, -pi / 3, P) : cand
        end
        C2 = apex(A, B, C)
        @test fermat_point(t) ≈ only(intersection(APLine(C, C2), APLine(A, apex(B, C, A))))

        # second Fermat point: isogonal conjugate of a first isodynamic point,
        # and fermat_axis joins the two Fermat points
        j1, j2 = isodynamic_points(t)
        fp2 = second_fermat_point(t)
        @test fp2 ≈ isogonal_conjugate(t, j1) || fp2 ≈ isogonal_conjugate(t, j2)
        @test fermat_axis(t) ≈ APLine(fermat_point(t), fp2)

        # Equilateral triangle: these centers all coincide with the centroid too
        eq = APTriangle(APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(1.0, sqrt(3.0)))
        g = centroid(eq)
        for center in (de_longchamps_point(eq), bevan_point(eq), fermat_point(eq))
            @test center ≈ g atol = 1e-9
        end

        # medial triangle: half the area, vertices at midpoints
        med = medial_triangle(t)
        @test area(med) ≈ area(t) / 4 atol = 1e-9
        @test Set([med[1], med[2], med[3]]) == Set([midpoint(B, C), midpoint(A, C), midpoint(A, B)])

        # orthic triangle: feet of the altitudes lie on the corresponding sides
        orth = orthic_triangle(t)
        @test on_segment(orth[1], APSegment(B, C))
        @test on_segment(orth[2], APSegment(C, A))
        @test on_segment(orth[3], APSegment(A, B))
        @test is_perpendicular(APLine(A, orth[1]), APLine(B, C))

        # excentral triangle: vertices are exactly the excenters
        ext = excentral_triangle(t)
        @test Set([ext[1], ext[2], ext[3]]) == Set([ec.A, ec.B, ec.C])

        # contact triangle: vertices at distance = inradius from the incenter, on the sides
        ct = contact_triangle(t)
        for (v, side) in zip((ct[1], ct[2], ct[3]), (APSegment(B, C), APSegment(C, A), APSegment(A, B)))
            @test distance(v, incenter(t)) ≈ inradius(t) atol = 1e-9
            @test on_segment(v, side)
        end

        # extouch triangle: vertices at distance = corresponding exradius from each excenter
        et = extouch_triangle(t)
        er = exradii(t)
        @test distance(et[1], ec.A) ≈ er.A atol = 1e-9
        @test distance(et[2], ec.B) ≈ er.B atol = 1e-9
        @test distance(et[3], ec.C) ≈ er.C atol = 1e-9

        # tangential triangle: each side of t's circumcircle-tangent-line touches only at the vertex
        tan_t = tangential_triangle(t)
        O, R = circumcenter(t), circumradius(t)
        @test distance(O, APLine(tan_t[1], tan_t[2])) ≈ R atol = 1e-6  # side opposite C, i.e. tangent at C... just check tangency

        # Spieker circle: incircle of the medial triangle; its center matches spieker_center
        spc = spieker_circle(t)
        @test spc.center ≈ spieker_center(t)
        @test spc.center ≈ incenter(medial_triangle(t))
        @test spc.r ≈ inradius(medial_triangle(t))

        # Napoleon's theorem: both the outer and inner Napoleon triangles are
        # equilateral, and their centers coincide with the centroid of t
        outer_nap = napoleon_triangle(t)
        s1, s2, s3 = distance(outer_nap[1], outer_nap[2]), distance(outer_nap[2], outer_nap[3]), distance(outer_nap[3], outer_nap[1])
        @test s1 ≈ s2 atol = 1e-9
        @test s2 ≈ s3 atol = 1e-9
        @test napoleon_point(t) ≈ centroid(t)

        inner_nap = napoleon_triangle(t; outward=false)
        i1, i2, i3 = distance(inner_nap[1], inner_nap[2]), distance(inner_nap[2], inner_nap[3]), distance(inner_nap[3], inner_nap[1])
        @test i1 ≈ i2 atol = 1e-9
        @test i2 ≈ i3 atol = 1e-9
        @test napoleon_point(t; outward=false) ≈ centroid(t)

        # square_inscribed: a genuine square, with one side on the base and
        # the other two vertices exactly on the two other sides
        for i in 1:3
            others = ((2, 3), (1, 3), (1, 2))
            j, k = others[i]
            sq = square_inscribed(t, i)
            sides_sq = (distance(sq[1], sq[2]), distance(sq[2], sq[3]), distance(sq[3], sq[4]), distance(sq[4], sq[1]))
            @test all(x -> isapprox(x, sides_sq[1]; atol=1e-9), sides_sq)  # all 4 sides equal
            @test is_perpendicular(APLine(sq[1], sq[2]), APLine(sq[2], sq[3]))
            @test on_line(sq[1], APLine(t[j], t[k]); atol=1e-9)
            @test on_line(sq[2], APLine(t[j], t[k]); atol=1e-9)
            @test on_line(sq[3], APLine(t[i], t[k]); atol=1e-9)
            @test on_line(sq[4], APLine(t[i], t[j]); atol=1e-9)
        end

        # Morley's trisector theorem: the Morley triangle is always equilateral
        morley = morley_triangle(t)
        m1, m2, m3 = distance(morley[1], morley[2]), distance(morley[2], morley[3]), distance(morley[3], morley[1])
        @test m1 ≈ m2 atol = 1e-9
        @test m2 ≈ m3 atol = 1e-9

        # Brocard points: both give the same (Brocard) angle at every vertex
        o1, o2 = first_brocard_point(t), second_brocard_point(t)
        ω = brocard_angle(t)
        @test angle_at(A, o1, B) ≈ ω atol = 1e-9
        @test angle_at(B, o1, C) ≈ ω atol = 1e-9
        @test angle_at(C, o1, A) ≈ ω atol = 1e-9
        @test angle_at(B, o2, A) ≈ ω atol = 1e-9
        @test angle_at(C, o2, B) ≈ ω atol = 1e-9
        @test angle_at(A, o2, C) ≈ ω atol = 1e-9
        @test !(o1 ≈ o2)

        # Brocard circle: equidistant from both Brocard points, centered at
        # the midpoint of the circumcenter and the symmedian point
        bc = brocard_circle(t)
        @test bc.center ≈ midpoint(circumcenter(t), symmedian_point(t))
        @test distance(bc.center, o1) ≈ bc.r atol = 1e-9
        @test distance(bc.center, o2) ≈ bc.r atol = 1e-9

        # Equilateral triangle: the Brocard points coincide with the center, angle is 30°
        eq2 = APTriangle(APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(1.0, sqrt(3.0)))
        @test first_brocard_point(eq2) ≈ centroid(eq2) atol = 1e-9
        @test second_brocard_point(eq2) ≈ centroid(eq2) atol = 1e-9
        @test brocard_angle(eq2) ≈ pi / 6 atol = 1e-9
    end

    @testset "Conway, Taylor, Lemoine, Soddy circles" begin
        t = APTriangle(APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(2.0, 4.0))
        A, B, C = t[1], t[2], t[3]
        a, b, c = distance(B, C), distance(C, A), distance(A, B)
        s = (a + b + c) / 2

        cp = conway_points(t)
        @test length(cp) == 6
        cc = conway_circle(t)
        @test cc.center ≈ incenter(t)
        @test cc.r ≈ sqrt(inradius(t)^2 + s^2) atol = 1e-9
        for p in cp
            @test distance(cc.center, p) ≈ cc.r atol = 1e-9
        end

        tc = taylor_circle(t)
        tp = taylor_points(t)
        @test length(tp) == 6
        for p in tp
            @test distance(tc.center, p) ≈ tc.r atol = 1e-9
        end

        flp = first_lemoine_points(t)
        @test length(flp) == 6
        flc = first_lemoine_circle(t)
        @test flc.center ≈ midpoint(circumcenter(t), symmedian_point(t))
        for p in flp
            @test distance(flc.center, p) ≈ flc.r atol = 1e-9
        end

        slc = second_lemoine_circle(t)
        @test slc.center ≈ symmedian_point(t)
        @test slc.r ≈ a * b * c / (a^2 + b^2 + c^2) atol = 1e-9

        # three_tangent_circles: pairwise externally tangent at each side
        base = three_tangent_circles(t)
        @test base[1].center == A && base[1].r ≈ s - a
        @test base[2].center == B && base[2].r ≈ s - b
        @test base[3].center == C && base[3].r ≈ s - c
        @test distance(base[1].center, base[2].center) ≈ base[1].r + base[2].r atol = 1e-9
        @test distance(base[2].center, base[3].center) ≈ base[2].r + base[3].r atol = 1e-9
        @test distance(base[3].center, base[1].center) ≈ base[3].r + base[1].r atol = 1e-9

        # Soddy circles: tangent to the 3 mutually-tangent vertex circles
        sc = soddy_circles(t)
        @test sc.inner.r < sc.outer.r
        for base_c in base
            din = distance(sc.inner.center, base_c.center)
            @test din ≈ sc.inner.r + base_c.r atol = 1e-6  # inner: external tangency
            dout = distance(sc.outer.center, base_c.center)
            @test dout ≈ sc.outer.r - base_c.r atol = 1e-6  # outer: encloses the vertex circles
        end

        # equilateral triangle: both Soddy circles are centered at the incenter/centroid
        eq = APTriangle(APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(1.0, sqrt(3.0)))
        sceq = soddy_circles(eq)
        @test sceq.inner.center ≈ centroid(eq) atol = 1e-9
        @test sceq.outer.center ≈ centroid(eq) atol = 1e-9
    end

    @testset "isodynamic points and orthopole" begin
        t = APTriangle(APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(2.0, 4.0))
        A, B, C = t[1], t[2], t[3]
        a, b, c = distance(B, C), distance(C, A), distance(A, B)

        j1, j2 = isodynamic_points(t)
        @test !(j1 ≈ j2)
        circ_a = apollonius_circle(B, C, c / b)
        circ_b = apollonius_circle(C, A, a / c)
        circ_c = apollonius_circle(A, B, b / a)

        # three_apollonius_circles matches these directly, and each passes
        # through its own vertex
        tac_a, tac_b, tac_c = three_apollonius_circles(t)
        for (tac, circ) in ((tac_a, circ_a), (tac_b, circ_b), (tac_c, circ_c))
            @test tac.center ≈ circ.center atol = 1e-9
            @test tac.r ≈ circ.r atol = 1e-9
        end
        @test distance(A, tac_a.center) ≈ tac_a.r atol = 1e-9
        @test distance(B, tac_b.center) ≈ tac_b.r atol = 1e-9
        @test distance(C, tac_c.center) ≈ tac_c.r atol = 1e-9

        for j in (j1, j2)
            @test distance(j, circ_a.center) ≈ circ_a.r atol = 1e-6
            @test distance(j, circ_b.center) ≈ circ_b.r atol = 1e-6
            @test distance(j, circ_c.center) ≈ circ_c.r atol = 1e-6
        end

        # equilateral triangle: the Apollonius circles degenerate (equal ratios)
        eq = APTriangle(APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(1.0, sqrt(3.0)))
        @test_throws ArgumentError isodynamic_points(eq)

        l = APLine(APPoint(-2.0, 3.0), APPoint(5.0, -1.0))
        op = orthopole(l, t)
        lA = perpendicular_through(APLine(B, C), projection(A, l))
        lB = perpendicular_through(APLine(C, A), projection(B, l))
        lC = perpendicular_through(APLine(A, B), projection(C, l))
        @test on_line(op, lA; atol=1e-9)
        @test on_line(op, lB; atol=1e-9)
        @test on_line(op, lC; atol=1e-9)

        # Poncelet point: common point of the 4 nine-point circles obtained
        # by leaving out each of the 4 points (t's 3 vertices, plus D) in turn
        D = APPoint(5.0, -2.0)
        pp = poncelet_point(t, D)
        for tri in (APTriangle(B, C, D), APTriangle(A, C, D), APTriangle(A, B, D), t)
            npc = nine_point_circle(tri)
            @test distance(pp, npc.center) ≈ npc.r atol = 1e-6
        end
    end

    @testset "Kenmotu and MacBeath points" begin
        t = APTriangle(APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(2.0, 4.0))
        A, B, C = t[1], t[2], t[3]
        angA, angB, angC = angle_at(A, B, C), angle_at(B, C, A), angle_at(C, A, B)

        kp = kenmotu_point(t)
        x, y, z = trilinear_coordinates(t, kp)
        # trilinear coords proportional to cos(A-pi/4) : cos(B-pi/4) : cos(C-pi/4)
        r1, r2, r3 = cos(angA - pi / 4), cos(angB - pi / 4), cos(angC - pi / 4)
        @test x / r1 ≈ y / r2 atol = 1e-9
        @test y / r2 ≈ z / r3 atol = 1e-9

        # equilateral triangle: all three trilinears are equal by symmetry,
        # so the Kenmotu point coincides with the center
        eq = APTriangle(APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(1.0, sqrt(3.0)))
        @test kenmotu_point(eq) ≈ centroid(eq) atol = 1e-9

        mp = macbeath_point(t)
        @test mp ≈ isotomic_conjugate(t, circumcenter(t))
        # isotomic conjugation is an involution
        @test isotomic_conjugate(t, mp) ≈ circumcenter(t) atol = 1e-6
    end

    @testset "brocard midpoint" begin
        t = APTriangle(APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(2.0, 4.0))
        bm = brocard_midpoint(t)
        @test bm ≈ midpoint(first_brocard_point(t), second_brocard_point(t))
        # equilateral: both Brocard points coincide with the center
        eq = APTriangle(APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(1.0, sqrt(3.0)))
        @test brocard_midpoint(eq) ≈ centroid(eq) atol = 1e-9
    end

    @testset "Steiner ellipses" begin
        t = APTriangle(APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(2.0, 4.0))
        A, B, C = t[1], t[2], t[3]
        g = centroid(t)

        inell = steiner_inellipse(t)
        @test inell.center ≈ g atol = 1e-9
        # tangent to the sides at their midpoints
        @test is_on_ellipse(midpoint(A, B), inell)
        @test is_on_ellipse(midpoint(B, C), inell)
        @test is_on_ellipse(midpoint(C, A), inell)

        circumell = steiner_circumellipse(t)
        @test circumell isa APEllipse2
        @test circumell.center ≈ g atol = 1e-9
        @test is_on_ellipse(A, circumell)
        @test is_on_ellipse(B, circumell)
        @test is_on_ellipse(C, circumell)

        # the circumellipse is the -2 homothety of the inellipse about the centroid
        @test circumell.a ≈ 2 * inell.a atol = 1e-6
        @test circumell.b ≈ 2 * inell.b atol = 1e-6

        # equilateral triangle: both reduce to circles (incircle/circumcircle)
        eq = APTriangle(APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(1.0, sqrt(3.0)))
        @test steiner_inellipse(eq).a ≈ steiner_inellipse(eq).b atol = 1e-9
        @test steiner_inellipse(eq).a ≈ inradius(eq) atol = 1e-9
        @test steiner_circumellipse(eq).a ≈ steiner_circumellipse(eq).b atol = 1e-9
        @test steiner_circumellipse(eq).a ≈ circumradius(eq) atol = 1e-9
    end

    @testset "bifocal conics" begin
        f1, f2 = APPoint(1.0, 2.0), APPoint(7.0, 5.0)

        e = APEllipse2(f1, f2, 5.0)
        ef1, ef2 = foci(e)
        @test (ef1 ≈ f1 && ef2 ≈ f2) || (ef1 ≈ f2 && ef2 ≈ f1)
        @test e.a == 5.0
        @test_throws ArgumentError APEllipse2(f1, f2, distance(f1, f2) / 2)  # a too small

        p = APPoint(4.0, 7.0)
        e2 = APEllipse2(f1, f2, p)
        @test is_on_ellipse(p, e2)
        @test e2.a ≈ (distance(p, f1) + distance(p, f2)) / 2

        h = APHyperbola2(f1, f2, 2.0)
        hf1, hf2 = foci(h)
        @test (hf1 ≈ f1 && hf2 ≈ f2) || (hf1 ≈ f2 && hf2 ≈ f1)
        @test h.a == 2.0
        @test_throws ArgumentError APHyperbola2(f1, f2, distance(f1, f2) / 2 + 1.0)  # a too large

        ph = point_on_hyperbola(h, 0.6)
        h2 = APHyperbola2(f1, f2, ph)
        @test is_on_hyperbola(ph, h2)
        @test h2.a ≈ abs(distance(ph, f1) - distance(ph, f2)) / 2
    end

    @testset "conic through 5 points" begin
        e_true = APEllipse2(APPoint(2.0, 3.0), 5.0, 3.0, 0.4)
        pts = [point_on_ellipse(e_true, t) for t in (0.1, 1.0, 2.0, 3.3, 4.7)]
        fit = conic_through_points(pts...)
        @test fit isa APEllipse2
        @test fit.center ≈ e_true.center
        @test fit.a ≈ e_true.a
        @test fit.b ≈ e_true.b
        @test fit.angle ≈ e_true.angle
        for p in pts
            @test is_on_ellipse(p, fit; atol=1e-6)
        end

        h_true = APHyperbola2(APPoint(2.0, 3.0), 4.0, 2.5, 0.6)
        ptsh = vcat([point_on_hyperbola(h_true, t; branch=1) for t in (0.3, 1.0, 1.7)],
                    [point_on_hyperbola(h_true, t; branch=-1) for t in (0.5, 1.2)])
        fith = conic_through_points(ptsh...)
        @test fith isa APHyperbola2
        @test fith.center ≈ h_true.center
        @test fith.a ≈ h_true.a
        @test fith.b ≈ h_true.b
        @test fith.angle ≈ h_true.angle
        for p in ptsh
            @test is_on_hyperbola(p, fith; atol=1e-6)
        end

        # degenerate: collinear points don't determine a unique conic
        @test_throws ArgumentError conic_through_points(
            APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(2.0, 0.0), APPoint(3.0, 0.0), APPoint(4.0, 0.0))

        # 5 points on a circle (a special ellipse) should also work
        circ = APCircle2(APPoint(1.0, 1.0), 3.0)
        cpts = [circ.center + circ.r * APVector(cos(t), sin(t)) for t in (0.2, 1.1, 2.3, 3.5, 5.0)]
        fitc = conic_through_points(cpts...)
        @test fitc isa APEllipse2
        @test fitc.a ≈ fitc.b ≈ circ.r
        @test fitc.center ≈ circ.center
    end

    @testset "isogonal and isotomic conjugates" begin
        t = APTriangle(APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(2.0, 4.0))

        # isogonal conjugate: classical pairings
        @test isogonal_conjugate(t, orthocenter(t)) ≈ circumcenter(t) atol = 1e-6
        @test isogonal_conjugate(t, circumcenter(t)) ≈ orthocenter(t) atol = 1e-6
        @test isogonal_conjugate(t, centroid(t)) ≈ symmedian_point(t) atol = 1e-6
        @test isogonal_conjugate(t, symmedian_point(t)) ≈ centroid(t) atol = 1e-6
        @test isogonal_conjugate(t, incenter(t)) ≈ incenter(t) atol = 1e-6  # self-conjugate

        # isotomic conjugate: fixes the centroid
        @test isotomic_conjugate(t, centroid(t)) ≈ centroid(t) atol = 1e-6

        # both are involutions, for an arbitrary interior point
        p = APPoint(2.0, 1.5)
        @test isogonal_conjugate(t, isogonal_conjugate(t, p)) ≈ p atol = 1e-6
        @test isotomic_conjugate(t, isotomic_conjugate(t, p)) ≈ p atol = 1e-6
    end

    @testset "general point-parametrized derived triangles" begin
        t = APTriangle(APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(2.0, 4.0))

        # pedal_triangle generalizes orthic_triangle and contact_triangle
        pt1, pt2, pt3 = pedal_triangle(t, orthocenter(t)), pedal_triangle(t, orthocenter(t)), pedal_triangle(t, incenter(t))
        ot, ct = orthic_triangle(t), contact_triangle(t)
        for i in 1:3
            @test pt1[i] ≈ ot[i] atol = 1e-9
            @test pt3[i] ≈ ct[i] atol = 1e-9
        end

        # cevian_triangle generalizes medial_triangle
        cvt = cevian_triangle(t, centroid(t))
        mt = medial_triangle(t)
        for i in 1:3
            @test cvt[i] ≈ mt[i] atol = 1e-9
        end

        # circumcevian_triangle: vertices always lie on the circumcircle
        cct = circumcevian_triangle(t, incenter(t))
        R = circumradius(t)
        O = circumcenter(t)
        for i in 1:3
            @test distance(cct[i], O) ≈ R atol = 1e-9
        end
    end

    @testset "mixtilinear incircles" begin
        t = APTriangle(APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(2.0, 4.0))
        cc = circumcircle(t)

        for i in 1:3
            vertex, other1, other2 = t[i], t[mod1(i + 1, 3)], t[mod1(i + 2, 3)]
            l1, l2 = APLine(vertex, other1), APLine(vertex, other2)
            m = mixtilinear_incircle(t, i)

            @test distance(m.center, l1) ≈ m.r atol = 1e-6
            @test distance(m.center, l2) ≈ m.r atol = 1e-6
            @test distance(m.center, cc.center) ≈ cc.r - m.r atol = 1e-6  # internal tangency
            @test side_of_line(m.center, l1) == side_of_line(other2, l1)  # inside the vertex's angle
            @test side_of_line(m.center, l2) == side_of_line(other1, l2)
        end
    end

    @testset "Thebault circles" begin
        t = APTriangle(APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0))
        A, B, C = t[1], t[2], t[3]
        cc = circumcircle(t)

        for frac in (0.2, 0.4, 0.7)
            D = B + frac * (C - B)
            th = thebault_circles(t, D)
            cevian, side_line = APLine(A, D), APLine(B, C)

            for (s, ref) in ((th.near_b, B), (th.near_c, C))
                @test distance(s.center, cevian) ≈ s.r atol = 1e-6
                @test distance(s.center, side_line) ≈ s.r atol = 1e-6
                @test distance(s.center, cc.center) ≈ cc.r - s.r atol = 1e-6  # internal tangency
                @test side_of_line(s.center, cevian) == side_of_line(ref, cevian)
                @test side_of_line(s.center, side_line) == side_of_line(A, side_line)
            end

            # Sawayama-Thebault theorem: the incenter lies on the segment
            # joining the two Thebault circle centers
            @test on_line(incenter(t), APLine(th.near_b.center, th.near_c.center); atol=1e-9)
        end
    end

    @testset "inversion" begin
        c = APCircle2(APPoint(0.0, 0.0), 2.0)
        p = APPoint(4.0, 0.0)
        p2 = inversion(p, c)
        @test p2 ≈ APPoint(1.0, 0.0)
        @test inversion(p2, c) ≈ p  # involution
        @test_throws ArgumentError inversion(c.center, c)

        center = APPoint(1.0, 2.0)
        point_on_circle(circ, t) = circ.center + circ.r * APVector(cos(t), sin(t))

        # inverting a line not through the center gives a circle through the center
        l = APLine(APPoint(-10.0, 5.0), APPoint(10.0, 5.0))
        il = invert(l, center)
        @test distance(center, il.center) ≈ il.r atol = 1e-9  # center lies on the image circle
        # inverting a point of the image circle back should land on l
        for t in (0.0, 1.1, 3.0)
            @test on_line(inversion(point_on_circle(il, t), APCircle2(center, 1.0)), l; atol=1e-6)
        end

        # a line through the center is its own image (not invertible to a circle)
        @test_throws ArgumentError invert(APLine(center, center + APVector(1.0, 0.0)), center)

        # inverting a circle not through the center gives another circle;
        # inverting a point of the original circle back should land on the image, and vice versa
        c0 = APCircle2(APPoint(6.0, 8.0), 2.0)
        ic0 = invert(c0, center)
        for t in (0.0, 1.3, 2.7)
            img = inversion(point_on_circle(c0, t), APCircle2(center, 1.0))
            @test abs(distance(img, ic0.center) - ic0.r) <= 1e-6
        end

        # a circle passing through the center inverts to a line, mirroring
        # invert(::APLine, ::APPoint) — verified by inverting a few points of
        # the original circle back and checking they land on that line
        c_through = APCircle2(center, 3.0)
        p_center = center + APVector(3.0, 0.0)  # on c_through
        img_line = invert(c_through, p_center)
        @test img_line isa APLine
        for t in (0.3, 1.7, 2.5, 4.1)
            p = point_on_circle(c_through, t)
            isapprox(p, p_center; atol=1e-6) && continue
            pimg = inversion(p, APCircle2(p_center, 1.0))
            @test on_line(pimg, img_line; atol=1e-6)
        end

        # inverting about the circle's own center just rescales it
        same_center_img = invert(APCircle2(center, 4.0), center; k=2.0)
        @test same_center_img.center == center
        @test same_center_img.r ≈ 2.0^2 / 4.0

        # invert(p::APPoint, center; k, atol) -- same (shape, center; k, atol)
        # convention as every other invert method, bridging to `inversion`.
        # Without this method, invert(p, center; k=...) would silently match
        # invert(center::APPoint; k, atol)'s 1-arg curried form instead
        # (built for p |> invert(center)) and return a function, not a point.
        @test invert(APPoint(4.0, 0.0), APPoint(0.0, 0.0); k=2.0) ≈ inversion(APPoint(4.0, 0.0), APCircle2(APPoint(0.0, 0.0), 2.0))
        @test_throws ArgumentError invert(APPoint(1.0, 2.0), APPoint(1.0, 2.0))   # coincides with center
    end

    @testset "invert(APSegment/APTriangle/APStraightNgon), APCurvilinearNgon2" begin
        center = APPoint(0.0, 0.0)

        # helper: fine polygon approximation of a APCurvilinearNgon2's boundary,
        # in a single consistent walk order, for numeric area/perimeter checks
        function walk(sides; atol=1e-9)
            n = length(sides)
            sp1(s) = s isa Apollonius.APSegment ? s[1] : s.p1
            sp2(s) = s isa Apollonius.APSegment ? s[2] : s.p2
            order = Tuple{eltype(sides),Bool}[(sides[1], false)]
            used, last_pt = Set(1), sp2(sides[1])
            for _ in 1:n-1
                for i in setdiff(1:n, used)
                    if isapprox(sp1(sides[i]), last_pt; atol=atol)
                        push!(order, (sides[i], false)); last_pt = sp2(sides[i]); push!(used, i); break
                    elseif isapprox(sp2(sides[i]), last_pt; atol=atol)
                        push!(order, (sides[i], true)); last_pt = sp1(sides[i]); push!(used, i); break
                    end
                end
            end
            return order
        end
        function boundary_samples(sides; n=2000)
            pts = APPoint{2,Float64}[]
            for (side, reversed) in walk(sides)
                if side isa Apollonius.APSegment
                    a, b = reversed ? (side[2], side[1]) : (side[1], side[2])
                    for i in 0:n-1
                        push!(pts, a + (i / n) * (b - a))
                    end
                else
                    ts = reversed ? range(1, 0; length=n) : range(0, 1; length=n)
                    for t in ts
                        push!(pts, point_on_arc(side, t))
                    end
                end
            end
            return pts
        end
        function shoelace(pts)
            total = 0.0
            m = length(pts)
            for i in 1:m
                p, q = pts[i], pts[mod1(i + 1, m)]
                total += p[1] * q[2] - q[1] * p[2]
            end
            return abs(total) / 2
        end

        @testset "invert(APSegment)" begin
            # not through center -> APCircularArc2 excluding the center
            p1, p2 = APPoint(5.0, 2.0), APPoint(8.0, 6.0)
            arc = invert(APSegment(p1, p2), center)
            @test arc isa APCircularArc2
            @test distance(arc.circle.center, center) ≈ arc.circle.r atol = 1e-9  # circle through center
            for t in (0.0, 0.3, 0.7, 1.0)
                p = p1 + t * (p2 - p1)
                ip = inversion(p, APCircle2(center, 1.0))
                @test distance(ip, arc.circle.center) ≈ arc.circle.r atol = 1e-9
            end
            @test arc.p1 ≈ inversion(p1, APCircle2(center, 1.0))
            @test arc.p2 ≈ inversion(p2, APCircle2(center, 1.0))

            # through the center -> stays a APSegment
            p3, p4 = APPoint(3.0, 0.0), APPoint(8.0, 0.0)
            seg = invert(APSegment(p3, p4), center)
            @test seg isa APSegment
            @test seg[1] ≈ inversion(p3, APCircle2(center, 1.0))
            @test seg[2] ≈ inversion(p4, APCircle2(center, 1.0))
        end

        @testset "invert(APTriangle) -> APCurvilinearNgon2" begin
            t = APTriangle(APPoint(5.0, 2.0), APPoint(9.0, 3.0), APPoint(6.0, 8.0))
            cp = invert(t, center)
            @test cp isa APCurvilinearNgon2
            @test length(cp) == 3
            @test all(s -> s isa APCircularArc2, cp.sides)  # no side's line passes through the center here

            pts = boundary_samples(cp.sides)
            @test area(cp) ≈ shoelace(pts) atol = 1e-6
            @test perimeter(cp) ≈ sum(distance(pts[i], pts[mod1(i + 1, length(pts))]) for i in eachindex(pts)) atol = 1e-3

            # round-trip: every sampled boundary point, inverted again, lands
            # back on one of t's own side-lines
            on_original(p; atol=1e-4) =
                min(distance(p, APLine(t[1], t[2])), distance(p, APLine(t[2], t[3])), distance(p, APLine(t[3], t[1]))) < atol
            @test all(on_original, inversion(p, APCircle2(center, 1.0)) for p in pts[1:200:end])

            # a triangle with one side's line through the center -> mixed APSegment+APCircularArc2
            t2 = APTriangle(APPoint(-3.0, 0.0), APPoint(5.0, 0.0), APPoint(2.0, 4.0))
            cp2 = invert(t2, center)
            @test count(s -> s isa APSegment, cp2.sides) == 1
            @test count(s -> s isa APCircularArc2, cp2.sides) == 2
            pts2 = boundary_samples(cp2.sides)
            @test area(cp2) ≈ shoelace(pts2) atol = 1e-6

            # a vertex at the inversion center itself is not invertible
            @test_throws ArgumentError invert(APTriangle(center, APPoint(1.0, 0.0), APPoint(0.0, 1.0)), center)
        end

        @testset "invert(APStraightNgon) -> APCurvilinearNgon2" begin
            pg = APStraightNgon([APPoint(4.0, 1.0), APPoint(8.0, 2.0), APPoint(7.0, 6.0), APPoint(3.0, 5.0)])
            cpg = invert(pg, center)
            @test length(cpg) == 4
            ptsg = boundary_samples(cpg.sides)
            @test area(cpg) ≈ shoelace(ptsg) atol = 1e-6
        end

        @testset "APCurvilinearNgon2 transforms" begin
            t = APTriangle(APPoint(5.0, 2.0), APPoint(9.0, 3.0), APPoint(6.0, 8.0))
            cp = invert(t, center)

            rot = rotate(cp, pi / 4, APPoint(1.0, 1.0))
            @test area(rot) ≈ area(cp) atol = 1e-6

            hom = homothety(cp, 2.0, APPoint(1.0, 1.0))
            @test area(hom) ≈ 4 * area(cp) atol = 1e-6

            refl_pt = reflection(cp, APPoint(1.0, 1.0))
            @test area(refl_pt) ≈ area(cp) atol = 1e-6

            refl_line = reflection(cp, APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)))
            @test area(refl_line) ≈ area(cp) atol = 1e-6
        end
    end

    @testset "named polygons" begin
        a, b, c = APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(3.0, 1.0)
        pgram = parallelogram(a, b, c)
        v = vertices(pgram)
        @test v[4] ≈ a + (c - b)
        @test (v[2] - v[1]) ≈ (v[3] - v[4])

        sq = square_on_segment(a, b)
        @test area(sq) ≈ 4.0
        @test is_convex(sq)

        rect = rectangle_on_segment(a, b, 3.0)
        @test area(rect) ≈ 6.0
        @test is_convex(rect)

        hexagon = regular_polygon(APPoint(0.0, 0.0), APPoint(1.0, 0.0), 6)
        vh = vertices(hexagon)
        @test length(vh) == 6
        for i in 1:6
            @test distance(APPoint(0.0, 0.0), vh[i]) ≈ 1.0 atol = 1e-9
        end
        @test distance(vh[1], vh[2]) ≈ 1.0 atol = 1e-9  # regular hexagon: side == radius
        @test is_convex(hexagon)
    end

    @testset "APAngle2" begin
        vertex = APPoint(0.0, 0.0)
        a, b = APPoint(1.0, 0.0), APPoint(0.0, 1.0)
        ang = APAngle2(vertex, a, b)

        @test measure(ang) ≈ pi / 2
        @test normalized_measure(ang) ≈ pi / 2
        @test abs(ang) ≈ pi / 2
        @test is_direct(ang)

        rev = APAngle2(vertex, b, a)
        @test measure(rev) ≈ -pi / 2
        @test normalized_measure(rev) ≈ 3pi / 2
        @test abs(rev) ≈ pi / 2  # unsigned: same as `ang`
        @test !is_direct(rev)

        # reverse(ang): the complementary wedge (a/b swapped) -- same thing
        # as `rev` above, and its own inverse
        @test reverse(ang) == rev
        @test reverse(reverse(ang)) == ang

        @test ang == APAngle2(vertex, a, b)
        @test ang ≈ APAngle2(vertex, a, b)

        # transforms
        rot = rotate(ang, pi / 3)
        @test measure(rot) ≈ measure(ang)  # rotation/homothety preserve signed measure
        @test rot.vertex ≈ rotate(vertex, pi / 3)
        hom = homothety(ang, -2.0, APPoint(0.5, 0.5))
        @test measure(hom) ≈ measure(ang)
        refl = reflection(ang, APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)))
        # APAngle2 swaps a/b under a line reflection (unlike the old bare
        # Angle) so its wedge (Base.in) stays a true mirror image rather
        # than the complementary region — see ap_unbounded.jl. Consequently
        # measure's sign is *preserved*, not flipped, by a mirror here.
        @test measure(refl) ≈ measure(ang)
        @test abs(refl) ≈ abs(ang)

        # degenerate: zero-measure angle (a and b in the same direction from vertex)
        zero_ang = APAngle2(vertex, APPoint(2.0, 0.0), APPoint(5.0, 0.0))
        @test measure(zero_ang) ≈ 0.0 atol = 1e-9
        @test abs(zero_ang) ≈ 0.0 atol = 1e-9

        # degenerate: straight angle (a, vertex, b collinear, opposite sides)
        straight = APAngle2(vertex, APPoint(1.0, 0.0), APPoint(-1.0, 0.0))
        @test abs(straight) ≈ pi atol = 1e-9
    end

    @testset "APQuadrilateral" begin
        a, b, c, d = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 3.0), APPoint(1.0, 3.0)
        q = APQuadrilateral(a, b, c, d)

        @test vertices(q) == (a, b, c, d)
        @test q[1] == a && q[4] == d
        @test collect(q) == [a, b, c, d]

        s = sides(q)
        @test length(s) == 4
        @test s[1] == APSegment(a, b)

        diags = diagonals(q)
        @test diags[1] == APSegment(a, c) && diags[2] == APSegment(b, d)
        @test diagonal_intersection(q) ≈ APPoint(16 / 7, 12 / 7)

        @test centroid(q) ≈ a + ((b - a) + (c - a) + (d - a)) / 4  # equal-weight average, unlike APStraightNgon's
        @test area(q) ≈ 10.5
        @test perimeter(q) ≈ distance(a, b) + distance(b, c) + distance(c, d) + distance(d, a)
        @test is_convex(q)
        @test !is_cyclic(q)  # this particular trapezoid isn't concyclic

        # no separate point_in_quadrilateral: point_in_polygon/Base.in are
        # already unified across the whole APPolygon family
        @test point_in_polygon(APPoint(2.0, 1.5), q)
        @test !point_in_polygon(APPoint(10.0, 10.0), q)

        bb = APBoundingBox(q)
        @test bb.min == APPoint(0.0, 0.0) && bb.max == APPoint(4.0, 3.0)

        # a genuinely cyclic (and non-convex-restricted) case: a square
        sq = square_on_segment(APPoint(0.0, 0.0), APPoint(2.0, 0.0))
        @test sq isa APQuadrilateral
        @test is_cyclic(sq)

        # non-convex (dart) quadrilateral
        dart = APQuadrilateral(APPoint(0.0, 0.0), APPoint(2.0, 1.0), APPoint(0.0, 2.0), APPoint(0.5, 1.0))
        @test !is_convex(dart)

        # transforms
        rot = rotate(q, pi / 6, APPoint(1.0, 1.0))
        @test rot == APQuadrilateral(rotate(a, pi / 6, APPoint(1.0, 1.0)), rotate(b, pi / 6, APPoint(1.0, 1.0)),
            rotate(c, pi / 6, APPoint(1.0, 1.0)), rotate(d, pi / 6, APPoint(1.0, 1.0)))
        @test area(rot) ≈ area(q) atol = 1e-9  # rotation preserves area

        hom = homothety(q, -2.0)
        @test area(hom) ≈ 4 * area(q) atol = 1e-9

        refl = reflection(q, APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)))
        @test area(refl) ≈ area(q) atol = 1e-9

        # degenerate: 4 collinear points -> zero area. `is_convex` still
        # reports `true` here: a set of collinear points is, degenerately, a
        # convex set (no concave vertex is ever found), same as it would be
        # for a APStraightNgon with the same vertices.
        collinear_q = APQuadrilateral(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(2.0, 0.0), APPoint(3.0, 0.0))
        @test area(collinear_q) ≈ 0.0 atol = 1e-9
        @test is_convex(collinear_q)
    end

    @testset "affine maps" begin
        p = APPoint(3.0, 2.0)
        center = APPoint(1.0, 1.0)

        rm = rotation_map(pi / 2, center)
        @test rm(p) ≈ rotate(p, pi / 2, center) atol = 1e-9

        hm = homothety_map(2.0, center)
        @test hm(p) ≈ homothety(p, 2.0, center)

        l = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
        refl = reflection_map(l)
        @test refl(p) ≈ reflection(p, l)

        tm = translation_map(APPoint(5.0, -3.0))
        @test tm(p) ≈ p + APVector(5.0, -3.0)

        # composition matches sequential application
        composed = hm ∘ rm
        @test composed(p) ≈ hm(rm(p)) atol = 1e-9

        # affine_map recovers an arbitrary map from 3 point correspondences
        src = (APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
        dst = map(rm, src)
        recovered = affine_map(src, dst)
        @test recovered(p) ≈ rm(p) atol = 1e-9

        # pointwise application to compound objects
        t = APTriangle(APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(0.0, 2.0))
        @test rm(t) == APTriangle(rm(t[1]), rm(t[2]), rm(t[3]))

        q = APQuadrilateral(APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(2.0, 2.0), APPoint(0.0, 2.0))
        @test rm(q) == APQuadrilateral(rm(q.a), rm(q.b), rm(q.c), rm(q.d))

        ang = APAngle2(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
        @test rm(ang) == APAngle2(rm(ang.vertex), rm(ang.a), rm(ang.b))

        # a general (non-conformal) affine map of a circle is an ellipse
        skew = APAffineMap(2.0, 0.5, -0.3, 1.4, 3.0, -1.0)
        c = APCircle2(APPoint(1.0, 2.0), 5.0)
        e = skew(c)
        @test e isa APEllipse2
        @test e.center ≈ skew(c.center)
        for θ in (0.0, 1.0, 2.5, 4.7)
            p = c.center + c.r * APVector(cos(θ), sin(θ))
            @test is_on_ellipse(skew(p), e; atol=1e-6)
        end
        # a conformal map (pure rotation) sends a circle to an ellipse with a == b
        e2 = rm(c)
        @test e2.a ≈ e2.b atol = 1e-9
        @test e2.center ≈ rm(c.center)

        @test_throws ArgumentError affine_map((APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(2.0, 0.0)), dst)
    end

    @testset "ellipse" begin
        e = APEllipse2(APPoint(0.0, 0.0), 2.0, 1.0)

        @test is_on_ellipse(APPoint(2.0, 0.0), e)
        @test is_on_ellipse(APPoint(0.0, 1.0), e)
        @test !is_on_ellipse(APPoint(2.0, 1.0), e)
        @test is_on_ellipse(point_on_ellipse(e, 0.7), e)

        @test area(e) ≈ pi * 2.0 * 1.0

        f1, f2 = foci(e)
        c = sqrt(2.0^2 - 1.0^2)
        @test f1 ≈ APPoint(c, 0.0)
        @test f2 ≈ APPoint(-c, 0.0)
        # defining property: sum of distances to the foci equals 2a for a point on the ellipse
        p = point_on_ellipse(e, 0.4)
        @test distance(p, f1) + distance(p, f2) ≈ 2 * e.a atol = 1e-9

        # line through the center hits the ellipse at the two axis endpoints
        pts = intersection(APLine(APPoint(-3.0, 0.0), APPoint(3.0, 0.0)), e)
        @test length(pts) == 2
        @test APPoint(2.0, 0.0) in pts
        @test APPoint(-2.0, 0.0) in pts

        tangent = APLine(APPoint(-1.0, 1.0), APPoint(1.0, 1.0))
        @test only(intersection(tangent, e)) ≈ APPoint(0.0, 1.0)

        far = APLine(APPoint(-1.0, 5.0), APPoint(1.0, 5.0))
        @test isempty(intersection(far, e))

        # rotated ellipse: local-frame math should still hold
        rot_e = APEllipse2(APPoint(1.0, 1.0), 2.0, 1.0, pi / 4)
        @test is_on_ellipse(point_on_ellipse(rot_e, 1.1), rot_e)

        # tangent lines from an external point
        rot_e2 = APEllipse2(APPoint(1.0, 1.0), 3.0, 2.0, pi / 6)
        pext = APPoint(8.0, 5.0)
        tpts = tangent_points(rot_e2, pext)
        @test length(tpts) == 2
        for tp in tpts
            @test is_on_ellipse(tp, rot_e2)
            @test only(intersection(APLine(pext, tp), rot_e2)) ≈ tp  # genuinely tangent: touches once
        end
        @test tangent_lines(rot_e2, pext) == [APLine(pext, tp) for tp in tpts]
        @test tangent_points(pext, rot_e2) == tpts

        # a point inside the ellipse (center or otherwise) has no tangent lines
        @test isempty(tangent_points(e, e.center))
        @test isempty(tangent_points(e, e.center + APVector(0.1, 0.1)))

        # tangent_lines when p is on the ellipse: the tangent line at p, not APLine(p,p)
        p_on = point_on_ellipse(rot_e2, 0.4)
        tl_on = only(tangent_lines(rot_e2, p_on))
        @test tl_on.p1 != tl_on.p2
        # touches only at p: right at a double root, the quadratic formula's
        # cancellation can report 2 roots a few atol-scales apart instead of
        # exactly 1 (same phenomenon as the hyperbola case above), so check
        # closeness to p rather than an exact count
        @test all(cand -> distance(cand, p_on) < 1e-6, intersection(tl_on, rot_e2))

        # orthoptic (director) circle: tangents from any point on it are perpendicular
        e3 = APEllipse2(APPoint(1.0, 2.0), 5.0, 3.0, 0.3)
        oc = orthoptic(e3)
        @test oc.center == e3.center
        @test oc.r ≈ sqrt(e3.a^2 + e3.b^2)
        p_oc = e3.center + oc.r * APVector(cos(0.7), sin(0.7))
        tl_oc = tangent_lines(e3, p_oc)
        @test length(tl_oc) == 2
        @test dot(direction(tl_oc[1]), direction(tl_oc[2])) ≈ 0.0 atol = 1e-9

        # perimeter: exact for a circle, and consistent with a fine polygon
        # approximation (Ramanujan's 2nd approximation is not exact in general)
        circle_e = APEllipse2(APPoint(0.0, 0.0), 3.0, 3.0)
        @test perimeter(circle_e) ≈ 2 * pi * 3.0 atol = 1e-9
        function poly_perimeter(e; n=20_000)
            total = 0.0
            prev = point_on_ellipse(e, 0.0)
            for i in 1:n
                cur = point_on_ellipse(e, 2pi * i / n)
                total += distance(prev, cur)
                prev = cur
            end
            return total
        end
        @test perimeter(rot_e2) ≈ poly_perimeter(rot_e2) atol = 1e-3

        # transforms
        rot = rotate(e, pi / 5, APPoint(1.0, 0.0))
        @test rot.center ≈ rotate(e.center, pi / 5, APPoint(1.0, 0.0))
        @test rot.a ≈ e.a && rot.b ≈ e.b
        @test rot.angle ≈ e.angle + pi / 5

        hom_neg = homothety(e, -1.5)
        @test hom_neg.a ≈ 1.5 * e.a && hom_neg.b ≈ 1.5 * e.b  # abs(k), not k
        @test hom_neg.angle ≈ e.angle  # unchanged, even for negative k

        refl_pt = reflection(e, APPoint(2.0, -3.0))
        @test refl_pt.angle ≈ e.angle  # point reflection: angle unchanged
        @test refl_pt.a ≈ e.a && refl_pt.b ≈ e.b

        line_about = APLine(APPoint(0.0, 0.0), APPoint(1.0, 2.0))
        refl_line = reflection(e, line_about)
        φ = atan(direction(line_about)[2], direction(line_about)[1])
        @test refl_line.angle ≈ 2φ - e.angle
        for t in (0.0, 1.3, 3.1)
            @test is_on_ellipse(reflection(point_on_ellipse(e, t), line_about), refl_line; atol=1e-6)
        end
    end

    @testset "tangent circles with given radius" begin
        l1 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
        l2 = APLine(APPoint(0.0, 0.0), APPoint(0.0, 1.0))
        sols = tangent_circles_with_radius(l1, l2, 1.0)
        @test length(sols) == 4
        for c in sols
            @test distance(c.center, l1) ≈ 1.0 atol = 1e-9
            @test distance(c.center, l2) ≈ 1.0 atol = 1e-9
            @test c.r == 1.0
        end

        # parallel lines are a documented no-solution case (would need an
        # infinite family of centers, not finitely many circles)
        parallel1 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
        parallel2 = APLine(APPoint(0.0, 5.0), APPoint(1.0, 5.0))
        @test isempty(tangent_circles_with_radius(parallel1, parallel2, 2.5))

        oblique1 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
        oblique2 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.5))
        oblique_sols = tangent_circles_with_radius(oblique1, oblique2, 1.0)
        @test length(oblique_sols) == 4
        for c in oblique_sols
            @test distance(c.center, oblique1) ≈ 1.0 atol = 1e-9
            @test distance(c.center, oblique2) ≈ 1.0 atol = 1e-9
        end

        line = APLine(APPoint(-10.0, 0.0), APPoint(10.0, 0.0))
        circ = APCircle2(APPoint(0.0, 5.0), 3.0)
        lc_sols = tangent_circles_with_radius(line, circ, 2.0)
        @test !isempty(lc_sols)
        for c in lc_sols
            @test distance(c.center, line) ≈ 2.0 atol = 1e-9
            @test abs(distance(c.center, circ.center) - (circ.r + 2.0)) <= 1e-9 ||
                  abs(distance(c.center, circ.center) - abs(circ.r - 2.0)) <= 1e-9
        end

        c1 = APCircle2(APPoint(0.0, 0.0), 1.0)
        c2 = APCircle2(APPoint(3.0, 0.0), 1.0)
        cc_sols = tangent_circles_with_radius(c1, c2, 1.0)
        @test !isempty(cc_sols)
        for c in cc_sols
            @test c.r == 1.0
        end
    end

    @testset "power of a point, radical axis, radical center" begin
        c = APCircle2(APPoint(0.0, 0.0), 2.0)
        @test power_of_point(APPoint(0.0, 0.0), c) == -4.0
        @test power_of_point(APPoint(2.0, 0.0), c) == 0.0
        @test power_of_point(APPoint(4.0, 0.0), c) == 12.0

        c1 = APCircle2(APPoint(0.0, 0.0), 2.0)
        c2 = APCircle2(APPoint(6.0, 0.0), 1.5)
        c3 = APCircle2(APPoint(2.0, 5.0), 1.0)

        l12, l23, l13 = radical_axis(c1, c2), radical_axis(c2, c3), radical_axis(c1, c3)
        rc = radical_center(c1, c2, c3)
        @test on_line(rc, l12; atol=1e-9)
        @test on_line(rc, l23; atol=1e-9)
        @test on_line(rc, l13; atol=1e-9)  # concurrency theorem
        @test power_of_point(rc, c1) ≈ power_of_point(rc, c2) atol = 1e-9
        @test power_of_point(rc, c2) ≈ power_of_point(rc, c3) atol = 1e-9

        # radical axis is perpendicular to the line joining the centers
        @test is_perpendicular(l12, APLine(c1.center, c2.center))

        # equal-radius circles: radical axis is the perpendicular bisector of the centers
        c4, c5 = APCircle2(APPoint(0.0, 0.0), 1.0), APCircle2(APPoint(6.0, 0.0), 1.0)
        @test radical_axis(c4, c5) ≈ perpendicular_bisector(c4.center, c5.center)

        # intersecting circles: radical axis passes through both intersection points
        c6, c7 = APCircle2(APPoint(0.0, 0.0), 2.0), APCircle2(APPoint(3.0, 0.0), 2.0)
        for p in intersection(c6, c7)
            @test on_line(p, radical_axis(c6, c7); atol=1e-6)
        end

        @test_throws ArgumentError radical_axis(c, APCircle2(c.center, 5.0))

        # radical circle: orthogonal to all three (d^2 == r1^2 + r2^2)
        far1 = APCircle2(APPoint(0.0, 0.0), 2.0)
        far2 = APCircle2(APPoint(8.0, 0.0), 1.5)
        far3 = APCircle2(APPoint(2.0, 9.0), 1.0)
        rcirc = radical_circle(far1, far2, far3)
        for cc in (far1, far2, far3)
            d = distance(rcirc.center, cc.center)
            @test d^2 ≈ rcirc.r^2 + cc.r^2 atol = 1e-9
        end
        @test rcirc.center ≈ radical_center(far1, far2, far3)

        # radical center inside the circles: no real orthogonal circle
        inside1 = APCircle2(APPoint(0.0, 0.0), 5.0)
        inside2 = APCircle2(APPoint(1.0, 0.0), 5.0)
        inside3 = APCircle2(APPoint(0.0, 1.0), 5.0)
        @test_throws ArgumentError radical_circle(inside1, inside2, inside3)
    end

    @testset "apollonius: circle through 2 points tangent to a line/circle" begin
        a, b = APPoint(1.0, 3.0), APPoint(5.0, 4.0)
        l = APLine(APPoint(-10.0, 0.0), APPoint(10.0, 0.7))

        lpp = tangent_circles_through_points(a, b, l)
        @test length(lpp) == 2
        for c in lpp
            @test distance(c.center, a) ≈ c.r atol = 1e-6
            @test distance(c.center, b) ≈ c.r atol = 1e-6
            @test distance(c.center, l) ≈ c.r atol = 1e-6
        end

        # symmetric case: perpendicular bisector of [a,b] parallel to itself
        # under the line's reflection -> exactly one of the two roots survives
        a2, b2 = APPoint(0.0, 2.0), APPoint(4.0, 2.0)
        l2 = APLine(APPoint(-10.0, 0.0), APPoint(10.0, 0.0))
        lpp2 = tangent_circles_through_points(a2, b2, l2)
        @test length(lpp2) == 1
        @test lpp2[1].center ≈ APPoint(2.0, 2.0)
        @test lpp2[1].r ≈ 2.0

        c = APCircle2(APPoint(8.0, 2.0), 2.0)
        cpp = tangent_circles_through_points(APPoint(1.0, 1.0), APPoint(2.0, 4.0), c)
        @test length(cpp) == 2
        for sol in cpp
            @test distance(sol.center, APPoint(1.0, 1.0)) ≈ sol.r atol = 1e-6
            @test distance(sol.center, APPoint(2.0, 4.0)) ≈ sol.r atol = 1e-6
            dc = distance(sol.center, c.center)
            @test abs(dc - (c.r + sol.r)) <= 1e-6 || abs(dc - abs(c.r - sol.r)) <= 1e-6
        end
    end

    @testset "angle bisectors" begin
        l1 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
        l2 = APLine(APPoint(0.0, 0.0), APPoint(0.0, 1.0))
        bis = angle_bisectors(l1, l2)
        @test length(bis) == 2
        @test is_perpendicular(bis[1], bis[2])
        for b in bis
            p = b.p1 + direction(b)
            @test distance(p, l1) ≈ distance(p, l2) atol = 1e-9
        end

        # parallel lines: single midline, equidistant from both
        pl1 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
        pl2 = APLine(APPoint(0.0, 4.0), APPoint(1.0, 4.0))
        midbis = angle_bisectors(pl1, pl2)
        @test length(midbis) == 1
        @test distance(midbis[1].p1, pl1) ≈ distance(midbis[1].p1, pl2) atol = 1e-9
        @test distance(midbis[1].p1, pl1) ≈ 2.0 atol = 1e-9
    end

    @testset "angle trisectors" begin
        v, p1, p2 = APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0)
        rays = angle_trisectors(v, p1, p2)
        @test length(rays) == 2
        @test rays[1].origin == v && rays[2].origin == v
        @test angle_at(v, p1, rays[1].through) ≈ pi / 6 atol = 1e-9
        @test angle_at(v, rays[1].through, rays[2].through) ≈ pi / 6 atol = 1e-9
        @test angle_at(v, rays[2].through, p2) ≈ pi / 6 atol = 1e-9

        # reversing p1/p2 reverses the trisection order (each ray is still
        # 1/3 and 2/3 of the way from p1 to p2, whichever comes "first")
        rays_rev = angle_trisectors(v, p2, p1)
        @test angle_at(v, p2, rays_rev[1].through) ≈ pi / 6 atol = 1e-9
        @test angle_at(v, rays_rev[2].through, p1) ≈ pi / 6 atol = 1e-9
    end

    @testset "apollonius: circle tangent to 2 lines through a point (LLP)" begin
        l1 = APLine(APPoint(0.0, 0.0), APPoint(3.0, 1.0))
        l2 = APLine(APPoint(0.0, 0.0), APPoint(-1.0, 2.0))
        p = APPoint(2.0, 5.0)

        sols = tangent_circles_through_point(l1, l2, p)
        @test !isempty(sols)
        for c in sols
            @test distance(c.center, l1) ≈ c.r atol = 1e-6
            @test distance(c.center, l2) ≈ c.r atol = 1e-6
            @test distance(c.center, p) ≈ c.r atol = 1e-6
        end

        # parallel lines
        pl1 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
        pl2 = APLine(APPoint(0.0, 4.0), APPoint(1.0, 4.0))
        p2 = APPoint(10.0, 1.0)
        psols = tangent_circles_through_point(pl1, pl2, p2)
        @test length(psols) == 2
        for c in psols
            @test distance(c.center, pl1) ≈ c.r atol = 1e-6
            @test distance(c.center, pl2) ≈ c.r atol = 1e-6
            @test distance(c.center, p2) ≈ c.r atol = 1e-6
        end
    end

    @testset "apollonius: circle tangent to 2 circles / a line+circle through a point (CCP, CLP)" begin
        C1 = APCircle2(APPoint(0.0, 0.0), 1.0)
        C2 = APCircle2(APPoint(5.0, 0.0), 1.5)
        P = APPoint(2.0, 3.0)

        ccp = tangent_circles_through_point(C1, C2, P)
        @test length(ccp) == 4
        for sol in ccp
            @test distance(sol.center, P) ≈ sol.r atol = 1e-6
            for c in (C1, C2)
                d = distance(sol.center, c.center)
                @test abs(d - (c.r + sol.r)) <= 1e-6 || abs(d - abs(c.r - sol.r)) <= 1e-6
            end
        end
        # order shouldn't matter
        @test length(tangent_circles_through_point(C2, C1, P)) == 4

        L = APLine(APPoint(-10.0, 0.0), APPoint(10.0, 0.0))
        C = APCircle2(APPoint(3.0, 6.0), 2.0)
        Pl = APPoint(-2.0, 4.0)

        clp = tangent_circles_through_point(L, C, Pl)
        @test !isempty(clp)
        for sol in clp
            @test distance(sol.center, Pl) ≈ sol.r atol = 1e-6
            @test distance(sol.center, L) ≈ sol.r atol = 1e-6
            d = distance(sol.center, C.center)
            @test abs(d - (C.r + sol.r)) <= 1e-6 || abs(d - abs(C.r - sol.r)) <= 1e-6
        end
        @test length(tangent_circles_through_point(C, L, Pl)) == length(clp)
    end

    @testset "apollonius: CLL, CCL, CCC (no point, every internal/external combination)" begin
        l1 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.2))
        l2 = APLine(APPoint(1.0, -3.0), APPoint(0.3, 1.0))
        c = APCircle2(APPoint(4.0, 2.0), 1.3)

        cll = tangent_circles(l1, l2, c)
        @test length(cll) == 4
        for sol in cll
            @test distance(sol.center, l1) ≈ sol.r atol = 1e-6
            @test distance(sol.center, l2) ≈ sol.r atol = 1e-6
            d = distance(sol.center, c.center)
            @test abs(d - (c.r + sol.r)) <= 1e-6 || abs(d - abs(c.r - sol.r)) <= 1e-6
        end
        @test length(tangent_circles(c, l1, l2)) == length(cll)

        # parallel lines aren't handled by this method
        @test isempty(tangent_circles(APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0)),
                                       APLine(APPoint(0.0, 4.0), APPoint(1.0, 4.0)),
                                       c))

        c1 = APCircle2(APPoint(0.0, 0.0), 1.0)
        c2 = APCircle2(APPoint(6.0, 0.0), 1.2)
        l = APLine(APPoint(-5.0, 5.0), APPoint(5.0, 6.0))

        ccl = tangent_circles(c1, c2, l)
        @test length(ccl) == 8
        for sol in ccl
            @test distance(sol.center, l) ≈ sol.r atol = 1e-6
            for cc in (c1, c2)
                d = distance(sol.center, cc.center)
                @test abs(d - (cc.r + sol.r)) <= 1e-6 || abs(d - abs(cc.r - sol.r)) <= 1e-6
            end
        end
        @test length(tangent_circles(l, c1, c2)) == length(ccl)

        # the classical Apollonius problem: circle(s) tangent to 3 circles
        ca = APCircle2(APPoint(0.0, 0.0), 1.0)
        cb = APCircle2(APPoint(6.0, 0.0), 1.5)
        cc = APCircle2(APPoint(3.0, 5.0), 1.2)

        ccc = tangent_circles(ca, cb, cc)
        @test length(ccc) == 8
        for sol in ccc
            for c0 in (ca, cb, cc)
                d = distance(sol.center, c0.center)
                @test abs(d - (c0.r + sol.r)) <= 1e-6 || abs(d - abs(c0.r - sol.r)) <= 1e-6
            end
        end

        # the classic "3 mutually tangent circles + inscribed circle" configuration:
        # unit circles centered at the vertices of an equilateral triangle of side 2
        # have a small circle nestled between them, tangent to all three externally
        eqc1 = APCircle2(APPoint(0.0, 0.0), 1.0)
        eqc2 = APCircle2(APPoint(2.0, 0.0), 1.0)
        eqc3 = APCircle2(APPoint(1.0, sqrt(3.0)), 1.0)
        nestled = tangent_circles(eqc1, eqc2, eqc3)
        @test any(sol -> sol.center ≈ APPoint(1.0, sqrt(3.0) / 3) && sol.r < 1.0, nestled)
        # with 3 mutually tangent circles, a circle is degenerately "tangent to
        # itself" under the ε-sign algebra, so this configuration used to
        # (spuriously) return eqc1/eqc2/eqc3 back as extra "solutions" —
        # exactly the small nested circle and the big enclosing one, no more
        @test length(nestled) == 2
        for c0 in (eqc1, eqc2, eqc3)
            @test !any(sol -> sol.center ≈ c0.center && sol.r ≈ c0.r, nestled)
        end

        # regression: a large circle mutually tangent to two others of a
        # symmetric trio used to come back duplicated (dedup tolerance wasn't
        # scaled to the problem's size) and a third, unrelated circle used to
        # come back exactly as a spurious "solution" too (see above)
        big_r = 100.0
        p1 = polar_point_deg(big_r, 90.0, APPoint(0.0, 0.0))
        p2 = polar_point_deg(big_r, 210.0, APPoint(0.0, 0.0))
        p3 = polar_point_deg(big_r, 330.0, APPoint(0.0, 0.0))
        side = distance(p1, p2)
        k1 = APCircle2(p1, side / 2)
        k2 = APCircle2(p2, side / 2)
        k3 = APCircle2(p3, side / 2)
        outer = APCircle2(APPoint(0.0, 0.0), big_r + side / 2)

        sols = tangent_circles(outer, k1, k2)
        @test length(sols) == 2
        @test !any(sol -> sol.center ≈ outer.center && sol.r ≈ outer.r, sols)
        @test !any(sol -> sol.center ≈ k2.center && sol.r ≈ k2.r, sols)
        @test any(sol -> sol.center ≈ k3.center && sol.r ≈ k3.r, sols)  # coincides for real, kept
    end

    @testset "APCircularArc2" begin
        circ = APCircle2(APPoint(1.0, 2.0), 5.0)
        p1 = circ.center + APVector(5.0, 0.0)   # angle 0
        p2 = circ.center + APVector(0.0, 5.0)   # angle pi/2
        arc = APCircularArc2(circ, p1, p2)

        @test measure(arc) ≈ pi / 2 atol = 1e-9
        @test arc_length(arc) ≈ 5.0 * pi / 2 atol = 1e-9
        @test point_on_arc(arc, 0.0) ≈ p1
        @test point_on_arc(arc, 1.0) ≈ p2
        @test midpoint(arc) ≈ circ.center + APVector(5.0 * cos(pi / 4), 5.0 * sin(pi / 4))

        # reversing p1/p2 gives the complementary arc (3/4 turn, not 1/4)
        rev = APCircularArc2(circ, p2, p1)
        @test measure(rev) ≈ 3pi / 2 atol = 1e-9

        @test arc ≈ APCircularArc2(circ, p1, p2)
        @test !(arc ≈ rev)

        @test reverse(arc) == rev
        @test reverse(reverse(arc)) == arc

        # degenerate: p1 == p2 -> zero measure, not a full turn
        deg = APCircularArc2(circ, p1, p1)
        @test measure(deg) ≈ 0.0 atol = 1e-9
        @test arc_length(deg) ≈ 0.0 atol = 1e-9
        @test midpoint(deg) ≈ p1

        # diametrically opposite points: measure is exactly pi either way
        antip = circ.center - (p1 - circ.center)
        half = APCircularArc2(circ, p1, antip)
        @test measure(half) ≈ pi atol = 1e-9

        # transforms
        rot = rotate(arc, pi / 3, APPoint(1.0, 1.0))
        @test measure(rot) ≈ measure(arc) atol = 1e-9  # rotation preserves the sweep
        @test rot.p1 ≈ rotate(p1, pi / 3, APPoint(1.0, 1.0))

        hom = homothety(arc, 2.5, APPoint(1.0, 1.0))
        @test measure(hom) ≈ measure(arc) atol = 1e-9
        @test hom.circle.r ≈ 2.5 * circ.r

        hom_neg = homothety(arc, -1.0, APPoint(1.0, 1.0))  # a point reflection: no swap, same measure
        @test measure(hom_neg) ≈ measure(arc) atol = 1e-9

        about_pt = APPoint(3.0, -1.0)
        refl_pt = reflection(arc, about_pt)
        @test measure(refl_pt) ≈ measure(arc) atol = 1e-9  # point reflection: orientation-preserving
        @test distance(reflection(midpoint(arc), about_pt), refl_pt.circle.center) ≈ refl_pt.circle.r atol = 1e-9

        about_line = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
        refl_line = reflection(arc, about_line)
        @test measure(refl_line) ≈ measure(arc) atol = 1e-9  # swap restores the same swept angle
        @test point_on_arc(refl_line, 0.5) ≈ reflection(midpoint(arc), about_line) atol = 1e-6
    end

    @testset "APCircularSector2 and APCircularSegment2" begin
        circ = APCircle2(APPoint(2.0, -1.0), 5.0)
        p1 = circ.center + APVector(5.0, 0.0)

        for θ in (2.3, 4.5)  # a minor (< π) and a major (> π) case
            p2 = circ.center + APVector(5.0 * cos(θ), 5.0 * sin(θ))
            arc = APCircularArc2(circ, p1, p2)

            sec = APCircularSector2(arc)
            @test sec == APCircularSector2(circ, p1, p2)
            @test area(sec) ≈ 0.5 * circ.r^2 * θ atol = 1e-9
            @test perimeter(sec) ≈ 2 * circ.r + arc_length(arc) atol = 1e-9
            @test circ.center in sec
            @test midpoint(arc) in sec
            @test !(circ.center + APVector(5.0 * cos(θ + 0.5), 5.0 * sin(θ + 0.5)) in sec)  # outside the swept angle
            @test !((circ.center + 6.0 * (midpoint(arc) - circ.center) / circ.r) in sec)  # outside the radius

            seg = APCircularSegment2(arc)
            @test seg == APCircularSegment2(circ, p1, p2)
            @test area(seg) ≈ 0.5 * circ.r^2 * (θ - sin(θ)) atol = 1e-9
            @test perimeter(seg) ≈ arc_length(arc) + distance(p1, p2) atol = 1e-9
            @test midpoint(arc) in seg
            @test (circ.center in seg) == (θ > pi)  # the center is only "inside" the major segment
        end

        # area consistency: sector = segment + triangle(center, p1, p2)
        θ = 2.3
        p2 = circ.center + APVector(5.0 * cos(θ), 5.0 * sin(θ))
        arc = APCircularArc2(circ, p1, p2)
        tri = APTriangle(circ.center, p1, p2)
        @test area(APCircularSector2(arc)) ≈ area(APCircularSegment2(arc)) + area(tri) atol = 1e-9

        # degenerate: zero-measure sector/segment (p1 == p2) has zero area
        deg_arc = APCircularArc2(circ, p1, p1)
        @test area(APCircularSector2(deg_arc)) ≈ 0.0 atol = 1e-9
        @test area(APCircularSegment2(deg_arc)) ≈ 0.0 atol = 1e-9

        # semicircle segment: chord is a diameter, area is exactly half the circle
        p_diam = circ.center - (p1 - circ.center)
        half_arc = APCircularArc2(circ, p1, p_diam)
        @test area(APCircularSegment2(half_arc)) ≈ pi * circ.r^2 / 2 atol = 1e-9
        @test area(APCircularSector2(half_arc)) ≈ pi * circ.r^2 / 2 atol = 1e-9

        # transforms (delegate to the underlying arc's, already verified above)
        sec = APCircularSector2(arc)
        rot = rotate(sec, pi / 4, APPoint(1.0, 1.0))
        @test area(rot) ≈ area(sec) atol = 1e-9
        hom = homothety(sec, 2.0, APPoint(1.0, 1.0))
        @test area(hom) ≈ 4 * area(sec) atol = 1e-9
        refl = reflection(sec, APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)))
        @test area(refl) ≈ area(sec) atol = 1e-9

        seg = APCircularSegment2(arc)
        rot_s = rotate(seg, pi / 4, APPoint(1.0, 1.0))
        @test area(rot_s) ≈ area(seg) atol = 1e-9
        hom_s = homothety(seg, 2.0, APPoint(1.0, 1.0))
        @test area(hom_s) ≈ 4 * area(seg) atol = 1e-9
        refl_s = reflection(seg, APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)))
        @test area(refl_s) ≈ area(seg) atol = 1e-9
    end

    # An APInterstice2's 3 arcs each connect to their neighbors via *some*
    # shared endpoint (p1 or p2, on either side) — not necessarily already
    # sequenced arc1->arc2->arc3 in that direction; `path(::APInterstice2)`
    # is what does the reversal-aware chaining. So the general check is:
    # among the 6 endpoints, exactly 3 distinct points, each shared by
    # exactly 2 of the 3 arcs.
    function _forms_closed_triangle(g; atol=1e-6)
        pts = [g.arc1.p1, g.arc1.p2, g.arc2.p1, g.arc2.p2, g.arc3.p1, g.arc3.p2]
        groups = APPoint[]
        counts = Int[]
        for p in pts
            idx = findfirst(q -> isapprox(p, q; atol=atol), groups)
            if idx === nothing
                push!(groups, p)
                push!(counts, 1)
            else
                counts[idx] += 1
            end
        end
        return length(groups) == 3 && all(==(2), counts)
    end

    @testset "interstices: chain (3 externally tangent circles)" begin
        c1 = Apollonius.APCircle2(APPoint(0.0, 0.0), 40.0)
        c2 = Apollonius.APCircle2(APPoint(90.0, 0.0), 50.0)  # tangent to c1: 90 == 40+50
        locus1 = Apollonius.APCircle2(c1.center, c1.r + 35.0)
        locus2 = Apollonius.APCircle2(c2.center, c2.r + 35.0)
        c3 = Apollonius.APCircle2(intersection(locus1, locus2)[1], 35.0)

        @test distance(c1.center, c3.center) ≈ c1.r + c3.r atol = 1e-6
        @test distance(c2.center, c3.center) ≈ c2.r + c3.r atol = 1e-6

        gaps = interstices(c1, c2, c3)
        @test length(gaps) == 1
        g = gaps[1]

        @test _forms_closed_triangle(g)

        # each arc's circle matches one of the 3 given circles
        arc_circles = [a.circle for a in g]
        for c in (c1, c2, c3)
            @test any(ac -> ac.center ≈ c.center && ac.r ≈ c.r, arc_circles)
        end

        # order independence
        @test length(interstices(c2, c3, c1)) == 1
        @test length(interstices(c3, c1, c2)) == 1

        # not mutually tangent -> error
        @test_throws ArgumentError interstices(Apollonius.APCircle2(APPoint(0.0, 0.0), 1.0), Apollonius.APCircle2(APPoint(5.0, 0.0), 1.0), Apollonius.APCircle2(APPoint(0.0, 5.0), 1.0))

        # area/perimeter, checked against a fine polygon approximation walked
        # in the same reversal-aware order as `path`/`area` itself use
        function walk_order(g; atol=1e-6)
            arcs = (g.arc1, g.arc2, g.arc3)
            order = [(arcs[1], false)]
            used, last_pt = Set(1), arcs[1].p2
            for _ in 1:2
                for i in setdiff(1:3, used)
                    if isapprox(arcs[i].p1, last_pt; atol=atol)
                        push!(order, (arcs[i], false)); last_pt = arcs[i].p2; push!(used, i); break
                    elseif isapprox(arcs[i].p2, last_pt; atol=atol)
                        push!(order, (arcs[i], true)); last_pt = arcs[i].p1; push!(used, i); break
                    end
                end
            end
            return order
        end
        function shoelace_area(g; n=20_000)
            pts = APPoint{2,Float64}[]
            for (a, reversed) in walk_order(g)
                ts = reversed ? range(1, 0; length=n) : range(0, 1; length=n)
                for t in ts
                    push!(pts, point_on_arc(a, t))
                end
            end
            total = 0.0
            m = length(pts)
            for i in 1:m
                p, q = pts[i], pts[mod1(i + 1, m)]
                total += p[1] * q[2] - q[1] * p[2]
            end
            return abs(total) / 2
        end
        @test area(g) ≈ shoelace_area(g) atol = 1e-3
        @test perimeter(g) ≈ arc_length(g.arc1) + arc_length(g.arc2) + arc_length(g.arc3)

        # transforms
        rot = rotate(g, pi / 3, APPoint(1.0, 1.0))
        @test area(rot) ≈ area(g) atol = 1e-6
        @test _forms_closed_triangle(rot)

        hom = homothety(g, 2.0, APPoint(1.0, 1.0))
        @test area(hom) ≈ 4 * area(g) atol = 1e-6
        @test _forms_closed_triangle(hom)

        refl_pt = reflection(g, APPoint(1.0, 1.0))
        @test area(refl_pt) ≈ area(g) atol = 1e-6
        @test _forms_closed_triangle(refl_pt)

        refl_line = reflection(g, APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)))
        @test area(refl_line) ≈ area(g) atol = 1e-6
        @test _forms_closed_triangle(refl_line)

        # symmetric edge case: 3 equal circles
        r = 10.0
        e1 = Apollonius.APCircle2(APPoint(0.0, 0.0), r)
        e2 = Apollonius.APCircle2(APPoint(2r, 0.0), r)
        e3 = Apollonius.APCircle2(APPoint(r, r * sqrt(3.0)), r)
        eg = only(interstices(e1, e2, e3))
        @test _forms_closed_triangle(eg)
        @test area(eg) ≈ shoelace_area(eg) atol = 1e-3
        # by symmetry, each of the 3 arcs sweeps the same angle
        m1, m2, m3 = measure(eg.arc1), measure(eg.arc2), measure(eg.arc3)
        @test isapprox(m1, m2; atol=1e-9) && isapprox(m2, m3; atol=1e-9)
    end

    @testset "interstices: nested (one circle containing two tangent circles)" begin
        R = 100.0
        Cc = Apollonius.APCircle2(APPoint(0.0, 0.0), R)
        rA = 25.0
        pA = polar_point_deg(R - rA, 100.0, APPoint(0.0, 0.0))
        A = Apollonius.APCircle2(pA, rA)
        rB = 45.0
        pB = intersection(Apollonius.APCircle2(APPoint(0.0, 0.0), R - rB), Apollonius.APCircle2(pA, rA + rB))[1]
        B = Apollonius.APCircle2(pB, rB)

        gaps = interstices(Cc, A, B)
        @test length(gaps) == 2

        for g in gaps
            @test _forms_closed_triangle(g)
        end

        # the two interstices are genuinely different regions
        @test !(gaps[1] ≈ gaps[2])

        # together, their swept angles on Cc account for its full circle
        function measure_on(g, c)
            for a in g
                a.circle.center ≈ c.center && a.circle.r ≈ c.r && return measure(a)
            end
            return nothing
        end
        m1, m2 = measure_on(gaps[1], Cc), measure_on(gaps[2], Cc)
        @test m1 + m2 ≈ 2π atol = 1e-6

        @test length(interstices(A, B, Cc)) == 2  # order independence

        # area/perimeter and transforms on the nested (large-radius-ratio) case
        for g in gaps
            @test perimeter(g) ≈ arc_length(g.arc1) + arc_length(g.arc2) + arc_length(g.arc3)
            @test area(g) > 0

            rot = rotate(g, 0.7, APPoint(3.0, -2.0))
            @test area(rot) ≈ area(g) atol = 1e-3
            @test _forms_closed_triangle(rot)

            hom = homothety(g, -3.0, APPoint(3.0, -2.0))
            @test area(hom) ≈ 9 * area(g) atol = 1e-2
            @test _forms_closed_triangle(hom)
        end
    end

    @testset "parabola" begin
        focus = APPoint(0.0, 1.0)
        directrix = APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0))
        par = APParabola2(focus, directrix)

        @test vertex(par) == APPoint(0.0, 0.0)
        @test focal_parameter(par) == 2.0

        v = vertex(par)
        @test distance(v, focus) ≈ distance(v, directrix)
        @test is_on_parabola(v, par)

        p = point_on_parabola(par, 3.0)
        @test is_on_parabola(p, par)

        # focus above a horizontal directrix -> axis is vertical, parabola
        # opens upward: global X^2 = 2p*Y, i.e. Y = X^2/(2p) with p = 2
        @test p ≈ APPoint(-3.0, 2.25)

        horizontal_line = APLine(APPoint(-10.0, 2.25), APPoint(10.0, 2.25))
        pts = intersection(horizontal_line, par)
        @test length(pts) == 2
        @test APPoint(3.0, 2.25) in pts
        @test APPoint(-3.0, 2.25) in pts

        tangent_at_vertex = APLine(APPoint(-5.0, 0.0), APPoint(5.0, 0.0))
        @test only(intersection(tangent_at_vertex, par)) ≈ APPoint(0.0, 0.0)

        missing_line = APLine(APPoint(-5.0, -5.0), APPoint(5.0, -5.0))
        @test isempty(intersection(missing_line, par))

        # tangent lines from an external point
        pext = APPoint(5.0, 5.0)
        tpts = tangent_points(par, pext)
        @test length(tpts) == 2
        for tp in tpts
            @test is_on_parabola(tp, par)
            @test only(intersection(APLine(pext, tp), par)) ≈ tp
        end
        @test tangent_lines(par, pext) == [APLine(pext, tp) for tp in tpts]
        @test tangent_points(pext, par) == tpts

        # a point "inside" the parabola (focus side) has no tangent lines
        @test isempty(tangent_points(par, par.focus))

        # tangent_lines when p is on the parabola: the tangent line at p, not APLine(p,p)
        p_on_par = point_on_parabola(par, 1.5)
        tl_on = only(tangent_lines(par, p_on_par))
        @test tl_on.p1 != tl_on.p2
        @test length(intersection(tl_on, par)) == 1

        # orthoptic curve of a parabola is exactly its own directrix
        @test orthoptic(par) == par.directrix
        p_on_directrix = APPoint(3.0, -1.0)
        tl_dir = tangent_lines(par, p_on_directrix)
        @test length(tl_dir) == 2
        @test dot(direction(tl_dir[1]), direction(tl_dir[2])) ≈ 0.0 atol = 1e-9

        # transforms: par is fully determined by focus+directrix, both of
        # which already transform correctly on their own
        rot = rotate(par, pi / 4, APPoint(1.0, 0.0))
        @test rot == APParabola2(rotate(focus, pi / 4, APPoint(1.0, 0.0)), rotate(directrix, pi / 4, APPoint(1.0, 0.0)))
        @test is_on_parabola(rotate(p, pi / 4, APPoint(1.0, 0.0)), rot; atol=1e-6)

        hom = homothety(par, -2.0)
        @test is_on_parabola(homothety(p, -2.0), hom; atol=1e-6)

        refl = reflection(par, APPoint(0.0, 0.0))
        @test is_on_parabola(reflection(p, APPoint(0.0, 0.0)), refl; atol=1e-6)
    end

    @testset "hyperbola" begin
        h = APHyperbola2(APPoint(0.0, 0.0), 2.0, 1.0)

        @test is_on_hyperbola(APPoint(2.0, 0.0), h)   # right-branch vertex
        @test is_on_hyperbola(APPoint(-2.0, 0.0), h)  # left-branch vertex
        @test !is_on_hyperbola(APPoint(0.0, 0.0), h)
        @test is_on_hyperbola(point_on_hyperbola(h, 0.6), h)
        @test is_on_hyperbola(point_on_hyperbola(h, 0.6; branch=-1), h)
        @test point_on_hyperbola(h, 0.6; branch=-1)[1] < 0  # on the left branch

        # Base.in: on or beyond either branch (the natural analogue of "inside" here)
        @test APPoint(2.0, 0.0) in h            # on the curve
        @test APPoint(3.0, 0.0) in h            # beyond the right branch
        @test APPoint(-3.0, 0.0) in h           # beyond the left branch
        @test !(APPoint(0.0, 0.0) in h)         # center: between the branches
        @test !(APPoint(1.0, 0.0) in h)         # between the branches

        f1, f2 = foci(h)
        c = sqrt(2.0^2 + 1.0^2)
        @test f1 ≈ APPoint(c, 0.0)
        @test f2 ≈ APPoint(-c, 0.0)
        # defining property: |d(p,f1) - d(p,f2)| == 2a for a point on the hyperbola
        p = point_on_hyperbola(h, 0.5)
        @test abs(distance(p, f1) - distance(p, f2)) ≈ 2 * h.a atol = 1e-9

        a1, a2 = asymptotes(h)
        @test on_line(h.center, a1) && on_line(h.center, a2)
        far = point_on_hyperbola(h, 6.0)  # far out: hugs an asymptote
        @test min(distance(far, a1), distance(far, a2)) < 1e-2

        # a horizontal line through the vertex hits both branches (y = 0 -> x = ±a)
        pts = intersection(APLine(APPoint(-10.0, 0.0), APPoint(10.0, 0.0)), h)
        @test length(pts) == 2
        @test APPoint(2.0, 0.0) in pts
        @test APPoint(-2.0, 0.0) in pts

        # a vertical line between the branches misses the hyperbola entirely
        @test isempty(intersection(APLine(APPoint(0.0, -10.0), APPoint(0.0, 10.0)), h))

        # rotated hyperbola: local-frame math should still hold
        rot_h = APHyperbola2(APPoint(1.0, 1.0), 2.0, 1.0, pi / 4)
        @test is_on_hyperbola(point_on_hyperbola(rot_h, 0.6), rot_h)

        # tangent lines from an external point on the convex side of a branch.
        # Note: unlike for an ellipse/parabola, a line tangent to one branch
        # of a hyperbola can still cross the *other* branch transversally, so
        # "tangent" here is checked via membership, not via a single intersection.
        pext = APPoint(10.0, 20.0)
        tpts = tangent_points(h, pext)
        @test length(tpts) == 2
        for tp in tpts
            @test is_on_hyperbola(tp, h)
            @test any(cand -> distance(cand, tp) < 1e-5, intersection(APLine(pext, tp), h))
        end
        @test tangent_lines(h, pext) == [APLine(pext, tp) for tp in tpts]
        @test tangent_points(pext, h) == tpts

        # a point in the concave region between the branches has no tangent lines
        @test isempty(tangent_points(h, APPoint(20.0, 1.0)))

        # tangent_lines when p is on the hyperbola: the tangent line at p, not APLine(p,p)
        p_on_h = point_on_hyperbola(h, 0.5)
        tl_on = only(tangent_lines(h, p_on_h))
        @test tl_on.p1 != tl_on.p2
        @test any(cand -> distance(cand, p_on_h) < 1e-6, intersection(tl_on, h))

        # orthoptic (director) circle: real only when a > b
        h2 = APHyperbola2(APPoint(0.0, 0.0), 5.0, 3.0, 0.2)
        oc = orthoptic(h2)
        @test oc.center == h2.center
        @test oc.r ≈ sqrt(h2.a^2 - h2.b^2)
        p_oc = h2.center + oc.r * APVector(cos(1.1), sin(1.1))
        tl_oc = tangent_lines(h2, p_oc)
        @test length(tl_oc) == 2
        @test dot(direction(tl_oc[1]), direction(tl_oc[2])) ≈ 0.0 atol = 1e-9

        @test_throws ArgumentError orthoptic(APHyperbola2(APPoint(0.0, 0.0), 2.0, 5.0))  # a <= b: no real orthoptic

        # transforms (same structure as APEllipse2's)
        rot = rotate(h, pi / 5, APPoint(1.0, 0.0))
        @test rot.center ≈ rotate(h.center, pi / 5, APPoint(1.0, 0.0))
        @test rot.a ≈ h.a && rot.b ≈ h.b
        @test rot.angle ≈ h.angle + pi / 5

        hom_neg = homothety(h, -1.5)
        @test hom_neg.a ≈ 1.5 * h.a && hom_neg.b ≈ 1.5 * h.b
        @test hom_neg.angle ≈ h.angle

        refl_pt = reflection(h, APPoint(2.0, -3.0))
        @test refl_pt.angle ≈ h.angle
        @test refl_pt.a ≈ h.a && refl_pt.b ≈ h.b

        line_about = APLine(APPoint(0.0, 0.0), APPoint(1.0, 2.0))
        refl_line = reflection(h, line_about)
        φ = atan(direction(line_about)[2], direction(line_about)[1])
        @test refl_line.angle ≈ 2φ - h.angle
        for t in (0.3, 1.1), branch in (1, -1)
            @test is_on_hyperbola(reflection(point_on_hyperbola(h, t; branch=branch), line_about), refl_line; atol=1e-6)
        end
    end

    @testset "additional named triangle centers and circles" begin
        t = APTriangle(APPoint(0.0, 0.0), APPoint(9.0, 1.0), APPoint(2.0, 7.0))
        A, B, C = t[1], t[2], t[3]

        @testset "complement / anticomplement" begin
            @test complement(t, A) ≈ midpoint(B, C)
            @test complement(t, B) ≈ midpoint(A, C)
            @test anticomplement(t, A) ≈ B + (C - A)
            @test isapprox(anticomplement(t, complement(t, A)), A; atol=1e-9)
        end

        @testset "kenmotu_circle" begin
            kc = kenmotu_circle(t)
            @test kc.center ≈ kenmotu_point(t)
            a, b, c = distance(B, C), distance(A, C), distance(A, B)
            @test kc.r ≈ sqrt(2) * a * b * c / (4 * area(t) + (a^2 + b^2 + c^2))
        end

        @testset "van Lamoen points/circle" begin
            pts = van_lamoen_points(t)
            @test length(pts) == 6
            vlc = van_lamoen_circle(t)
            @test all(p -> isapprox(distance(vlc.center, p), vlc.r; atol=1e-6), pts)
        end

        @testset "feuerbach_points (excircles)" begin
            fp = feuerbach_points(t)
            npc = nine_point_circle(t)
            exc = excircles(t)
            for (name, p) in pairs(fp)
                @test distance(npc.center, p) ≈ npc.r atol = 1e-6
                J = getfield(exc, name)
                @test distance(J.center, p) ≈ J.r atol = 1e-6
                # external tangency: d(npc.center, J.center) == npc.r + J.r
                @test distance(npc.center, J.center) ≈ npc.r + J.r atol = 1e-6
            end
        end

        @testset "reflection_triangle / anticomplementary_triangle" begin
            rt = reflection_triangle(t)
            @test rt[1] ≈ reflection(A, APLine(B, C))
            @test rt[2] ≈ reflection(B, APLine(A, C))
            @test rt[3] ≈ reflection(C, APLine(A, B))

            at = anticomplementary_triangle(t)
            mt = medial_triangle(at)
            @test mt[1] ≈ A && mt[2] ≈ B && mt[3] ≈ C
        end

        @testset "soddy_line" begin
            sl = soddy_line(t)
            sc = soddy_circles(t)
            @test on_line(sc.inner.center, sl)
            @test on_line(sc.outer.center, sl)
        end

        @testset "Kiepert hyperbola/parabola" begin
            kh = kiepert_hyperbola(t)
            @test kh isa APHyperbola2
            a1, a2 = asymptotes(kh)
            @test dot(direction(a1), direction(a2)) ≈ 0.0 atol = 1e-6  # rectangular
            a, b, c = distance(B, C), distance(A, C), distance(A, B)
            X115 = barycentric_point(t, (b^2 - c^2)^2, (c^2 - a^2)^2, (a^2 - b^2)^2)
            @test kh.center ≈ X115
            for p in (A, B, C, centroid(t), orthocenter(t))
                @test is_on_hyperbola(p, kh; atol=1e-6)
            end

            kp = kiepert_parabola(t)
            @test kp isa APParabola2
            @test kp.directrix ≈ euler_line(t)

            iso = APTriangle(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(2.0, 3.0))
            @test_throws ArgumentError kiepert_parabola(iso)
        end

        @testset "named inellipses" begin
            for e in (lemoine_inellipse(t), brocard_inellipse(t), macbeath_inellipse(t),
                mandart_inellipse(t), orthic_inellipse(t))
                @test e isa APEllipse2
            end
            @test lemoine_inellipse(t).center ≈ midpoint(centroid(t), symmedian_point(t))
            @test mandart_inellipse(t).center ≈ mittenpunkt(t)
            @test orthic_inellipse(t).center ≈ symmedian_point(t)
        end

        @testset "tangent_parallel" begin
            circ = APCircle2(APPoint(1.0, 1.0), 4.0)
            l = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
            t1, t2 = tangent_parallel(circ, l)
            @test distance(circ.center, t1) ≈ circ.r atol = 1e-9
            @test distance(circ.center, t2) ≈ circ.r atol = 1e-9
            @test is_parallel(t1, l)
            @test is_parallel(t2, l)
        end

        @testset "circles_position / line_circle_position" begin
            @test circles_position(APCircle2(APPoint(0.0, 0.0), 1.0), APCircle2(APPoint(10.0, 0.0), 1.0)) == :disjoint_ext
            @test circles_position(APCircle2(APPoint(0.0, 0.0), 2.0), APCircle2(APPoint(5.0, 0.0), 3.0)) == :tangent_ext
            @test circles_position(APCircle2(APPoint(0.0, 0.0), 3.0), APCircle2(APPoint(4.0, 0.0), 2.0)) == :secant
            @test circles_position(APCircle2(APPoint(0.0, 0.0), 5.0), APCircle2(APPoint(2.0, 0.0), 3.0)) == :tangent_int
            @test circles_position(APCircle2(APPoint(0.0, 0.0), 5.0), APCircle2(APPoint(1.0, 0.0), 1.0)) == :disjoint_int
            @test circles_position(APCircle2(APPoint(0.0, 0.0), 5.0), APCircle2(APPoint(0.0, 0.0), 3.0)) == :concentric
            @test circles_position(APCircle2(APPoint(1.0, 1.0), 5.0), APCircle2(APPoint(1.0, 1.0), 5.0)) == :identical

            @test line_circle_position(APLine(APPoint(0.0, 10.0), APPoint(1.0, 10.0)), APCircle2(APPoint(0.0, 0.0), 5.0)) == :disjoint
            @test line_circle_position(APLine(APPoint(0.0, 5.0), APPoint(1.0, 5.0)), APCircle2(APPoint(0.0, 0.0), 5.0)) == :tangent
            @test line_circle_position(APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0)), APCircle2(APPoint(0.0, 0.0), 5.0)) == :secant
        end

        @testset "inversion_neg / invert_neg" begin
            p = APPoint(10.0, 0.0)
            ci = APCircle2(APPoint(0.0, 0.0), 5.0)
            @test inversion_neg(p, ci) ≈ APPoint(-2.5, 0.0)
            @test inversion_neg(p, ci) ≈ reflection(inversion(p, ci), ci.center)

            l = APLine(APPoint(3.0, -5.0), APPoint(3.0, 5.0))
            got_l, expected_l = invert_neg(l, ci.center), reflection(invert(l, ci.center), ci.center)
            @test got_l.center ≈ expected_l.center && got_l.r ≈ expected_l.r

            c2 = APCircle2(APPoint(8.0, 0.0), 2.0)
            got_c, expected_c = invert_neg(c2, ci.center), reflection(invert(c2, ci.center), ci.center)
            @test got_c.center ≈ expected_c.center && got_c.r ≈ expected_c.r
        end

        @testset "named triangles on a segment" begin
            p1, p2 = APPoint(0.0, 0.0), APPoint(6.0, 0.0)

            eq = equilateral_triangle_on_segment(p1, p2)
            @test distance(p1, p2) ≈ distance(p2, eq[3]) ≈ distance(eq[3], p1)
            eq2 = equilateral_triangle_on_segment(p1, p2; ccw=false)
            @test eq[3][2] > 0 && eq2[3][2] < 0

            iso = isosceles_triangle_on_segment(p1, p2, 5.0)
            @test distance(p1, iso[3]) ≈ 5.0 atol = 1e-9
            @test distance(p2, iso[3]) ≈ 5.0 atol = 1e-9
            @test_throws ArgumentError isosceles_triangle_on_segment(p1, p2, 1.0)

            r306090 = triangle_30_60_90_on_segment(p1, p2)
            @test angle_at(p1, p2, r306090[3]) ≈ deg2rad(30) atol = 1e-9
            @test angle_at(p2, p1, r306090[3]) ≈ deg2rad(60) atol = 1e-9
            @test angle_at(r306090[3], p1, p2) ≈ deg2rad(90) atol = 1e-9

            thales = isosceles_right_triangle_on_segment(p1, p2)
            @test angle_at(thales[3], p1, p2) ≈ deg2rad(90) atol = 1e-9
            @test distance(p1, thales[3]) ≈ distance(p2, thales[3])

            golden = golden_triangle_on_segment(p1, p2)
            @test angle_at(p1, p2, golden[3]) ≈ deg2rad(72) atol = 1e-9
            @test angle_at(p2, p1, golden[3]) ≈ deg2rad(72) atol = 1e-9
            @test angle_at(golden[3], p1, p2) ≈ deg2rad(36) atol = 1e-9

            gnomon = golden_gnomon_on_segment(p1, p2)
            @test angle_at(p1, p2, gnomon[3]) ≈ deg2rad(36) atol = 1e-9
            @test angle_at(p2, p1, gnomon[3]) ≈ deg2rad(36) atol = 1e-9
            @test angle_at(gnomon[3], p1, p2) ≈ deg2rad(108) atol = 1e-9

            egy = egyptian_triangle_on_segment(p1, p2)
            @test angle_at(p2, p1, egy[3]) ≈ deg2rad(90) atol = 1e-9
            @test distance(p2, egy[3]) / distance(p1, p2) ≈ 0.75 atol = 1e-9
            @test distance(p1, egy[3]) / distance(p1, p2) ≈ 1.25 atol = 1e-9
        end
    end

    @testset "Julia idioms: in / == / ≈ / show" begin
        # `in` for our own types (APCircle2/APTriangle already get a geometric
        # `in` for free from GeometryBasics; APStraightNgon deliberately keeps
        # `point_in_polygon` instead, to avoid type piracy)
        bb = APBoundingBox([APPoint(0.0, 0.0), APPoint(4.0, 2.0)])
        @test APPoint(2.0, 1.0) in bb
        @test !(APPoint(5.0, 1.0) in bb)

        e = APEllipse2(APPoint(0.0, 0.0), 2.0, 1.0)
        @test APPoint(0.0, 0.0) in e       # center: inside
        @test APPoint(2.0, 0.0) in e       # on the boundary
        @test !(APPoint(3.0, 0.0) in e)    # outside

        par = APParabola2(APPoint(0.0, 1.0), APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0)))
        @test APPoint(0.0, 5.0) in par        # above the vertex, focus side
        @test !(APPoint(0.0, -5.0) in par)    # below the directrix side

        # == / ≈ for the types this package introduces
        l1, l2 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)), APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0 + 1e-12))
        @test l1 == APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
        @test l1 ≈ l2
        @test rotation_map(0.3, APPoint(0.0, 0.0)) ≈ rotation_map(0.3 + 1e-13, APPoint(0.0, 0.0))
        @test APEllipse2(APPoint(0.0, 0.0), 2.0, 1.0) == e
        @test par ≈ APParabola2(APPoint(0.0, 1.0 + 1e-13), APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0)))

        # show: readable, not the raw default struct dump
        @test !occursin("APLine{Float64}(", sprint(show, l1))
        @test occursin("APLine(", sprint(show, l1))
        @test occursin("APRay(", sprint(show, APRay(APPoint(0.0, 0.0), APPoint(1.0, 0.0))))
        @test occursin("APBoundingBox(", sprint(show, bb))
        @test occursin("APEllipse2(", sprint(show, e))
        @test occursin("APParabola2(", sprint(show, par))
        @test occursin("APHyperbola2(", sprint(show, APHyperbola2(APPoint(0.0, 0.0), 2.0, 1.0)))
        @test occursin("APAffineMap(", sprint(show, rotation_map(0.3, APPoint(0.0, 0.0))))
    end

    # Regression coverage for a real bug: mixing Int and Float64 arguments to
    # a constructor (e.g. an APPoint built from integer literals, combined
    # with a Float64 radius/parameter) used to throw a `convert` MethodError
    # for most types in the hierarchy — the auto-generated default inner
    # constructor Julia builds for a parametric struct converts each field
    # to its declared type, but `APPoint`/`APVector` (and, one level up,
    # `APLine`/`APSegment`/`APRay`/every conic and conic-arc type) had no
    # `convert` method letting it change element type, so that implicit
    # conversion always failed. Every constructor below is exercised with
    # deliberately mismatched Int/Float64 arguments — this entire testset
    # would have failed before that fix.
    @testset "type promotion: mixed Int/Float64 construction" begin
        @test APCircle2(APPoint(5, 10), 10) isa APCircle2{Int}
        @test APCircle2(APPoint(5, 10), 10.0) isa APCircle2{Float64}
        C, A = APPoint(300, 250), APPoint(150, 350) # the exact user-reported repro
        radio = distance(C, A) # always Float64 (sqrt), even though C/A are Int
        @test APCircle2(C, radio) isa APCircle2{Float64}

        @test APTriangle(APPoint(0, 0), APPoint(4, 0), APPoint(1.5, 3.0)) isa APTriangle
        @test APQuadrilateral(APPoint(0, 0), APPoint(4, 0), APPoint(4, 4), APPoint(0.0, 4.0)) isa APQuadrilateral
        @test APStraightNgon([APPoint(0, 0), APPoint(1, 0), APPoint(0.0, 1.0)]) isa APStraightNgon
        @test APSegment(APPoint(0, 0), APPoint(1.5, 2.0)) isa APSegment
        @test APLine(APPoint(0, 0), APPoint(1.5, 2.0)) isa APLine
        @test APRay(APPoint(0, 0), APPoint(1.5, 2.0)) isa APRay
        @test APAngle2(APPoint(0, 0), APPoint(1, 0), APPoint(0.0, 1.0)) isa APAngle2
        @test APHalfPlane2(APLine(APPoint(0, 0), APPoint(0, 1)), APPoint(1.0, 0.0)) isa APHalfPlane2
        @test APStrip2(APLine(APPoint(0, 0), APPoint(0, 1)), APLine(APPoint(1.0, 0.0), APPoint(1.0, 1.0))) isa APStrip2

        @test APEllipse2(APPoint(0, 0), 5, 3.0, 0.1) isa APEllipse2
        @test APEllipse2(APPoint(0, 0), APPoint(4.0, 0.0), 5) isa APEllipse2 # foci form
        @test APHyperbola2(APPoint(0, 0), 2, 1.0, 0.1) isa APHyperbola2
        @test APHyperbola2(APPoint(0, 0), APPoint(10.0, 0.0), 2) isa APHyperbola2 # foci form
        @test APParabola2(APPoint(0, 1), APLine(APPoint(-5, -1), APPoint(5.0, -1.0))) isa APParabola2

        @test APCircularArc2(APCircle2(APPoint(0, 0), 5), APPoint(5, 0), APPoint(0.0, 5.0)) isa APCircularArc2
        @test APEllipticArc2(APEllipse2(APPoint(0, 0), 5, 3, 0), APPoint(5, 0), APPoint(0.0, 3.0)) isa APEllipticArc2
        parA = APParabola2(APPoint(0, 1), APLine(APPoint(-5, -1), APPoint(5, -1)))
        @test APParabolicArc2(parA, APPoint(-3.0, 4.5), APPoint(3, 4.5)) isa APParabolicArc2
        hypA = APHyperbola2(APPoint(0, 0), 2, 1, 0)
        @test APHyperbolicArc2(hypA, APPoint(2.5, 2.0), APPoint(4, 3)) isa APHyperbolicArc2

        @test APCircularSector2(APCircle2(APPoint(0, 0), 5), APPoint(5, 0), APPoint(0.0, 5.0)) isa APCircularSector2
        @test APCircularSegment2(APCircle2(APPoint(0, 0), 5), APPoint(5, 0), APPoint(0.0, 5.0)) isa APCircularSegment2
        @test APAnnularSector2(APCircularArc2(APCircle2(APPoint(0, 0), 5), APPoint(5, 0), APPoint(0, 5)), 2.0) isa APAnnularSector2
        @test APInterstice2(
            APCircularArc2(APCircle2(APPoint(0, 0), 3), APPoint(3, 0), APPoint(0, 3)),
            APCircularArc2(APCircle2(APPoint(5.0, 0.0), 2.0), APPoint(7.0, 0.0), APPoint(5.0, 2.0)),
            APCircularArc2(APCircle2(APPoint(3, 2), 1), APPoint(4, 2), APPoint(3, 3)),
        ) isa APInterstice2

        @test APCurvilinearTriangle2(
            APSegment(APPoint(0, 0), APPoint(1, 0)), APSegment(APPoint(1, 0), APPoint(1, 1)), APSegment(APPoint(1, 1), APPoint(0.0, 0.0)),
        ) isa APCurvilinearTriangle2
        @test APCurvilinearQuadrilateral2(
            APSegment(APPoint(0, 0), APPoint(1, 0)), APSegment(APPoint(1, 0), APPoint(1, 1)),
            APSegment(APPoint(1, 1), APPoint(0, 1)), APSegment(APPoint(0, 1), APPoint(0.0, 0.0)),
        ) isa APCurvilinearQuadrilateral2
        @test APCurvilinearNgon2([APSegment(APPoint(0, 0), APPoint(1, 0)), APSegment(APPoint(1, 0), APPoint(0.0, 1.0))]) isa APCurvilinearNgon2
        @test APCurvilinearNgon2([
            APSegment(APPoint(0, 0), APPoint(1, 0)),
            APCircularArc2(APCircle2(APPoint(0.0, 0.0), 1.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0)),
        ]) isa APCurvilinearNgon2

        @test APAffineMap(1, 0, 0, 1.0, 0, 0) isa APAffineMap
        @test APBoundingBox([APPoint(0, 0), APPoint(1.0, 1.0)]) isa APBoundingBox
        @test APVector(1, 2.0) isa APVector

        # the underlying fix: APPoint/APVector, and the composite curve/conic
        # types nested inside other structs, all convert element type on demand
        @test convert(APPoint{2,Float64}, APPoint(1, 2)) === APPoint(1.0, 2.0)
        @test convert(APVector{2,Float64}, APVector(1, 2)) === APVector(1.0, 2.0)
        @test convert(APLine{2,Float64}, APLine(APPoint(0, 0), APPoint(1, 1))) == APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
        @test convert(APCircle2{Float64}, APCircle2(APPoint(0, 0), 5)) == APCircle2(APPoint(0.0, 0.0), 5.0)
    end

    # Regression coverage for a second, subtler bug found while adding tuple
    # support to these same constructors: a naive "add a second method with
    # point parameters widened to Union{APPoint,Tuple}" approach either
    # became genuinely ambiguous with the existing typed method, or — worse,
    # for 2-argument constructors — silently always dispatched to the new
    # method even when both arguments were already APPoint, causing infinite
    # recursion (a StackOverflowError), specifically when the two APPoint
    # arguments had *different* element types (e.g. one Int, one Float64).
    # This is a known Julia "diagonal dispatch" limitation: method
    # specificity comparison isn't complete once 2+ argument positions vary
    # simultaneously with a shared type parameter on one side and an
    # unconstrained Union on the other. The fix was to never have two
    # competing methods at all — each constructor now has exactly one
    # (fully generic) method that converts through `_topoint` itself. Every
    # check below uses *mixed*-element-type APPoint arguments specifically
    # (not tuples) — that combination is what actually triggered the bug;
    # plain tuple support alone did not.
    @testset "tuple construction, incl. the mixed-APPoint-type regression" begin
        @test APSegment(APPoint(0, 0), APPoint(1.5, 2.0)) isa APSegment
        @test APLine(APPoint(0, 0), APPoint(1.5, 2.0)) isa APLine
        @test APRay(APPoint(0, 0), APPoint(1.5, 2.0)) isa APRay
        @test APBoundingBox(APPoint(0, 0), APPoint(1.5, 2.0)) isa APBoundingBox
        @test APTriangle(APPoint(0, 0), APPoint(4, 0), APPoint(1.5, 3.0)) isa APTriangle
        @test APQuadrilateral(APPoint(0, 0), APPoint(4, 0), APPoint(4, 4), APPoint(0.0, 4.0)) isa APQuadrilateral
        @test APAngle2(APPoint(0, 0), APPoint(1, 0), APPoint(0.0, 1.0)) isa APAngle2
        @test APCircularArc2(APCircle2(APPoint(0, 0), 5), APPoint(5, 0), APPoint(0.0, 5.0)) isa APCircularArc2
        @test APEllipticArc2(APEllipse2(APPoint(0, 0), 5, 3, 0), APPoint(5, 0), APPoint(0.0, 3.0)) isa APEllipticArc2
        parA = APParabola2(APPoint(0, 1), APLine(APPoint(-5, -1), APPoint(5, -1)))
        @test APParabolicArc2(parA, APPoint(-3.0, 4.5), APPoint(3, 4.5)) isa APParabolicArc2
        hypA = APHyperbola2(APPoint(0, 0), 2, 1, 0)
        @test APHyperbolicArc2(hypA, APPoint(2.5, 2.0), APPoint(4, 3)) isa APHyperbolicArc2
        @test APCircularSector2(APCircle2(APPoint(0, 0), 5), APPoint(5, 0), APPoint(0.0, 5.0)) isa APCircularSector2
        @test APCircularSegment2(APCircle2(APPoint(0, 0), 5), APPoint(5, 0), APPoint(0.0, 5.0)) isa APCircularSegment2
        @test APEllipse2(APPoint(0, 0), APPoint(4.0, 0.0), 5) isa APEllipse2
        @test APEllipse2(APPoint(0, 0), APPoint(4.0, 0.0), APPoint(2, 3.0)) isa APEllipse2
        @test APHyperbola2(APPoint(0, 0), APPoint(10.0, 0.0), 2) isa APHyperbola2
        @test APHalfPlane2(APLine(APPoint(0, 0), APPoint(0, 1)), APPoint(1.0, 0.0)) isa APHalfPlane2

        # tuple support itself (same-type and mixed-type tuples), the
        # original feature request
        @test APPoint((5, 10)) isa APPoint{2,Int}
        @test APPoint((5, 10.0)) == APPoint(5.0, 10.0)
    end

    @testset "vectors" begin
        u, v = APPoint(1.0, 0.0), APPoint(0.0, 1.0)
        @test norm(u) == 1.0
        @test dot(u, v) == 0.0
        @test angle_between(u, v) ≈ pi / 2
        @test angle_at(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0)) ≈ pi / 2
    end

    @testset "tangency" begin
        c = APCircle2(APPoint(0.0, 0.0), 1.0)
        p = APPoint(2.0, 0.0)

        @test tangent_length(c, p) ≈ sqrt(3)

        pts = tangent_points(c, p)
        @test length(pts) == 2
        for tp in pts
            @test distance(c.center, tp) ≈ 1.0 atol = 1e-9
            @test is_perpendicular(APLine(c.center, tp), APLine(p, tp))
        end

        @test isempty(tangent_points(c, APPoint(0.5, 0.0)))
        @test only(tangent_points(c, APPoint(1.0, 0.0))) ≈ APPoint(1.0, 0.0)

        # tangent_lines when p is on the circle: the tangent line at p, not APLine(p,p)
        on_c = c.center + c.r * APVector(1.0, 0.0)
        tl_on = only(tangent_lines(c, on_c))
        @test tl_on.p1 != tl_on.p2
        @test is_perpendicular(tl_on, APLine(c.center, on_c))
        @test on_line(on_c, tl_on)

        c1 = APCircle2(APPoint(0.0, 0.0), 1.0)
        c2 = APCircle2(APPoint(4.0, 0.0), 1.0)
        ext = external_tangent_lines(c1, c2)
        @test length(ext) == 2
        for l in ext
            @test distance(c1.center, l) ≈ 1.0 atol = 1e-9
            @test distance(c2.center, l) ≈ 1.0 atol = 1e-9
        end

        internal = internal_tangent_lines(c1, c2)
        @test length(internal) == 2
        for l in internal
            @test distance(c1.center, l) ≈ 1.0 atol = 1e-9
            @test distance(c2.center, l) ≈ 1.0 atol = 1e-9
        end

        # p1/p2 are the actual points of tangency on c1/c2 respectively --
        # not just any two points determining the line -- checked here with
        # different radii, where a naive implementation could instead return
        # the (off-circle) similitude center as one endpoint
        cd1, cd2 = APCircle2(APPoint(500.0, 400.0), 200.0), APCircle2(APPoint(900.0, 200.0), 100.0)
        for l in external_tangent_lines(cd1, cd2)
            @test distance(l.p1, cd1.center) ≈ cd1.r atol = 1e-9
            @test distance(l.p2, cd2.center) ≈ cd2.r atol = 1e-9
        end
        for l in internal_tangent_lines(cd1, cd2)
            @test distance(l.p1, cd1.center) ≈ cd1.r atol = 1e-9
            @test distance(l.p2, cd2.center) ≈ cd2.r atol = 1e-9
        end

        # degenerate branches (equal radii with coincident centers, and
        # touching circles with no internal tangent) must return the same
        # concrete element type as the normal branches, not an abstract APLine[]
        same_point = APCircle2(APPoint(0.0, 0.0), 1.0)
        @test eltype(external_tangent_lines(same_point, same_point)) == APLine{2,Float64}
        touching = APCircle2(APPoint(0.0, 0.0), 0.0)
        @test eltype(internal_tangent_lines(touching, touching)) == APLine{2,Float64}

        # similitude centers: divide the segment of centers in ratio r1:r2
        # (use different radii here; c1/c2 above have equal radii, where the
        # external center is undefined)
        cA, cB = APCircle2(APPoint(0.0, 0.0), 2.0), APCircle2(APPoint(10.0, 0.0), 3.0)
        ext_sim = external_similitude_center(cA, cB)
        int_sim = internal_similitude_center(cA, cB)
        @test distance(ext_sim, cA.center) / distance(ext_sim, cB.center) ≈ cA.r / cB.r atol = 1e-9
        @test distance(int_sim, cA.center) / distance(int_sim, cB.center) ≈ cA.r / cB.r atol = 1e-9
        @test on_line(int_sim, APLine(cA.center, cB.center))
        @test on_segment(int_sim, APSegment(cA.center, cB.center))         # internal: between the centers
        @test !on_segment(ext_sim, APSegment(cA.center, cB.center))        # external: outside the segment
        @test_throws ArgumentError external_similitude_center(c1, c2)    # equal radii: undefined

        # pole/polar duality for a circle
        circ = APCircle2(APPoint(1.0, 2.0), 3.0)
        pext = APPoint(8.0, 5.0)
        pl = polar_line(circ, pext)
        @test pole(circ, pl) ≈ pext atol = 1e-6
        l2 = APLine(APPoint(4.0, 1.0), APPoint(6.0, 7.0))
        p_of_l2 = pole(circ, l2)
        @test on_line(l2.p1, polar_line(circ, p_of_l2); atol=1e-6)
        @test polar_line(circ, circ.center) === nothing  # matches APEllipse2/APHyperbola2/APParabola2's convention
        # `polar_line` also takes `atol`, like its conic siblings, so the
        # shared `_tangent_lines_via_polar` helper works for APCircle2 too
        @test Apollonius._tangent_lines_via_polar(c, on_c) == tangent_lines(c, on_c)
        @test on_line(l2.p2, polar_line(circ, p_of_l2); atol=1e-6)
        @test_throws ArgumentError pole(circ, APLine(circ.center, circ.center + APVector(1.0, 0.0)))

        overlapping = APCircle2(APPoint(0.5, 0.0), 1.0)
        @test isempty(internal_tangent_lines(c1, overlapping))
    end

    @testset "bounding box" begin
        t = APTriangle(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(1.0, 3.0))
        bb = APBoundingBox(t)
        @test bb.min == APPoint(0.0, 0.0)
        @test bb.max == APPoint(4.0, 3.0)
        @test bbox_width(bb) == 4.0
        @test bbox_height(bb) == 3.0
        @test bbox_center(bb) == APPoint(2.0, 1.5)
        @test APPoint(2.0, 1.0) in bb
        @test !(APPoint(5.0, 1.0) in bb)

        bb2 = APBoundingBox([APPoint(3.0, -1.0), APPoint(6.0, 2.0)])
        @test bboxes_intersect(bb, bb2)
        inter = bbox_intersection(bb, bb2)
        @test inter.min == APPoint(3.0, 0.0)
        @test inter.max == APPoint(4.0, 2.0)

        far = APBoundingBox([APPoint(10.0, 10.0), APPoint(11.0, 11.0)])
        @test !bboxes_intersect(bb, far)
        @test bbox_intersection(bb, far) === nothing

        # bbox_union always exists, overlapping or not, and contains both inputs
        u = bbox_union(bb, bb2)
        @test u.min == APPoint(0.0, -1.0)
        @test u.max == APPoint(6.0, 3.0)
        u_far = bbox_union(bb, far)
        @test u_far.min == APPoint(0.0, 0.0) && u_far.max == APPoint(11.0, 11.0)
        @test bb.min in u && bb.max in u && bb2.min in u && bb2.max in u

        # scaling by a positive factor keeps the min/max invariant
        scaled = bb * 2.0
        @test scaled.min == APPoint(0.0, 0.0)
        @test scaled.max == APPoint(8.0, 6.0)

        # scaling by a negative factor must swap min/max so bbox_width/height
        # stay non-negative and `in`/`bboxes_intersect` keep working
        neg = bb * -1.0
        @test neg.min == APPoint(-4.0, -3.0)
        @test neg.max == APPoint(0.0, 0.0)
        @test bbox_width(neg) == 4.0
        @test bbox_height(neg) == 3.0
        @test APPoint(-2.0, -1.0) in neg

        @testset "@boundingbox macro" begin
            # assignments made inside the block stay usable afterward, exactly
            # like ordinary code (no `let`-style scoping of its own)
            bb1 = @boundingbox begin
                mc = APCircle2(APPoint(0.0, 0.0), 2.0)
                ms = APSegment(APPoint(5.0, 5.0), APPoint(6.0, 7.0))
            end
            @test bb1 == bbox_union(APBoundingBox(APCircle2(APPoint(0.0, 0.0), 2.0)), APBoundingBox(APSegment(APPoint(5.0, 5.0), APPoint(6.0, 7.0))))
            @test mc == APCircle2(APPoint(0.0, 0.0), 2.0)
            @test ms == APSegment(APPoint(5.0, 5.0), APPoint(6.0, 7.0))

            # bare references to shapes already defined outside the block
            mc2 = APCircle2(APPoint(10.0, 10.0), 1.0)
            ms2 = APSegment(APPoint(-3.0, -3.0), APPoint(-1.0, -1.0))
            bb2 = @boundingbox begin
                mc2
                ms2
            end
            @test bb2 == bbox_union(APBoundingBox(mc2), APBoundingBox(ms2))

            # mixed: an existing shape alongside a freshly defined one
            mt3 = APTriangle(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
            bb3 = @boundingbox begin
                mt3
                me3 = APEllipse2(APPoint(20.0, 20.0), 3.0, 1.0, 0.5)
            end
            @test bb3 == bbox_union(APBoundingBox(mt3), APBoundingBox(me3))

            # destructuring assignment `name1, name2 = expr` folds in each
            # name individually, exactly like two separate lines would
            c1, c2 = APCircle2(APPoint(0.0, 0.0), 2.0), APCircle2(APPoint(10.0, 0.0), 1.0)
            bb4 = @boundingbox begin
                p1, p2 = external_tangent_lines(c1, c2)
            end
            @test bb4 == bbox_union(APBoundingBox(p1), APBoundingBox(p2))
            @test isempty(bb4)  # both are APLine -- unbounded, no finite extent

            # works the same inside a function (proper local scope, not global leakage)
            function _boundingbox_macro_test_fn()
                bb = @boundingbox begin
                    fc = APCircle2(APPoint(0.0, 0.0), 2.0)
                    fs = APSegment(APPoint(5.0, 5.0), APPoint(6.0, 7.0))
                end
                return bb, fc, fs
            end
            bbf, fc, fs = _boundingbox_macro_test_fn()
            @test bbf == bb1
            @test fc isa APCircle2 && fs isa APSegment

            @test_throws ArgumentError @boundingbox begin end

            # a single expression (not wrapped in begin/end) works too,
            # treated as a one-line block
            mc4 = APCircle2(APPoint(7.0, 7.0), 1.0)
            @test (@boundingbox mc4) == APBoundingBox(mc4)
            bb5 = @boundingbox mc5 = APCircle2(APPoint(9.0, 9.0), 2.0)
            @test bb5 == APBoundingBox(mc5)
            @test mc5 == APCircle2(APPoint(9.0, 9.0), 2.0)
        end

        @testset "@to_luxor_picture / @to_luxor_picture!" begin
            fresh() = (APCircle2(APPoint(3.0, -1.0), 5.0), APSegment(APPoint(-2.0, 4.0), APPoint(6.0, -3.0)))
            # bbox of (c, s): min=(-2,-6), max=(8,4) -- 10x10

            # no scaling options: natural size, bbox center translated to (0,0)
            # (matches Luxor's own origin() convention)
            c, s = fresh()
            (w, h), (c2, s2) = @to_luxor_picture flip = false begin
                c
                s
            end
            @test (w, h) == (10.0, 10.0)
            @test c == APCircle2(APPoint(3.0, -1.0), 5.0)   # original untouched (non-mutating form)
            @test c2 == APCircle2(APPoint(0.0, 0.0), 5.0)
            @test s2 == APSegment(APPoint(-5.0, 5.0), APPoint(3.0, -2.0))
            @test bbox_union(APBoundingBox(c2), APBoundingBox(s2)) ==
                  APBoundingBox(APPoint(-w / 2, -h / 2), APPoint(w / 2, h / 2))

            # the size is a NamedTuple -- (w, h) = ... still works
            # positionally (checked just above), and so does field access
            c, s = fresh()
            sz, _ = @to_luxor_picture begin
                c
                s
            end
            @test sz isa NamedTuple{(:width, :height)}
            @test sz.width == 10.0 && sz.height == 10.0

            # ...same for the mutating form, which returns just the size
            c, s = fresh()
            sz2 = @to_luxor_picture! width = 50.0 begin
                c
                s
            end
            @test sz2 isa NamedTuple{(:width, :height)}
            @test sz2.width == 50.0 && sz2.height == 50.0

            # flip (default true): reflects across the x-axis, since this
            # package's own geometry is y-up but Luxor draws y-down --
            # flip=false gives back the raw, un-mirrored coordinates
            c, s = fresh()
            (_, (c2, s2)) = @to_luxor_picture begin
                c
                s
            end
            (_, (c2f, s2f)) = @to_luxor_picture flip = false begin
                c
                s
            end
            @test c2 == APCircle2(APPoint(c2f.center[1], -c2f.center[2]), c2f.r)
            @test s2 == APSegment(APPoint(s2f.p1[1], -s2f.p1[2]), APPoint(s2f.p2[1], -s2f.p2[2]))
            @test c2f == APCircle2(APPoint(0.0, 0.0), 5.0)              # matches the flip=false tests elsewhere
            @test s2f == APSegment(APPoint(-5.0, 5.0), APPoint(3.0, -2.0))
            @test s2 == APSegment(APPoint(-5.0, -5.0), APPoint(3.0, 2.0))   # flip=true (default): y negated

            # width alone: uniform scale (bbox is square here, so trivially uniform)
            c, s = fresh()
            (w, h), _ = @to_luxor_picture width = 400.0 begin
                c
                s
            end
            @test (w, h) == (400.0, 400.0)

            # scale=: literal multiplier
            c, s = fresh()
            (w, h), _ = @to_luxor_picture scale = 2.0 begin
                c
                s
            end
            @test (w, h) == (20.0, 20.0)

            # margin alone (no width/height/scale): scale factor stays 1.0,
            # margin just pads the natural content size on every side
            c, s = fresh()
            (w, h), (c2, s2) = @to_luxor_picture margin = 3.0 flip = false begin
                c
                s
            end
            @test (w, h) == (16.0, 16.0)
            @test c2 == APCircle2(APPoint(0.0, 0.0), 5.0)
            @test s2 == APSegment(APPoint(-5.0, 5.0), APPoint(3.0, -2.0))

            # margin (single, applied to all 4 sides) adds to the reported size
            # and insets the content
            c, s = fresh()
            (w, h), (c2, s2) = @to_luxor_picture width = 100.0 margin = 5.0 flip = false begin
                c
                s
            end
            @test (w, h) == (100.0, 100.0)
            @test c2 == APCircle2(APPoint(0.0, 0.0), 45.0)
            @test s2 == APSegment(APPoint(-45.0, 45.0), APPoint(27.0, -18.0))

            # width and height both given, with a different aspect ratio than
            # the content (here a square bbox): a "contain" fit -- scale is
            # still uniform (never distorts: the circle stays an APCircle2),
            # canvas is exactly (width, height), content centered with extra
            # blank space on the less-restrictive axis (here, x)
            c, s = fresh()
            (w, h), (c2, s2) = @to_luxor_picture width = 400.0 height = 200.0 flip = false begin
                c
                s
            end
            @test (w, h) == (400.0, 200.0)
            @test c2 isa APCircle2   # never distorted
            @test c2 == APCircle2(APPoint(0.0, 0.0), 100.0)
            @test s2 == APSegment(APPoint(-100.0, 100.0), APPoint(60.0, -40.0))

            # `scale` combined with `width`/`height` errors as soon as the macro
            # call is expanded (not a runtime exception the generated code
            # throws), so it's only catchable by forcing that expansion to
            # happen inside the `@test_throws` call itself, via `eval`.
            c1 = APCircle2(APPoint(0.0, 0.0), 1.0)
            @test_throws LoadError eval(:(@to_luxor_picture scale = 2.0 width = 10.0 c1))

            @test_throws ArgumentError @to_luxor_picture begin end

            # mutating form: rebinds c/s in place, returns just (w, h)
            c, s = fresh()
            (w, h) = @to_luxor_picture! width = 50.0 flip = false begin
                c
                s
            end
            @test (w, h) == (50.0, 50.0)
            @test c == APCircle2(APPoint(0.0, 0.0), 25.0)
            @test s == APSegment(APPoint(-25.0, 25.0), APPoint(15.0, -10.0))

            # mutating form rejects an unnamed expression -- nothing to rebind
            function _to_luxor_picture_unnamed_mutating_test()
                c = APCircle2(APPoint(0.0, 0.0), 1.0)
                @to_luxor_picture! begin
                    c
                    APCircle2(APPoint(1.0, 1.0), 1.0)
                end
            end
            @test_throws ArgumentError _to_luxor_picture_unnamed_mutating_test()

            # a single shape/expression (not begin/end) works too
            c, _ = fresh()
            (w, h), c2 = @to_luxor_picture c
            @test (w, h) == (10.0, 10.0)   # a lone APCircle2's bbox is a square of side 2r
            @test c2 == APCircle2(APPoint(0.0, 0.0), 5.0)

            # construction helpers mixed into the block: a plain number and a
            # bare APPoint used only to build the actual shape. The number
            # contributes nothing to the bbox and is left untouched (nothing
            # for a plain number to transform); the point *does* contribute
            # (it's the circle's own center here, so it doesn't grow the bbox
            # beyond the circle's own) and *is* repositioned like any shape.
            centro = APPoint(2.0, 1.0)
            radio = 5.0
            circle = APCircle2(centro, radio)
            (w, h) = @to_luxor_picture! width = 400.0 height = 300.0 begin
                centro
                radio
                circle
            end
            @test (w, h) == (400.0, 300.0)
            @test radio == 5.0                                   # untouched
            @test centro == APPoint(0.0, 0.0)                    # circle's own center -> origin
            @test circle == APCircle2(APPoint(0.0, 0.0), 150.0)  # bbox 10x10 -> s = 30

            # @unbounded: excluded from sizing, but still bound/transformed
            # normally. Without it, a huge auxiliary circle dominates the
            # bbox union and everything else shrinks to a speck by comparison:
            A_dom, B_dom = APPoint(1.0, 1.0), APPoint(3.0, 3.0)
            @to_luxor_picture! width = 500.0 height = 240.0 margin = 20.0 begin
                A_dom
                B_dom
                huge_dom = APCircle2(APPoint(0.0, 0.0), 1000.0)   # NOT unbounded: dominates sizing
            end
            @test norm(direction(APLine(A_dom, B_dom))) < 1.0   # A_dom/B_dom barely moved at all

            # with @unbounded (RHS-only form), huge_ub is excluded from
            # sizing -- A_ub/B_ub get a real, non-tiny scale -- but huge_ub
            # itself is still scaled up too, just not counted for sizing
            A_ub, B_ub = APPoint(1.0, 1.0), APPoint(3.0, 3.0)
            huge_ub = APCircle2(APPoint(0.0, 0.0), 1000.0)
            @to_luxor_picture! width = 500.0 height = 240.0 margin = 20.0 begin
                A_ub
                B_ub
                huge_ub = @unbounded APCircle2(APPoint(0.0, 0.0), 1000.0)
            end
            @test norm(direction(APLine(A_ub, B_ub))) > 1.0   # sized by A_ub/B_ub, not by huge_ub's r=1000
            @test huge_ub.r > 1.0   # huge_ub is still transformed (scaled up), just not sized-by

            # whole-line form (@unbounded wrapping the entire assignment)
            # gives the exact same result as the RHS-only form above
            A_ub2, B_ub2 = APPoint(1.0, 1.0), APPoint(3.0, 3.0)
            @to_luxor_picture! width = 500.0 height = 240.0 margin = 20.0 begin
                A_ub2
                B_ub2
                @unbounded huge_ub2 = APCircle2(APPoint(0.0, 0.0), 1000.0)
            end
            @test A_ub2 ≈ A_ub && B_ub2 ≈ B_ub && huge_ub2.r ≈ huge_ub.r

            # outside a picture block, @unbounded is a harmless passthrough
            @test (@unbounded 5.0 + 3.0) == 8.0

            # if EVERY shape ends up @unbounded, there's nothing left to size by
            @test_throws ArgumentError @to_luxor_picture begin
                z = @unbounded APCircle2(APPoint(0.0, 0.0), 5.0)
            end

            # a bare APVector still has no bounding box of its own (doesn't
            # contribute to sizing, unlike centro/circle above) -- but
            # unlike a plain number, it DOES get scaled/flipped to the
            # picture's own scale (see APVector's own `homothety` method
            # and `_place_in_picture`'s comment), so it still composes
            # correctly with a separately-placed anchor point:
            # place(from) + place(v) == place(from + v)
            from0 = APPoint(2.0, 3.0)
            v0 = APVector(1.0, -1.0)
            tip0 = from0 + v0
            (_, (from_, v_, tip_)) = @to_luxor_picture width = 500.0 height = 240.0 begin
                from0
                v0
                tip0
            end
            @test v_ isa APVector
            @test norm(v_) > norm(v0)      # got scaled up along with everything else
            @test from_ + v_ ≈ tip_        # composes exactly like the already-placed tip

            # a block with nothing but non-positional values has no finite
            # content to size a canvas around
            @test_throws ArgumentError @to_luxor_picture begin
                5.0
                APVector(1.0, 0.0)
            end

            # destructuring assignment (`name1, name2 = expr`) is recognized
            # just like a single-name one, folding each name in/rebinding
            # each individually -- this is what functions like
            # external_tangent_lines/internal_tangent_lines naturally return
            c1 = APCircle2(APPoint(0.0, 0.0), 3.0)
            c2 = APCircle2(APPoint(10.0, 0.0), 3.0)
            (w, h) = @to_luxor_picture! width = 200.0 flip = false begin
                c1
                c2
                el1, el2 = external_tangent_lines(c1, c2)
            end
            @test (w, h) == (200.0, 75.0)
            @test c1 == APCircle2(APPoint(-62.5, 0.0), 37.5)
            @test c2 == APCircle2(APPoint(62.5, 0.0), 37.5)
            # el1/el2 are APLine -- unbounded, so APBoundingBox(el1) is empty
            # and they don't grow the canvas -- but they DO get the same
            # shift+scale as c1/c2, since (unlike a plain number or an
            # APVector) APLine still supports translate/homothety
            @test el1 == APLine(APPoint(-62.5, 37.5), APPoint(62.5, 37.5))
            @test el2 == APLine(APPoint(-62.5, -37.5), APPoint(62.5, -37.5))

            # a destructured item that's itself a Vector (what intersection
            # returns, since it can give 0/1/2 points) is transformed
            # element-wise too, via the Vector{<:APObject} translate/
            # homothety methods -- this used to error inside _place_in_picture
            cc1 = APCircle2(APPoint(0.0, 0.0), 3.0)
            cc2 = APCircle2(APPoint(10.0, 0.0), 3.0)
            (w2, h2) = @to_luxor_picture! width = 200.0 begin
                cc1
                cc2
                ee1, ee2 = external_tangent_lines(cc1, cc2)
                P1, P2 = intersection.(ee1, [cc1, cc2])
            end
            @test (w2, h2) == (200.0, 75.0)
            @test P1 == [ee1.p1] && P2 == [ee1.p2]  # ee1's own endpoints, transformed the same way
        end

        @testset "@translate/@rotate/@homothety/@reflection macros" begin
            v = APVector(3.0, -2.0)

            # copying form: originals untouched, transformed copies returned as a tuple
            C1, S1, R1 = @translate v begin
                tc = APCircle2(APPoint(0.0, 0.0), 2.0)
                ts = APSegment(APPoint(1.0, 1.0), APPoint(2.0, 2.0))
                tr = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
            end
            @test tc == APCircle2(APPoint(0.0, 0.0), 2.0) # untouched
            @test C1 == translate(APCircle2(APPoint(0.0, 0.0), 2.0), v)
            @test S1 == translate(ts, v)
            @test R1 == translate(tr, v)

            # a single item unwraps to a bare value, not a 1-tuple
            p = APPoint(1.0, 0.0)
            @test (@translate v p) == translate(p, v)
            @test p == APPoint(1.0, 0.0) # untouched

            # mutating form: rebinds named items in place, errors on an unnamed one
            mc = APCircle2(APPoint(0.0, 0.0), 2.0)
            @translate! v begin
                mc
                ml = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
            end
            @test mc == translate(APCircle2(APPoint(0.0, 0.0), 2.0), v)
            @test ml == translate(APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0)), v)
            @test_throws ArgumentError @translate! v begin
                APCircle2(APPoint(9.0, 9.0), 1.0)
            end

            # destructuring assignment `name1, name2 = expr` folds in each
            # name individually, exactly like two separate lines would --
            # copying form
            c1, c2 = APCircle2(APPoint(0.0, 0.0), 2.0), APCircle2(APPoint(10.0, 0.0), 1.0)
            l1, l2 = external_tangent_lines(c1, c2)
            D1, D2 = @translate v begin
                dl1, dl2 = external_tangent_lines(c1, c2)
            end
            @test D1 == translate(l1, v) && D2 == translate(l2, v)
            @test dl1 == l1 && dl2 == l2 # untouched (copying form)

            # ...and mutating form: both names get rebound
            @translate! v begin
                dl1, dl2 = external_tangent_lines(c1, c2)
            end
            @test dl1 == translate(l1, v) && dl2 == translate(l2, v)

            # @rotate: 1-arg (default center) and 2-arg (explicit center) forms
            # (the macro call itself needs its own parens when embedded inside
            # another call's argument list, e.g. isapprox(...) here — without
            # them, Julia's bare `@macro a b` parsing swallows the following
            # comma-separated arguments into a tuple)
            @test isapprox((@rotate (pi / 2) p), rotate(p, pi / 2); atol=1e-9)
            @test isapprox((@rotate (pi / 2) APPoint(1.0, 1.0) p), rotate(p, pi / 2, APPoint(1.0, 1.0)); atol=1e-9)
            p1, p2 = APPoint(1.0, 0.0), APPoint(0.0, 1.0)
            @rotate! (pi / 2) begin
                p1
                p2
            end
            @test isapprox(p1, APPoint(0.0, 1.0); atol=1e-9)
            @test isapprox(p2, APPoint(-1.0, 0.0); atol=1e-9)

            # @homothety: 1-arg and 2-arg forms
            @test (@homothety 2.0 p) == homothety(p, 2.0)
            @test (@homothety 2.0 APPoint(1.0, 1.0) p) == homothety(p, 2.0, APPoint(1.0, 1.0))

            # @reflection
            about = APPoint(5.0, 5.0)
            @test (@reflection about p) == reflection(p, about)
            mp = APPoint(2.0, 3.0)
            @reflection! about mp
            @test mp == reflection(APPoint(2.0, 3.0), about)
        end

        @testset "@invert/@invert_neg/@affinemap macros" begin
            center = APPoint(0.0, 0.0)
            l = APLine(APPoint(2.0, 0.0), APPoint(2.0, 1.0))
            c1 = APCircle2(APPoint(5.0, 5.0), 1.0)

            # copying form, multi-item, mixed shape types (line + circle)
            L1, C1 = @invert center begin
                il = l
                ic = c1
            end
            @test L1 == invert(l, center)
            @test C1 == invert(c1, center)
            @test il == l && ic == c1 # untouched

            # explicit k (2-arg form)
            @test (@invert center 2.0 l) == invert(l, center; k=2.0)

            # mutating form changes both value AND type (APLine -> APCircle2)
            l2 = APLine(APPoint(2.0, 0.0), APPoint(2.0, 1.0))
            @invert! center l2
            @test l2 == invert(APLine(APPoint(2.0, 0.0), APPoint(2.0, 1.0)), center)
            @test l2 isa APCircle2

            # @invert_neg mirrors @invert
            @test (@invert_neg center l) == invert_neg(l, center)
            @test (@invert_neg center 2.0 l) == invert_neg(l, center; k=2.0)
            l3 = APLine(APPoint(2.0, 0.0), APPoint(2.0, 1.0))
            @invert_neg! center l3
            @test l3 == invert_neg(APLine(APPoint(2.0, 0.0), APPoint(2.0, 1.0)), center)

            # @affinemap / @affinemap!
            m = APAffineMap(1.3, 0.4, -0.2, 0.9, 2.0, -1.0)
            t = APTriangle(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
            @test (@affinemap m t) == m(t)
            @test t == APTriangle(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0)) # untouched
            mt = APTriangle(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
            @affinemap! m mt
            @test mt == m(APTriangle(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0)))
        end
    end

    @testset "segment intersection" begin
        s1 = APSegment(APPoint(0.0, 0.0), APPoint(2.0, 2.0))
        s2 = APSegment(APPoint(0.0, 2.0), APPoint(2.0, 0.0))
        @test only(intersection(s1, s2)) ≈ APPoint(1.0, 1.0)

        s3 = APSegment(APPoint(3.0, 3.0), APPoint(4.0, 4.0))
        @test isempty(intersection(s1, s3))  # same line, but non-overlapping segments

        s4 = APSegment(APPoint(0.0, 1.0), APPoint(2.0, 3.0))
        @test isempty(intersection(s1, s4))  # parallel lines
    end

    @testset "polygon" begin
        square = APStraightNgon([APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(2.0, 2.0), APPoint(0.0, 2.0)])

        @test area(square) == 4.0
        @test perimeter(square) == 8.0
        @test centroid(square) == APPoint(1.0, 1.0)
        @test is_convex(square)

        @test point_in_polygon(APPoint(1.0, 1.0), square)
        @test !point_in_polygon(APPoint(3.0, 1.0), square)

        dart = APStraightNgon([APPoint(0.0, 0.0), APPoint(2.0, 1.0), APPoint(0.0, 2.0), APPoint(0.5, 1.0)])
        @test !is_convex(dart)

        pts = [APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(2.0, 2.0), APPoint(0.0, 2.0), APPoint(1.0, 1.0)]
        hull = convex_hull(pts)
        @test length(vertices(hull)) == 4
        @test area(hull) == 4.0

        # transforms
        rot = rotate(square, pi / 2, APPoint(1.0, 1.0))
        @test collect(vertices(rot)) ≈ [rotate(v, pi / 2, APPoint(1.0, 1.0)) for v in vertices(square)]
        @test area(rot) ≈ area(square) atol = 1e-9

        hom = homothety(square, -2.0)
        @test area(hom) ≈ 4 * area(square) atol = 1e-9

        refl = reflection(square, APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)))
        @test area(refl) ≈ area(square) atol = 1e-9
    end

    @testset "proportions" begin
        a, b = APPoint(0.0, 0.0), APPoint(10.0, 0.0)
        g = golden_ratio_point(a, b)
        @test g ≈ APPoint(10 / golden, 0.0)

        p = APPoint(2.0, 0.0)  # between a and b, not the midpoint
        q = harmonic_conjugate(a, b, p)
        @test is_collinear(a, b, q)
        @test_throws ArgumentError harmonic_conjugate(a, b, midpoint(a, b))
    end

    @testset "polar_point" begin
        # no zero-argument default for `center` here — see rotation_map's
        # docstring for why
        origin = APPoint(0.0, 0.0)
        @test polar_point(5.0, 0.0, origin) ≈ APPoint(5.0, 0.0)
        @test polar_point(5.0, pi / 2, origin) ≈ APPoint(0.0, 5.0) atol = 1e-9
        @test polar_point_deg(5.0, 90.0, origin) ≈ APPoint(0.0, 5.0) atol = 1e-9
        @test polar_point_deg(5.0, 90.0, origin) ≈ polar_point(5.0, pi / 2, origin)

        center = APPoint(1.0, 1.0)
        p = polar_point(2.0, pi / 4, center)
        @test distance(p, center) ≈ 2.0
        @test slope_angle(APLine(center, p)) ≈ pi / 4
        @test polar_point_deg(2.0, 45.0, center) ≈ p
    end

    @testset "scale robustness (large coordinates / large radii)" begin
        # A whole family of predicates/constructions used to compare a
        # computed quantity against a *fixed* absolute `atol`, without
        # scaling it to the actual size of the problem. That's fine near
        # the origin at unit scale, but for objects with large coordinates
        # or large radii, ordinary floating-point round-off in computing
        # the quantity itself routinely exceeds a fixed 1e-9 — so genuinely
        # exact configurations (collinear points, tangent circles, etc.)
        # were incorrectly reported as not-quite. Each check below
        # reproduces a configuration that is exact by construction at a
        # scale where the bug used to trigger.

        @testset "is_collinear / is_degenerate" begin
            a = APPoint(1234.5678, 9876.5432)
            dir = APVector(cos(0.37), sin(0.37))
            b = a + 5000.0 * dir
            c = a + 12345.678 * dir
            @test is_collinear(a, b, c)
            @test is_degenerate(APTriangle(a, b, c))

            d = a + APVector(0.001, 12345.0)  # genuinely off the line
            @test !is_collinear(a, b, d)
            @test !is_degenerate(APTriangle(a, b, d))
        end

        @testset "is_concyclic" begin
            scale = 1e7
            center = APPoint(2.5, -1.5) * scale
            pts = [center + scale * APVector(cos(t), sin(t)) for t in (0.3, 1.1, 2.4, 4.0)]
            @test is_concyclic(pts...)
        end

        @testset "on_line" begin
            scale = 1e8
            a = APPoint(2.5, -1.5) * scale
            dir = APVector(cos(0.37), sin(0.37))
            l = APLine(a, a + scale * dir)
            @test on_line(a + 0.3 * scale * dir, l)
        end

        @testset "intersection(APLine, APLine) with short direction vectors" begin
            # lines defined by very close points (tiny direction vectors,
            # far from the origin): clearly not parallel, but the raw
            # cross2 of their directions is tiny in absolute terms too
            p1 = APPoint(1e5, 2e5)
            l1 = APLine(p1, p1 + APVector(1e-6, 0.0))
            l2 = APLine(p1 + APVector(1.0, 1.0), p1 + APVector(1.0, 1.0) + APVector(0.0, 1e-6))
            @test length(intersection(l1, l2)) == 1
        end

        @testset "intersection(APLine, APCircle2) tangency" begin
            scale = 1e7
            c = APCircle2(APPoint(1.234, -0.987) * scale, scale)
            θ = 0.7
            p_on = c.center + c.r * APVector(cos(θ), sin(θ))
            tangent_dir = APVector(-sin(θ), cos(θ))
            l = APLine(p_on, p_on + 0.3 * scale * tangent_dir)
            @test length(intersection(l, c)) == 1
        end

        @testset "tangent_points" begin
            scale = 1e7
            c = APCircle2(APPoint(1.3, -2.1) * scale, scale)
            p_on = c.center + c.r * APVector(cos(0.5), sin(0.5))
            @test length(tangent_points(c, p_on)) == 1
        end

        @testset "conic_through_points" begin
            for scale in (1.0, 1e2, 1e4, 1e6)
                off = APPoint(1.7, -0.9) * scale
                e_true = APEllipse2(off, 5.0 * scale, 3.0 * scale, 0.3)
                pts = [point_on_ellipse(e_true, t) for t in (0.1, 1.3, 2.5, 3.7, 5.0)]
                fit = conic_through_points(pts...)
                @test fit.center ≈ e_true.center rtol = 1e-6
                @test fit.a ≈ e_true.a rtol = 1e-6
                @test fit.b ≈ e_true.b rtol = 1e-6
            end
        end

        @testset "APEllipse2/APHyperbola2/APParabola2 polar_line stays well-defined at large scale" begin
            # the two points defining the returned line used to end up
            # almost coincident for a large conic (the offset shrank like
            # 1/scale), degrading everything computed from that line
            # afterwards; check the line is still usable and correct.
            scale = 1e6
            off = APPoint(1.7, -0.9) * scale

            e = APEllipse2(off, 5.0 * scale, 3.0 * scale, 0.3)
            pe = point_on_ellipse(e, 0.5)
            le = polar_line(e, pe)
            @test distance(le.p1, le.p2) > 1e-3 * scale
            @test any(pt -> distance(pt, pe) <= 1e-3 * scale, intersection(le, e))

            h = APHyperbola2(off, 4.0 * scale, 2.0 * scale, 0.2)
            ph = point_on_hyperbola(h, 0.4)
            lh = polar_line(h, ph)
            @test distance(lh.p1, lh.p2) > 1e-3 * scale
            @test any(pt -> distance(pt, ph) <= 1e-3 * scale, intersection(lh, h))

            par = APParabola2(off, APLine(off + APVector(-5.0, -3.0) * scale, off + APVector(5.0, -3.0) * scale))
            pp = point_on_parabola(par, 2.0 * scale)
            lp = polar_line(par, pp)
            @test distance(lp.p1, lp.p2) > 1e-3 * scale
            @test any(pt -> distance(pt, pp) <= 1e-3 * scale, intersection(lp, par))
        end

        @testset "affine_map collinearity check" begin
            scale = 1e5
            a = APPoint(1234.5678, 9876.5432)
            dir = APVector(cos(0.37), sin(0.37))
            b = a + scale * dir
            c = a + 2scale * dir
            @test_throws ArgumentError affine_map((a, b, c), (APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(2.0, 0.0)))
        end

        @testset "intersection(APLine, APParabola2) at large scale" begin
            scale = 1e8
            off = APPoint(1.7, -0.9) * scale
            par = APParabola2(off, APLine(off + APVector(-5.0, -3.0) * scale, off + APVector(5.0, -3.0) * scale))
            p1 = point_on_parabola(par, 0.5 * scale)
            p2 = point_on_parabola(par, -0.8 * scale)
            l = APLine(p1, p2)
            pts = intersection(l, par)
            @test length(pts) == 2
            @test all(pt -> distance(pt, p1) < 1e-3 * scale || distance(pt, p2) < 1e-3 * scale, pts)
        end

        @testset "invert / polar_line(APCircle2) degenerate checks" begin
            scale = 1e7
            center = APPoint(1.3, -2.1) * scale
            c = APCircle2(center, scale)
            p_on = center + scale * APVector(cos(0.5), sin(0.5))
            @test invert(c, p_on) isa APLine  # a circle through the inversion center -> a line, at scale
            @test polar_line(c, center) === nothing

            l_through_center = APLine(center, center + scale * APVector(1.0, 0.3))
            @test_throws ArgumentError invert(l_through_center, center)
        end
    end

    @testset "boundary and degenerate configurations" begin
        # Cases that are mathematically singular/atypical rather than
        # merely large in scale: concentric circles, circles that don't
        # meet at all (too far apart or one inside the other), circles
        # tangent at exactly one point, a circular (a == b) ellipse, and
        # a polygon with fewer than 3 distinct vertices.

        @testset "concentric circles" begin
            c1 = APCircle2(APPoint(0.0, 0.0), 2.0)
            c2 = APCircle2(APPoint(0.0, 0.0), 5.0)
            @test isempty(intersection(c1, c2))
            @test_throws ArgumentError radical_axis(c1, c2)
        end

        @testset "circle-circle: disjoint / contained / tangent" begin
            disjoint1, disjoint2 = APCircle2(APPoint(0.0, 0.0), 1.0), APCircle2(APPoint(10.0, 0.0), 1.0)
            @test isempty(intersection(disjoint1, disjoint2))

            outer, inner = APCircle2(APPoint(0.0, 0.0), 5.0), APCircle2(APPoint(1.0, 0.0), 1.0)
            @test isempty(intersection(outer, inner))  # inner fully inside, not touching

            ext1, ext2 = APCircle2(APPoint(0.0, 0.0), 2.0), APCircle2(APPoint(5.0, 0.0), 3.0)
            ext_pts = intersection(ext1, ext2)
            @test length(ext_pts) == 1
            @test only(ext_pts) ≈ APPoint(2.0, 0.0)

            big, small = APCircle2(APPoint(0.0, 0.0), 5.0), APCircle2(APPoint(2.0, 0.0), 3.0)
            int_pts = intersection(big, small)
            @test length(int_pts) == 1
            @test only(int_pts) ≈ APPoint(5.0, 0.0)
        end

        @testset "circular (a == b) ellipse" begin
            e = APEllipse2(APPoint(0.0, 0.0), 3.0, 3.0, 0.0)
            @test is_on_ellipse(APPoint(3.0, 0.0), e)
            @test point_on_ellipse(e, pi / 2) ≈ APPoint(0.0, 3.0) atol = 1e-9
            f1, f2 = foci(e)
            @test f1 ≈ e.center && f2 ≈ e.center  # both foci collapse to the center
        end

        @testset "polygon with fewer than 3 distinct vertices" begin
            @test !is_convex(APStraightNgon([APPoint(0.0, 0.0), APPoint(1.0, 0.0)]))
            @test !is_convex(APStraightNgon([APPoint(0.0, 0.0)]))
        end

        @testset "equilateral triangle: coincident centers collapse several axes" begin
            # For an equilateral triangle, circumcenter == nine-point center
            # -- `radical_axis` used to check via bare `==`, which can miss
            # a near-but-not-quite coincidence and return a wildly wrong,
            # numerically-exploded "line" instead of recognizing the circles
            # as concentric, so it must use `≈` instead.
            t = APTriangle(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.5, sqrt(3.0) / 2))
            @test circumcircle(t).center ≈ nine_point_circle(t).center
            @test_throws ArgumentError orthic_axis(t)
            @test_throws ArgumentError radical_axis(circumcircle(t), nine_point_circle(t))

            # symmedian point == circumcenter here too, so the Lemoine axis
            # (the polar line of the symmedian point w.r.t. the circumcircle)
            # is the polar of the circle's own center: `nothing`, by design.
            @test lemoine_axis(t) === nothing

            # the Brocard axis (through circumcenter and the symmedian point)
            # degenerates to the same point twice.
            ba = brocard_axis(t)
            @test ba.p1 ≈ ba.p2
        end
    end

    # `distance` extended to every AP type where a distance makes sense
    # (curves get plain distance-to-the-curve; the 2D-region family gets a
    # `mode::Symbol` kwarg — :region [default]: 0 when the point belongs to
    # the set; :boundary: always distance to the outline). Placed before the
    # Luxor extension testset deliberately: that testset's `using Luxor`
    # brings in Luxor's own exported `distance`, which would otherwise make
    # every unqualified `distance(...)` call below ambiguous.
    @testset "distance extension" begin
        @testset "point to segment / ray" begin
            s = APSegment(APPoint(0.0, 0.0), APPoint(4.0, 0.0))
            @test distance(APPoint(2.0, 3.0), s) ≈ 3.0
            @test distance(APPoint(-3.0, 4.0), s) ≈ 5.0
            @test distance(APPoint(7.0, 4.0), s) ≈ 5.0
            @test distance(s, APPoint(2.0, 3.0)) ≈ 3.0

            r = APRay(APPoint(0.0, 0.0), APPoint(4.0, 0.0))
            @test distance(APPoint(2.0, 3.0), r) ≈ 3.0
            @test distance(APPoint(-3.0, 4.0), r) ≈ 5.0
            @test distance(APPoint(100.0, 3.0), r) ≈ 3.0
        end

        @testset "line / ray / segment pairwise" begin
            l1 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
            l2 = APLine(APPoint(0.0, 5.0), APPoint(1.0, 5.0))
            @test distance(l1, l2) ≈ 5.0
            l3 = APLine(APPoint(2.0, -5.0), APPoint(2.0, 5.0))
            @test distance(l1, l3) ≈ 0.0

            r1 = APRay(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
            r2 = APRay(APPoint(5.0, 3.0), APPoint(6.0, 3.0))
            @test distance(r1, r2) ≈ 3.0
            r4 = APRay(APPoint(0.0, -5.0), APPoint(0.0, 5.0))
            @test distance(r1, r4) ≈ 0.0

            s1 = APSegment(APPoint(0.0, 0.0), APPoint(2.0, 2.0))
            s2 = APSegment(APPoint(0.0, 2.0), APPoint(2.0, 0.0))
            @test distance(s1, s2) ≈ 0.0
            s3 = APSegment(APPoint(3.0, 3.0), APPoint(4.0, 4.0))
            @test distance(s1, s3) ≈ distance(APPoint(2.0, 2.0), APPoint(3.0, 3.0))

            @test distance(APLine(APPoint(0.0, -5.0), APPoint(0.0, 5.0)), r1) ≈ 0.0
            @test distance(APLine(APPoint(-3.0, -5.0), APPoint(-3.0, 5.0)), r1) ≈ 3.0
            seg = APSegment(APPoint(0.0, 0.0), APPoint(4.0, 0.0))
            @test distance(APLine(APPoint(1.0, -5.0), APPoint(1.0, 5.0)), seg) ≈ 0.0
            @test distance(APLine(APPoint(-3.0, -5.0), APPoint(-3.0, 5.0)), seg) ≈ 3.0
        end

        @testset "bounding box" begin
            bb = APBoundingBox(APPoint(0.0, 0.0), APPoint(4.0, 3.0))
            @test distance(APPoint(2.0, 1.0), bb; mode=:region) == 0.0
            @test distance(APPoint(6.0, 1.0), bb; mode=:region) ≈ 2.0
            @test distance(APPoint(6.0, 5.0), bb; mode=:region) ≈ sqrt(2.0^2 + 2.0^2)
            @test distance(APPoint(2.0, 1.0), bb; mode=:boundary) ≈ 1.0
            @test distance(APPoint(6.0, 1.0), bb; mode=:boundary) ≈ 2.0
            @test_throws ArgumentError distance(APPoint(0.0, 0.0), bb; mode=:bogus)
        end

        @testset "circle to point / line / circle" begin
            c = Apollonius.APCircle2(APPoint(2.0, -1.0), 5.0)
            @test distance(APPoint(2.0, -1.0), c) ≈ 5.0
            @test distance(c.center + APVector(8.0, 0.0), c) ≈ 3.0
            @test distance(c, APLine(APPoint(20.0, -10.0), APPoint(20.0, 10.0))) ≈ 13.0
            c2 = Apollonius.APCircle2(APPoint(2.0, -1.0), 2.0)
            @test distance(c, c2) ≈ 3.0 # concentric: nested gap = |r1 - r2|
            c2b = Apollonius.APCircle2(APPoint(2.0 + 3.0, -1.0), 2.0)
            @test distance(c, c2b) ≈ 0.0 # internally tangent (d + r2 == r1)
            c3 = Apollonius.APCircle2(APPoint(20.0, -1.0), 3.0)
            @test distance(c, c3) ≈ 10.0
        end

        @testset "ellipse / hyperbola / parabola (Newton, brute-force checked)" begin
            e = Apollonius.APEllipse2(APPoint(1.0, 2.0), 5.0, 3.0, 0.4)
            for (px, py) in [(20.0, 15.0), (2.0, 2.5), (1.0, 2.0), (6.0, 2.0)]
                p = APPoint(px, py)
                bf = minimum(distance(p, point_on_ellipse(e, t)) for t in range(0, 2pi; length=20_000))
                @test isapprox(distance(p, e), bf; atol=1e-2)
            end
            ecirc = Apollonius.APEllipse2(APPoint(0.0, 0.0), 5.0, 5.0, 0.0)
            @test isapprox(distance(APPoint(10.0, 0.0), ecirc), 5.0; atol=1e-9)

            h = Apollonius.APHyperbola2(APPoint(0.0, 0.0), 4.0, 2.0, 0.3)
            for (px, py) in [(20.0, 5.0), (0.0, 10.0), (0.0, 0.0)]
                p = APPoint(px, py)
                bf = minimum(distance(p, point_on_hyperbola(h, t; branch=b)) for t in range(-5, 5; length=10_000), b in (1, -1))
                @test isapprox(distance(p, h), bf; atol=2e-2)
            end

            par = Apollonius.APParabola2(APPoint(0.0, 1.0), APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0)))
            for (px, py) in [(20.0, 20.0), (0.0, 0.0), (-5.0, 10.0)]
                p = APPoint(px, py)
                bf = minimum(distance(p, point_on_parabola(par, s)) for s in range(-30, 30; length=20_000))
                @test isapprox(distance(p, par), bf; atol=2e-2)
            end
        end

        @testset "conic arcs (range-restricted, brute-force checked)" begin
            c = Apollonius.APCircle2(APPoint(2.0, -1.0), 5.0)
            arc = APCircularArc2(c, c.center + APVector(5.0, 0.0), c.center + APVector(5.0 * cos(2.3), 5.0 * sin(2.3)))
            for p in [APPoint(2.0, -1.0), APPoint(20.0, 10.0), APPoint(-5.0, -8.0)]
                bf = minimum(distance(p, point_on_arc(arc, t)) for t in range(0, 1; length=20_000))
                @test isapprox(distance(p, arc), bf; atol=1e-2)
            end

            e = Apollonius.APEllipse2(APPoint(1.0, 2.0), 5.0, 3.0, 0.4)
            earc = APEllipticArc2(e, point_on_ellipse(e, 0.3), point_on_ellipse(e, 3.5))
            for p in [APPoint(15.0, 10.0), APPoint(-10.0, -5.0)]
                bf = minimum(distance(p, point_on_arc(earc, t)) for t in range(0, 1; length=20_000))
                @test isapprox(distance(p, earc), bf; atol=2e-2)
            end

            h = Apollonius.APHyperbola2(APPoint(0.0, 0.0), 2.0, 1.0, 0.1)
            harc = APHyperbolicArc2(h, point_on_hyperbola(h, 0.2; branch=1), point_on_hyperbola(h, 1.5; branch=1))
            for p in [APPoint(4.93, -0.33), APPoint(10.0, -5.0)] # the (4.93,-0.33) case is the one that exposed the local-vs-global-minimum bug
                bf = minimum(distance(p, point_on_arc(harc, t)) for t in range(0, 1; length=20_000))
                @test isapprox(distance(p, harc), bf; atol=5e-2)
            end

            par = Apollonius.APParabola2(APPoint(0.0, 1.0), APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0)))
            parc = APParabolicArc2(par, point_on_parabola(par, -3.0), point_on_parabola(par, 4.0))
            for p in [APPoint(10.0, 10.0), APPoint(-8.0, 5.0)]
                bf = minimum(distance(p, point_on_arc(parc, t)) for t in range(0, 1; length=20_000))
                @test isapprox(distance(p, parc), bf; atol=5e-2)
            end
        end

        @testset "polygon family (mode=:region/:boundary)" begin
            t = APTriangle(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 3.0))
            @test distance(APPoint(1.0, 1.0), t; mode=:region) == 0.0 # inside
            @test distance(APPoint(1.0, 1.0), t; mode=:boundary) > 0.0
            @test distance(APPoint(-5.0, 0.0), t; mode=:region) ≈ 5.0
            @test distance(APPoint(-5.0, 0.0), t; mode=:region) ≈ distance(APPoint(-5.0, 0.0), t; mode=:boundary)
            @test distance(t, APPoint(-5.0, 0.0)) ≈ 5.0
            @test_throws ArgumentError distance(APPoint(0.0, 0.0), t; mode=:bogus)

            q = APQuadrilateral(APPoint(0.0, 0.0), APPoint(5.0, 0.0), APPoint(5.0, 5.0), APPoint(0.0, 5.0))
            @test distance(APPoint(2.0, 2.0), q; mode=:region) == 0.0
            @test distance(APPoint(-3.0, 2.0), q; mode=:region) ≈ 3.0

            c = Apollonius.APCircle2(APPoint(0.0, 0.0), 5.0)
            arc = APCircularArc2(c, APPoint(5.0, 0.0), APPoint(0.0, 5.0))
            sec = APCircularSector2(arc)
            @test distance(APPoint(1.0, 1.0), sec; mode=:region) == 0.0 # near center, inside the wedge
            @test distance(APPoint(-5.0, -5.0), sec; mode=:region) ≈ distance(APPoint(-5.0, -5.0), sec; mode=:boundary)
        end

        @testset "half-plane / strip / angle (mode=:region/:boundary)" begin
            hp = APHalfPlane2(APLine(APPoint(0.0, 0.0), APPoint(0.0, 1.0)), APPoint(1.0, 0.0))
            @test distance(APPoint(1.0, 0.0), hp; mode=:region) == 0.0
            @test distance(APPoint(1.0, 0.0), hp; mode=:boundary) ≈ 1.0
            pout = APPoint(1.0, 0.0) in hp ? APPoint(-3.0, 0.0) : APPoint(3.0, 0.0)
            @test distance(pout, hp; mode=:region) ≈ distance(pout, hp; mode=:boundary)
            @test distance(hp, pout) ≈ distance(pout, hp)

            strip = APStrip2(APLine(APPoint(-2.0, 0.0), APPoint(-2.0, 1.0)), APLine(APPoint(2.0, 0.0), APPoint(2.0, 1.0)))
            @test distance(APPoint(0.0, 0.0), strip; mode=:region) == 0.0
            @test distance(APPoint(0.0, 0.0), strip; mode=:boundary) ≈ 2.0
            @test distance(APPoint(5.0, 0.0), strip; mode=:region) ≈ 3.0

            ang = APAngle2(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0)) # convex, pi/2 wedge
            @test distance(APPoint(0.5, 0.5), ang; mode=:region) == 0.0
            @test distance(APPoint(-1.0, -1.0), ang; mode=:region) ≈ distance(APPoint(-1.0, -1.0), ang; mode=:boundary)
            @test distance(APPoint(-1.0, -1.0), ang; mode=:boundary) ≈ sqrt(2.0)

            # reflex wedge (measure > pi): boundary distance is still min-of-two-rays
            ang_reflex = APAngle2(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(-1.0, -0.001))
            @test Apollonius.normalized_measure(ang_reflex) > pi
            p = APPoint(0.0, -5.0)
            bf = min(distance(p, APRay(ang_reflex.vertex, ang_reflex.a)), distance(p, APRay(ang_reflex.vertex, ang_reflex.b)))
            @test isapprox(distance(p, ang_reflex; mode=:boundary), bf)
        end
    end

    # `translate` added as the fourth member of the rotate/homothety/
    # reflection/translate quartet, across the same types as the other
    # three; `APAffineMap` extended from its original small subset (point/
    # vector/segment/line/ray/triangle/ngon/quad/angle/circle) to cover
    # every remaining AP-typed curve and region. Placed before the Luxor
    # extension testset for the same reason as "distance extension" above:
    # Luxor exports its own `rotate`, which would make every unqualified
    # `rotate(...)` call below ambiguous once `using Luxor` runs.
    @testset "transform extension (translate, APAffineMap coverage)" begin
        @testset "translate: APPoint / APVector / APBoundingBox" begin
            v = APVector(3.0, -2.0)
            @test translate(APPoint(1.0, 2.0), v) == APPoint(4.0, 0.0)
            bb = APBoundingBox(APPoint(0.0, 0.0), APPoint(4.0, 3.0))
            @test translate(bb, v) == APBoundingBox(APPoint(3.0, -2.0), APPoint(7.0, 1.0))

            vv = APVector(1.0, 0.0)
            @test isapprox(rotate(vv, pi / 2), APVector(0.0, 1.0); atol=1e-9)
            @test reflection(vv, APPoint(5.0, 5.0)) == -vv
            l = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
            @test isapprox(reflection(APVector(1.0, 0.0), l), APVector(0.0, 1.0); atol=1e-9)

            # homothety on a bare APVector: just k*v, center is irrelevant
            # (there's no position for it to act on) -- this is what lets
            # @to_luxor_picture scale a positionless vector consistently
            # with everything else, even though it has no bounding box.
            @test homothety(APVector(3.0, 4.0), 2.0) == APVector(6.0, 8.0)
            @test homothety(APVector(3.0, 4.0), 2.0, APPoint(100.0, -50.0)) == APVector(6.0, 8.0)
            @test homothety(APVector(1.0, 2.0, 3.0), -1.0, APPoint(0.0, 0.0, 0.0)) == APVector(-1.0, -2.0, -3.0)
        end

        @testset "translate: curves and conics move every defining point by v" begin
            v = APVector(3.0, -2.0)
            s = APSegment(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
            ts = translate(s, v)
            @test ts.p1 == APPoint(0.0, 0.0) + v && ts.p2 == APPoint(1.0, 1.0) + v

            c = APCircle2(APPoint(1.0, 1.0), 5.0)
            @test translate(c, v) == APCircle2(APPoint(1.0, 1.0) + v, 5.0)

            e = APEllipse2(APPoint(1.0, 2.0), 5.0, 3.0, 0.4)
            te = translate(e, v)
            for t in range(0, 2pi; length=10)
                @test isapprox(point_on_ellipse(te, t), point_on_ellipse(e, t) + v; atol=1e-9)
            end

            h = APHyperbola2(APPoint(0.0, 0.0), 2.0, 1.0, 0.1)
            th = translate(h, v)
            @test isapprox(point_on_hyperbola(th, 0.5; branch=1), point_on_hyperbola(h, 0.5; branch=1) + v; atol=1e-9)

            par = APParabola2(APPoint(0.0, 1.0), APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0)))
            tpar = translate(par, v)
            @test isapprox(point_on_parabola(tpar, 2.0), point_on_parabola(par, 2.0) + v; atol=1e-9)

            arc = APCircularArc2(c, c.center + APVector(5.0, 0.0), c.center + APVector(0.0, 5.0))
            tarc = translate(arc, v)
            @test isapprox(point_on_arc(tarc, 0.3), point_on_arc(arc, 0.3) + v; atol=1e-9)
        end

        @testset "translate: polygon family and unbounded sets" begin
            v = APVector(3.0, -2.0)
            t = APTriangle(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 3.0))
            @test vertices(translate(t, v)) == Tuple(vx + v for vx in vertices(t))

            c1 = APCircle2(APPoint(0.0, 0.0), 3.0)
            c2 = APCircle2(APPoint(5.0, 0.0), 2.0)
            c3 = APCircle2(APPoint(3.2, 2.4), 1.0)
            g = only(interstices(c1, c2, c3))
            tg = translate(g, v)
            @test isapprox(point_on_arc(sides(tg)[1], 0.4), point_on_arc(sides(g)[1], 0.4) + v; atol=1e-6)

            hp = APHalfPlane2(APLine(APPoint(0.0, 0.0), APPoint(0.0, 1.0)), APPoint(1.0, 0.0))
            thp = translate(hp, v)
            @test (APPoint(2.0, 3.0) in hp) == ((APPoint(2.0, 3.0) + v) in thp)

            strip = APStrip2(APLine(APPoint(-2.0, 0.0), APPoint(-2.0, 1.0)), APLine(APPoint(2.0, 0.0), APPoint(2.0, 1.0)))
            tstrip = translate(strip, v)
            @test (APPoint(-5.0, 3.0) in strip) == ((APPoint(-5.0, 3.0) + v) in tstrip)

            ang = APAngle2(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
            tang = translate(ang, v)
            @test (APPoint(0.5, 0.5) in ang) == ((APPoint(0.5, 0.5) + v) in tang)
        end

        @testset "APAffineMap: ellipse/hyperbola/parabola stay the same conic type" begin
            m = APAffineMap(1.3, 0.4, -0.2, 0.9, 2.0, -1.0) # a genuine shear+scale, not just conformal

            e = APEllipse2(APPoint(1.0, 2.0), 5.0, 3.0, 0.4)
            te = m(e)
            for t in range(0, 2pi; length=15)
                @test is_on_ellipse(m(point_on_ellipse(e, t)), te; atol=1e-6)
            end

            h = APHyperbola2(APPoint(0.0, 0.0), 2.0, 1.0, 0.1)
            th = m(h)
            for t in range(-2, 2; length=15), br in (1, -1)
                @test is_on_hyperbola(m(point_on_hyperbola(h, t; branch=br)), th; atol=1e-6)
            end

            par = APParabola2(APPoint(0.0, 1.0), APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0)))
            tpar = m(par)
            for s in range(-5, 5; length=15)
                @test is_on_parabola(m(point_on_parabola(par, s)), tpar; atol=1e-6)
            end
        end

        @testset "APAffineMap: conic arcs, incl. orientation-reversing maps" begin
            m_orient_preserving = APAffineMap(1.3, 0.4, -0.2, 0.9, 2.0, -1.0)
            m_orient_reversing = APAffineMap(1.3, 0.4, 0.2, -0.9, 2.0, -1.0) # negative determinant

            for m in (m_orient_preserving, m_orient_reversing)
                c = APCircle2(APPoint(2.0, -1.0), 5.0)
                arc = APCircularArc2(c, c.center + APVector(5.0, 0.0), c.center + APVector(5.0 * cos(2.3), 5.0 * sin(2.3)))
                tarc = m(arc) # an APEllipticArc2, not APCircularArc2
                @test tarc isa APEllipticArc2
                t1 = Apollonius._ellipse_param(tarc.ellipse, tarc.p1)
                for t in range(0, 1; length=10)
                    q = m(point_on_arc(arc, t))
                    tp = Apollonius._ellipse_param(tarc.ellipse, q)
                    delta = mod(tp - t1, 2pi)
                    @test (delta <= measure(tarc) + 1e-6) || (delta >= 2pi - 1e-6)
                end

                h = APHyperbola2(APPoint(0.0, 0.0), 2.0, 1.0, 0.1)
                harc = APHyperbolicArc2(h, point_on_hyperbola(h, 0.2; branch=1), point_on_hyperbola(h, 1.3; branch=1))
                tharc = m(harc)
                @test isapprox(m(point_on_arc(harc, 0.5)), point_on_arc(tharc, 0.5); atol=1e-6)
            end
        end

        @testset "APAffineMap: half-plane / strip membership under a sheared map" begin
            m = APAffineMap(1.3, 0.4, -0.2, 0.9, 2.0, -1.0)
            hp = APHalfPlane2(APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0)), APPoint(0.0, 1.0))
            thp = m(hp)
            for p in (APPoint(0.0, 5.0), APPoint(0.0, -5.0), APPoint(3.0, 2.0), APPoint(-3.0, -2.0))
                @test (p in hp) == (m(p) in thp)
            end

            strip = APStrip2(APLine(APPoint(-2.0, 0.0), APPoint(-2.0, 1.0)), APLine(APPoint(2.0, 0.0), APPoint(2.0, 1.0)))
            tstrip = m(strip)
            for p in (APPoint(0.0, 0.0), APPoint(5.0, 0.0), APPoint(-5.0, 0.0))
                @test (p in strip) == (m(p) in tstrip)
            end
        end

        @testset "APAffineMap: circular-arc regions become curvilinear (elliptic-arc-sided)" begin
            m = APAffineMap(1.3, 0.4, -0.2, 0.9, 2.0, -1.0)
            c = APCircle2(APPoint(0.5, -0.3), 4.0)
            e0 = APEllipse2(c.center, c.r, c.r, 0.0)
            arc = APCircularArc2(c, point_on_ellipse(e0, 0.2), point_on_ellipse(e0, 2.0))

            sec = APCircularSector2(arc)
            tsec = m(sec)
            @test tsec isa APCurvilinearTriangle2
            @test isapprox(area(tsec), area(sec) * abs(m.a11 * m.a22 - m.a12 * m.a21); rtol=1e-6)

            asec = APAnnularSector2(arc, c.r * 0.4)
            tasec = m(asec)
            @test tasec isa APCurvilinearQuadrilateral2
            @test isapprox(area(tasec), area(asec) * abs(m.a11 * m.a22 - m.a12 * m.a21); rtol=1e-6)

            c1 = APCircle2(APPoint(0.0, 0.0), 3.0)
            c2 = APCircle2(APPoint(5.0, 0.0), 2.0)
            c3 = APCircle2(APPoint(3.2, 2.4), 1.0)
            g = only(interstices(c1, c2, c3))
            tg = m(g)
            @test tg isa APCurvilinearTriangle2
            @test isapprox(area(tg), area(g) * abs(m.a11 * m.a22 - m.a12 * m.a21); rtol=1e-6)
        end
    end

    # `APBoundingBox` extended to every genuinely bounded type that lacked
    # it: APEllipse2, all 4 conic arcs (bounded even when their full conic
    # isn't), and the 7 curved-region types (whose generic
    # APBoundingBox(::APPolygon) failed since they don't implement
    # `vertices`). Left out on purpose: APLine/APRay (infinite),
    # APHyperbola2/APParabola2 as full curves (also infinite), and the
    # unbounded sets APHalfPlane2/APStrip2/APAngle2.
    @testset "bounding box extension (ellipse, conic arcs, curved regions)" begin
        @testset "APEllipse2" begin
            e = APEllipse2(APPoint(1.0, 2.0), 5.0, 3.0, 0.4)
            bb = APBoundingBox(e)
            for t in range(0, 2pi; length=30)
                p = point_on_ellipse(e, t)
                @test bb.min[1] - 1e-6 <= p[1] <= bb.max[1] + 1e-6
                @test bb.min[2] - 1e-6 <= p[2] <= bb.max[2] + 1e-6
            end
            # axis-aligned ellipse: bbox is exactly center +- (a,b)
            e0 = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0, 0.0)
            @test APBoundingBox(e0) == APBoundingBox(APPoint(-5.0, -3.0), APPoint(5.0, 3.0))
        end

        @testset "conic arcs stay within their own bounding box" begin
            c = APCircle2(APPoint(1.0, -2.0), 5.0)
            e0 = APEllipse2(c.center, c.r, c.r, 0.0)
            arc = APCircularArc2(c, point_on_ellipse(e0, 0.3), point_on_ellipse(e0, 2.5))
            bb = APBoundingBox(arc)
            for t in range(0, 1; length=20)
                p = point_on_arc(arc, t)
                @test bb.min[1] - 1e-6 <= p[1] <= bb.max[1] + 1e-6 && bb.min[2] - 1e-6 <= p[2] <= bb.max[2] + 1e-6
            end

            e = APEllipse2(APPoint(2.0, 1.0), 3.0, 1.5, 0.3)
            earc = APEllipticArc2(e, point_on_ellipse(e, 0.2), point_on_ellipse(e, 3.5))
            bb2 = APBoundingBox(earc)
            for t in range(0, 1; length=20)
                p = point_on_arc(earc, t)
                @test bb2.min[1] - 1e-6 <= p[1] <= bb2.max[1] + 1e-6 && bb2.min[2] - 1e-6 <= p[2] <= bb2.max[2] + 1e-6
            end

            h = APHyperbola2(APPoint(0.0, 0.0), 2.0, 1.0, 0.1)
            harc = APHyperbolicArc2(h, point_on_hyperbola(h, -1.0; branch=1), point_on_hyperbola(h, 1.5; branch=1))
            bb3 = APBoundingBox(harc)
            for t in range(0, 1; length=20)
                p = point_on_arc(harc, t)
                @test bb3.min[1] - 1e-6 <= p[1] <= bb3.max[1] + 1e-6 && bb3.min[2] - 1e-6 <= p[2] <= bb3.max[2] + 1e-6
            end

            par = APParabola2(APPoint(0.0, 1.0), APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0)))
            parc = APParabolicArc2(par, point_on_parabola(par, -3.0), point_on_parabola(par, 4.0))
            bb4 = APBoundingBox(parc)
            for t in range(0, 1; length=20)
                p = point_on_arc(parc, t)
                @test bb4.min[1] - 1e-6 <= p[1] <= bb4.max[1] + 1e-6 && bb4.min[2] - 1e-6 <= p[2] <= bb4.max[2] + 1e-6
            end
        end

        @testset "curved regions (via sides -- vertices(p) is now derived from sides(p))" begin
            point_on_arc_or_seg(s::APSegment, t) = s.p1 + t * (s.p2 - s.p1)
            point_on_arc_or_seg(s, t) = point_on_arc(s, t)

            c = APCircle2(APPoint(1.0, -2.0), 5.0)
            e0 = APEllipse2(c.center, c.r, c.r, 0.0)
            arc = APCircularArc2(c, point_on_ellipse(e0, 0.3), point_on_ellipse(e0, 2.5))

            sec = APCircularSector2(arc)
            bb_sec = APBoundingBox(sec)
            for side in sides(sec), t in range(0, 1; length=15)
                p = point_on_arc_or_seg(side, t)
                @test bb_sec.min[1] - 1e-6 <= p[1] <= bb_sec.max[1] + 1e-6 && bb_sec.min[2] - 1e-6 <= p[2] <= bb_sec.max[2] + 1e-6
            end
            # vertices(p) == the starting point of each side, in order
            @test vertices(sec) == [Apollonius._side_p1(s) for s in sides(sec)]
            @test vertices(sec) == [c.center, arc.p1, arc.p2]
            seg2 = APCircularSegment2(arc)
            @test vertices(seg2) == [arc.p1, arc.p2]

            asec = APAnnularSector2(arc, 2.0)
            bb_asec = APBoundingBox(asec)
            @test all(isfinite, (bb_asec.min[1], bb_asec.min[2], bb_asec.max[1], bb_asec.max[2]))

            c1 = APCircle2(APPoint(0.0, 0.0), 3.0)
            c2 = APCircle2(APPoint(5.0, 0.0), 2.0)
            c3 = APCircle2(APPoint(3.2, 2.4), 1.0)
            g = only(interstices(c1, c2, c3))
            bb_g = APBoundingBox(g)
            for side in sides(g), t in range(0, 1; length=15)
                p = point_on_arc(side, t)
                @test bb_g.min[1] - 1e-6 <= p[1] <= bb_g.max[1] + 1e-6 && bb_g.min[2] - 1e-6 <= p[2] <= bb_g.max[2] + 1e-6
            end
        end
    end

    # Regression coverage for a real bug found while auditing `in`/`distance`
    # coverage across every type: `Base.in(p::APPoint, pg::APPolygon)` used
    # to be built on `vertices(pg)`, which only straight-sided polygons
    # implement — so it crashed with a MethodError for every curved-region
    # type EXCEPT APCircularSector2/APCircularSegment2 (which happened to
    # have their own bespoke `Base.in` override). Fixed by rewriting
    # `point_in_polygon` to ray-cast against `sides(pg)` generically (via a
    # new `_ray_crossings` per side type), which works for straight and
    # curved sides alike. Separately, `APSegment` had an even sneakier bug:
    # since it defines `iterate`/`getindex` (for `s[1]`/`s[2]`), `p in s`
    # silently fell through to Julia's own generic, iteration-based `in` —
    # testing whether `p` equals one of the two *endpoints*, not whether it
    # lies on the segment — so it silently returned `false` for interior
    # points instead of erroring or working. `APLine`/`APRay` and the 4
    # conic-arc types had no `in` method at all. All of this was missed by
    # the existing test suite because it tests the *named* predicates
    # (`on_segment`, `on_line`, `point_in_polygon`, ...) heavily but almost
    # never the `in` operator itself on these specific types.
    @testset "Base.in coverage: every APCurve/APPolygon type, not just the named predicates" begin
        @testset "APSegment / APLine / APRay: in matches on_segment/on_line/on_ray" begin
            s = APSegment(APPoint(0.0, 0.0), APPoint(4.0, 4.0))
            l = APLine(APPoint(0.0, 0.0), APPoint(4.0, 4.0))
            r = APRay(APPoint(0.0, 0.0), APPoint(4.0, 4.0))
            mid = APPoint(2.0, 2.0)       # interior point, not equal to either endpoint
            beyond = APPoint(6.0, 6.0)    # on the line, beyond the segment/ray's defining points
            behind = APPoint(-2.0, -2.0)  # on the line, behind the ray's origin
            off_line = APPoint(2.0, 3.0)

            @test mid in s
            @test !(off_line in s)
            @test !(beyond in s)          # regression: used to silently succeed/fail via iterate, not geometry
            @test (mid in s) == on_segment(mid, s)
            @test (beyond in s) == on_segment(beyond, s)

            @test mid in l
            @test beyond in l             # infinite line: also on it
            @test !(off_line in l)
            @test (mid in l) == on_line(mid, l)

            @test mid in r
            @test beyond in r
            @test !(behind in r)          # regression: on the line, but behind the ray's own origin
            @test on_ray(mid, r) && on_ray(beyond, r) && !on_ray(behind, r)
            @test (mid in r) == on_ray(mid, r)
        end

        @testset "conic arcs: in tests the arc's own sweep, not the full curve" begin
            circ = APCircle2(APPoint(0.0, 0.0), 5.0)
            carc = APCircularArc2(circ, APPoint(5.0, 0.0), APPoint(0.0, 5.0))
            @test APPoint(5 / sqrt(2), 5 / sqrt(2)) in carc      # on the arc's own sweep
            @test !(APPoint(-5.0, 0.0) in carc)                   # on the circle, wrong side
            @test !(APPoint(3.0, 3.0) in carc)                    # not even on the circle

            ell = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
            earc = APEllipticArc2(ell, point_on_ellipse(ell, 0.2), point_on_ellipse(ell, 2.0))
            @test point_on_arc(earc, 0.5) in earc
            @test !(point_on_ellipse(ell, 4.0) in earc)

            par = APParabola2(APPoint(0.0, 1.0), APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0)))
            parc = APParabolicArc2(par, point_on_parabola(par, -3.0), point_on_parabola(par, 3.0))
            @test point_on_arc(parc, 0.5) in parc
            @test !(point_on_parabola(par, 10.0) in parc)

            hyp = APHyperbola2(APPoint(0.0, 0.0), 3.0, 4.0)
            harc = APHyperbolicArc2(hyp, point_on_hyperbola(hyp, -0.5), point_on_hyperbola(hyp, 0.5))
            @test point_on_arc(harc, 0.5) in harc
            @test !(point_on_hyperbola(hyp, 0.5; branch=-1) in harc)  # right branch point, wrong branch of arc
        end

        @testset "curved regions: in/distance work via sides(), agree with the bespoke sector/segment methods" begin
            circ = APCircle2(APPoint(0.0, 0.0), 5.0)
            carc = APCircularArc2(circ, APPoint(5.0, 0.0), APPoint(0.0, 5.0))
            sector = APCircularSector2(carc)

            asec = APAnnularSector2(carc, 2.0)
            @test APPoint(3.5 / sqrt(2), 3.5 / sqrt(2)) in asec   # between the two radii, right angle
            @test !(APPoint(1 / sqrt(2), 1 / sqrt(2)) in asec)     # inside the inner hole
            @test !(APPoint(7 / sqrt(2), 7 / sqrt(2)) in asec)     # outside the outer radius
            @test !(APPoint(-3.5, 0.0) in asec)                     # right radius, wrong angle
            @test distance(APPoint(1 / sqrt(2), 1 / sqrt(2)), asec) > 0
            @test distance(APPoint(3.5 / sqrt(2), 3.5 / sqrt(2)), asec) == 0.0

            u1 = APCircle2(APPoint(0.0, 0.0), 1.0)
            u2 = APCircle2(APPoint(2.0, 0.0), 1.0)
            u3 = APCircle2(APPoint(1.0, sqrt(3)), 1.0)
            gap = only(interstices(u1, u2, u3))
            inside_pt = APPoint(1.0, sqrt(3) / 3)
            @test inside_pt in gap
            @test !(APPoint(100.0, 100.0) in gap)
            @test !(u1.center in gap)
            @test distance(inside_pt, gap) == 0.0
            @test distance(APPoint(100.0, 100.0), gap) > 0

            chord = APSegment(APPoint(0.0, 5.0), APPoint(0.0, 0.0))
            radius = APSegment(APPoint(0.0, 0.0), APPoint(5.0, 0.0))
            ct = APCurvilinearTriangle2(radius, carc, chord)  # same shape as `sector` above
            cngon = APCurvilinearNgon2([radius, carc, chord])
            for x in -6.0:1.5:6.0, y in -6.0:1.5:6.0
                p = APPoint(x, y)
                @test (p in ct) == (p in sector)
                @test (p in cngon) == (p in sector)
            end
        end
    end

    # 3D geometry (Phase 1: plane/sphere foundation). Placed before the
    # Luxor extension testset for the same reason as the "distance
    # extension" testset above: that testset's `using Luxor` brings in
    # Luxor's own exported `distance`, which would otherwise make every
    # unqualified `distance(...)` call below ambiguous.
    # 3D geometry is paused (see scratch/ notes) -- its source files are
    # untracked/commented out of Apollonius.jl's includes, so every
    # 3D type below is undefined. `if false` disables this whole block
    # without deleting it (re-enable by removing the `if false`/`end` once
    # 3D work resumes) -- the code still needs to *parse*, which it does.
    if false
    @testset "3D geometry (Phase 1: plane/sphere foundation)" begin
        @testset "APPlane3 construction, distance, projection, reflection" begin
            xy = APPlane3(APPoint(0.0, 0.0, 0.0), APVector(0.0, 0.0, 1.0))
            @test xy.normal ≈ APVector(0.0, 0.0, 1.0)

            # normal is normalized on construction, even from a non-unit input
            pl2 = APPlane3(APPoint(0.0, 0.0, 0.0), APVector(0.0, 0.0, 5.0))
            @test pl2.normal ≈ APVector(0.0, 0.0, 1.0)

            # 3-point constructor
            pl3 = APPlane3(APPoint(0.0, 0.0, 0.0), APPoint(1.0, 0.0, 0.0), APPoint(0.0, 1.0, 0.0))
            @test abs(pl3.normal[3]) ≈ 1.0
            @test_throws ArgumentError APPlane3(APPoint(0.0, 0.0, 0.0), APPoint(1.0, 0.0, 0.0), APPoint(2.0, 0.0, 0.0))

            p = APPoint(1.0, 2.0, 3.0)
            @test distance(p, xy) ≈ 3.0
            @test distance(xy, p) ≈ 3.0
            @test side_of_plane(p, xy) == 1
            @test side_of_plane(APPoint(1.0, 2.0, -3.0), xy) == -1
            @test side_of_plane(APPoint(1.0, 2.0, 0.0), xy) == 0
            @test on_plane(APPoint(5.0, -3.0, 0.0), xy)
            @test !on_plane(p, xy)

            @test projection(p, xy) ≈ APPoint(1.0, 2.0, 0.0)
            @test reflection(p, xy) ≈ APPoint(1.0, 2.0, -3.0)

            # reflecting twice is the identity
            @test reflection(reflection(p, xy), xy) ≈ p
        end

        @testset "APSphere3: volume, surface_area, distance modes, on_sphere" begin
            sph = APSphere3(APPoint(1.0, 1.0, 1.0), 2.0)
            @test volume(sph) ≈ (4 / 3) * pi * 8.0
            @test surface_area(sph) ≈ 4 * pi * 4.0
            @test centroid(sph) == sph.center

            @test on_sphere(APPoint(3.0, 1.0, 1.0), sph)
            @test !on_sphere(APPoint(1.0, 1.0, 1.0), sph)

            pin, pout = APPoint(1.0, 1.0, 1.0), APPoint(10.0, 1.0, 1.0)
            @test distance(pin, sph) == 0.0
            @test distance(pin, sph; mode=:boundary) ≈ 2.0
            @test distance(pout, sph) ≈ distance(pout, sph.center) - 2.0
            @test distance(pout, sph; mode=:boundary) ≈ distance(pout, sph; mode=:region)
        end

        @testset "rotate(::APPoint{3}, angle, axis) via Rodrigues" begin
            zaxis = APLine(APPoint(0.0, 0.0, 0.0), APPoint(0.0, 0.0, 1.0))
            @test rotate(APPoint(1.0, 0.0, 0.0), pi / 2, zaxis) ≈ APPoint(0.0, 1.0, 0.0) atol = 1e-12
            @test rotate(APPoint(1.0, 0.0, 5.0), pi / 2, zaxis) ≈ APPoint(0.0, 1.0, 5.0) atol = 1e-12 # axis coord untouched
            @test rotate(APPoint(1.0, 0.0, 0.0), 2pi, zaxis) ≈ APPoint(1.0, 0.0, 0.0) atol = 1e-9

            # an off-origin axis: only the component perpendicular to it moves
            axis = APLine(APPoint(1.0, 0.0, 0.0), APPoint(1.0, 0.0, 1.0))
            @test rotate(APPoint(2.0, 0.0, 0.0), pi / 2, axis) ≈ APPoint(1.0, 1.0, 0.0) atol = 1e-12
            @test rotate(APPoint(1.0, 0.0, 7.0), pi / 3, axis) ≈ APPoint(1.0, 0.0, 7.0) atol = 1e-12 # on the axis: fixed

            # APSegment/APLine/APRay rotate about an axis (pointwise, via the new dispatch)
            seg = APSegment(APPoint(2.0, 0.0, 0.0), APPoint(2.0, 0.0, 5.0))
            rseg = rotate(seg, pi / 2, axis)
            @test rseg.p1 ≈ APPoint(1.0, 1.0, 0.0) atol = 1e-12
            @test rseg.p2 ≈ APPoint(1.0, 1.0, 5.0) atol = 1e-12

            # translate/homothety/reflection on APSegment{3} already "just work"
            # generically (dimension-generic point-level formulas underneath)
            v = APVector(0.0, 0.0, 10.0)
            @test translate(seg, v).p1 ≈ APPoint(2.0, 0.0, 10.0)
            @test homothety(seg, 2.0, APPoint(0.0, 0.0, 0.0)).p2 ≈ APPoint(4.0, 0.0, 10.0)
            xy = APPlane3(APPoint(0.0, 0.0, 0.0), APVector(0.0, 0.0, 1.0))
            @test reflection(seg, xy).p2 ≈ APPoint(2.0, 0.0, -5.0)

            # reflection(::APPoint{2}, ::APLine{2}) must NOT silently accept 3D args
            # (the orientation-changing trap the plan calls out)
            @test_throws MethodError reflection(APPoint(1.0, 0.0, 0.0), APLine(APPoint(0.0, 0.0, 0.0), APPoint(0.0, 0.0, 1.0)))
        end

        @testset "distance(::APPoint{3}, ::APLine{3}) via cross3" begin
            l = APLine(APPoint(0.0, 0.0, 0.0), APPoint(1.0, 0.0, 0.0))
            @test distance(APPoint(0.0, 3.0, 4.0), l) ≈ 5.0
            @test distance(l, APPoint(0.0, 3.0, 4.0)) ≈ 5.0
            @test distance(APPoint(0.5, 0.0, 0.0), l) ≈ 0.0 atol = 1e-12
        end

        @testset "is_coplanar / line_line_position / line-line intersection & distance" begin
            a, b, c = APPoint(0.0, 0.0, 0.0), APPoint(1.0, 0.0, 0.0), APPoint(0.0, 1.0, 0.0)
            @test is_coplanar(a, b, c, APPoint(1.0, 1.0, 0.0))
            @test !is_coplanar(a, b, c, APPoint(0.0, 0.0, 1.0))

            l1 = APLine(APPoint(0.0, 0.0, 0.0), APPoint(1.0, 0.0, 0.0))
            l2 = APLine(APPoint(0.0, 0.0, 0.0), APPoint(0.0, 1.0, 0.0))
            @test line_line_position(l1, l2) == :intersecting
            @test only(intersection(l1, l2)) ≈ APPoint(0.0, 0.0, 0.0)
            @test distance(l1, l2) ≈ 0.0 atol = 1e-12

            l_par = APLine(APPoint(0.0, 1.0, 0.0), APPoint(1.0, 1.0, 0.0))
            @test line_line_position(l1, l_par) == :parallel
            @test isempty(intersection(l1, l_par))
            @test distance(l1, l_par) ≈ 1.0

            l_coincident = APLine(APPoint(2.0, 0.0, 0.0), APPoint(3.0, 0.0, 0.0))
            @test line_line_position(l1, l_coincident) == :coincident

            l_skew = APLine(APPoint(0.0, 0.0, 1.0), APPoint(0.0, 1.0, 1.0))
            @test line_line_position(l1, l_skew) == :skew
            @test isempty(intersection(l1, l_skew))
            @test distance(l1, l_skew) ≈ 1.0
        end

        @testset "line <-> plane" begin
            xy = APPlane3(APPoint(0.0, 0.0, 0.0), APVector(0.0, 0.0, 1.0))
            crossing = APLine(APPoint(0.0, 0.0, -1.0), APPoint(0.0, 0.0, 1.0))
            @test only(intersection(crossing, xy)) ≈ APPoint(0.0, 0.0, 0.0)
            @test only(intersection(xy, crossing)) ≈ APPoint(0.0, 0.0, 0.0)
            @test distance(crossing, xy) == 0.0

            parallel_line = APLine(APPoint(0.0, 0.0, 5.0), APPoint(1.0, 0.0, 5.0))
            @test isempty(intersection(parallel_line, xy))
            @test distance(parallel_line, xy) ≈ 5.0

            contained_line = APLine(APPoint(0.0, 0.0, 0.0), APPoint(1.0, 1.0, 0.0))
            @test_throws ArgumentError intersection(contained_line, xy)
        end

        @testset "plane <-> plane" begin
            xy = APPlane3(APPoint(0.0, 0.0, 0.0), APVector(0.0, 0.0, 1.0))
            xz = APPlane3(APPoint(0.0, 0.0, 0.0), APVector(0.0, 1.0, 0.0))
            iline = intersection(xy, xz)
            @test iline isa APLine
            @test on_line(APPoint(0.0, 0.0, 0.0), iline)
            @test on_line(APPoint(7.0, 0.0, 0.0), iline)
            @test distance(xy, xz) == 0.0

            z1 = APPlane3(APPoint(0.0, 0.0, 1.0), APVector(0.0, 0.0, 1.0))
            @test intersection(xy, z1) === nothing
            @test distance(xy, z1) ≈ 1.0
        end

        @testset "line <-> sphere, plane <-> sphere, sphere <-> sphere" begin
            sph = APSphere3(APPoint(0.0, 0.0, 0.0), 5.0)

            through = APLine(APPoint(-10.0, 0.0, 0.0), APPoint(10.0, 0.0, 0.0))
            pts = intersection(through, sph)
            @test length(pts) == 2
            @test all(p -> on_sphere(p, sph), pts)

            tangent_l = APLine(APPoint(5.0, -1.0, 0.0), APPoint(5.0, 1.0, 0.0))
            @test length(intersection(tangent_l, sph)) == 1

            missing_l = APLine(APPoint(10.0, -1.0, 0.0), APPoint(10.0, 1.0, 0.0))
            @test isempty(intersection(missing_l, sph))
            @test isempty(intersection(sph, missing_l))

            # plane through the center -> a great circle of the same radius
            xy = APPlane3(APPoint(0.0, 0.0, 0.0), APVector(0.0, 0.0, 1.0))
            gc = intersection(xy, sph)
            @test gc isa APCircle3
            @test gc.r ≈ 5.0
            @test gc.center ≈ APPoint(0.0, 0.0, 0.0)

            # tangent plane
            tangent_pl = APPlane3(APPoint(0.0, 0.0, 5.0), APVector(0.0, 0.0, 1.0))
            tp = intersection(tangent_pl, sph)
            @test tp isa APPoint
            @test tp ≈ APPoint(0.0, 0.0, 5.0)

            # disjoint plane
            far_pl = APPlane3(APPoint(0.0, 0.0, 10.0), APVector(0.0, 0.0, 1.0))
            @test intersection(far_pl, sph) === nothing

            # sphere-sphere: overlapping -> circle, verified by construction
            s1 = APSphere3(APPoint(0.0, 0.0, 0.0), 5.0)
            s2 = APSphere3(APPoint(6.0, 0.0, 0.0), 5.0)
            circ = intersection(s1, s2)
            @test circ isa APCircle3
            @test circ.center ≈ APPoint(3.0, 0.0, 0.0)
            @test circ.r ≈ 4.0
            @test all(isapprox.(distance.(Ref(circ.center), (s1.center, s2.center)), (3.0, 3.0)))

            # sphere-sphere: tangent -> point
            s3 = APSphere3(APPoint(10.0, 0.0, 0.0), 5.0)
            tangent_pt = intersection(s1, s3)
            @test tangent_pt isa APPoint
            @test tangent_pt ≈ APPoint(5.0, 0.0, 0.0)

            # sphere-sphere: disjoint -> nothing
            s4 = APSphere3(APPoint(100.0, 0.0, 0.0), 5.0)
            @test intersection(s1, s4) === nothing

            # sphere-sphere: concentric -> nothing
            s5 = APSphere3(APPoint(0.0, 0.0, 0.0), 2.0)
            @test intersection(s1, s5) === nothing
        end

        @testset "APAffineMap3: rotation_map/homothety_map/reflection_map/translation_map, ∘, affine_map" begin
            axis = APLine(APPoint(0.0, 0.0, 0.0), APPoint(0.0, 0.0, 1.0))
            p = APPoint(1.0, 0.0, 0.0)

            rm = rotation_map(pi / 2, axis)
            @test rm(p) ≈ rotate(p, pi / 2, axis) atol = 1e-12
            @test rm(APVector(1.0, 0.0, 0.0)) ≈ APVector(0.0, 1.0, 0.0) atol = 1e-12 # linear part only, no translation

            hm = homothety_map(2.0, APPoint(1.0, 1.0, 1.0))
            @test hm(APPoint(3.0, 1.0, 1.0)) ≈ APPoint(5.0, 1.0, 1.0)
            @test hm(p) ≈ homothety(p, 2.0, APPoint(1.0, 1.0, 1.0))

            xy = APPlane3(APPoint(0.0, 0.0, 0.0), APVector(0.0, 0.0, 1.0))
            refm = reflection_map(xy)
            @test refm(APPoint(1.0, 2.0, 3.0)) ≈ APPoint(1.0, 2.0, -3.0)
            @test refm(APPoint(1.0, 2.0, 3.0)) ≈ reflection(APPoint(1.0, 2.0, 3.0), xy)

            ptrefm = reflection_map(APPoint(1.0, 1.0, 1.0))
            @test ptrefm(APPoint(2.0, 1.0, 1.0)) ≈ APPoint(0.0, 1.0, 1.0)
            @test ptrefm(p) ≈ reflection(p, APPoint(1.0, 1.0, 1.0))

            tm = translation_map(APVector(1.0, 2.0, 3.0))
            @test tm(APPoint(0.0, 0.0, 0.0)) ≈ APPoint(1.0, 2.0, 3.0)
            @test tm(p) ≈ translate(p, APVector(1.0, 2.0, 3.0))

            # type-preserving 1-arg forms (plain functions, not APAffineMap3)
            # -- same tradeoff as 2D: exact per-type call, not a combined map
            sph = APSphere3(APPoint(1.0, 1.0, 1.0), 2.0)
            @test rotate(pi / 2, axis)(sph) isa APSphere3
            @test rotate(pi / 2, axis)(sph) == rotate(sph, pi / 2, axis)
            @test homothety(2.0, APPoint(1.0, 1.0, 1.0))(sph) isa APSphere3
            @test translate(APVector(1.0, 2.0, 3.0))(sph) isa APSphere3
            @test reflection(xy)(sph) isa APSphere3
            @test reflection(APPoint(1.0, 1.0, 1.0))(sph) isa APSphere3
            chain = rotate(pi / 2, axis) ∘ translate(APVector(1.0, 2.0, 3.0))
            @test chain isa Function && !(chain isa APAffineMap3)
            @test chain(sph) isa APSphere3

            # composition, right-to-left like ordinary functions
            composed = rm ∘ tm
            @test composed(APPoint(0.0, 0.0, 0.0)) ≈ rm(tm(APPoint(0.0, 0.0, 0.0))) atol = 1e-12
            @test composed isa APAffineMap3

            # apply directly to APSegment/APLine/APRay
            seg = APSegment(APPoint(1.0, 0.0, 0.0), APPoint(2.0, 0.0, 0.0))
            @test rm(seg).p1 ≈ APPoint(0.0, 1.0, 0.0) atol = 1e-12

            # affine_map: 4 non-coplanar point correspondences
            src = (APPoint(0.0, 0.0, 0.0), APPoint(1.0, 0.0, 0.0), APPoint(0.0, 1.0, 0.0), APPoint(0.0, 0.0, 1.0))
            dst = (APPoint(2.0, 3.0, 5.0), APPoint(3.0, 3.0, 5.0), APPoint(2.0, 4.0, 5.0), APPoint(2.0, 3.0, 6.0))
            am = affine_map(src, dst)
            @test all(isapprox(am(s), d; atol=1e-9) for (s, d) in zip(src, dst))
            @test_throws ArgumentError affine_map(
                (APPoint(0.0, 0.0, 0.0), APPoint(1.0, 0.0, 0.0), APPoint(2.0, 0.0, 0.0), APPoint(3.0, 0.0, 0.0)),
                dst)
        end
    end

    @testset "3D geometry (unbounded sets, polyhedra, curved solids)" begin
        @testset "APHalfSpace3" begin
            xy = APPlane3(APPoint(0.0, 0.0, 0.0), APVector(0.0, 0.0, 1.0))
            hs = APHalfSpace3(xy, APPoint(0.0, 0.0, 5.0))
            @test APPoint(0.0, 0.0, 3.0) in hs
            @test !(APPoint(0.0, 0.0, -3.0) in hs)
            @test APPoint(0.0, 0.0, 0.0) in hs # boundary included
            @test distance(APPoint(0.0, 0.0, 3.0), hs) == 0.0
            @test distance(APPoint(0.0, 0.0, 3.0), hs; mode=:boundary) ≈ 3.0
            @test distance(APPoint(0.0, 0.0, -3.0), hs) ≈ 3.0
            @test_throws ArgumentError APHalfSpace3(xy, APPoint(1.0, 1.0, 0.0))

            # k < 0 is orientation-reversing in 3D: the half-space flips
            hs2 = homothety(hs, -1.0, APPoint(0.0, 0.0, 0.0))
            @test !(APPoint(0.0, 0.0, 3.0) in hs2)
            @test APPoint(0.0, 0.0, -3.0) in hs2
        end

        @testset "APSlab3" begin
            z0 = APPlane3(APPoint(0.0, 0.0, 0.0), APVector(0.0, 0.0, 1.0))
            z5 = APPlane3(APPoint(0.0, 0.0, 5.0), APVector(0.0, 0.0, 1.0))
            slab = APSlab3(z0, z5)
            @test slab_width(slab) ≈ 5.0
            @test APPoint(0.0, 0.0, 2.0) in slab
            @test !(APPoint(0.0, 0.0, 10.0) in slab)
            @test distance(APPoint(0.0, 0.0, 2.0), slab) == 0.0
            @test distance(APPoint(0.0, 0.0, 2.0), slab; mode=:boundary) ≈ 2.0

            not_parallel = APPlane3(APPoint(0.0, 0.0, 0.0), APVector(1.0, 0.0, 0.0))
            @test_throws ArgumentError APSlab3(z0, not_parallel)
        end

        @testset "APDihedralAngle3" begin
            edge = APLine(APPoint(0.0, 0.0, 0.0), APPoint(0.0, 0.0, 1.0))
            d = APDihedralAngle3(edge, APPoint(1.0, 0.0, 5.0), APPoint(0.0, 1.0, -3.0))
            @test measure(d) ≈ pi / 2
            @test abs(d) ≈ pi / 2
            @test is_direct(d)
            @test measure(reverse(d)) ≈ -pi / 2
            @test APPoint(1.0, 1.0, 0.0) in d
            @test !(APPoint(-1.0, 0.0, 0.0) in d)

            xy = APPlane3(APPoint(0.0, 0.0, 0.0), APVector(0.0, 0.0, 1.0))
            # both plane- and point-reflection swap a/b in 3D (both are
            # orientation-reversing here, unlike 2D where only the mirror is)
            @test measure(reflection(d, xy)) ≈ pi / 2
            @test measure(reflection(d, APPoint(0.0, 0.0, 0.0))) ≈ pi / 2
            # k < 0 is also orientation-reversing in 3D -> swap; k > 0 doesn't
            @test measure(homothety(d, -1.0, APPoint(0.0, 0.0, 0.0))) ≈ pi / 2
            @test measure(homothety(d, 2.0, APPoint(0.0, 0.0, 0.0))) ≈ pi / 2
        end

        @testset "APPolyhedralAngle3 (n=3 is the 'triedro')" begin
            vertex = APPoint(0.0, 0.0, 0.0)
            rays = [APPoint(1.0, 0.0, 0.0), APPoint(0.0, 1.0, 0.0), APPoint(0.0, 0.0, 1.0)]
            pa = APPolyhedralAngle3(vertex, rays)
            @test solid_angle(pa) ≈ pi / 2 # one octant = 1/8 of 4π steradians
            @test APPoint(1.0, 1.0, 1.0) in pa
            @test !(APPoint(-1.0, -1.0, -1.0) in pa)
            @test_throws ArgumentError APPolyhedralAngle3(vertex, rays[1:2])
        end

        @testset "APTetrahedron3" begin
            t = APTetrahedron3(APPoint(0.0, 0.0, 0.0), APPoint(1.0, 0.0, 0.0), APPoint(0.0, 1.0, 0.0), APPoint(0.0, 0.0, 1.0))
            @test volume(t) ≈ 1 / 6
            @test centroid(t) ≈ APPoint(0.25, 0.25, 0.25)
            @test surface_area(t) ≈ 1.5 + sqrt(3) / 2
            @test length(faces(t)) == 4

            # order-independence: faces() works out outward orientation itself
            t2 = APTetrahedron3(APPoint(0.0, 0.0, 1.0), APPoint(0.0, 0.0, 0.0), APPoint(1.0, 0.0, 0.0), APPoint(0.0, 1.0, 0.0))
            @test volume(t2) ≈ 1 / 6
            @test centroid(t2) ≈ APPoint(0.25, 0.25, 0.25)

            axis = APLine(APPoint(0.0, 0.0, 0.0), APPoint(0.0, 0.0, 1.0))
            @test volume(rotate(t, pi / 3, axis)) ≈ volume(t)
            @test volume(translate(t, APVector(10.0, 20.0, 30.0))) ≈ volume(t)
            @test volume(homothety(t, 2.0, APPoint(0.0, 0.0, 0.0))) ≈ volume(t) * 8
            @test volume(homothety(t, -2.0, APPoint(0.0, 0.0, 0.0))) ≈ volume(t) * 8 # abs
            xy = APPlane3(APPoint(0.0, 0.0, 0.0), APVector(0.0, 0.0, 1.0))
            @test volume(reflection(t, xy)) ≈ volume(t)
        end

        @testset "APParallelepiped3, box3, cube3" begin
            b = box3(APPoint(0.0, 0.0, 0.0), 2.0, 3.0, 4.0)
            @test volume(b) ≈ 24.0
            @test surface_area(b) ≈ 2 * (2 * 3 + 2 * 4 + 3 * 4)
            @test centroid(b) ≈ APPoint(1.0, 1.5, 2.0)
            @test length(vertices(b)) == 8
            @test length(faces(b)) == 6

            c = cube3(APPoint(1.0, 1.0, 1.0), 5.0)
            @test volume(c) ≈ 125.0
        end

        @testset "APPyramid3" begin
            base_sq = APStraightNgon([APPoint(-1.0, -1.0, 0.0), APPoint(1.0, -1.0, 0.0), APPoint(1.0, 1.0, 0.0), APPoint(-1.0, 1.0, 0.0)])
            pyr = APPyramid3(APPoint(0.0, 0.0, 3.0), base_sq)
            @test volume(pyr) ≈ 4.0 # (1/3)*base_area(4)*height(3)
            c = centroid(pyr)
            @test c[3] ≈ 0.75 # 1/4 of the way from base to apex
            @test c[1] ≈ 0.0 atol = 1e-12
            @test c[2] ≈ 0.0 atol = 1e-12
            @test length(faces(pyr)) == 5 # 1 base + 4 lateral
        end

        @testset "APPrism3" begin
            base_sq = APStraightNgon([APPoint(-1.0, -1.0, 0.0), APPoint(1.0, -1.0, 0.0), APPoint(1.0, 1.0, 0.0), APPoint(-1.0, 1.0, 0.0)])
            prism = APPrism3(base_sq, APVector(0.0, 0.0, 5.0))
            @test volume(prism) ≈ 20.0 # base_area(4)*height(5)
            @test centroid(prism) ≈ APPoint(0.0, 0.0, 2.5)
            @test surface_area(prism) ≈ 2 * 4 + 4 * (2 * 5)
            @test length(faces(prism)) == 6 # base + top + 4 lateral
        end

        @testset "APGeneralPolyhedron3" begin
            t = APTetrahedron3(APPoint(0.0, 0.0, 0.0), APPoint(1.0, 0.0, 0.0), APPoint(0.0, 1.0, 0.0), APPoint(0.0, 0.0, 1.0))
            gp = APGeneralPolyhedron3(collect(faces(t)))
            @test volume(gp) ≈ volume(t)
            @test surface_area(gp) ≈ surface_area(t)
        end

        @testset "APCylinder3" begin
            cyl = APCylinder3(APPoint(0.0, 0.0, 0.0), APPoint(0.0, 0.0, 10.0), 2.0)
            @test height(cyl) ≈ 10.0
            @test volume(cyl) ≈ pi * 4 * 10
            @test surface_area(cyl) ≈ 2 * pi * 4 + 2 * pi * 2 * 10
            @test centroid(cyl) ≈ APPoint(0.0, 0.0, 5.0)
            @test APPoint(1.0, 0.0, 5.0) in cyl
            @test !(APPoint(3.0, 0.0, 5.0) in cyl) # outside radius
            @test !(APPoint(1.0, 0.0, 15.0) in cyl) # beyond height
            c1, c2 = caps(cyl)
            @test c1.r == 2.0 && c2.r == 2.0

            axis = APLine(APPoint(0.0, 0.0, 0.0), APPoint(1.0, 0.0, 0.0))
            @test volume(rotate(cyl, pi / 4, axis)) ≈ volume(cyl)
            @test volume(homothety(cyl, 2.0, APPoint(0.0, 0.0, 0.0))) ≈ volume(cyl) * 8
        end

        @testset "APCone3" begin
            cone = APCone3(APPoint(0.0, 0.0, 9.0), APPoint(0.0, 0.0, 0.0), 3.0)
            @test height(cone) ≈ 9.0
            @test slant_height(cone) ≈ sqrt(81.0 + 9.0)
            @test volume(cone) ≈ pi * 9 * 9 / 3
            @test surface_area(cone) ≈ pi * 9 + pi * 3 * sqrt(90.0)
            @test centroid(cone) ≈ APPoint(0.0, 0.0, 2.25)
            @test APPoint(0.0, 0.0, 0.0) in cone
            @test APPoint(2.0, 0.0, 0.0) in cone # base edge, r=3
            @test APPoint(0.0, 0.0, 9.0) in cone # apex
            @test !(APPoint(2.0, 0.0, 8.0) in cone) # radius shrinks near apex
            @test base(cone).r == 3.0
        end
    end

    @testset "3D geometry (correctness fixes and coverage gaps)" begin
        @testset "centroid/is_convex/point_in_polygon/is_planar for APPolygon{3}" begin
            tri3 = APTriangle(APPoint(0.0, 0.0, 0.0), APPoint(4.0, 0.0, 0.0), APPoint(0.0, 4.0, 0.0))
            @test centroid(tri3) ≈ APPoint(4 / 3, 4 / 3, 0.0)
            @test is_convex(tri3)
            @test area(tri3) ≈ 8.0 # already fixed earlier; re-verified alongside its siblings

            # a genuinely tilted (non-axis-aligned) planar square
            sq = APStraightNgon([APPoint(0.0, 0.0, 0.0), APPoint(1.0, 0.0, 1.0), APPoint(1.0, 1.0, 1.0), APPoint(0.0, 1.0, 0.0)])
            @test is_planar(sq)
            @test area(sq) ≈ sqrt(2.0)
            @test centroid(sq) ≈ APPoint(0.5, 0.5, 0.5)
            @test is_convex(sq)
            @test centroid(sq) in sq
            @test !(APPoint(5.0, 5.0, 5.0) in sq)

            non_planar = APStraightNgon([APPoint(0.0, 0.0, 0.0), APPoint(1.0, 0.0, 0.0), APPoint(1.0, 1.0, 1.0), APPoint(0.0, 1.0, 0.0)])
            @test !is_planar(non_planar)

            # an L-shape (non-convex), embedded flat in 3D
            lshape = APStraightNgon([APPoint(0.0, 0.0, 0.0), APPoint(2.0, 0.0, 0.0), APPoint(2.0, 1.0, 0.0),
                APPoint(1.0, 1.0, 0.0), APPoint(1.0, 2.0, 0.0), APPoint(0.0, 2.0, 0.0)])
            @test !is_convex(lshape)
            @test area(lshape) ≈ 3.0
        end

        @testset "APSegment{3}/APRay{3} <-> APPlane3" begin
            xy = APPlane3(APPoint(0.0, 0.0, 0.0), APVector(0.0, 0.0, 1.0))

            s_cross = APSegment(APPoint(0.0, 0.0, -1.0), APPoint(0.0, 0.0, 1.0))
            @test distance(s_cross, xy) == 0.0
            @test only(intersection(s_cross, xy)) ≈ APPoint(0.0, 0.0, 0.0)
            @test only(intersection(xy, s_cross)) ≈ APPoint(0.0, 0.0, 0.0)

            s_above = APSegment(APPoint(0.0, 0.0, 3.0), APPoint(0.0, 0.0, 5.0))
            @test distance(s_above, xy) ≈ 3.0
            @test distance(xy, s_above) ≈ 3.0
            @test isempty(intersection(s_above, xy))

            r_toward = APRay(APPoint(0.0, 0.0, 5.0), APPoint(0.0, 0.0, 4.0))
            @test distance(r_toward, xy) == 0.0
            @test only(intersection(r_toward, xy)) ≈ APPoint(0.0, 0.0, 0.0)

            r_away = APRay(APPoint(0.0, 0.0, 5.0), APPoint(0.0, 0.0, 6.0))
            @test distance(r_away, xy) ≈ 5.0
            @test isempty(intersection(r_away, xy))
        end

        @testset "APSegment{3}/APRay{3} <-> APSphere3" begin
            sph = APSphere3(APPoint(0.0, 0.0, 0.0), 5.0)

            s_through = APSegment(APPoint(-10.0, 0.0, 0.0), APPoint(10.0, 0.0, 0.0))
            pts = intersection(s_through, sph)
            @test length(pts) == 2
            @test all(p -> on_sphere(p, sph), pts)
            @test distance(s_through, sph) == 0.0

            s_outside = APSegment(APPoint(10.0, 0.0, 0.0), APPoint(20.0, 0.0, 0.0))
            @test isempty(intersection(s_outside, sph))
            @test isempty(intersection(sph, s_outside))
            @test distance(s_outside, sph) ≈ 5.0
            @test distance(s_outside, sph; mode=:boundary) ≈ 5.0

            # entirely INSIDE the sphere: boundary distance is to the FARTHER
            # endpoint, not the closer one (the bug this test guards against)
            s_inside = APSegment(APPoint(-1.0, 0.0, 0.0), APPoint(1.0, 0.0, 0.0))
            @test distance(s_inside, sph) == 0.0
            @test distance(s_inside, sph; mode=:boundary) ≈ 4.0

            r_sph = APRay(APPoint(0.0, 0.0, 0.0), APPoint(1.0, 0.0, 0.0))
            @test only(intersection(r_sph, sph)) ≈ APPoint(5.0, 0.0, 0.0)
            @test only(intersection(sph, r_sph)) ≈ APPoint(5.0, 0.0, 0.0)

            r_missing = APRay(APPoint(10.0, 0.0, 0.0), APPoint(11.0, 0.0, 0.0))
            @test isempty(intersection(r_missing, sph))
            @test distance(r_missing, sph) ≈ 5.0
        end

        @testset "distance(::APPoint{3}, ::APCylinder3/::APCone3; mode)" begin
            cyl = APCylinder3(APPoint(0.0, 0.0, 0.0), APPoint(0.0, 0.0, 10.0), 2.0)
            @test distance(APPoint(0.0, 0.0, 5.0), cyl) == 0.0 # on axis, well inside
            @test distance(APPoint(0.0, 0.0, 5.0), cyl; mode=:boundary) ≈ 2.0 # to the lateral surface, NOT 0 (the axis isn't a boundary)
            @test distance(APPoint(5.0, 0.0, 5.0), cyl) ≈ 3.0 # outside radially: 5-2
            @test distance(APPoint(0.0, 0.0, 15.0), cyl) ≈ 5.0 # beyond the top cap, on-axis
            @test distance(APPoint(5.0, 0.0, 15.0), cyl) ≈ sqrt(3.0^2 + 5.0^2) # beyond top cap AND outside radially
            @test (distance(APPoint(0.0, 0.0, 5.0), cyl) == 0.0) == (APPoint(0.0, 0.0, 5.0) in cyl)

            cone = APCone3(APPoint(0.0, 0.0, 9.0), APPoint(0.0, 0.0, 0.0), 3.0)
            @test distance(APPoint(0.0, 0.0, 3.0), cone) == 0.0
            @test distance(APPoint(0.0, 0.0, 0.0), cone; mode=:boundary) == 0.0 # base center lies ON the base disk
            @test distance(APPoint(100.0, 0.0, 0.0), cone) ≈ 97.0
        end
    end

    @testset "3D conics (APEllipse3/APParabola3/APHyperbola3 + arcs)" begin
        @testset "APCircle3 fuller API" begin
            c = APCircle3(APPoint(0.0, 0.0, 5.0), 3.0, APVector(0.0, 0.0, 1.0))
            p0 = point_on_circle3(c, 0.0)
            @test is_on_circle3(p0, c)
            @test distance(p0, c.center) ≈ 3.0
            @test point_on_circle3(c, pi / 2)[3] == 5.0 # stays in the supporting plane
        end

        @testset "APEllipse3" begin
            e = APEllipse3(APPoint(1.0, 1.0, 1.0), 5.0, 3.0, APVector(0.0, 0.0, 1.0), APVector(1.0, 0.0, 0.0))
            @test area(e) ≈ pi * 15
            p_on = point_on_ellipse3(e, 0.7)
            @test is_on_ellipse3(p_on, e)
            @test p_on[3] ≈ 1.0 # embedded in its own plane
            f1, f2 = foci(e)
            @test distance(p_on, f1) + distance(p_on, f2) ≈ 10.0 # 2a
            @test distance(e.center, e) ≈ 3.0 # Newton solve; min(a,b) at the center

            # u gets auto-orthogonalized against a non-perpendicular normal
            e2 = APEllipse3(APPoint(0.0, 0.0, 0.0), 4.0, 2.0, APVector(1.0, 1.0, 1.0), APVector(1.0, -1.0, 0.0))
            @test dot(e2.u, e2.normal) ≈ 0.0 atol = 1e-12
            @test norm(e2.u) ≈ 1.0
            @test norm(e2.normal) ≈ 1.0
            p2 = point_on_ellipse3(e2, 1.3)
            @test is_on_ellipse3(p2, e2)
            @test on_plane(p2, plane(e2))

            # bifocal-through-point: no extra plane argument needed
            f1b, f2b = APPoint(-3.0, 0.0, 0.0), APPoint(3.0, 0.0, 0.0)
            pb = APPoint(0.0, 4.0, 0.0)
            eb = APEllipse3(f1b, f2b, pb)
            @test is_on_ellipse3(pb, eb)
            @test eb.a ≈ 5.0

            # bifocal + axis: explicit normal required (underdetermined otherwise)
            ec = APEllipse3(f1b, f2b, 5.0, APVector(0.0, 0.0, 1.0))
            @test ec.b ≈ 4.0
            @test_throws ArgumentError APEllipse3(f1b, f2b, 2.0, APVector(0.0, 0.0, 1.0)) # a <= c

            orth = orthoptic(e)
            @test orth isa APCircle3
            @test orth.r ≈ sqrt(5.0^2 + 3.0^2)

            axis = APLine(APPoint(0.0, 0.0, 0.0), APPoint(0.0, 0.0, 1.0))
            er = rotate(e, pi / 2, axis)
            @test area(er) ≈ area(e)
            @test is_on_ellipse3(rotate(p_on, pi / 2, axis), er)
            @test area(homothety(e, 2.0, APPoint(0.0, 0.0, 0.0))) ≈ area(e) * 4
        end

        @testset "APHyperbola3" begin
            h = APHyperbola3(APPoint(0.0, 0.0, 0.0), 3.0, 4.0, APVector(0.0, 0.0, 1.0), APVector(1.0, 0.0, 0.0))
            ph = point_on_hyperbola3(h, 0.5)
            @test is_on_hyperbola3(ph, h)
            f1h, f2h = foci(h)
            @test distance(f1h, h.center) ≈ sqrt(9.0 + 16.0)
            asym1, asym2 = asymptotes(h)
            @test on_line(h.center, asym1)
            @test on_line(h.center, asym2)

            # bifocal-through-point
            f1b, f2b = APPoint(-5.0, 0.0, 0.0), APPoint(5.0, 0.0, 0.0)
            pb = APPoint(3.0, 0.0, 0.0) # on the transverse axis itself, a=3
            hb = APHyperbola3(f1b, f2b, pb)
            @test hb.a ≈ 3.0
        end

        @testset "APParabola3" begin
            focus3 = APPoint(0.0, 1.0, 0.0)
            directrix3 = APLine(APPoint(-5.0, -1.0, 0.0), APPoint(5.0, -1.0, 0.0))
            par3 = APParabola3(focus3, directrix3)
            @test focal_parameter(par3) ≈ 2.0
            pp = point_on_parabola3(par3, 2.0)
            @test is_on_parabola3(pp, par3)
            @test orthoptic(par3) == directrix3
        end

        @testset "Arcs: measure/arc_length/reverse/point_on_arc/Base.in" begin
            circ = APCircle3(APPoint(0.0, 0.0, 0.0), 5.0, APVector(0.0, 0.0, 1.0))
            u0 = point_on_circle3(circ, 0.0)
            u90 = point_on_circle3(circ, pi / 2)
            arc = APCircularArc3(circ, u0, u90)
            @test measure(arc) ≈ pi / 2
            @test arc_length(arc) ≈ 5 * pi / 2
            @test midpoint(arc) in arc
            @test measure(reverse(arc)) ≈ 3pi / 2

            ell = APEllipse3(APPoint(0.0, 0.0, 0.0), 5.0, 3.0, APVector(0.0, 0.0, 1.0), APVector(1.0, 0.0, 0.0))
            p1e, p2e = point_on_ellipse3(ell, 0.2), point_on_ellipse3(ell, 2.0)
            earc = APEllipticArc3(ell, p1e, p2e)
            @test point_on_arc(earc, 0.0) ≈ p1e
            @test point_on_arc(earc, 1.0) ≈ p2e
            @test arc_length(earc) > distance(p1e, p2e)

            par = APParabola3(APPoint(0.0, 1.0, 0.0), APLine(APPoint(-5.0, -1.0, 0.0), APPoint(5.0, -1.0, 0.0)))
            parc = APParabolicArc3(par, point_on_parabola3(par, -3.0), point_on_parabola3(par, 3.0))
            @test arc_length(parc) > distance(parc.p1, parc.p2)

            hyp = APHyperbola3(APPoint(0.0, 0.0, 0.0), 3.0, 4.0, APVector(0.0, 0.0, 1.0), APVector(1.0, 0.0, 0.0))
            harc = APHyperbolicArc3(hyp, point_on_hyperbola3(hyp, -0.5), point_on_hyperbola3(hyp, 0.5))
            @test harc isa APHyperbolicArc3
            @test point_on_arc(harc, 0.0) ≈ harc.p1 atol = 1e-9
        end
    end

    @testset "Quadric surfaces" begin
        @testset "APEllipsoid3" begin
            e = APEllipsoid3(APPoint(0.0, 0.0, 0.0), 3.0, 4.0, 5.0, APVector(1.0, 0.0, 0.0), APVector(0.0, 1.0, 0.0))
            @test volume(e) ≈ (4 / 3) * pi * 60.0
            sph_like = APEllipsoid3(APPoint(0.0, 0.0, 0.0), 2.0, 2.0, 2.0, APVector(1.0, 0.0, 0.0), APVector(0.0, 1.0, 0.0))
            @test surface_area(sph_like) ≈ 4 * pi * 4.0 # a sphere is the one exact case for Thomsen's approximation
            p = point_on_ellipsoid3(e, 1.0, 0.5)
            @test is_on_ellipsoid3(p, e)

            axis = APLine(APPoint(0.0, 0.0, 0.0), APPoint(0.0, 0.0, 1.0))
            er = rotate(e, pi / 3, axis)
            @test volume(er) ≈ volume(e)
            @test is_on_ellipsoid3(rotate(p, pi / 3, axis), er)
        end

        @testset "APParaboloid3" begin
            par = APParaboloid3(APPoint(0.0, 0.0, 0.0), 2.0, 3.0, APVector(0.0, 0.0, 1.0), APVector(1.0, 0.0, 0.0))
            @test is_on_paraboloid3(par.vertex, par)
            @test is_on_paraboloid3(point_on_paraboloid3(par, 1.5, 0.8), par)
        end

        @testset "APHyperboloid3 (1 and 2 sheets)" begin
            h1 = APHyperboloid3(APPoint(0.0, 0.0, 0.0), 2.0, 3.0, 4.0, APVector(1.0, 0.0, 0.0), APVector(0.0, 1.0, 0.0); sheets=1)
            @test is_on_hyperboloid3(point_on_hyperboloid3(h1, 0.7, 1.2), h1)
            waist = point_on_hyperboloid3(h1, 0.0, 0.0)
            w = Apollonius.cross3(h1.u, h1.v)
            @test dot(waist - h1.center, w) ≈ 0.0 atol = 1e-12

            h2 = APHyperboloid3(APPoint(0.0, 0.0, 0.0), 2.0, 3.0, 4.0, APVector(1.0, 0.0, 0.0), APVector(0.0, 1.0, 0.0); sheets=2)
            pa = point_on_hyperboloid3(h2, 0.5, 0.3; branch=1)
            pb = point_on_hyperboloid3(h2, 0.5, 0.3; branch=-1)
            @test is_on_hyperboloid3(pa, h2)
            @test is_on_hyperboloid3(pb, h2)
            @test sign(dot(pa - h2.center, w)) != sign(dot(pb - h2.center, w)) # two disjoint sheets, opposite sides

            @test_throws ArgumentError APHyperboloid3(APPoint(0.0, 0.0, 0.0), 1.0, 1.0, 1.0, APVector(1.0, 0.0, 0.0), APVector(0.0, 1.0, 0.0); sheets=3)
        end

        @testset "APHyperbolicParaboloid3 (the saddle)" begin
            hp = APHyperbolicParaboloid3(APPoint(0.0, 0.0, 0.0), 2.0, 3.0, APVector(0.0, 0.0, 1.0), APVector(1.0, 0.0, 0.0))
            @test is_on_hyperbolic_paraboloid3(point_on_hyperbolic_paraboloid3(hp, 1.0, 1.0), hp)
            along_x = point_on_hyperbolic_paraboloid3(hp, 2.0, 0.0)
            along_y = point_on_hyperbolic_paraboloid3(hp, 0.0, 2.0)
            @test dot(along_x - hp.vertex, hp.axis) > 0 # opens up along x
            @test dot(along_y - hp.vertex, hp.axis) < 0 # opens down along y -- the saddle
        end
    end

    @testset "regular_tetrahedron3 / regular_octahedron3" begin
        t = regular_tetrahedron3(APPoint(0.0, 0.0, 0.0), 4.0)
        vs = vertices(t)
        edges = [distance(vs[i], vs[j]) for i in 1:4 for j in i+1:4]
        @test all(e -> isapprox(e, 4.0), edges)
        @test volume(t) ≈ 4.0^3 / (6 * sqrt(2))
        @test centroid(t) ≈ APPoint(0.0, 0.0, 0.0)

        o = regular_octahedron3(APPoint(1.0, 1.0, 1.0), 3.0)
        fs = collect(faces(o))
        @test length(fs) == 8
        areas = area.(fs)
        @test all(a -> isapprox(a, areas[1]), areas)
        @test volume(o) ≈ sqrt(2) / 3 * 27.0
        @test centroid(o) ≈ APPoint(1.0, 1.0, 1.0)
        @test surface_area(o) ≈ 8 * areas[1]

        axis = APLine(APPoint(1.0, 1.0, 1.0), APPoint(1.0, 1.0, 2.0))
        @test volume(rotate(o, pi / 5, axis)) ≈ volume(o)
        @test volume(homothety(o, 2.0, APPoint(1.0, 1.0, 1.0))) ≈ volume(o) * 8
    end

    @testset "3D curved regions (APCircularSector3/Segment3/AnnularSector3)" begin
        circ = APCircle3(APPoint(1.0, 1.0, 1.0), 5.0, APVector(1.0, 1.0, 1.0))
        u0 = point_on_circle3(circ, 0.0)
        u90 = point_on_circle3(circ, pi / 2)

        sec = APCircularSector3(circ, u0, u90)
        @test area(sec) ≈ 5.0^2 * (pi / 2) / 2
        @test perimeter(sec) ≈ 2 * 5.0 + 5.0 * (pi / 2)
        @test on_plane(centroid(sec), plane(circ))
        @test circ.center in sec
        @test !(APPoint(1000.0, 1000.0, 1000.0) in sec)

        seg = APCircularSegment3(circ, u0, u90)
        @test area(seg) ≈ 5.0^2 * (pi / 2 - sin(pi / 2)) / 2

        asec = APAnnularSector3(APCircularArc3(circ, u0, u90), 2.0)
        @test area(asec) ≈ 5.0^2 * (pi / 2) / 2 - 2.0^2 * (pi / 2) / 2
        @test_throws ArgumentError APAnnularSector3(APCircularArc3(circ, u0, u90), 10.0)

        axis = APLine(APPoint(1.0, 1.0, 1.0), APPoint(2.0, 1.0, 1.0))
        @test area(rotate(sec, pi / 3, axis)) ≈ area(sec)
        @test area(homothety(sec, 2.0, APPoint(1.0, 1.0, 1.0))) ≈ area(sec) * 4
    end
    end # if false (3D geometry, paused)

    @testset "APEquipollentVector" begin
        ev = APEquipollentVector(APVector(3.0, 4.0), APPoint(1.0, 2.0))
        @test tip(ev) ≈ APPoint(4.0, 6.0)
        @test direction(ev) == ev.vector
        @test !isempty(APBoundingBox(ev)) # unlike a bare APVector
        @test APBoundingBox(ev) == APBoundingBox(APPoint(1.0, 2.0), APPoint(4.0, 6.0))
        @test APEquipollentVector(APVector(3.0, 4.0)).point == APPoint(0.0, 0.0) # single-arg: applied at the origin

        # linear-algebra functions act on .vector; normalize keeps .point fixed
        @test norm(ev) ≈ 5.0
        @test normalize(ev).point == ev.point
        @test normalize(ev).vector ≈ APVector(0.6, 0.8)
        @test dot(ev, APVector(1.0, 0.0)) ≈ 3.0
        @test dot(APVector(1.0, 0.0), ev) ≈ 3.0
        @test dot(ev, APEquipollentVector(APVector(0.0, 1.0), APPoint(5.0, 5.0))) ≈ 4.0

        # arithmetic: point of application stays fixed, vectors add
        @test (ev + APVector(1.0, 1.0)).point == ev.point
        @test (ev + APVector(1.0, 1.0)).vector ≈ APVector(4.0, 5.0)
        @test APVector(1.0, 1.0) + ev == ev + APVector(1.0, 1.0)
        @test (ev - APVector(1.0, 1.0)).vector ≈ APVector(2.0, 3.0)

        # APPoint + APEquipollentVector: same as APPoint + ev.vector, ev.point ignored
        q = APPoint(10.0, 20.0)
        @test q + ev == q + ev.vector
        @test ev + q == q + ev
        @test q + ev ≈ APPoint(13.0, 24.0)

        # translate: point shifts, vector (a free direction) doesn't
        evt = translate(ev, APVector(10.0, 10.0))
        @test evt.point ≈ APPoint(11.0, 12.0)
        @test evt.vector == ev.vector

        # APVector(ev): unwraps back to the bare, positionless vector
        @test APVector(ev) == ev.vector
        @test APVector(ev) === ev.vector

        # translate(obj, ev): any object can be translated by an
        # APEquipollentVector's own displacement, ignoring its point
        w = APEquipollentVector(APVector(3.0, 4.0), APPoint(100.0, 100.0))
        p = APPoint(1.0, 2.0)
        @test translate(p, w) ≈ APPoint(4.0, 6.0)
        s = APSegment(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
        @test translate(s, w) == APSegment(APPoint(3.0, 4.0), APPoint(4.0, 4.0))
        # translating one APEquipollentVector by another still goes through
        # the more specific translate(::APEquipollentVector, ::APVector)
        evw = translate(ev, w)
        @test evw.point ≈ APPoint(4.0, 6.0)
        @test evw.vector == ev.vector

        # rotate: both point and vector rotate
        evr = rotate(ev, pi / 2, APPoint(0.0, 0.0))
        @test evr.point ≈ APPoint(-2.0, 1.0)
        @test evr.vector ≈ APVector(-4.0, 3.0)

        # homothety: point scales about center, vector scales by literal k
        # (not abs(k)) -- a bare APVector also scales correctly on its own
        # now (see its own homothety method), but only APEquipollentVector
        # additionally moves the point of application as ONE unit alongside it
        evh = homothety(ev, 2.0, APPoint(0.0, 0.0))
        @test evh.point ≈ APPoint(2.0, 4.0)
        @test evh.vector ≈ APVector(6.0, 8.0)
        evhneg = homothety(ev, -1.0, APPoint(0.0, 0.0))
        @test evhneg.point ≈ APPoint(-1.0, -2.0)
        @test evhneg.vector ≈ APVector(-3.0, -4.0) # direction flips too, matching the point reflection

        # reflection
        refl_pt = reflection(ev, APPoint(0.0, 0.0))
        @test refl_pt.point ≈ APPoint(-1.0, -2.0)
        @test refl_pt.vector ≈ APVector(-3.0, -4.0)
        refl_line = reflection(ev, APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0)))
        @test refl_line.point ≈ APPoint(1.0, -2.0)
        @test refl_line.vector ≈ APVector(3.0, -4.0)

        # 3D
        ev3d = APEquipollentVector(APVector(1.0, 0.0, 0.0), APPoint(1.0, 2.0, 3.0))
        axis = APLine(APPoint(0.0, 0.0, 0.0), APPoint(0.0, 0.0, 1.0))
        ev3dr = rotate(ev3d, pi / 2, axis)
        @test ev3dr.point ≈ APPoint(-2.0, 1.0, 3.0) atol = 1e-12
        @test ev3dr.vector ≈ APVector(0.0, 1.0, 0.0) atol = 1e-12
        ev3dh = homothety(ev3d, 3.0, APPoint(0.0, 0.0, 0.0))
        @test ev3dh.point ≈ APPoint(3.0, 6.0, 9.0)
        @test ev3dh.vector ≈ APVector(3.0, 0.0, 0.0)

        # it correctly scales inside @to_luxor_picture as ONE self-contained
        # unit, with a real bounding box of its own to size the canvas by --
        # a bare APVector still contributes nothing to that sizing (see the
        # "bare APVector" test in the @to_luxor_picture testset for what it
        # *does* get: scaled/flipped, just not sized-by or shifted). Only
        # ONE name is bound inside the block here on purpose, so the macro
        # returns the placed value directly rather than a tuple of every
        # named shape.
        raw = APEquipollentVector(direction(APLine(APPoint(3.0, 4.0), APPoint(0.0, 0.0))), APPoint(0.0, 0.0))
        sz, ev_placed = @to_luxor_picture width=500 height=240 margin=20 begin
            evp = raw
        end
        @test norm(ev_placed.vector) > norm(raw.vector) # got scaled up to fit the canvas
    end

    @testset "Luxor extension" begin
        # `path` has no methods at all until Luxor is loaded too — the
        # extension mechanism is what keeps Apollonius itself
        # Luxor-free. This must stay the last testset in the file: once
        # `using Luxor` runs (below), this check is no longer meaningful.
        @test isempty(methods(path))

        using Luxor

        @test Base.get_extension(Apollonius, :ApolloniusLuxorExt) !== nothing
        @test !isempty(methods(path))

        mktempdir() do dir
            Luxor.Drawing(200, 200, joinpath(dir, "test.png"))
            Luxor.origin()

            t = APTriangle(APPoint(-80.0, 60.0), APPoint(80.0, 60.0), APPoint(-20.0, -80.0))
            ang = APAngle2(t[1], t[2], t[3])
            # each of these should run without error inside an active Drawing,
            # combining path-building with Luxor's own color/action vocabulary
            Luxor.sethue("red")
            path(t; action=:stroke)
            path(circumcircle(t); action=:stroke)
            path(incenter(t); action=:fill)
            path(APSegment(APPoint(0.0, 0.0), APPoint(50.0, 50.0)); action=:stroke)
            path(APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)); action=:stroke)
            path(APRay(APPoint(0.0, 0.0), APPoint(1.0, 1.0)); action=:stroke)
            # `APBoundingBox` is ambiguous once Luxor is loaded too (Luxor has
            # its own type of the same name) — qualify it, exactly as a
            # real caller of both packages together would have to
            path(Apollonius.APBoundingBox(t); action=:stroke)
            path(APEllipse2(APPoint(0.0, 0.0), 40.0, 20.0, pi / 6); action=:stroke)
            path(APParabola2(APPoint(0.0, 20.0), APLine(APPoint(-50.0, -20.0), APPoint(50.0, -20.0))); action=:stroke)
            path(APHyperbola2(APPoint(0.0, 0.0), 20.0, 10.0); action=:stroke)
            path(ang; as=:rays, action=:stroke)
            path(ang; as=:arc, action=:stroke)
            path(ang; as=:sector, action=:fill)
            path(ang; as=:rarc, action=:stroke)
            path(ang; as=:rsector, action=:fill)
            @test_throws ArgumentError path(ang; as=:bogus)

            arc = APCircularArc2(Apollonius.APCircle2(APPoint(0.0, 0.0), 30.0), APPoint(30.0, 0.0), APPoint(0.0, 30.0))
            path(arc; action=:stroke)
            path(APCircularSector2(arc); action=:fill)
            path(APCircularSegment2(arc); action=:fill)

            c1 = Apollonius.APCircle2(APPoint(0.0, 0.0), 40.0)
            c2 = Apollonius.APCircle2(APPoint(90.0, 0.0), 50.0)
            locus1 = Apollonius.APCircle2(c1.center, c1.r + 35.0)
            locus2 = Apollonius.APCircle2(c2.center, c2.r + 35.0)
            c3 = Apollonius.APCircle2(intersection(locus1, locus2)[1], 35.0)
            sethue("green")
            path(only(interstices(c1, c2, c3)); action=:fill)

            sethue("purple")
            path(invert(t, APPoint(0.0, 0.0)); action=:fill)

            # default action=:path only builds the path; caller drives rendering
            Luxor.sethue("blue")
            path(t)
            Luxor.strokepath()

            # standalone path() for the 3 conic-arc types with no native Cairo
            # primitive (sampled polyline, like APParabola2/APHyperbola2 above)
            e2 = APEllipse2(APPoint(0.0, 0.0), 40.0, 20.0, pi / 6)
            earc = APEllipticArc2(e2, point_on_ellipse(e2, 0.2), point_on_ellipse(e2, 2.0))
            path(earc; action=:stroke)
            par2 = APParabola2(APPoint(0.0, 20.0), APLine(APPoint(-50.0, -20.0), APPoint(50.0, -20.0)))
            parc = APParabolicArc2(par2, point_on_parabola(par2, -30.0), point_on_parabola(par2, 30.0))
            path(parc; action=:stroke)
            hyp2 = APHyperbola2(APPoint(0.0, 0.0), 20.0, 10.0)
            hyparc = APHyperbolicArc2(hyp2, point_on_hyperbola(hyp2, -0.5; branch=1), point_on_hyperbola(hyp2, 0.5; branch=1))
            path(hyparc; action=:stroke)

            # regression: a curvilinear region whose side is one of those 3
            # arc types (only reachable via APAffineMap on a circular-arc
            # region) used to throw a MethodError inside path(::APPolygon)
            apex = APPoint(-60.0, -60.0)
            curv_tri = APCurvilinearTriangle2(APSegment(earc.p2, apex), APSegment(apex, earc.p1), earc)
            path(curv_tri; action=:stroke)

            # as=:arrow (the one path() case that draws immediately, since
            # Luxor's own `arrow` has no deferred form)
            path(APSegment(APPoint(0.0, 0.0), APPoint(50.0, 30.0)); as=:arrow)
            path(APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)); extend=0.0, as=:arrow)
            path(APRay(APPoint(0.0, 0.0), APPoint(1.0, 1.0)); extend=0.0, as=:arrow, arrowheadlength=15)

            # APVector has no position, so path() takes an optional anchor
            # point (defaulting to the origin); APHalfPlane2/APStrip2 are
            # unbounded, so path() draws their boundary line(s) only
            path(APVector(1.0, 1.0); action=:stroke)
            path(APVector(1.0, 1.0), APPoint(10.0, 10.0); action=:stroke)
            path(APVector(1.0, 1.0), APPoint(10.0, 10.0); as=:arrow)
            path(APHalfPlane2(APLine(APPoint(0.0, 0.0), APPoint(0.0, 1.0)), APPoint(1.0, 0.0)); action=:stroke)
            path(APStrip2(APLine(APPoint(-20.0, 0.0), APPoint(-20.0, 1.0)), APLine(APPoint(20.0, 0.0), APPoint(20.0, 1.0))); action=:stroke)

            # Luxor's own label() accepts an APPoint directly (converted via
            # _lp), for both the alignment-Symbol and direction-angle forms
            Luxor.label("I", :N, incenter(t))
            Luxor.label("O", pi / 4, circumcenter(t); offset=10)

            # path() on a Vector{<:APObject}: each element gets its own
            # path+action, same as broadcasting `path.(v; ...)` by hand --
            # this is what lets intersection's result (always a Vector, even
            # for a single point) get drawn directly
            path([APPoint(0.0, 0.0), APPoint(10.0, 10.0)]; action=:fill)
            path(intersection(APLine(APPoint(-50.0, 0.0), APPoint(50.0, 0.0)), circumcircle(t)); action=:fill)
            path(APPoint{2,Float64}[]; action=:fill)   # empty vector: no-op, no error

            # path() also accepts any AbstractArray shape, not just a Vector
            # -- a Tuple (e.g. vertices(::APTriangle), which isn't a Vector)
            path(vertices(t); action=:fill)
            # ...and a Matrix (e.g. hcat-ing two tangent-line pairs together,
            # which previously had no path() method at all)
            c_ta, c_tb = APCircle2(APPoint(0.0, 0.0), 20.0), APCircle2(APPoint(90.0, 0.0), 30.0)
            ext_ta = external_tangent_lines(c_ta, c_tb)
            int_ta = internal_tangent_lines(c_ta, c_tb)
            path([ext_ta int_ta]; action=:stroke)

            Luxor.finish()
            @test isfile(joinpath(dir, "test.png"))
        end

        @testset "as=:arrow inherits the active setline() width" begin
            # Luxor's own `arrow` ignores setline() entirely and defaults
            # to linewidth=1.0 (documented behavior of Luxor.arrow) -- our
            # `_arrow` helper instead inherits the currently active width,
            # so `as=:plain`/`action=:stroke` and `as=:arrow` come out the
            # same thickness by default, and an explicit `linewidth=`
            # still overrides it exactly as passing it to Luxor.arrow would.
            mktempdir() do dir
                fn = joinpath(dir, "arrow_linewidth.svg")
                Luxor.Drawing(100, 100, fn)
                Luxor.origin()
                setline(6)
                path(APSegment(APPoint(0.0, 0.0), APPoint(10.0, 0.0)); action=:stroke)
                path(APSegment(APPoint(0.0, 20.0), APPoint(10.0, 20.0)); as=:arrow)
                path(APSegment(APPoint(0.0, 40.0), APPoint(10.0, 40.0)); as=:arrow, linewidth=2)
                Luxor.finish()
                svg = read(fn, String)
                widths = [parse(Float64, m.captures[1]) for m in eachmatch(r"stroke-width=\"([0-9.]+)\"", svg)]
                @test count(==(6.0), widths) == 2   # plain stroke + default arrow, both at setline(6)
                @test count(==(2.0), widths) == 1   # explicit override
            end
        end

        @testset "path(::Vector) batches into one path without a stray connecting line" begin
            # Cairo's circle/arc primitives connect to wherever the current
            # path left off with a straight line unless a fresh subpath is
            # started first -- path(::AbstractVector) calls Luxor.newsubpath()
            # before each element specifically to avoid that, so several
            # circles/points can share one fillpreserve()+strokepath() (e.g.
            # to fill them one color and outline them another) without a
            # spurious line fanning out between them.
            pts = [APPoint(-50.0, -50.0), APPoint(50.0, 50.0), APPoint(-50.0, 50.0)]
            mktempdir() do dir
                fn = joinpath(dir, "t.svg")
                Luxor.Drawing(200, 200, fn)
                Luxor.origin()
                path(pts; action=:path)
                Luxor.sethue("white")
                Luxor.fillpreserve()
                Luxor.sethue("blue")
                Luxor.strokepath()
                Luxor.finish()
                svg = read(fn, String)
                @test occursin("<path ", svg)
                @test !occursin(" L ", svg)   # no line segment -- only M (move) and C (curve) commands
            end
        end

        @testset "path(::APAngle2) as=:rarc/:rsector -- the parallelogram-law angle marker" begin
            # at exactly 90 degrees, pa/pc/pb form the familiar square corner
            # marker (pa/pb are `radius` from the vertex along each ray; pc =
            # pa + pb - vertex completes the parallelogram/square)
            ang90 = APAngle2(APPoint(0.0, 0.0), APPoint(50.0, 0.0), APPoint(0.0, 50.0))
            mktempdir() do dir
                Luxor.Drawing(200, 200, joinpath(dir, "rarc.png"))
                Luxor.origin()
                path(ang90; as=:rarc, radius=20.0, action=:path)
                @test current_path_bbox() ≈ Apollonius.APBoundingBox(APPoint(0.0, 0.0), APPoint(20.0, 20.0))
                Luxor.strokepath()

                path(ang90; as=:rsector, radius=20.0, action=:path)
                @test current_path_bbox() ≈ Apollonius.APBoundingBox(APPoint(0.0, 0.0), APPoint(20.0, 20.0))
                Luxor.finish()
            end

            # a non-right angle still traces a rhombus (pa/pb both `radius`
            # from the vertex), not a right-angle square, but the same
            # parallelogram-law construction
            ang60 = APAngle2(APPoint(0.0, 0.0), APPoint(50.0, 0.0), Apollonius.rotate(APPoint(50.0, 0.0), pi / 3))
            vertex, a, b = ang60.vertex, ang60.a, ang60.b
            r = 15.0
            pa = vertex + r * (a - vertex) / norm(a - vertex)
            pb = vertex + r * (b - vertex) / norm(b - vertex)
            pc = pa + (pb - vertex)
            @test Apollonius.distance(pa, pc) ≈ r && Apollonius.distance(pb, pc) ≈ r   # rhombus: all 4 sides equal
            @test !is_perpendicular(APLine(vertex, pa), APLine(vertex, pb))   # not a right angle
            mktempdir() do dir
                Luxor.Drawing(200, 200, joinpath(dir, "rarc60.png"))
                Luxor.origin()
                path(ang60; as=:rarc, radius=r, action=:path)
                # atol here (rather than the default isapprox tolerance):
                # Cairo's internal fixed-point path representation rounds
                # coordinates slightly, and pa/pb/pc themselves involve
                # sin/cos(pi/3), so a couple thousandths of a unit of slack
                # is expected, not a sign of a real geometry bug
                @test current_path_bbox() ≈ Apollonius.APBoundingBox([pa, pc, pb]) atol = 1e-2
                Luxor.finish()
            end
        end

        @testset "path(::APLine) with a 2-tuple extend" begin
            l = APLine(APPoint(0.0, 0.0), APPoint(10.0, 0.0))
            mktempdir() do dir
                Luxor.Drawing(200, 200, joinpath(dir, "extend.png"))
                Luxor.origin()

                # extend=(0.0, 5.0): nothing added past p1, 5 units past p2
                path(l; extend=(0.0, 5.0), action=:path)
                @test current_path_bbox() ≈ Apollonius.APBoundingBox(APPoint(0.0, 0.0), APPoint(15.0, 0.0))
                Luxor.strokepath()

                # a bare number is still short for extending both ends equally
                path(l; extend=5.0, action=:path)
                @test current_path_bbox() ≈ Apollonius.APBoundingBox(APPoint(-5.0, 0.0), APPoint(15.0, 0.0))
                Luxor.strokepath()

                Luxor.finish()
            end
        end

        @testset "current_path_bbox and @to_luxor_picture together" begin
            t = APTriangle(APPoint(2.0, -5.0), APPoint(9.0, 3.0), APPoint(-1.0, 6.0))
            circ = Apollonius.APCircle2(APPoint(4.0, 1.0), 4.0)

            (w, h), (t2, c2) = @to_luxor_picture width = 300.0 margin = 10.0 begin
                t
                circ
            end

            mktempdir() do dir
                Luxor.Drawing(w, h, joinpath(dir, "picture.png"))
                Luxor.origin()
                path(t2; action=:path)
                path(c2; action=:path)

                # matches the analytic AP-side bbox exactly (both types have
                # native Cairo primitives here, so no sampling error)
                expected = bbox_union(Apollonius.APBoundingBox(t2), Apollonius.APBoundingBox(c2))
                @test current_path_bbox() ≈ expected

                Luxor.strokepath()
                # the path is consumed by the stroke action, same as Luxor's
                # own shape functions
                @test current_path_bbox() == Apollonius.APBoundingBox(APPoint(0.0, 0.0), APPoint(0.0, 0.0))

                Luxor.finish()
            end
        end
    end

end
