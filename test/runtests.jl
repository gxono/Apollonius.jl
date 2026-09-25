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
            pmix = APPoint(1, 2.0)
            @test pmix isa APPoint{2,Float64}
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
        @test direction(s) isa APVector
        @test s[1] == p1 && s[2] == p2
        @test collect(s) == [p1, p2]
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
            far1 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
            far2 = APLine(APPoint(1000.0, 1000.0), APPoint(1005.0, 1005.0))
            @test isapprox(far1, far2)
            @test isapprox(far1, APLine(APPoint(1.0, 1.0), APPoint(0.0, 0.0)))
            @test !isapprox(far1, APLine(APPoint(0.0, 1.0), APPoint(1.0, 2.0)))
            @test !isapprox(far1, APLine(APPoint(0.0, 1.0), APPoint(1.0, 0.0)))
        end
        @testset "isapprox: APRay (same origin AND same direction, not just parallel)" begin
            base = APRay(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
            @test isapprox(base, APRay(APPoint(0.0, 0.0), APPoint(2.0, 2.0)))
            @test !isapprox(base, APRay(APPoint(0.0, 0.0), APPoint(-1.0, -1.0)))
            @test !isapprox(base, APRay(APPoint(1.0, 0.0), APPoint(2.0, 1.0)))
        end
        @testset "projection, distance to a line, reflection" begin
            off = APPoint(2.0, 3.0)
            @test projection(off, l) == APPoint(2.0, 0.0)
            @test distance(off, l) == 3.0
            @test distance(l, off) == distance(off, l)
            @test reflection(off, l) == APPoint(2.0, -3.0)
            @test projection(off, l; angle=pi / 2) == projection(off, l)
            @test isapprox(projection(off, l; angle=pi / 4), APPoint(-1.0, 0.0); atol=1e-9)
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
            p = APPoint(3.0, -2.0)
            @test APBoundingBox(p) == APBoundingBox(p, p)
            @test bbox_width(APBoundingBox(p)) == 0.0 && bbox_height(APBoundingBox(p)) == 0.0
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
            @test !isempty(APBoundingBox(APCircle2(APPoint(0.0, 0.0), 1.0)))
            bb = APBoundingBox(APPoint(1.0, 2.0), APPoint(4.0, 6.0))
            empty1, empty2 = APBoundingBox(5), APBoundingBox(APVector(0.0, 0.0))
            @test bbox_union(empty1, bb) == bb
            @test bbox_union(bb, empty1) == bb
            @test isempty(bbox_union(empty1, empty2))
            l1 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
            l2 = APLine(APPoint(5.0, 5.0), APPoint(6.0, 6.0))
            @test isempty(APBoundingBox([l1, l2]))
            mixed = [l1, APCircle2(APPoint(0.0, 0.0), 2.0)]
            @test APBoundingBox(mixed) == APBoundingBox(mixed[2])
            @test isempty(APBoundingBox(APLine{2,Float64}[]))
            @test_throws ArgumentError APBoundingBox(APPoint{2,Float64}[])
            pts_matrix = [APPoint(0.0, 0.0) APPoint(1.0, 0.0); APPoint(0.0, 1.0) APPoint(1.0, 1.0)]
            @test APBoundingBox(pts_matrix) == APBoundingBox(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
            @test APBoundingBox((APPoint(0.0, 0.0), APPoint(2.0, 3.0))) ==
                  APBoundingBox(APPoint(0.0, 0.0), APPoint(2.0, 3.0))
            named = (A=APPoint(-1.0, 0.0), B=APPoint(1.0, 4.0))
            @test APBoundingBox(named) == APBoundingBox(APPoint(-1.0, 0.0), APPoint(1.0, 4.0))
            @test isempty(APBoundingBox((A=1.0, B=2.0, C=3.0)))
        end
        @testset "3D construction works (forward-compat check)" begin
            s3 = APSegment(APPoint(0.0, 0.0, 0.0), APPoint(1.0, 2.0, 2.0))
            @test distance(s3) == 3.0
        end
        @testset "every APObject/APTransform broadcasts as a scalar" begin
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
            v = APVector(1.0, -2.0)
            pts = [APPoint(0.0, 0.0), APPoint(3.0, 4.0)]
            @test translate(pts, v) == translate.(pts, v)
            @test rotate(pts, pi / 2) == rotate.(pts, pi / 2)
            @test homothety(pts, 2.0) == homothety.(pts, 2.0)
            @test reflection(pts, APPoint(1.0, 1.0)) == reflection.(pts, APPoint(1.0, 1.0))
            center = APPoint(0.0, 0.0)
            lines = [APLine(APPoint(2.0, 0.0), APPoint(2.0, 1.0)), APLine(APPoint(3.0, 0.0), APPoint(3.0, 1.0))]
            @test translate(lines, v) == translate.(lines, v)
            @test invert(lines, center; k=2.0) == invert.(lines, center; k=2.0)
            @test invert_neg(lines, center; k=2.0) == invert_neg.(lines, center; k=2.0)
            @test translate(APPoint[], v) == APPoint[]
        end
        @testset "translate/rotate/homothety/reflection/invert/invert_neg on a Tuple of shapes" begin
            t = APTriangle(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 3.0))
            pts = vertices(t)
            @test pts isa Tuple
            v = APVector(1.0, -2.0)
            @test translate(pts, v) == translate.(pts, v)
            @test rotate(pts, pi / 2) == rotate.(pts, pi / 2)
            @test homothety(pts, 2.0) == homothety.(pts, 2.0)
            @test reflection(pts, APPoint(1.0, 1.0)) == reflection.(pts, APPoint(1.0, 1.0))
            lines = (APLine(APPoint(2.0, 0.0), APPoint(2.0, 1.0)), APLine(APPoint(3.0, 0.0), APPoint(3.0, 1.0)))
            center = APPoint(-1.0, -1.0)
            @test invert(lines, center; k=2.0) == invert.(lines, center; k=2.0)
            @test invert_neg(lines, center; k=2.0) == invert_neg.(lines, center; k=2.0)
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
            @test centroid(q) ≈ a + ((b - a) + (c - a) + (d - a)) / 4
            @test area(q) ≈ 10.5
            @test perimeter(q) ≈ distance(a, b) + distance(b, c) + distance(c, d) + distance(d, a)
            @test is_convex(q)
            @test APPoint(2.0, 1.5) in q
            @test !(APPoint(10.0, 10.0) in q)
            bb = APBoundingBox(q)
            @test bb.min == APPoint(0.0, 0.0) && bb.max == APPoint(4.0, 3.0)
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
            @test square == APStraightNgon(APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(2.0, 2.0), APPoint(0.0, 2.0))
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
            c2 = APCircle2(APPoint(1.0, 2.0), APPoint(4.0, 6.0))
            @test c2 == APCircle2(APPoint(1.0, 2.0), 5.0)
            p1, p2, p3 = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 3.0)
            c3 = APCircle2(p1, p2, p3)
            @test c3 ≈ circumcircle(APTriangle(p1, p2, p3))
            @test_throws ArgumentError APCircle2(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(2.0, 0.0))
            @test antipode(APPoint(6.0, 2.0), c) == APPoint(-4.0, 2.0)   # opposite end of the diameter through (6,2)
            @test midpoint(APPoint(6.0, 2.0), antipode(APPoint(6.0, 2.0), c)) == c.center
        end
        @testset "APEllipse2" begin
            e = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0, 0.4)
            for t in (0.0, 0.7, 2.1, 4.4)
                @test is_on_ellipse(point_on(e, t), e; atol=1e-9)
            end
            @test area(e) ≈ pi * 5 * 3
            f1, f2 = foci(e)
            p = point_on(e, 0.4)
            @test distance(p, f1) + distance(p, f2) ≈ 2 * e.a atol = 1e-9
            v1, v2 = vertices(e)
            @test is_on_ellipse(v1, e; atol=1e-9) && is_on_ellipse(v2, e; atol=1e-9)
            @test distance(v1, v2) ≈ 2 * max(e.a, e.b) atol = 1e-9
            e_swapped = APEllipse2(APPoint(0.0, 0.0), 3.0, 5.0)   # a < b: vertices still on the LONGER axis
            @test distance(e_swapped.center, vertices(e_swapped)[1]) ≈ 5.0 atol = 1e-9
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
                @test is_on_hyperbola(point_on(h, t; branch=branch), h; atol=1e-9)
            end
            a1, a2 = asymptotes(h)
            @test distance(h.center, a1) < 1e-9 && distance(h.center, a2) < 1e-9
            v1, v2 = vertices(h)
            @test is_on_hyperbola(v1, h; atol=1e-9) && is_on_hyperbola(v2, h; atol=1e-9)
            @test distance(h.center, v1) ≈ h.a atol = 1e-9
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
            @test vertices(par) == (v,)
            @test focal_parameter(par) == 2.0
            @test is_on_parabola(v, par)
            p = point_on(par, 3.0)
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
            @test point_on(arc, 0.0) ≈ p1
            @test point_on(arc, 1.0) ≈ p2
            off_circle_p2 = circ.center + APVector(0.0, 3.0)
            off_arc = APCircularArc2(circ, p1, off_circle_p2)
            @test off_arc.p2 ≈ p2
            @test distance(circ.center, off_arc.p2) ≈ circ.r
            off_sec = APCircularSector2(off_arc)
            sds = sides(off_sec)
            @test distance(sds[3].p1, sds[3].p2) ≈ circ.r
            about_pt = APPoint(3.0, -1.0)
            refl_pt = reflection(arc, about_pt)
            @test measure(refl_pt) ≈ measure(arc) atol = 1e-9
            about_line = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
            refl_line = reflection(arc, about_line)
            @test measure(refl_line) ≈ measure(arc) atol = 1e-9
            @testset "APCircularArc2(center, p1, p2; ccw)" begin
                from_center = APCircularArc2(circ.center, p1, p2)
                @test from_center == arc   # radius = distance(center, p1), same as circ.r here
                cw = APCircularArc2(circ.center, p1, p2; ccw=false)
                @test cw == APCircularArc2(circ, p2, p1)
                @test measure(cw) ≈ 2pi - measure(arc) atol = 1e-9
                far_p2 = circ.center + APVector(0.0, 30.0)   # same angle as p2, far outside circ.r
                @test APCircularArc2(circ.center, p1, far_p2) == arc
            end
            @testset "APCircularArc2(center, r, p1, p2; ccw)" begin
                from_center_r = APCircularArc2(circ.center, circ.r, p1, p2)
                @test from_center_r == arc
                @test APCircularArc2(circ.center, p1, p2) == APCircularArc2(circ.center, distance(circ.center, p1), p1, p2)
                cw = APCircularArc2(circ.center, circ.r, p1, p2; ccw=false)
                @test cw == APCircularArc2(circ, p2, p1)
                bigger = APCircularArc2(circ.center, 2 * circ.r, p1, p2)   # p1/p2 projected onto the r=2*circ.r circle
                @test distance(circ.center, bigger.p1) ≈ 2 * circ.r
                @test bigger.p1 ≈ circ.center + 2 * (p1 - circ.center)
            end
            @testset "arc_with_measure / arc_with_length" begin
                ctr, start = APPoint(1.0, 2.0), APPoint(4.0, 2.0)
                ccw = arc_with_measure(ctr, start, pi / 3)
                @test ccw isa APCircularArc2
                @test ccw.p1 ≈ start && measure(ccw) ≈ pi / 3 && ccw.circle.r ≈ 3.0
                cw = arc_with_measure(ctr, start, -pi / 3)
                @test cw.p2 ≈ start && measure(cw) ≈ pi / 3
                by_len = arc_with_length(ctr, start, pi)
                @test by_len ≈ arc_with_measure(ctr, start, pi / 3)
                @test arc_length(by_len) ≈ pi atol = 1e-9
                @test arc_with_length(ctr, start, -pi) ≈ cw
                @test_throws ArgumentError arc_with_measure(ctr, start, 0.0)
                @test_throws ArgumentError arc_with_measure(ctr, start, 2pi)
                @test_throws ArgumentError arc_with_measure(ctr, ctr, 1.0)
                @test_throws ArgumentError arc_with_length(ctr, ctr, 1.0)
            end
        end
        @testset "APEllipticArc2 (new)" begin
            e2 = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0, 0.2)
            pa = point_on(e2, 0.3)
            pb = point_on(e2, 1.7)
            earc = APEllipticArc2(e2, pa, pb)
            @test isapprox(point_on(earc, 0.0), pa; atol=1e-6)
            @test isapprox(point_on(earc, 1.0), pb; atol=1e-6)
            for t in (0.0, 0.3, 0.6, 1.0)
                @test is_on_ellipse(point_on(earc, t), e2; atol=1e-6)
            end
            about_pt = APPoint(1.0, 1.0)
            refl_pt = reflection(earc, about_pt)
            @test measure(refl_pt) ≈ measure(earc) atol = 1e-6
            line_eg = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
            refl_l = reflection(earc, line_eg)
            @test measure(refl_l) ≈ measure(earc) atol = 1e-6
            for t in (0.0, 0.25, 0.5, 0.75, 1.0)
                expected = reflection(point_on(earc, 1 - t), line_eg)
                @test isapprox(point_on(refl_l, t), expected; atol=1e-6)
            end
            rev = reverse(earc)
            @test rev == APEllipticArc2(e2, pb, pa)
            @test reverse(rev) == earc
            @test APEllipticArc2(APPoint(0.0, 0.0), 5.0, 3.0, pa, pb; angle=0.2) == earc
        end
        @testset "APParabolicArc2 (new)" begin
            par = APParabola2(APPoint(0.0, 1.0), APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0)))
            pa = point_on(par, -2.0)
            pb = point_on(par, 3.0)
            parc = APParabolicArc2(par, pa, pb)
            @test isapprox(point_on(parc, 0.0), pa; atol=1e-6)
            @test isapprox(point_on(parc, 1.0), pb; atol=1e-6)
            about_l = APLine(APPoint(0.0, 0.0), APPoint(1.0, 2.0))
            refl = reflection(parc, about_l)
            for t in (0.0, 0.3, 0.6, 1.0)
                expected = reflection(point_on(parc, t), about_l)
                @test isapprox(point_on(refl, t), expected; atol=1e-6)
            end
            rev = reverse(parc)
            @test rev == APParabolicArc2(par, pb, pa)
            @test isapprox(point_on(rev, 0.0), pb; atol=1e-6)
            @test isapprox(point_on(rev, 1.0), pa; atol=1e-6)
            @test reverse(rev) == parc
            @test APParabolicArc2(APPoint(0.0, 1.0), APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0)), pa, pb) == parc
        end
        @testset "APHyperbolicArc2 (new)" begin
            h = APHyperbola2(APPoint(0.0, 0.0), 2.0, 1.0, 0.1)
            pa = point_on(h, 0.2; branch=1)
            pb = point_on(h, 1.5; branch=1)
            harc = APHyperbolicArc2(h, pa, pb)
            @test isapprox(point_on(harc, 0.0), pa; atol=1e-6)
            @test isapprox(point_on(harc, 1.0), pb; atol=1e-6)
            about_l = APLine(APPoint(0.0, 0.0), APPoint(1.0, 2.0))
            refl = reflection(harc, about_l)
            for t in (0.0, 0.3, 0.6, 1.0)
                expected = reflection(point_on(harc, t), about_l)
                @test isapprox(point_on(refl, t), expected; atol=1e-6)
            end
            rev = reverse(harc)
            @test rev == APHyperbolicArc2(h, pb, pa)
            @test reverse(rev) == harc
            @test APHyperbolicArc2(APPoint(0.0, 0.0), 2.0, 1.0, pa, pb; angle=0.1) == harc
        end
    end
    @testset "tangent_at / marks" begin
        fd(arc, t) = (d = point_on(arc, t + 1e-6) - point_on(arc, t - 1e-6); d / norm(d))
        @testset "tangent_at on lines" begin
            s = APSegment(APPoint(1.0, 1.0), APPoint(1.0, 5.0))
            f = tangent_at(s, 0.25)
            @test f.point ≈ APPoint(1.0, 2.0) && f.vector ≈ APVector(0.0, 1.0)
            @test tangent_at(APLine(APPoint(0.0, 0.0), APPoint(3.0, 0.0)), 2.0).point ≈ APPoint(6.0, 0.0)
            @test tangent_at(APRay(APPoint(1.0, 0.0), APPoint(1.0, 2.0)), 0.5).vector ≈ APVector(0.0, 1.0)
            @test_throws ArgumentError tangent_at(APSegment(APPoint(1.0, 1.0), APPoint(1.0, 1.0)), 0.5)
        end
        @testset "tangent_at on every arc type, against finite differences (both directions)" begin
            c = APCircle2(APPoint(1.0, 2.0), 3.0)
            e = APEllipse2(APPoint(1.0, -1.0), 5.0, 2.0, 0.6)
            par = APParabola2(APPoint(0.0, 1.0), APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0)))
            h = APHyperbola2(APPoint(0.0, 0.0), 2.0, 1.0, 0.3)
            arcs = [APCircularArc2(c, APPoint(4.0, 2.0), APPoint(1.0, 5.0)),
                APCircularArc2(c, APPoint(1.0, 5.0), APPoint(4.0, 2.0)),
                APEllipticArc2(e, point_on(e, 0.3), point_on(e, 2.0)),
                APEllipticArc2(e, point_on(e, 4.0), point_on(e, 1.0)),
                APParabolicArc2(par, point_on(par, -2.0), point_on(par, 3.0)),
                APParabolicArc2(par, point_on(par, 3.0), point_on(par, -2.0)),
                APHyperbolicArc2(h, point_on(h, -0.5), point_on(h, 1.0)),
                APHyperbolicArc2(h, point_on(h, 1.0), point_on(h, -0.5)),
                APHyperbolicArc2(h, point_on(h, -0.5; branch=-1), point_on(h, 1.0; branch=-1))]
            for a in arcs, t in (0.0, 0.3, 0.5, 1.0)
                f = tangent_at(a, t)
                @test f.point ≈ point_on(a, t) atol = 1e-9
                @test norm(f.vector) ≈ 1.0 atol = 1e-12
                @test isapprox(f.vector, fd(a, t); atol=1e-5)
            end
        end
        @testset "marks" begin
            s = APSegment(APPoint(0.0, 0.0), APPoint(10.0, 0.0))
            tick = only(marks(s))
            @test tick isa APSegment && tick ≈ APSegment(APPoint(5.0, -3.0), APPoint(5.0, 3.0))
            three = marks(s; count=3, gap=2.0, size=4.0)
            @test [m.p1[1] for m in three] ≈ [3.0, 5.0, 7.0]
            @test all(m -> distance(m.p1, m.p2) ≈ 4.0, three)
            @test only(marks(s; at=0.2)).p1[1] ≈ 2.0
            @test length(marks(s; style=:cross)) == 2
            @test only(marks(s; style=:circle, size=2.0)) ≈ APCircle2(APPoint(5.0, 0.0), 1.0)
            # :z and :s are letters that stand upright on a vertical segment (drawn coordinates, y down)
            vs = APSegment(APPoint(0.0, 50.0), APPoint(0.0, -50.0))
            zz = only(marks(vs; style=:z, size=20.0))
            @test zz isa APPolyline2 && length(vertices(zz)) == 4
            z1, z2, z3, z4 = vertices(zz)
            @test z1[2] == z2[2] < z3[2] == z4[2] || z1[2] == z2[2] > z3[2] == z4[2]   # two horizontal strokes
            @test z1[1] < z2[1] && z3[1] < z4[1]                                          # both left to right, like a Z
            @test z1[2] < z3[2] && z1[1] == z3[1]                                         # top stroke first, diagonal down-left
            ss = marks(vs; style=:s, size=20.0)
            @test length(ss) == 2 && all(x -> x isa APCircularArc2, ss)
            @test all(x -> x.circle.r ≈ 5.0, ss)
            two = marks(vs; style=:z, count=2, size=20.0, gap=4.0)   # gap < size: raised so letters do not overlap
            @test length(two) == 2 && distance(midpoint(two[1][1], two[1][3]), midpoint(two[2][1], two[2][3])) ≈ 20.0
            @test_throws ArgumentError marks(vs; style=:zigzag)
            cs = marks(s; style=:circle, count=3, size=6.0, gap=4.0)   # gap < size: raised so circles are tangent
            @test distance(cs[1].center, cs[2].center) ≈ 6.0 && distance(cs[2].center, cs[3].center) ≈ 6.0
            cs = marks(s; style=:circle, count=2, size=2.0, gap=5.0)   # gap > size: disjoint
            @test distance(cs[1].center, cs[2].center) ≈ 5.0
            chev = marks(s; style=:chevron, size=4.0)
            @test length(chev) == 2 && chev[1].p1 ≈ chev[2].p1   # both arms share the tip
            slash = only(marks(s; style=:slash, slant=pi / 6, size=2.0))
            @test direction(slash) ≈ APVector(2 * sin(pi / 6), 2 * cos(pi / 6))   # tilted slant from the perpendicular
            circ = APCircle2(APPoint(1.0, 2.0), 3.0)
            arc = APCircularArc2(circ, APPoint(4.0, 2.0), APPoint(1.0, 5.0))
            mk = only(marks(arc; size=1.0))
            @test is_on_line(circ.center, APLine(mk.p1, mk.p2))   # a tick on a circular arc lies along a radius
            @test distance(midpoint(mk), circ.center) ≈ circ.r atol = 1e-9
            @test_throws ArgumentError marks(s; style=:bogus)
            @test_throws ArgumentError marks(s; count=0)
            @test_throws ArgumentError marks(s; size=0.0)
        end
    end
    @testset "angle marks and compass arcs" begin
        @testset "marks(::APAngle2)" begin
            ang = APAngle2(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 4.0))
            arcs3 = marks(ang; count=3, size=1.0, gap=0.5)
            @test arcs3 isa Vector{<:APCircularArc2} && length(arcs3) == 3
            @test [a.circle.r for a in arcs3] ≈ [1.0, 1.5, 2.0]
            # `arcs=n` adds n arcs and centers the symbols across them
            crossed = marks(ang; style=:tick, arcs=2, size=1.0, gap=0.5, mark_size=0.5)
            @test length(crossed) == 3 && crossed[1] isa APCircularArc2 && crossed[3] isa APSegment
            @test [a.circle.r for a in crossed[1:2]] ≈ [1.0, 1.5]
            rs = sort([distance(crossed[3].p1, ang.vertex), distance(crossed[3].p2, ang.vertex)])
            @test rs[1] < 1.0 && rs[2] > 1.5   # the tick crosses both arcs
            @test length(marks(ang; style=:cross, count=2, arcs=3)) == 3 + 4
            @test marks(ang; style=:tick, arcs=0) == marks(ang; style=:tick)
            @test_throws ArgumentError marks(ang; style=:tick, arcs=-1)
            # integer coordinates are accepted (the arcs are built in floating point)
            iang = APAngle2(APPoint(-150, 60), APPoint(150, 60), APPoint(-40, -90))
            @test length(marks(iang; count=2, size=25, gap=5)) == 2
            @test measure(APCircularArc2(APCircle2(APPoint(0, 0), 3), APPoint(3, 0), APPoint(0, 3))) ≈ pi / 2
            @test all(a -> a.circle.center ≈ ang.vertex && measure(a) ≈ pi / 2, arcs3)
            @test only(marks(ang)).circle.r ≈ 0.15 * 4.0   # default radius, as path(::APAngle2) uses
            ticks = marks(ang; style=:tick, count=2, size=1.0, gap=0.3, mark_size=0.4)
            @test length(ticks) == 2 && all(t -> t isa APSegment && distance(t.p1, t.p2) ≈ 0.4, ticks)
            @test all(t -> isapprox(distance(midpoint(t), ang.vertex), 1.0; atol=0.05), ticks)   # ticks sit on the arc of radius 1
            @test_throws ArgumentError marks(APAngle2(APPoint(0.0, 0.0), APPoint(0.0, 0.0), APPoint(0.0, 4.0)))
            @test_throws ArgumentError marks(ang; count=0)
            @test_throws ArgumentError marks(ang; style=:bogus)
        end
        c0, p0 = APPoint(0.0, 0.0), APPoint(5.0, 0.0)
        @testset "APCircularArc2(center, r, θ1, θ2)" begin
            @test isapprox(APCircularArc2(c0, 5.0, 0.0, pi / 2), APCircularArc2(c0, 5.0, p0, APPoint(0.0, 5.0)); atol=1e-9)
            @test measure(APCircularArc2(c0, 5.0, pi / 2, 0.0; ccw=false)) ≈ pi / 2
            @test measure(APCircularArc2(c0, 5.0, 0.0, 3pi / 2)) ≈ 3pi / 2
        end
        @testset "semicircle / extend_arc" begin
            sc = semicircle(c0, p0)
            @test measure(sc) ≈ pi && sc.p2 ≈ APPoint(-5.0, 0.0)
            @test isapprox(semicircle(c0, p0; ccw=false).p1, APPoint(-5.0, 0.0); atol=1e-9) && isapprox(semicircle(c0, p0; ccw=false).p2, p0; atol=1e-9)
            a = APCircularArc2(c0, 5.0, 0.0, pi / 2)
            e = extend_arc(a, 0.1)
            @test measure(e) ≈ pi / 2 + 0.2 && e.circle == a.circle
            @test e.p1 ≈ APPoint(5cos(-0.1), 5sin(-0.1))
            @test measure(extend_arc(a, -0.1)) ≈ pi / 2 - 0.2
            @test_throws ArgumentError extend_arc(a, -pi)
            @test_throws ArgumentError extend_arc(a, 3.0)
        end
        @testset "compass_trace" begin
            t = compass_trace(c0, p0; angle=pi / 3)
            @test t isa APCircularArc2 && measure(t) ≈ pi / 3 && isapprox(midpoint(t), p0; atol=1e-9)
            @test t.circle.r ≈ 5.0
            tl = compass_trace(c0, p0; length=5.0)
            @test arc_length(tl) ≈ 5.0 && isapprox(midpoint(tl), p0; atol=1e-9)
            @test_throws ArgumentError compass_trace(c0, p0)
            @test_throws ArgumentError compass_trace(c0, p0; angle=1.0, length=1.0)
            @test_throws ArgumentError compass_trace(c0, c0; angle=1.0)
            @test_throws ArgumentError compass_trace(c0, p0; angle=7.0)
        end
    end
    @testset "calculation helpers: points by parameter, choosing intersections, more triangles" begin
        seg = APSegment(APPoint(0.0, 0.0), APPoint(4.0, 2.0))
        @test point_on(seg, 0.5) ≈ APPoint(2.0, 1.0) && point_on(seg, 2.0) ≈ APPoint(8.0, 4.0)
        @test point_on(APLine(APPoint(1.0, 1.0), APPoint(2.0, 1.0)), -1.0) ≈ APPoint(0.0, 1.0)
        @test point_on(APRay(APPoint(1.0, 1.0), APPoint(1.0, 3.0)), 0.5) ≈ APPoint(1.0, 2.0)
        c = APCircle2(APPoint(1.0, 2.0), 5.0)
        @test point_on(c, 0.0) ≈ APPoint(6.0, 2.0) && point_on(c, pi / 2) ≈ APPoint(1.0, 7.0)
        @test distance(point_on(c, 1.234), c.center) ≈ c.r
        # documented order of the solutions
        line = APLine(APPoint(-10.0, 0.0), APPoint(10.0, 0.0))
        xs = intersection(line, APCircle2(APPoint(0.0, 0.0), 5.0))
        @test xs[1] ≈ APPoint(-5.0, 0.0) && xs[2] ≈ APPoint(5.0, 0.0)   # along the line
        ys = intersection(APCircle2(APPoint(0.0, 0.0), 5.0), APCircle2(APPoint(6.0, 0.0), 5.0))
        @test ys[1][2] > 0 > ys[2][2]   # the first is to the left going from the first center to the second
        # nearest_point / other_intersection
        @test nearest_point(xs, APPoint(9.0, 1.0)) ≈ APPoint(5.0, 0.0)
        @test_throws ArgumentError nearest_point(APPoint{2,Float64}[], APPoint(0.0, 0.0))
        circ = APCircle2(APPoint(0.0, 0.0), 5.0)
        @test other_intersection(line, circ, APPoint(-5.0, 0.0)) ≈ APPoint(5.0, 0.0)
        @test other_intersection(circ, APCircle2(APPoint(6.0, 0.0), 5.0), ys[2]) ≈ ys[1]
        @test other_intersection(APLine(APPoint(5.0, 0.0), APPoint(5.0, 1.0)), circ, APPoint(5.0, 0.0)) === nothing   # tangent
        @test_throws ArgumentError other_intersection(line, circ, APPoint(1.0, 1.0))
        @test_throws ArgumentError other_intersection(line, APCircle2(APPoint(0.0, 9.0), 1.0), APPoint(0.0, 0.0))
        far = APPoint(1e6, 1e6)   # the tolerance does not depend on the distance from the origin
        cf = APCircle2(far, 5.0)
        @test other_intersection(APLine(far + APVector(-5.0, 0.0), far + APVector(5.0, 0.0)), cf, far + APVector(-5.0, 0.0)) ≈ far + APVector(5.0, 0.0)
        # angle between circles
        @test angle_measure_intersection(circ, orthogonal_circle(circ, APPoint(13.0, 0.0))) ≈ pi / 2
        @test angle_measure_intersection(circ, APCircle2(APPoint(8.0, 0.0), 3.0)) ≈ 0.0 atol = 1e-6   # tangent
        @test angle_measure_intersection(circ, APCircle2(APPoint(20.0, 0.0), 1.0)) === nothing
        @test angle_measure_intersection(circ, APCircle2(APPoint(0.5, 0.0), 1.0)) === nothing        # nested
        @test angle_measure_intersection(circ, APCircle2(APPoint(0.0, 0.0), 2.0)) === nothing        # concentric
        d1, d2 = APCircle2(APPoint(0.0, 0.0), 5.0), APCircle2(APPoint(6.0, 0.0), 3.0)
        p = first(intersection(d1, d2))
        @test angle_measure_intersection(d1, d2) ≈ angle_measure_between(p - d1.center, p - d2.center) || angle_measure_intersection(d1, d2) ≈ pi - angle_measure_between(p - d1.center, p - d2.center)
        # triangles
        a, b = APPoint(0.0, 0.0), APPoint(2.0, 0.0)
        ch = cheops_triangle_on_segment(a, b)
        @test distance(ch[1], ch[3]) ≈ golden && distance(ch[2], ch[3]) ≈ golden
        @test cheops_triangle_on_segment(APSegment(a, b); ccw=false)[3][2] < 0
        gr = golden_right_triangle_on_segment(a, b)
        @test distance(gr[2], gr[3]) ≈ 2 / golden && abs(dot(gr[1] - gr[2], gr[3] - gr[2])) < 1e-12
        @test distance(gr[1], gr[2]) / distance(gr[2], gr[3]) ≈ golden
        @test golden_right_triangle_on_segment(APSegment(a, b))[3] ≈ gr[3]
        # random interior points
        rng = Apollonius.Random.Xoshiro(1)
        tri = APTriangle(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(1.0, 3.0))
        @test all(_ -> in(rand_inside(rng, tri), tri), 1:200)
        @test all(_ -> distance(rand_inside(rng, circ), circ.center) <= circ.r, 1:200)
        el = APEllipse2(APPoint(1.0, 1.0), 4.0, 2.0, 0.6)
        @test all(_ -> (let f = foci(el), q = rand_inside(rng, el); distance(q, f[1]) + distance(q, f[2]) <= 2 * el.a + 1e-9 end), 1:200)
        bb = APBoundingBox(APPoint(-1.0, -2.0), APPoint(3.0, 5.0))
        @test all(_ -> in(rand_inside(rng, bb), bb), 1:200)
        radii = [distance(rand_inside(rng, circ), circ.center) for _ in 1:4000]
        @test 0.45 < count(<(circ.r / sqrt(2)), radii) / 4000 < 0.55   # uniform in area: half the points within r/√2
        @test rand_inside(circ) isa APPoint
        quad = APQuadrilateral(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 4.0), APPoint(0.0, 4.0))
        @test all(_ -> in(rand_inside(rng, quad), quad), 1:200)
        dart = APQuadrilateral(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(2.0, 1.0), APPoint(0.0, 4.0))
        @test !is_convex(dart) && all(_ -> in(rand_inside(rng, dart), dart), 1:400)
        L = APStraightNgon([APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 1.0), APPoint(1.0, 1.0), APPoint(1.0, 4.0), APPoint(0.0, 4.0)])
        @test all(_ -> in(rand_inside(rng, L), L), 1:400)
    end

    @testset "extend_line (tkz add, relative)" begin
        l = APLine(APPoint(0.0, 0.0), APPoint(10.0, 0.0))
        @test extend_line(l, 0.2) == APSegment(APPoint(-2.0, 0.0), APPoint(12.0, 0.0))
        @test extend_line(l, 0.5, 0.0) == APSegment(APPoint(-5.0, 0.0), APPoint(10.0, 0.0))
        @test extend_line(l, 0.0, -0.3) == APSegment(APPoint(0.0, 0.0), APPoint(7.0, 0.0))   # a negative fraction shortens
        @test extend_line(APSegment(APPoint(0.0, 0.0), APPoint(0.0, 4.0)), 0.25) == APSegment(APPoint(0.0, -1.0), APPoint(0.0, 5.0))
        scaled = APLine(APPoint(0.0, 0.0), APPoint(100.0, 0.0))   # relative: twice the length adds twice the units
        @test extend_line(scaled, 0.2).p1[1] ≈ -20.0
        @test_throws ArgumentError extend_line(l, -0.6, -0.5)
        @test_throws ArgumentError extend_line(APLine(APPoint(1.0, 1.0), APPoint(1.0, 1.0)), 0.2)
    end
    @testset "arrow_head / brace / coordinate_guides" begin
        s = APSegment(APPoint(0.0, 0.0), APPoint(10.0, 0.0))
        @testset "arrow_head" begin
            hd = arrow_head(s)
            @test hd isa APTriangle
            h = 10.0 * cos(pi / 8)
            @test hd[1] ≈ APPoint(5.0 + h / 2, 0.0)   # tip ahead of the middle: the head is centered on the point
            @test distance(hd[1], hd[2]) ≈ 10.0 && distance(hd[1], hd[3]) ≈ 10.0   # arms of length `size`
            @test hd[2][1] ≈ hd[3][1] ≈ 5.0 - h / 2 && hd[2][2] ≈ -hd[3][2]
            @test arrow_head(s; place=:tip)[1] ≈ APPoint(5.0, 0.0)
            @test arrow_head(s; at=1.0, place=:tip)[1] ≈ s.p2
            arc = APCircularArc2(APPoint(0.0, 0.0), 5.0, 0.0, pi / 2)
            @test isapprox(arrow_head(arc; at=1.0, place=:tip)[1], arc.p2; atol=1e-9)   # an arrow at the end of an arc
            @test area(arrow_head(s; size=4.0)) < area(hd)
            @test_throws ArgumentError arrow_head(s; size=0.0)
            @test_throws ArgumentError arrow_head(s; angle=pi / 2)
            @test_throws ArgumentError arrow_head(s; place=:middle)
            @test_throws ArgumentError arrow_head(s; style=:fancy)
            st = arrow_head(s; style=:stealth)
            @test st isa APStraightNgon && length(vertices(st)) == 4
            @test st[1] ≈ hd[1] && st[2] ≈ hd[2] && st[4] ≈ hd[3]   # same tip and back corners as the triangle
            @test 0 < area(st) < area(hd) && st[3][1] < st[1][1] && st[3][1] > st[2][1]   # a notch between the back corners and the tip
            op = arrow_head(s; style=:open)
            @test op isa APPolyline2 && length(op) == 3 && op[2] ≈ hd[1]
            @test distance(op[1], op[2]) ≈ 10.0 && distance(op[3], op[2]) ≈ 10.0
        end
        @testset "brace" begin
            b = brace(APPoint(0.0, 0.0), APPoint(100.0, 0.0); height=10.0)
            @test length(b) == 6 && count(x -> x isa APCircularArc2, b) == 4 && count(x -> x isa APSegment, b) == 2
            @test sum(x isa APCircularArc2 ? arc_length(x) : distance(x.p1, x.p2) for x in b) ≈ 2pi * 5 + 80
            tips = [q for x in b for q in (x isa APCircularArc2 ? (x.p1, x.p2) : (x.p1, x.p2))]
            has(q) = any(t -> isapprox(t, q; atol=1e-9), tips)
            @test has(APPoint(0.0, 0.0)) && has(APPoint(100.0, 0.0)) && has(APPoint(50.0, -10.0))   # ends on the segment, point up on screen (left)
            @test has(APPoint(50.0, 10.0)) == false
            @test any(t -> isapprox(t, APPoint(50.0, 10.0); atol=1e-9), [q for x in brace(APPoint(0.0, 0.0), APPoint(100.0, 0.0); height=10.0, side=:right) for q in (x.p1, x.p2)])
            @test all(x -> x isa APCircularArc2 ? measure(x) ≈ pi / 2 : true, b)   # quarter arcs
            @test length(brace(APPoint(0.0, 0.0), APPoint(20.0, 0.0); height=10.0)) == 4   # the two straight pieces vanish at the maximum height
            @test length(brace(APPoint(0.0, 0.0), APPoint(50.0, 0.0))) == 6   # default height 10
            @test_throws ArgumentError brace(APPoint(0.0, 0.0), APPoint(10.0, 0.0); height=6.0)
            @test_throws ArgumentError brace(APPoint(0.0, 0.0), APPoint(0.0, 0.0))
            @test_throws ArgumentError brace(APPoint(0.0, 0.0), APPoint(10.0, 0.0); side=:up)
            ba = brace_anchor(APPoint(0.0, 0.0), APPoint(100.0, 0.0))
            @test ba == (alignment=:N, point=APPoint(50.0, -10.0))   # the point of the brace, label beyond it (screen coordinates)
            @test brace_anchor(APPoint(0.0, 0.0), APPoint(100.0, 0.0); side=:right, height=6.0) == (alignment=:S, point=APPoint(50.0, 6.0))
            @test brace_anchor(APPoint(0.0, 0.0), APPoint(0.0, 100.0)).alignment == :E
            @test any(q -> isapprox(q, ba.point; atol=1e-9), [q for x in b for q in (x.p1, x.p2)])   # it is a point of the brace itself
            @test_throws ArgumentError brace_anchor(APPoint(0.0, 0.0), APPoint(10.0, 0.0); height=6.0)
        end
        @testset "coordinate_guides" begin
            g = coordinate_guides(APPoint(3.0, 4.0))
            @test g == [APSegment(APPoint(3.0, 4.0), APPoint(3.0, 0.0)), APSegment(APPoint(3.0, 4.0), APPoint(0.0, 4.0))]
            @test coordinate_guides(APPoint(3.0, 0.0)) == [APSegment(APPoint(3.0, 0.0), APPoint(0.0, 0.0))]
            @test isempty(coordinate_guides(APPoint(0.0, 0.0)))
            @test coordinate_guides(APPoint(3.0, 4.0); origin=APPoint(1.0, 1.0)) ==
                  [APSegment(APPoint(3.0, 4.0), APPoint(3.0, 1.0)), APSegment(APPoint(3.0, 4.0), APPoint(1.0, 4.0))]
        end
    end
    @testset "grid_lines / axes_lines" begin
        bb = Apollonius.APBoundingBox(APPoint(0.0, 0.0), APPoint(3.0, 2.0))
        g = grid_lines(bb)
        @test length(g) == 4 + 3 && all(s -> s isa APSegment, g)
        @test g[1] == APSegment(APPoint(0.0, 0.0), APPoint(0.0, 2.0))     # vertical lines first, full height
        @test g[5] == APSegment(APPoint(0.0, 0.0), APPoint(3.0, 0.0))     # then horizontal ones, full width
        shifted = Apollonius.APBoundingBox(APPoint(0.5, -0.5), APPoint(3.5, 1.5))   # anchored at the origin, not at the box corner
        gs = grid_lines(shifted)
        @test [s.p1[1] for s in gs[1:3]] == [1.0, 2.0, 3.0] && [s.p1[2] for s in gs[4:end]] == [0.0, 1.0]
        @test length(grid_lines(bb; xstep=1.5, ystep=1.0)) == 3 + 3
        @test length(grid_lines(bb; step=0.5)) == 7 + 5
        @test isempty(grid_lines(Apollonius.APBoundingBox()))
        @test_throws ArgumentError grid_lines(bb; step=0.0)
        @test axes_lines(bb) == [APSegment(APPoint(0.0, 0.0), APPoint(3.0, 0.0)), APSegment(APPoint(0.0, 0.0), APPoint(0.0, 2.0))]
        @test axes_lines(Apollonius.APBoundingBox(APPoint(1.0, -1.0), APPoint(3.0, 1.0))) == [APSegment(APPoint(1.0, 0.0), APPoint(3.0, 0.0))]   # only the x axis crosses this box
        @test isempty(axes_lines(Apollonius.APBoundingBox(APPoint(1.0, 1.0), APPoint(3.0, 3.0))))
    end
    @testset "label_anchor" begin
        h = APSegment(APPoint(0.0, 0.0), APPoint(10.0, 0.0))
        @test label_anchor(h) == (alignment=:N, point=APPoint(5.0, 0.0))   # screen coordinates: y grows downward, left of travel is up
        @test label_anchor(h; side=:right).alignment == :S
        @test label_anchor(h, 0.2).point ≈ APPoint(2.0, 0.0)
        @test label_anchor(APSegment(APPoint(0.0, 0.0), APPoint(0.0, 10.0))).alignment == :E
        @test label_anchor(APSegment(APPoint(0.0, 10.0), APPoint(0.0, 0.0))).alignment == :W   # reversing the segment flips the side
        @test_throws ArgumentError label_anchor(h; side=:up)
        ang = APAngle2(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 4.0))
        la = label_anchor(ang)
        @test la.alignment == :SE && la.point ≈ APPoint(0.25 * 4 / sqrt(2), 0.25 * 4 / sqrt(2))
        @test label_anchor(ang; dist=2.0).point ≈ APPoint(sqrt(2), sqrt(2))
        reflex = APAngle2(APPoint(0.0, 0.0), APPoint(0.0, 4.0), APPoint(4.0, 0.0))   # the wedge from a to b sweeps the long way round
        @test label_anchor(reflex).alignment == :NW
        @test_throws ArgumentError label_anchor(APAngle2(APPoint(0.0, 0.0), APPoint(0.0, 0.0), APPoint(4.0, 0.0)))
        circ = APCircle2(APPoint(1.0, 1.0), 3.0)
        @test label_anchor(circ, 0.0) == (alignment=:E, point=APPoint(4.0, 1.0))
        @test label_anchor(circ, pi).alignment == :W
        @test label_anchor(APPoint(3.0, -3.0), APPoint(0.0, 0.0)) == (alignment=:NE, point=APPoint(3.0, -3.0))
        @test label_anchor(APPoint(-3.0, 0.0), APPoint(0.0, 0.0)).alignment == :W
        arc = APCircularArc2(APPoint(0.0, 0.0), 5.0, 0.0, pi / 2)
        @test label_anchor(arc; side=:left).alignment == :SE && label_anchor(arc; side=:right).alignment == :NW
        @test first(keys(label_anchor(h))) == :alignment   # same order as Luxor's label(txt, alignment, pos)
    end
    @testset "shown compass-and-ruler constructions" begin
        a, b = APPoint(0.0, 0.0), APPoint(6.0, 2.0)
        @testset "mediator_construction" begin
            m = mediator_construction(a, b)
            @test isapprox(m.result, perpendicular_bisector(a, b); atol=1e-9)
            p, q = m.points
            @test distance(p, a) ≈ distance(p, b) ≈ 0.75 * distance(a, b)
            @test Apollonius.cross2(b - a, p - a) > 0 > Apollonius.cross2(b - a, q - a)   # left crossing first
            @test length(m.arcs) == 4 && all(x -> x isa APCircularArc2 && measure(x) ≈ pi / 6, m.arcs)
            @test all(x -> any(c -> isapprox(x.circle.center, c; atol=1e-9), (a, b)) && x.circle.r ≈ 0.75 * distance(a, b), m.arcs)
            @test all(x -> any(c -> isapprox(midpoint(x), c; atol=1e-9), (p, q)), m.arcs)   # each trace is centered on a crossing
            @test measure(mediator_construction(a, b; sweep=0.4).arcs[1]) ≈ 0.4
            @test_throws ArgumentError mediator_construction(a, a)
            @test_throws ArgumentError mediator_construction(a, b; radius=1.0)
        end
        l = APLine(APPoint(0.0, 0.0), APPoint(5.0, 1.0))
        @testset "perpendicular_construction" begin
            p = APPoint(2.0, 4.0)
            pc = perpendicular_construction(l, p)
            @test is_perpendicular(pc.result, l) && is_on_line(p, pc.result)
            x1, x2, y = pc.points
            @test is_on_line(x1, l) && is_on_line(x2, l) && distance(p, x1) ≈ distance(p, x2)
            @test side_of_line(y, l) != side_of_line(p, l)   # the second pair of circles crosses on the other side
            @test length(pc.arcs) == 4 && all(x -> x isa APCircularArc2, pc.arcs)
            p_on = APPoint(2.5, 0.5)   # on l
            pc2 = perpendicular_construction(l, p_on)
            @test is_perpendicular(pc2.result, l) && is_on_line(p_on, pc2.result)
            @test length(pc2.arcs) == 6 && length(pc2.points) == 4
            @test_throws ArgumentError perpendicular_construction(l, p; radius=0.1)
        end
        @testset "parallel_construction" begin
            p = APPoint(2.0, 4.0)
            par = parallel_construction(l, p)
            @test is_parallel(par.result, l) && is_on_line(p, par.result) && !is_on_line(p, l)
            D, E = par.points
            @test is_on_line(D, l) && distance(D, l.p1) ≈ distance(p, l.p1)
            @test distance(E, D) ≈ distance(p, l.p1) ≈ distance(E, p)   # a rhombus: all four sides equal
            @test length(par.arcs) == 4
            @test_throws ArgumentError parallel_construction(l, APPoint(2.5, 0.5))
        end
        @testset "bisector_construction" begin
            v, p1, p2 = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(1.0, 3.0)
            bc = bisector_construction(v, p1, p2)
            y = bc.points[3]
            @test angle_measure_at(v, p1, y) ≈ angle_measure_at(v, y, p2)
            @test angle_measure_at(v, p1, y) ≈ angle_measure_at(v, p1, p2) / 2
            @test is_on_line(y, bc.result) && is_on_line(v, bc.result)
            @test length(bc.arcs) == 4
            wide = bisector_construction(v, APPoint(-3.0, 1.0), APPoint(2.0, -4.0); radius=1.0, radius2=1.2)   # obtuse angle, explicit radii
            @test angle_measure_at(v, APPoint(-3.0, 1.0), wide.points[3]) ≈ angle_measure_at(v, wide.points[3], APPoint(2.0, -4.0))
            @test_throws ArgumentError bisector_construction(v, p1, APPoint(-2.0, 0.0))   # opposite rays
            @test_throws ArgumentError bisector_construction(v, p1, APPoint(8.0, 0.0))    # same direction
            @test_throws ArgumentError bisector_construction(v, v, p2)
        end
    end
    @testset "shown constructions of transformations" begin
        l = APLine(APPoint(0.0, 0.0), APPoint(5.0, 1.0))
        p = APPoint(2.0, 4.0)
        @testset "projection_construction" begin
            pr = projection_construction(p, l)
            @test pr.result ≈ projection(p, l) && is_on_line(pr.result, l)
            @test length(pr.arcs) == 4 && length(pr.points) == 3
            @test isapprox(projection_construction(APPoint(2.5, 0.5), l).result, APPoint(2.5, 0.5); atol=1e-9)   # p on l: its own foot
        end
        @testset "reflection_construction" begin
            rf = reflection_construction(p, l)
            @test rf.result ≈ reflection(p, l)
            x1, x2 = rf.points
            @test is_on_line(x1, l) && is_on_line(x2, l)
            @test distance(x1, p) ≈ 1.5 * distance(p, l)
            @test distance(x1, rf.result) ≈ distance(x1, p) && distance(x2, rf.result) ≈ distance(x2, p)   # both circles pass through p and its image
            @test length(rf.arcs) == 6 && all(a -> a isa APCircularArc2, rf.arcs)
            triv = reflection_construction(APPoint(2.5, 0.5), l)
            @test triv.result == APPoint(2.5, 0.5) && isempty(triv.arcs) && isempty(triv.points)
            @test_throws ArgumentError reflection_construction(p, l; radius=0.1)
        end
        @testset "symmetry_construction" begin
            c = APPoint(1.0, 1.0)
            sy = symmetry_construction(p, c)
            @test sy.result ≈ reflection(p, c) && midpoint(p, sy.result) ≈ c
            @test length(sy.arcs) == 2 && all(a -> isapprox(a.circle.center, c; atol=1e-9) && a.circle.r ≈ distance(p, c), sy.arcs)
            @test_throws ArgumentError symmetry_construction(c, c)
        end
        @testset "translation_construction" begin
            a, b = APPoint(0.0, 0.0), APPoint(3.0, 1.0)
            tr = translation_construction(p, a, b)
            @test tr.result ≈ p + (b - a)
            @test length(tr.arcs) == 2 && all(x -> isapprox(midpoint(x), tr.result; atol=1e-9), tr.arcs)   # both traces are centered on the image
            @test translation_construction(APPoint(2.0, 0.0), APPoint(0.0, 0.0), APPoint(1.0, 0.0)).result ≈ APPoint(3.0, 0.0)   # p collinear with a and b: tangent circles
            @test translation_construction(p, a, a).result == p
            @test_throws ArgumentError translation_construction(a, a, b)
        end
    end
    @testset "APParametricCurve2" begin
        curve = APParametricCurve2(t -> APPoint(2t, t^2), (0.0, 3.0))
        @test point_on(curve, 0.0) == APPoint(0.0, 0.0)
        @test point_on(curve, 2.0) == APPoint(4.0, 4.0)
        @test curve.trange == (0.0, 3.0)
        v = APVector(1.0, -2.0)
        tcurve = translate(curve, v)
        @test point_on(tcurve, 2.0) ≈ point_on(curve, 2.0) + v
        @test tcurve.trange == curve.trange
        rcurve = rotate(curve, pi / 2, APPoint(0.0, 0.0))
        @test point_on(rcurve, 2.0) ≈ rotate(point_on(curve, 2.0), pi / 2, APPoint(0.0, 0.0))
        hcurve = homothety(curve, 2.0)
        @test point_on(hcurve, 2.0) ≈ point_on(curve, 2.0) * 2.0
        rfcurve = reflection(curve, APPoint(0.0, 0.0))
        @test point_on(rfcurve, 2.0) ≈ reflection(point_on(curve, 2.0), APPoint(0.0, 0.0))
        bb = APBoundingBox(curve)
        @test isapprox(bb.min, APPoint(0.0, 0.0); atol=1e-6)
        @test isapprox(bb.max, APPoint(6.0, 9.0); atol=1e-6)
        @test APBoundingBox(curve; n=1000) ≈ APBoundingBox(curve; n=200) atol = 1e-3
    end
    @testset "APPolygon curved regions" begin
        @testset "APCircularSector2" begin
            circ = APCircle2(APPoint(2.0, -1.0), 5.0)
            p1 = circ.center + APVector(5.0, 0.0)
            θ = 2.3
            p2 = circ.center + APVector(5.0 * cos(θ), 5.0 * sin(θ))
            arc = APCircularArc2(circ, p1, p2)
            sec = APCircularSector2(arc)
            @test APCircularSector2(circ.center, circ.r, p1, p2) == sec
            @test area(sec) ≈ 0.5 * 25 * θ atol = 1e-9
            @test perimeter(sec) ≈ 2 * 5 + 5 * θ atol = 1e-9
            @test circ.center in sec
            @test !(circ.center + APVector(20.0, 0.0) in sec)
            @test area(rotate(sec, pi / 3, APPoint(1.0, 1.0))) ≈ area(sec) atol = 1e-6
            @test area(homothety(sec, 2.0)) ≈ 4 * area(sec) atol = 1e-6
            @test area(reflection(sec, APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)))) ≈ area(sec) atol = 1e-6
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
            @test APCircularSegment2(circ.center, circ.r, p1, p2) == seg
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
            @test APAnnularSector2(circ.center, circ.r, p1, p2, 2.0) == asec
            @test area(asec) ≈ 0.5 * 25 * θ - 0.5 * 4 * θ atol = 1e-9
            @test perimeter(asec) ≈ (5 * θ) + (2 * θ) + 2 * (5.0 - 2.0) atol = 1e-9
            @test_throws ArgumentError APAnnularSector2(arc, 6.0)
            @test area(rotate(asec, pi / 4, APPoint(0.0, 0.0))) ≈ area(asec) atol = 1e-6
            full_sec = APCircularSector2(arc)
            @test distance(centroid(asec), circ.center) > distance(centroid(full_sec), circ.center)
        end
        @testset "APInterstice2" begin
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
            @test ngon == APCurvilinearNgon2(APSegment(A, p1), arc, APSegment(p2, A))
        end
        @testset "APPolyline2" begin
            p0, p1, p2 = APPoint(0.0, 0.0), APPoint(3.0, 0.0), APPoint(3.0, 4.0)
            pl = APPolyline2(p0, p1, p2)
            @test pl == APPolyline2([p0, p1, p2])
            @test vertices(pl) == [p0, p1, p2]
            @test length(pl) == 3
            @test collect(pl) == [p0, p1, p2]
            @test_throws ArgumentError APPolyline2([p0])
            s = sides(pl)
            @test length(s) == 2
            @test s[1] == APSegment(p0, p1) && s[2] == APSegment(p1, p2)
            @test arc_length(pl) ≈ 3.0 + 4.0
            bb = APBoundingBox(pl)
            @test bb.min == APPoint(0.0, 0.0) && bb.max == APPoint(3.0, 4.0)
            @test reverse(pl) == APPolyline2([p2, p1, p0])
            @test reverse(reverse(pl)) == pl
            rot = rotate(pl, pi / 2, APPoint(0.0, 0.0))
            @test isapprox(rot[1], APPoint(0.0, 0.0); atol=1e-9)
            @test isapprox(rot[2], APPoint(0.0, 3.0); atol=1e-9)
            @test area(APTriangle(p0, p1, p2)) ≈ area(APTriangle(rotate.([p0, p1, p2], pi / 2, APPoint(0.0, 0.0))...))
            hom = homothety(pl, 2.0, APPoint(0.0, 0.0))
            @test hom[3] == APPoint(6.0, 8.0)
            refl = reflection(pl, APPoint(0.0, 0.0))
            @test refl[3] == APPoint(-3.0, -4.0)
            tr = translate(pl, APVector(1.0, 1.0))
            @test tr[1] == APPoint(1.0, 1.0)
            @test APPoint(1.5, 0.0) in pl
            @test APPoint(3.0, 2.0) in pl
            @test !(APPoint(10.0, 10.0) in pl)
            @test distance(APPoint(0.0, 4.0), pl) ≈ 3.0
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
            @test_throws ArgumentError APCurvilinearPolyline2(APCurve[])
            @test_throws ArgumentError APCurvilinearPolyline2([APSegment(APPoint(0.0, 0.0), APPoint(1.0, 0.0)), APSegment(APPoint(5.0, 5.0), APPoint(6.0, 6.0))])
            @test arc_length(cpl) ≈ arc_length(arc) + distance(p2, p3)
            bb = APBoundingBox(cpl)
            @test bb.min ≈ APPoint(-5.0, 0.0) atol = 1e-9
            @test bb.max ≈ APPoint(5.0, 5.0) atol = 1e-9
            rcpl = reverse(cpl)
            @test rcpl[1] == reverse(seg) && rcpl[2] == reverse(arc)
            @test reverse(rcpl) == cpl
            tr = translate(cpl, APVector(1.0, 1.0))
            @test tr[1] == translate(arc, APVector(1.0, 1.0))
            mirror = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
            mcpl = reflection(cpl, mirror)   # a mirror swaps the arc's endpoints: the chain must still be continuous
            @test arc_length(mcpl) ≈ arc_length(cpl)
            @test reflection(midpoint(arc), mirror) in mcpl && reflection(midpoint(seg), mirror) in mcpl
            @test reflection(cpl, APPoint(1.0, 1.0)) isa APCurvilinearPolyline2
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
            @test rotate(APPoint(5.0, 5.0), ang, APPoint(2.0, 3.0)) ==
                  rotate(APPoint(5.0, 5.0), measure(ang), APPoint(2.0, 3.0))
            @test rotate(APPoint(5.0, 5.0), ang) == rotate(APPoint(5.0, 5.0), measure(ang))
            axis = APLine(APPoint(0.0, 0.0, 0.0), APPoint(0.0, 0.0, 1.0))
            @test rotate(APPoint(5.0, 5.0, 1.0), ang, axis) == rotate(APPoint(5.0, 5.0, 1.0), measure(ang), axis)
            @test (vertex + APVector(1.0, 1.0)) in ang
            @test !((vertex + APVector(-1.0, 0.0)) in ang)
            l = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
            refl_l = reflection(ang, l)
            @test measure(refl_l) ≈ measure(ang) atol = 1e-9
            refl_p = reflection(ang, APPoint(0.0, 0.0))
            @test measure(refl_p) ≈ measure(ang) atol = 1e-9
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
            @test APPoint(5.0, 0.0) in hp
            @test APHalfPlane2(l2, APPoint(3.0, 5.0)) == hp
            @test_throws ArgumentError APHalfPlane2(l2, APPoint(3.0, 0.0))
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
            @test APPoint(0.0, 0.0) in strip
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
        @testset "region intersected with a line, segment or ray: the part inside, not boundary points" begin
            P(x, y) = APPoint(x, y)
            hp = APHalfPlane2(APLine(P(0.0, 0.0), P(1.0, 0.0)), P(0.0, 1.0))   # y >= 0
            @test intersection(hp, APLine(P(2.0, -3.0), P(2.0, 3.0))) ≈ APRay(P(2.0, 0.0), P(2.0, 6.0))
            @test intersection(hp, APLine(P(-5.0, 2.0), P(5.0, 2.0))) ≈ APLine(P(-5.0, 2.0), P(5.0, 2.0))
            @test intersection(hp, APLine(P(-5.0, -2.0), P(5.0, -2.0))) === nothing
            @test intersection(hp, APLine(P(-5.0, 0.0), P(5.0, 0.0))) ≈ APLine(P(-5.0, 0.0), P(5.0, 0.0))
            @test intersection(hp, APSegment(P(1.0, 1.0), P(2.0, 2.0))) ≈ APSegment(P(1.0, 1.0), P(2.0, 2.0))
            @test intersection(hp, APSegment(P(1.0, -1.0), P(2.0, -2.0))) === nothing
            @test intersection(hp, APSegment(P(1.0, -1.0), P(1.0, 3.0))) ≈ APSegment(P(1.0, 0.0), P(1.0, 3.0))
            @test intersection(hp, APRay(P(1.0, 1.0), P(1.0, 5.0))) ≈ APRay(P(1.0, 1.0), P(1.0, 5.0))
            @test intersection(hp, APRay(P(1.0, 1.0), P(1.0, -5.0))) ≈ APSegment(P(1.0, 1.0), P(1.0, 0.0))
            @test intersection(hp, P(1.0, 1.0)) ≈ P(1.0, 1.0)
            @test intersection(hp, P(1.0, -1.0)) === nothing
            @test intersection(APLine(P(2.0, -3.0), P(2.0, 3.0)), hp) ≈ APRay(P(2.0, 0.0), P(2.0, 6.0))   # reverse order
            @test intersection(P(1.0, 1.0), hp) ≈ P(1.0, 1.0)

            st = APStrip2(APLine(P(0.0, 0.0), P(1.0, 0.0)), APLine(P(0.0, 3.0), P(1.0, 3.0)))   # 0 <= y <= 3
            @test intersection(st, APLine(P(2.0, -2.0), P(2.0, 10.0))) ≈ APSegment(P(2.0, 0.0), P(2.0, 3.0))
            @test intersection(st, APSegment(P(2.0, 1.0), P(2.0, 2.0))) ≈ APSegment(P(2.0, 1.0), P(2.0, 2.0))
            @test intersection(st, APSegment(P(2.0, -1.0), P(2.0, 1.0))) ≈ APSegment(P(2.0, 0.0), P(2.0, 1.0))
            @test intersection(st, APLine(P(-5.0, 1.0), P(5.0, 1.0))) ≈ APLine(P(-5.0, 1.0), P(5.0, 1.0))
            @test intersection(st, APLine(P(-5.0, 5.0), P(5.0, 5.0))) === nothing
            @test intersection(st, APRay(P(2.0, -5.0), P(2.0, 5.0))) ≈ APSegment(P(2.0, 0.0), P(2.0, 3.0))
            @test intersection(st, P(2.0, 1.5)) ≈ P(2.0, 1.5)
            @test intersection(st, P(2.0, 5.0)) === nothing
            @test intersection(APSegment(P(2.0, -1.0), P(2.0, 1.0)), st) ≈ APSegment(P(2.0, 0.0), P(2.0, 1.0))   # reverse order

            ang = APAngle2(P(0.0, 0.0), P(4.0, 0.0), P(0.0, 4.0))   # convex: the first quadrant
            @test only(intersection(ang, APLine(P(-1.0, 2.0), P(5.0, 2.0)))) ≈ APRay(P(0.0, 2.0), P(6.0, 2.0))
            @test isempty(intersection(ang, APLine(P(-5.0, -1.0), P(5.0, -1.0))))
            @test only(intersection(ang, APLine(P(-2.0, 2.0), P(2.0, -2.0)))) ≈ P(0.0, 0.0)   # touches only at the vertex
            @test only(intersection(ang, APRay(P(1.0, 1.0), P(10.0, 10.0)))) ≈ APRay(P(1.0, 1.0), P(10.0, 10.0))
            @test intersection(ang, P(1.0, 1.0)) ≈ P(1.0, 1.0)
            @test intersection(ang, P(1.0, -1.0)) === nothing
            @test only(intersection(APLine(P(-1.0, 2.0), P(5.0, 2.0)), ang)) ≈ APRay(P(0.0, 2.0), P(6.0, 2.0))   # reverse order

            angr = APAngle2(P(0.0, 0.0), P(1.0, 0.0), P(0.0, -1.0))   # reflex: everything except the 4th quadrant
            @test normalized_measure(angr) ≈ 3pi / 2
            @test only(intersection(angr, APLine(P(-5.0, 2.0), P(5.0, 2.0)))) ≈ APLine(P(-5.0, 2.0), P(5.0, 2.0))   # never touches the excluded quadrant
            # y = x - 2 crosses the axes at (2,0) and (0,-2): the excluded interval is x in (0,2), so two pieces survive
            l = APLine(P(-3.0, -5.0), P(7.0, 5.0))
            pieces = intersection(angr, l)
            @test length(pieces) == 2
            @test any(pc -> pc isa APRay && isapprox(pc, APRay(P(0.0, -2.0), P(-1.0, -3.0)); atol=1e-9), pieces)
            @test any(pc -> pc isa APRay && isapprox(pc, APRay(P(2.0, 0.0), P(3.0, 1.0)); atol=1e-9), pieces)
            seg_pieces = intersection(angr, APSegment(P(-3.0, -5.0), P(7.0, 5.0)))
            @test length(seg_pieces) == 2
            @test any(pc -> pc isa APSegment && isapprox(pc, APSegment(P(-3.0, -5.0), P(0.0, -2.0)); atol=1e-9), seg_pieces)
            @test any(pc -> pc isa APSegment && isapprox(pc, APSegment(P(2.0, 0.0), P(7.0, 5.0)); atol=1e-9), seg_pieces)
        end
        @testset "region intersected with a circle or an ellipse: the arc(s) inside, not boundary points" begin
            P(x, y) = APPoint(x, y)
            hp = APHalfPlane2(APLine(P(0.0, 0.0), P(0.0, 1.0)), P(1.0, 0.0))   # x >= 0
            c = APCircle2(P(0.0, 0.0), 3.0)
            @test isapprox(intersection(hp, c), APCircularArc2(c, P(0.0, -3.0), P(0.0, 3.0)); atol=1e-9)   # the x >= 0 half
            @test intersection(hp, APCircle2(P(-10.0, 0.0), 3.0)) === nothing   # fully outside
            @test intersection(hp, APCircle2(P(10.0, 0.0), 3.0)) === APCircle2(P(10.0, 0.0), 3.0)   # fully inside: itself, unchanged
            @test intersection(hp, APCircle2(P(-3.0, 0.0), 3.0)) ≈ P(0.0, 0.0)   # tangent from outside: just the touch point
            @test intersection(hp, APCircle2(P(3.0, 0.0), 3.0)) === APCircle2(P(3.0, 0.0), 3.0)   # tangent from inside: nothing lost
            @test isapprox(intersection(c, hp), APCircularArc2(c, P(0.0, -3.0), P(0.0, 3.0)); atol=1e-9)   # reverse order
            @test intersection(hp, P(1.0, 0.0)) ≈ P(1.0, 0.0)
            @test intersection(hp, P(-1.0, 0.0)) === nothing

            # a strip narrower than the circle's diameter: the circle pokes out both sides, 2 arcs survive
            st = APStrip2(APLine(P(-10.0, -1.0), P(10.0, -1.0)), APLine(P(-10.0, 1.0), P(10.0, 1.0)))
            big_c = APCircle2(P(0.0, 0.0), 5.0)
            pieces = intersection(st, big_c)
            @test length(pieces) == 2
            half_angle = asin(1 / 5)
            @test all(pc -> pc isa APCircularArc2 && isapprox(measure(pc), 2half_angle; atol=1e-9), pieces)
            @test any(pc -> isapprox(midpoint(pc), P(5.0, 0.0); atol=1e-9), pieces)
            @test any(pc -> isapprox(midpoint(pc), P(-5.0, 0.0); atol=1e-9), pieces)
            @test intersection(big_c, st) == pieces   # reverse order

            # convex angle centered at the circle's own center: a clean quarter-circle arc
            ang = APAngle2(P(0.0, 0.0), P(4.0, 0.0), P(0.0, 4.0))
            only_piece = only(intersection(ang, c))
            @test only_piece isa APCircularArc2 && isapprox(measure(only_piece), pi / 2; atol=1e-9)
            @test intersection(ang, P(1.0, 1.0)) ≈ P(1.0, 1.0)
            @test intersection(ang, P(-1.0, -1.0)) === nothing

            # reflex angle, circle centered at the vertex: excludes exactly its own quadrant slice
            reflex = APAngle2(P(0.0, 0.0), P(1.0, 0.0), P(0.0, -1.0))   # excludes the 4th quadrant
            reflex_piece = only(intersection(reflex, c))
            @test reflex_piece isa APCircularArc2 && isapprox(measure(reflex_piece), 3pi / 2; atol=1e-9)

            # clipping an existing arc further keeps it an arc, restricted correctly
            top_half = APCircularArc2(c, P(3.0, 0.0), P(-3.0, 0.0))   # 0 to 180 degrees
            quarter = intersection(hp, top_half)
            @test quarter isa APCircularArc2 && isapprox(quarter, APCircularArc2(c, P(3.0, 0.0), P(0.0, 3.0)); atol=1e-9)

            # an ellipse behaves the same way through the same machinery
            e = APEllipse2(P(0.0, 0.0), 5.0, 3.0)
            e_piece = only(intersection(ang, e))
            @test e_piece isa APEllipticArc2 && isapprox(e_piece.p1, P(5.0, 0.0); atol=1e-9) && isapprox(e_piece.p2, P(0.0, 3.0); atol=1e-9)
        end
        @testset "region intersected with another region: whichever type it collapses to" begin
            P(x, y) = APPoint(x, y)
            O = P(0.0, 0.0)
            hp(x0, dir) = APHalfPlane2(APLine(P(x0, 0.0), P(x0, 4.0)), P(dir, 0.0))

            # halfplane vs halfplane
            @test intersection(hp(0.0, 10.0), hp(-5.0, 10.0)) == hp(0.0, 10.0)   # redundant, same direction
            @test intersection(hp(5.0, 10.0), hp(0.0, -10.0)) === nothing        # disjoint
            @test intersection(hp(0.0, 10.0), APHalfPlane2(APLine(P(0.0, 0.0), P(0.0, 4.0)), -1)) ==
                  APHalfPlane2(APLine(P(0.0, 0.0), P(0.0, 4.0)), -1)             # literally the same halfplane
            @test intersection(hp(0.0, 10.0), APHalfPlane2(APLine(P(0.0, 0.0), P(0.0, 4.0)), 1)) ==
                  APLine(P(0.0, 0.0), P(0.0, -4.0))                             # same line, opposite sides
            hp_y0 = APHalfPlane2(APLine(P(0.0, 0.0), P(4.0, 0.0)), P(0.0, 1.0))  # y >= 0
            wedge = intersection(hp(0.0, 10.0), hp_y0)
            @test wedge isa APAngle2 && isapprox(normalized_measure(wedge), pi / 2; atol=1e-9)

            # halfplane vs strip
            s = APStrip2(APLine(P(0.0, 0.0), P(1.0, 0.0)), APLine(P(0.0, 3.0), P(1.0, 3.0)))   # 0 <= y <= 3
            r = intersection(hp(0.0, 10.0), s)   # x >= 0
            @test r isa APUnboundedPolygon2
            @test P(2.0, 1.5) in r && !(P(-1.0, 1.5) in r) && !(P(2.0, 5.0) in r)
            @test distance(P(-3.0, 1.5), r) ≈ 3.0
            @test intersection(s, hp(0.0, 10.0)) == r   # reverse order
            @test intersection(APHalfPlane2(APLine(P(-5.0, 1.0), P(5.0, 1.0)), P(0.0, 3.0)), s) ==
                  APStrip2(APLine(P(-5.0, 1.0), P(5.0, 1.0)), APLine(P(0.0, 3.0), P(-1.0, 3.0)))   # y >= 1 tightens the strip
            @test intersection(APHalfPlane2(APLine(P(-5.0, 10.0), P(5.0, 10.0)), P(0.0, 20.0)), s) === nothing

            # strip vs strip
            s2 = APStrip2(APLine(P(0.0, 0.0), P(0.0, 1.0)), APLine(P(4.0, 0.0), P(4.0, 1.0)))   # 0 <= x <= 4
            @test intersection(s, s2) == APQuadrilateral(P(0.0, 0.0), P(4.0, 0.0), P(4.0, 3.0), P(0.0, 3.0))

            # convex angle vs halfplane/strip
            ang = APAngle2(O, P(4.0, 0.0), P(0.0, 4.0))   # first quadrant
            hp_cut = APHalfPlane2(APLine(P(6.0, 0.0), P(0.0, 6.0)), O)   # x + y <= 6
            @test only(intersection(ang, hp_cut)) == APTriangle(P(6.0, 0.0), P(0.0, 6.0), P(0.0, 0.0))
            hp_one_ray = APHalfPlane2(APLine(P(2.0, -5.0), P(2.0, 5.0)), O)   # x <= 2, crosses only one ray
            u = only(intersection(ang, hp_one_ray))
            @test u isa APUnboundedPolygon2 && P(1.0, 5.0) in u && !(P(3.0, 1.0) in u)
            @test only(intersection(ang, s)) isa APUnboundedPolygon2   # 1 <= y <= 3 clipped to x >= 0

            # reflex angle: distributes into up to 2 pieces
            reflex = APAngle2(O, P(1.0, 0.0), P(0.0, -1.0))   # excludes the 4th quadrant
            pieces = intersection(reflex, hp_cut)
            @test length(pieces) == 2
            @test any(p -> isapprox(p, APAngle2(P(6.0, 0.0), P(0.0, 6.0), P(5.0, 0.0)); atol=1e-9), pieces)
            @test any(p -> isapprox(p, APAngle2(P(0.0, 6.0), P(-6.0, 12.0), P(0.0, 5.0)); atol=1e-9), pieces)

            # angle vs angle: sharing only a boundary ray collapses to that ray
            ang2 = APAngle2(O, P(0.0, 4.0), P(-4.0, 0.0))   # second quadrant
            @test only(intersection(ang, ang2)) == APRay(O, P(0.0, 4.0))
            # a redundant halfplane already implied by ang leaves ang unchanged
            @test only(intersection(hp(0.0, 10.0), ang)) == ang
            # genuinely disjoint angles (different vertices, opening away from each other)
            ang3 = APAngle2(P(-10.0, 0.0), P(-11.0, 0.0), P(-10.0, -1.0))
            @test isempty(intersection(ang, ang3))

            # both operands reflex: distributes into up to 4 pieces (not merged
            # even when adjacent, see ap_region_intersections.jl)
            reflex2 = APAngle2(O, P(-1.0, 0.0), P(0.0, 1.0))
            both = intersection(reflex, reflex2)
            @test length(both) == 4
            @test count(p -> p isa APLine, both) == 2
            @test count(p -> p isa APAngle2, both) == 2
        end
        @testset "region intersected with a bounded straight-sided polygon" begin
            P(x, y) = APPoint(x, y)
            t = APTriangle(P(0.0, 0.0), P(4.0, 0.0), P(2.0, 4.0))

            # a halfplane crossing exactly at a vertex: no spurious duplicate vertex
            hp = APHalfPlane2(APLine(P(2.0, -5.0), P(2.0, 5.0)), P(0.0, 0.0))   # x <= 2
            @test intersection(hp, t) == APTriangle(P(0.0, 0.0), P(2.0, 0.0), P(2.0, 4.0))
            @test intersection(t, hp) == intersection(hp, t)   # reverse order

            # fully inside / fully outside
            @test intersection(APHalfPlane2(APLine(P(-5.0, -1.0), P(5.0, -1.0)), P(0.0, 10.0)), t) == t
            @test intersection(APHalfPlane2(APLine(P(-5.0, 10.0), P(5.0, 10.0)), P(0.0, 20.0)), t) === nothing

            # a strip cuts both ends off, leaving a quadrilateral
            s = APStrip2(APLine(P(-5.0, 1.0), P(5.0, 1.0)), APLine(P(-5.0, 3.0), P(5.0, 3.0)))
            r = intersection(s, t)
            @test r isa APQuadrilateral
            @test Set(vertices(r)) == Set([P(0.5, 1.0), P(3.5, 1.0), P(2.5, 3.0), P(1.5, 3.0)])

            # a convex angle already containing the whole triangle leaves it unchanged;
            # any pair involving APAngle2 always comes back as a Vector
            ang = APAngle2(P(0.0, 0.0), P(4.0, 0.0), P(0.0, 4.0))
            @test only(intersection(ang, t)) == t

            # a reflex angle can split it into two disjoint pieces
            reflex = APAngle2(P(2.0, 2.0), P(6.0, 2.0), P(2.0, -2.0))
            @test rad2deg(normalized_measure(reflex)) ≈ 270.0
            pieces = intersection(reflex, t)
            @test length(pieces) == 2 && all(pc -> pc isa APTriangle, pieces)

            # a pentagon (APStraightNgon) clipped to 5 vertices, and a square clipped to 4
            pent = APStraightNgon([P(0.0, 0.0), P(4.0, 0.0), P(5.0, 3.0), P(2.0, 5.0), P(-1.0, 3.0)])
            rp = intersection(APHalfPlane2(APLine(P(0.0, 2.0), P(4.0, 2.0)), P(0.0, 10.0)), pent)
            @test rp isa APStraightNgon && length(rp.vertices) == 5
            q = APQuadrilateral(P(0.0, 0.0), P(6.0, 0.0), P(6.0, 6.0), P(0.0, 6.0))
            rq = intersection(s, q)
            @test rq isa APQuadrilateral && Set(vertices(rq)) == Set([P(0.0, 1.0), P(6.0, 1.0), P(6.0, 3.0), P(0.0, 3.0)])

            # numeric ground-truth check, sampled off any exact-boundary point
            # (Base.in for APPolygon may return either value exactly on an edge)
            function check(region, pg; grid=-1.13:0.197:6.07)
                r = intersection(region, pg)
                pieces = r isa Vector ? r : [r]
                contains(obj, p) = obj isa APPoint ? isapprox(obj, p; atol=1e-6) : (obj isa APSegment ? is_on_segment(p, obj; atol=1e-6) : p in obj)
                all(Iterators.product(grid, grid)) do (x, y)
                    p = P(x, y)
                    expected = (p in region) && (p in pg)
                    got = any(pc -> pc !== nothing && contains(pc, p), pieces)
                    expected == got
                end
            end
            @test check(hp, t)
            @test check(s, t)
            @test check(ang, t)
            @test check(reflex, t)
            @test check(s, q; grid=-1.13:0.197:7.07)
        end
        @testset "APUnboundedPolygon2" begin
            P(x, y) = APPoint(x, y)
            u = APUnboundedPolygon2(APRay(P(0.0, 3.0), P(1.0, 3.0)), APPoint{2,Float64}[], APRay(P(0.0, 0.0), P(1.0, 0.0)))
            @test vertices(u) == [P(0.0, 3.0), P(0.0, 0.0)]
            @test P(2.0, 1.5) in u && !(P(-1.0, 1.5) in u) && !(P(2.0, 5.0) in u)
            @test distance(P(2.0, 1.5), u) == 0.0
            @test distance(P(-3.0, 1.5), u) ≈ 3.0
            @test distance(P(2.0, 10.0), u; mode=:boundary) ≈ 7.0
            @test APBoundingBox(u) == APBoundingBox()

            pts = [P(x, y) for x in -3.0:1.5:6.0 for y in -3.0:1.5:6.0]
            transforms = [
                p -> rotate(p, pi / 3), p -> translate(p, APVector(2.0, -1.0)),
                p -> homothety(p, 1.7), p -> reflection(p, P(1.0, 1.0)),
                p -> reflection(p, APLine(P(0.0, 0.0), P(1.0, 1.0))),
            ]
            objs = [
                rotate(u, pi / 3), translate(u, APVector(2.0, -1.0)),
                homothety(u, 1.7), reflection(u, P(1.0, 1.0)),
                reflection(u, APLine(P(0.0, 0.0), P(1.0, 1.0))),
            ]
            for (T, obj) in zip(transforms, objs)
                @test all((p in u) == (T(p) in obj) for p in pts)
            end

            m = APAffineMap(2.0, 0.0, 0.0, 1.0, 5.0, -3.0)
            um = m(u)
            @test um isa APUnboundedPolygon2
            @test all((p in u) == (m(p) in um) for p in pts)
        end
    end
    @testset "APParabolicRay2, APHyperbolicRay2, APHyperbolaBranch2" begin
        P(x, y) = APPoint(x, y)
        par = APParabola2(P(0.0, 1.0), APLine(P(-5.0, -1.0), P(5.0, -1.0)))   # vertex (0,0), y = x^2/4
        ray = APParabolicRay2(par, point_on(par, 2.0), 1)   # from (-2,1), toward s -> +inf (x -> -inf)
        @test point_on(par, 5.0) in ray
        @test !(point_on(par, 0.0) in ray)
        @test point_on(par, 2.0) in ray
        @test distance(P(-2.0, 1.0), ray) == 0.0
        @test distance(P(0.0, 0.0), ray) ≈ sqrt(5.0)   # vertex excluded: falls back to ray's own endpoint
        @test APBoundingBox(ray) == APBoundingBox()

        h = APHyperbola2(P(0.0, 0.0), 1.0, 1.0, 0.0)
        hray = APHyperbolicRay2(h, point_on(h, 1.0; branch=1), 1, 1)
        @test point_on(h, 3.0; branch=1) in hray
        @test !(point_on(h, -1.0; branch=1) in hray)
        @test !(point_on(h, 1.0; branch=-1) in hray)   # wrong branch

        b = APHyperbolaBranch2(h, -1)
        @test point_on(h, 2.0; branch=-1) in b
        @test !(point_on(h, 2.0; branch=1) in b)
        @test distance(P(0.0, 0.0), b) ≈ 1.0   # closest point is the branch's own vertex

        pts = [P(x, y) for x in -6.0:0.7:6.0 for y in -6.0:0.7:6.0]
        for obj in (ray, hray, b)
            @test all((p in obj) == (rotate(p, pi / 5) in rotate(obj, pi / 5)) for p in pts)
            @test all((p in obj) == (translate(p, APVector(1.0, 2.0)) in translate(obj, APVector(1.0, 2.0))) for p in pts)
            @test all((p in obj) == (homothety(p, 1.3) in homothety(obj, 1.3)) for p in pts)
            @test all((p in obj) == (reflection(p, P(1.0, 1.0)) in reflection(obj, P(1.0, 1.0))) for p in pts)
            mirror = APLine(P(0.0, 0.0), P(1.0, 1.0))
            @test all((p in obj) == (reflection(p, mirror) in reflection(obj, mirror)) for p in pts)
            m = APAffineMap(2.0, 0.0, 0.0, 1.0, 5.0, -3.0)
            @test all((p in obj) == (m(p) in m(obj)) for p in pts)
        end
    end
    @testset "region intersected with a parabola or hyperbola: always a Vector" begin
        P(x, y) = APPoint(x, y)
        par = APParabola2(P(0.0, 1.0), APLine(P(-5.0, -1.0), P(5.0, -1.0)))   # y = x^2/4
        h = APHyperbola2(P(0.0, 0.0), 1.0, 1.0, 0.0)

        # a single halfplane crossing a parabola ONCE, transversally (not tangent):
        # exactly one side survives, as the new ray type
        hp_le2 = APHalfPlane2(APLine(P(2.0, -10.0), P(2.0, 10.0)), P(-10.0, 0.0))   # x <= 2
        r1 = only(intersection(hp_le2, par))
        @test r1 isa APParabolicRay2 && isapprox(r1.p, P(2.0, 1.0); atol=1e-9) && r1.dir == 1

        # crossing TWICE with the middle excluded: two disjoint rays, from one halfplane alone
        hp_ge4 = APHalfPlane2(APLine(P(-5.0, 4.0), P(5.0, 4.0)), P(0.0, 10.0))   # y >= 4
        r2 = intersection(hp_ge4, par)
        @test length(r2) == 2 && all(pc -> pc isa APParabolicRay2, r2)
        @test all(pc -> isapprox(abs(pc.p[1]), 4.0; atol=1e-9) && isapprox(pc.p[2], 4.0; atol=1e-9), r2)

        # crossing twice with the middle kept: a single bounded arc
        hp_le4 = APHalfPlane2(APLine(P(-5.0, 4.0), P(5.0, 4.0)), P(0.0, -10.0))   # y <= 4
        r3 = only(intersection(hp_le4, par))
        @test r3 isa APParabolicArc2 && isapprox(r3, APParabolicArc2(par, P(4.0, 4.0), P(-4.0, 4.0)); atol=1e-9)

        # entirely inside / entirely outside
        @test only(intersection(APHalfPlane2(APLine(P(-5.0, -10.0), P(5.0, -10.0)), P(0.0, 10.0)), par)) == par
        @test isempty(intersection(APHalfPlane2(APLine(P(-5.0, -10.0), P(5.0, -10.0)), P(0.0, -100.0)), par))

        # tangent at the vertex: from outside, only the touch point; from inside, the whole thing
        @test only(intersection(APHalfPlane2(APLine(P(-5.0, 0.0), P(5.0, 0.0)), P(0.0, -10.0)), par)) ≈ P(0.0, 0.0)
        @test only(intersection(APHalfPlane2(APLine(P(-5.0, 0.0), P(5.0, 0.0)), P(0.0, 10.0)), par)) == par

        # a hyperbola: one branch untouched (APHyperbolaBranch2), the other clipped to an arc
        hp_le2h = APHalfPlane2(APLine(P(2.0, -10.0), P(2.0, 10.0)), P(-10.0, 0.0))   # x <= 2
        r4 = intersection(hp_le2h, h)
        @test length(r4) == 2
        @test count(pc -> pc isa APHyperbolaBranch2 && pc.branch == -1, r4) == 1
        arc4 = only(filter(pc -> pc isa APHyperbolicArc2, r4))
        @test isapprox(abs(arc4.p1[1]), 2.0; atol=1e-9) && isapprox(abs(arc4.p2[1]), 2.0; atol=1e-9)

        # a strip chains both boundaries: each branch clipped to its own arc
        s = APStrip2(APLine(P(-1.5, -10.0), P(-1.5, 10.0)), APLine(P(1.5, -10.0), P(1.5, 10.0)))
        r5 = intersection(s, h)
        @test length(r5) == 2 && all(pc -> pc isa APHyperbolicArc2, r5)

        # re-clipping an already-existing arc keeps it within its own range
        arc = APHyperbolicArc2(h, point_on(h, -2.0; branch=1), point_on(h, 2.0; branch=1))
        @test only(intersection(hp_le2h, arc)) ≈ arc4

        # convex angle vs reflex angle: complementary results (an arc vs the two outer rays)
        ang = APAngle2(P(0.0, 4.0), P(-10.0, 3.0), P(10.0, 3.0))
        reflex = APAngle2(P(0.0, 4.0), P(10.0, 3.0), P(-10.0, 3.0))
        @test only(intersection(ang, par)) isa APParabolicArc2
        r6 = intersection(reflex, par)
        @test length(r6) == 2 && all(pc -> pc isa APParabolicRay2, r6)

        # numeric ground-truth check, sampled along the curve's own parameter,
        # for every case above plus one more (angle vs hyperbola)
        function check_parabola(region, curve; srange=-10.0:0.2:10.0)
            pieces = intersection(region, curve)
            all(srange) do s
                p = point_on(curve, s)
                expected = p in region
                got = any(pc -> pc isa APPoint ? isapprox(pc, p; atol=1e-6) : (p in pc), pieces)
                expected == got
            end
        end
        function check_hyperbola(region, hh; trange=-4.0:0.1:4.0)
            pieces = intersection(region, hh)
            all(Iterators.product((1, -1), trange)) do (branch, t)
                p = point_on(hh, t; branch=branch)
                expected = p in region
                got = any(pc -> pc isa APPoint ? isapprox(pc, p; atol=1e-6) : (p in pc), pieces)
                expected == got
            end
        end
        @test check_parabola(hp_ge4, par)
        @test check_parabola(ang, par)
        @test check_parabola(reflex, par)
        @test check_hyperbola(s, h)
        @test check_hyperbola(hp_le2h, h)
        @test check_hyperbola(APAngle2(P(0.0, 0.0), P(3.0, 1.0), P(3.0, -1.0)), h)
    end
    @testset "APAffineMap" begin
        src = (APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
        dst = (APPoint(2.0, 3.0), APPoint(5.0, 3.0), APPoint(2.0, 7.0))
        m = affine_map(src, dst)
        for (s, d) in zip(src, dst)
            @test isapprox(m(s), d; atol=1e-9)
        end
        p1, p2, p3 = APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(1.0, 0.0)
        @test_throws ArgumentError affine_map((p1, p2, p3), (p1, p2, p3))
        pair_map = affine_map(src[1] => dst[1], src[2] => dst[2], src[3] => dst[3])   # three source => image pairs
        @test pair_map == m
        @test_throws ArgumentError affine_map(p1 => p1, p2 => p2, p3 => p3)   # collinear sources
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
        c = APCircle2(APPoint(0.0, 0.0), 1.0)
        shear = APAffineMap(1.0, 0.5, 0.0, 1.0, 0.0, 0.0)
        ell = shear(c)
        @test ell isa APEllipse2
        circle_as_ellipse = APEllipse2(c.center, c.r, c.r, 0.0)
        for t in (0.0, 0.3, 1.1, 2.5, 4.0)
            @test is_on_ellipse(shear(point_on(circle_as_ellipse, t)), ell; atol=1e-6)
        end
        vec = APVector(1.0, 0.0)
        @test isapprox(rmap(vec), APVector(cos(pi / 3), sin(pi / 3)); atol=1e-9)
        @test isapprox(tmap(vec), vec; atol=1e-9)
        vvec = APVector(3.0, -2.0)
        @test isapprox(translation_map(vvec)(p), translation_map(v)(p); atol=1e-9)
    end
    @testset "curried transform/predicate forms" begin
        t = APTriangle(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 3.0))
        O = APPoint(0.0, 0.0)
        c = APCircle2(APPoint(1.0, 2.0), 5.0)
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
        composed = rotate(pi / 2) ∘ translate(v)
        @test composed isa Function && !(composed isa APAffineMap)
        @test composed(t) == rotate(translate(t, v), pi / 2)
        @test t |> translate(v) |> rotate(pi / 2) == composed(t)
        @test composed(c) isa APCircle2
        mapped = map(translate(v), [t, t])
        @test mapped[1] == translate(t, v) && mapped[2] == translate(t, v)
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
        composed_map = rotation_map(pi / 2, O) ∘ translation_map(v)
        @test composed_map isa APAffineMap
        @test isapprox(composed_map(t), rotate(translate(t, v), pi / 2); atol=1e-9)
        @test isapprox(t |> translation_map(v) |> rotation_map(pi / 2, O), composed_map(t); atol=1e-9)
        @test translation_map(v)(c) isa APCircle2
        mapped_map = map(rotation_map(pi / 2, O), [t, t])
        @test isapprox(mapped_map[1], rotate(t, pi / 2); atol=1e-9) && isapprox(mapped_map[2], rotate(t, pi / 2); atol=1e-9)
        center = APPoint(0.0, 0.0)
        l_offset = APLine(APPoint(2.0, 0.0), APPoint(2.0, 1.0))
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
        @test is_on_line(lx)(mid) == is_on_line(mid, lx)
        @test is_on_segment(s)(mid) == is_on_segment(mid, s)
        @test is_on_ray(r)(mid) == is_on_ray(mid, r)
        @test filter(is_on_line(lx), [mid, APPoint(1.0, 1.0)]) == [mid]
        @test in(t) isa Base.Fix2
        @test in(t)(APPoint(1.0, 1.0)) == (APPoint(1.0, 1.0) in t)
    end
    @testset "AP predicates" begin
        a, b, c = APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(1.0, 0.0)
        @test is_collinear(a, b, c)
        @test !is_collinear(a, b, APPoint(1.0, 1.0))
        l = APLine(APPoint(0.0, 0.0), APPoint(2.0, 0.0))
        @test is_on_line(APPoint(5.0, 0.0), l)
        @test !is_on_line(APPoint(5.0, 1.0), l)
        s = APSegment(APPoint(0.0, 0.0), APPoint(2.0, 0.0))
        @test is_on_segment(APPoint(1.0, 0.0), s)
        @test !is_on_segment(APPoint(5.0, 0.0), s)
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
        @test is_parallel(APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0)), APLine(APPoint(0.0, 1.0), APPoint(1.0, 1.0)))
        @test is_perpendicular(APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0)), APLine(APPoint(0.0, 0.0), APPoint(0.0, 1.0)))
    end
    @testset "AP intersections" begin
        l1 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
        l2 = APLine(APPoint(0.0, -1.0), APPoint(0.0, 1.0))
        @test intersection(l1, l2) == [APPoint(0.0, 0.0)]
        l3 = APLine(APPoint(0.0, 1.0), APPoint(1.0, 1.0))
        @test isempty(intersection(l1, l3))
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
        @test isempty(intersection(s2, s3))
        @testset "APSegment against APLine/APCircle2/every conic" begin
            l = APLine(APPoint(0.0, 0.0), APPoint(10.0, 0.0))
            sc = APCircle2(APPoint(5.0, 0.0), 5.0)   # diameter [0,10] x-axis
            crossing = APSegment(APPoint(0.0, -1.0), APPoint(0.0, 1.0))
            @test intersection(crossing, l) == [APPoint(0.0, 0.0)]
            @test intersection(l, crossing) == intersection(crossing, l)
            short_of_it = APSegment(APPoint(0.0, 1.0), APPoint(0.0, 5.0))
            @test isempty(intersection(short_of_it, l))

            full_diameter = APSegment(APPoint(-10.0, 0.0), APPoint(20.0, 0.0))
            @test Set(intersection(full_diameter, sc)) == Set([APPoint(0.0, 0.0), APPoint(10.0, 0.0)])
            @test intersection(sc, full_diameter) == intersection(full_diameter, sc)
            strictly_inside = APSegment(APPoint(4.0, 0.0), APPoint(6.0, 0.0))
            @test isempty(intersection(strictly_inside, sc))   # never reaches the circle's boundary

            se = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
            @test Set(intersection(APSegment(APPoint(-10.0, 0.0), APPoint(10.0, 0.0)), se)) ==
                  Set([APPoint(5.0, 0.0), APPoint(-5.0, 0.0)])
            @test intersection(se, APSegment(APPoint(-10.0, 0.0), APPoint(10.0, 0.0))) ==
                  intersection(APSegment(APPoint(-10.0, 0.0), APPoint(10.0, 0.0)), se)

            sh = APHyperbola2(APPoint(0.0, 0.0), 2.0, 1.0)
            @test intersection(APSegment(APPoint(0.0, 0.0), APPoint(10.0, 0.0)), sh) == [APPoint(2.0, 0.0)]
            @test intersection(sh, APSegment(APPoint(0.0, 0.0), APPoint(10.0, 0.0))) ==
                  intersection(APSegment(APPoint(0.0, 0.0), APPoint(10.0, 0.0)), sh)

            spar = APParabola2(APPoint(0.0, 1.0), APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0)))
            above = APSegment(APPoint(-5.0, 5.0), APPoint(5.0, 5.0))
            pts = intersection(above, spar)
            @test length(pts) == 2 && all(p -> is_on_parabola(p, spar; atol=1e-9), pts)
            @test intersection(spar, above) == pts
        end
        @testset "APRay against APLine/APSegment/APCircle2/APRay/every conic" begin
            O = APPoint(0.0, 0.0)
            r_right = APRay(O, APPoint(1.0, 0.0))
            r_left = APRay(O, APPoint(-1.0, 0.0))

            l_vert = APLine(APPoint(5.0, -5.0), APPoint(5.0, 5.0))
            @test intersection(r_right, l_vert) == [APPoint(5.0, 0.0)]
            @test isempty(intersection(r_left, l_vert))   # behind the origin, wrong direction
            @test intersection(l_vert, r_right) == intersection(r_right, l_vert)

            rc = APCircle2(APPoint(10.0, 0.0), 3.0)
            @test Set(intersection(r_right, rc)) == Set([APPoint(7.0, 0.0), APPoint(13.0, 0.0)])
            @test isempty(intersection(r_left, rc))
            @test intersection(rc, r_right) == intersection(r_right, rc)

            rs = APSegment(APPoint(3.0, -3.0), APPoint(3.0, 3.0))
            @test intersection(r_right, rs) == [APPoint(3.0, 0.0)]
            @test intersection(rs, r_right) == intersection(r_right, rs)
            @test isempty(intersection(r_left, rs))

            r2 = APRay(APPoint(10.0, -10.0), APPoint(5.0, 0.0))
            @test intersection(r_right, r2) == [APPoint(5.0, 0.0)]
            @test isempty(intersection(r_left, r2))   # r_left never reaches x=5

            re = APEllipse2(APPoint(8.0, 0.0), 3.0, 2.0)
            re_pts = sort(intersection(r_right, re); by=p -> p[1])
            @test isapprox(re_pts[1], APPoint(5.0, 0.0); atol=1e-9) && isapprox(re_pts[2], APPoint(11.0, 0.0); atol=1e-9)
            @test intersection(re, r_right) == intersection(r_right, re)

            rh = APHyperbola2(APPoint(0.0, 0.0), 2.0, 1.0)
            @test intersection(r_right, rh) == [APPoint(2.0, 0.0)]
            @test intersection(rh, r_right) == intersection(r_right, rh)

            rpar = APParabola2(APPoint(0.0, 1.0), APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0)))
            r_up = APRay(O, APPoint(0.0, 1.0))
            @test intersection(r_up, rpar) == [APPoint(0.0, 0.0)]
            @test intersection(rpar, r_up) == intersection(r_up, rpar)
        end
        @testset "conic arcs against APLine/APSegment/APRay/APCircle2/APCircularArc2" begin
            circ = APCircle2(APPoint(0.0, 0.0), 5.0)
            arc = APCircularArc2(circ, APPoint(5.0, 0.0), APPoint(0.0, 5.0))   # first-quadrant quarter
            l = APLine(APPoint(-10.0, 2.5), APPoint(10.0, 2.5))
            expected = APPoint(sqrt(25 - 2.5^2), 2.5)
            @test isapprox(only(intersection(l, arc)), expected; atol=1e-9)
            @test intersection(arc, l) == intersection(l, arc)
            @test isempty(intersection(APLine(APPoint(-10.0, -2.5), APPoint(10.0, -2.5)), arc))   # wrong quadrant
            s = APSegment(APPoint(-10.0, 2.5), APPoint(10.0, 2.5))
            @test isapprox(only(intersection(s, arc)), expected; atol=1e-9)
            @test intersection(arc, s) == intersection(s, arc)
            r = APRay(APPoint(0.0, 2.5), APPoint(10.0, 2.5))
            @test isapprox(only(intersection(r, arc)), expected; atol=1e-9)
            @test intersection(arc, r) == intersection(r, arc)
            @test isempty(intersection(APRay(APPoint(0.0, 2.5), APPoint(-10.0, 2.5)), arc))   # points away from arc
            c2 = APCircle2(APPoint(5.0, 5.0), 5.0)
            c2pts = intersection(c2, arc)
            @test length(c2pts) == 2
            @test all(p -> isapprox(distance(p, circ.center), 5.0; atol=1e-6), c2pts)
            @test intersection(arc, c2) == c2pts
            other_circ = APCircle2(APPoint(5.0, 0.0), 5.0)   # p1/p2 are opposite ends of a diameter -> lower half
            other_arc = APCircularArc2(other_circ, APPoint(0.0, 0.0), APPoint(10.0, 0.0))
            @test isempty(intersection(arc, other_arc))   # the two circle-circle points land in disjoint quadrants
            e = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
            earc = APEllipticArc2(e, APPoint(5.0, 0.0), APPoint(0.0, 3.0))
            el = APLine(APPoint(-10.0, 1.5), APPoint(10.0, 1.5))
            epts = intersection(el, earc)
            @test length(epts) == 1 && is_on_ellipse(epts[1], e; atol=1e-9) && epts[1][1] > 0
            @test intersection(earc, el) == epts
            h = APHyperbola2(APPoint(0.0, 0.0), 2.0, 1.0)
            harc = APHyperbolicArc2(h, point_on(h, -1.0), point_on(h, 1.0))
            hl = APLine(APPoint(0.0, -10.0), APPoint(0.0, 10.0))
            @test isempty(intersection(hl, harc))   # the branch never crosses x=0
            par = APParabola2(APPoint(0.0, 1.0), APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0)))
            parc = APParabolicArc2(par, point_on(par, -3.0), point_on(par, 3.0))
            pl = APLine(APPoint(-10.0, 1.0), APPoint(10.0, 1.0))
            ppts = intersection(pl, parc)
            @test length(ppts) == 2 && all(p -> is_on_parabola(p, par; atol=1e-9), ppts)
            @test intersection(parc, pl) == ppts
            far_line = APLine(APPoint(-10.0, 5.0), APPoint(10.0, 5.0))   # meets the full parabola outside the arc's own sweep
            @test isempty(intersection(far_line, parc))
        end
        @testset "general conic-vs-conic intersection (ellipse/hyperbola/parabola, any pair)" begin
            # hand-verifiable: circle r=5 and axis-aligned ellipse a=4,b=3, both centered at the origin -- no real solution
            cc0 = APCircle2(APPoint(0.0, 0.0), 5.0)
            ee0 = APEllipse2(APPoint(0.0, 0.0), 4.0, 3.0)
            @test isempty(intersection(cc0, ee0))
            @test isempty(intersection(ee0, cc0))
            # hand-verifiable, and a repeated-root case (both curves share the y-axis as an axis of symmetry):
            # circle r=5, ellipse a=6,b=2, both centered at the origin -> y^2 = 11/8 exactly, each with 2 x-values
            ee1 = APEllipse2(APPoint(0.0, 0.0), 6.0, 2.0)
            pts1 = intersection(cc0, ee1)
            @test length(pts1) == 4
            @test all(p -> isapprox(abs(p[2]), sqrt(11 / 8); atol=1e-6), pts1)
            @test all(p -> isapprox(distance(p, cc0.center), 5.0; atol=1e-6) && is_on_ellipse(p, ee1; atol=1e-6), pts1)
            pts1_swapped = intersection(ee1, cc0)
            @test length(pts1_swapped) == length(pts1) &&
                  all(p -> any(q -> isapprox(p, q; atol=1e-6), pts1_swapped), pts1)
            # generic ellipse-ellipse, ellipse-hyperbola, hyperbola-hyperbola, ellipse-parabola,
            # hyperbola-parabola, parabola-parabola, circle-hyperbola, circle-parabola: every point
            # returned must lie on both curves (checked via each curve's own independent `is_on_*`)
            e1 = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
            e2 = APEllipse2(APPoint(2.0, 1.0), 4.0, 2.0, 0.4)
            pe = intersection(e1, e2)
            @test length(pe) == 2
            @test all(p -> is_on_ellipse(p, e1; atol=1e-6) && is_on_ellipse(p, e2; atol=1e-6), pe)
            h1 = APHyperbola2(APPoint(2.0, 0.0), 2.0, 1.5, 0.3)
            peh = intersection(e1, h1)
            @test length(peh) == 4
            @test all(p -> is_on_ellipse(p, e1; atol=1e-6) && is_on_hyperbola(p, h1; atol=1e-6), peh)
            h2 = APHyperbola2(APPoint(-1.0, 1.0), 3.0, 2.0, 1.1)
            phh = intersection(h1, h2)
            @test all(p -> is_on_hyperbola(p, h1; atol=1e-6) && is_on_hyperbola(p, h2; atol=1e-6), phh)
            par1 = APParabola2(APPoint(0.0, 3.0), APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0)))
            pep = intersection(e1, par1)
            @test all(p -> is_on_ellipse(p, e1; atol=1e-6) && is_on_parabola(p, par1; atol=1e-6), pep)
            phhp = intersection(h1, par1)
            @test all(p -> is_on_hyperbola(p, h1; atol=1e-6) && is_on_parabola(p, par1; atol=1e-6), phhp)
            par2 = APParabola2(APPoint(1.0, -2.0), APLine(APPoint(-4.0, 2.0), APPoint(4.0, 2.0)))
            ppp = intersection(par1, par2)
            @test all(p -> is_on_parabola(p, par1; atol=1e-6) && is_on_parabola(p, par2; atol=1e-6), ppp)
            pch = intersection(cc0, h1)
            @test all(p -> isapprox(distance(p, cc0.center), cc0.r; atol=1e-6) && is_on_hyperbola(p, h1; atol=1e-6), pch)
            pcp = intersection(cc0, par1)
            @test all(p -> isapprox(distance(p, cc0.center), cc0.r; atol=1e-6) && is_on_parabola(p, par1; atol=1e-6), pcp)
        end
        @testset "general conic intersection stays accurate far from the origin" begin
            # same relative ellipse pair, translated by increasingly large offsets: without
            # recentering internally, the implicit-form coefficients grow with absolute
            # position and the elimination step squares them, losing enough precision by
            # offset ~1e4 to return points that don't actually lie on either curve
            for offset in (0.0, 1e3, 1e4, 1e5, 1e6, 1e9)
                oe1 = APEllipse2(APPoint(offset, offset), 5.0, 3.0)
                oe2 = APEllipse2(APPoint(offset + 7.0, offset + 1.0), 4.0, 2.0, 0.3)
                opts = intersection(oe1, oe2)
                @test length(opts) == 2
                @test all(p -> is_on_ellipse(p, oe1; atol=1e-6) && is_on_ellipse(p, oe2; atol=1e-6), opts)
            end
        end
        @testset "general conic intersection reaches conic arcs of any type" begin
            e1 = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
            h1 = APHyperbola2(APPoint(2.0, 0.0), 2.0, 1.5, 0.3)
            circ = APCircle2(APPoint(0.0, 0.0), 5.0)
            earc = APEllipticArc2(e1, point_on(e1, -0.5), point_on(e1, 1.5))
            # elliptic arc against a full circle (previously impossible: different conic types)
            pts_ec = intersection(earc, circ)
            full_ec = intersection(e1, circ)
            expected_ec = filter(p -> in(p, earc; atol=1e-9), full_ec)
            @test length(pts_ec) == length(expected_ec) && all(p -> any(q -> isapprox(p, q; atol=1e-6), expected_ec), pts_ec)
            pts_ce = intersection(circ, earc)
            @test length(pts_ce) == length(pts_ec) && all(p -> any(q -> isapprox(p, q; atol=1e-6), pts_ec), pts_ce)
            # elliptic arc against a hyperbolic arc (different conic types entirely)
            harc = APHyperbolicArc2(h1, point_on(h1, -1.0), point_on(h1, 1.0))
            pts_eh = intersection(earc, harc)
            full_eh = intersection(e1, h1)
            expected_eh = filter(p -> in(p, earc; atol=1e-9) && in(p, harc; atol=1e-9), full_eh)
            @test length(pts_eh) == length(expected_eh) && all(p -> any(q -> isapprox(p, q; atol=1e-6), expected_eh), pts_eh)
            @test !isempty(pts_eh)   # this specific pair genuinely shares points, not just a vacuous check
            pts_he = intersection(harc, earc)
            @test length(pts_he) == length(pts_eh) &&
                  all(p -> any(q -> isapprox(p, q; atol=1e-6), pts_he), pts_eh)
        end
        c1 = APCircle2(APPoint(0.0, 0.0), 5.0)
        c2 = APCircle2(APPoint(8.0, 0.0), 5.0)
        cpts = intersection(c1, c2)
        @test length(cpts) == 2
        @test all(p -> isapprox(distance(p, c1.center), 5.0; atol=1e-9) && isapprox(distance(p, c2.center), 5.0; atol=1e-9), cpts)
        c3 = APCircle2(APPoint(10.0, 0.0), 5.0)
        @test length(intersection(c1, c3)) == 1
        c4 = APCircle2(APPoint(0.0, 0.0), 3.0)
        @test isempty(intersection(c1, c4))
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
        @test is_on_line(APPoint(2.0, 0.0), pb)
        @test is_perpendicular(pb, APLine(APPoint(0.0, 0.0), APPoint(4.0, 0.0)))
        @test perpendicular_bisector(APSegment(APPoint(0.0, 0.0), APPoint(4.0, 0.0))) == pb
        l1 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
        l2 = APLine(APPoint(0.0, 0.0), APPoint(0.0, 1.0))
        bisectors = angle_bisectors(l1, l2)
        @test length(bisectors) == 2
        @test all(b -> isapprox(abs(angle_measure_between(direction(l1), direction(b))), pi / 4; atol=1e-6) ||
                       isapprox(abs(angle_measure_between(direction(l1), direction(b))), 3pi / 4; atol=1e-6), bisectors)
        tris = angle_trisectors(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
        @test length(tris) == 2
        @testset "angle_bisectors/angle_trisectors(::APAngle2)" begin
            ang = APAngle2(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
            h1, h2 = angle_bisectors(ang)
            @test h1.vertex == ang.vertex && h1.a == ang.a && h2.b == ang.b
            @test h1.b == h2.a
            @test isapprox(measure(h1), measure(h2); atol=1e-9)
            @test isapprox(measure(h1) + measure(h2), measure(ang); atol=1e-9)
            t1, t2, t3 = angle_trisectors(ang)
            @test t1.a == ang.a && t3.b == ang.b
            @test t1.b == t2.a && t2.b == t3.a
            @test isapprox(measure(t1), measure(t2); atol=1e-9) && isapprox(measure(t2), measure(t3); atol=1e-9)
            @test isapprox(measure(t1) + measure(t2) + measure(t3), measure(ang); atol=1e-9)
        end
        gr = golden_ratio_point(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
        @test gr[1] ≈ 1 / Base.MathConstants.golden atol = 1e-9
        @test golden_ratio_point(APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))) == gr
        a, b = APPoint(0.0, 0.0), APPoint(4.0, 0.0)
        q = harmonic_conjugate(a, b, APPoint(1.0, 0.0))
        cr = ((1.0 - a[1]) / (1.0 - b[1])) / ((q[1] - a[1]) / (q[1] - b[1]))
        @test cr ≈ -1.0 atol = 1e-6
        @test_throws ArgumentError harmonic_conjugate(a, b, midpoint(a, b))
        ac = apollonius_circle(APPoint(0.0, 0.0), APPoint(4.0, 0.0), 2.0)
        testpt = point_on(APEllipse2(ac.center, ac.r, ac.r, 0.0), 0.7)
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
        @test is_on_segment(isc, APSegment(c1.center, c2.center))
        @test_throws ArgumentError external_similitude_center(APCircle2(APPoint(0.0, 0.0), 3.0), APCircle2(APPoint(1.0, 0.0), 3.0))
        tk = APTriangle(APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(2.0, 4.0))
        ak, bk, ck = distance(tk[2], tk[3]), distance(tk[1], tk[3]), distance(tk[1], tk[2])
        x55 = trilinear_point(tk, ak * (bk + ck - ak), bk * (ck + ak - bk), ck * (ak + bk - ck))
        x56 = trilinear_point(tk, ak / (bk + ck - ak), bk / (ck + ak - bk), ck / (ak + bk - ck))
        @test internal_similitude_center(circumcircle(tk), incircle(tk)) ≈ x55 atol = 1e-6   # Kimberling X(55)
        @test external_similitude_center(circumcircle(tk), incircle(tk)) ≈ x56 atol = 1e-6   # Kimberling X(56)
        etl = external_tangent_lines(c1, c2)
        @test length(etl) == 2
        @test all(l -> line_circle_position(l, c1) == :tangent && line_circle_position(l, c2) == :tangent, etl)
        itl = internal_tangent_lines(c1, c2)
        @test length(itl) == 2
        @test all(l -> line_circle_position(l, c1) == :tangent && line_circle_position(l, c2) == :tangent, itl)
        ol = offset_line(APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0)), 3.0)
        @test distance(APPoint(0.0, 0.0), ol) ≈ 3.0 atol = 1e-9
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
    @testset "AP radical axis and invert" begin
        c1 = APCircle2(APPoint(0.0, 0.0), 5.0)
        c2 = APCircle2(APPoint(8.0, 0.0), 5.0)
        @test power_of_point(APPoint(5.0, 0.0), c1) ≈ 0.0 atol = 1e-9
        @test power_of_point(c1.center, c1) ≈ -25.0 atol = 1e-9
        ra = radical_axis(c1, c2)
        @test all(p -> is_on_line(p, ra; atol=1e-6), intersection(c1, c2))
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
        pinv = invert(p, c)
        @test distance(p, c.center) * distance(pinv, c.center) ≈ 25.0 atol = 1e-9
        @test isapprox(pinv, APPoint(2.5, 0.0); atol=1e-9)
        @test isapprox(invert(pinv, c), p; atol=1e-9)
        @test_throws ArgumentError invert(c.center, c)
        l = APLine(APPoint(10.0, -5.0), APPoint(10.0, 5.0))
        circ_img = invert(l, APPoint(0.0, 0.0); k=5.0)
        @test circ_img isa APCircle2
        @test isapprox(distance(APPoint(0.0, 0.0), circ_img.center), circ_img.r; atol=1e-6)
        testp_inv = invert(APPoint(10.0, 3.0), c)
        @test isapprox(distance(testp_inv, circ_img.center), circ_img.r; atol=1e-6)
        @test_throws ArgumentError invert(APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)), APPoint(0.0, 0.0))
        ccirc = APCircle2(APPoint(10.0, 0.0), 5.0)
        @test invert(ccirc, APPoint(0.0, 0.0); k=5.0) isa APCircle2
        ccirc2 = APCircle2(APPoint(5.0, 0.0), 5.0)
        @test invert(ccirc2, APPoint(0.0, 0.0); k=5.0) isa APLine
        seg_through = APSegment(APPoint(1.0, 1.0), APPoint(-1.0, -1.0))
        @test invert(seg_through, APPoint(0.0, 0.0); k=5.0) isa APSegment
        seg_off = APSegment(APPoint(10.0, -2.0), APPoint(10.0, 2.0))
        arcimg = invert(seg_off, APPoint(0.0, 0.0); k=5.0)
        @test arcimg isa APCircularArc2
        @test !Apollonius._arc_sweep_contains(arcimg, APPoint(0.0, 0.0))
        pneg = invert_neg(p, c)
        @test isapprox(pneg, reflection(pinv, c.center); atol=1e-9)
        @test invert_neg(l, APPoint(0.0, 0.0); k=5.0) isa APCircle2
        pl = polar_line(c, APPoint(10.0, 0.0))
        @test is_perpendicular(pl, APLine(c.center, APPoint(10.0, 0.0)))
        @test is_on_line(invert(APPoint(10.0, 0.0), c), pl)
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
        sols = tangent_circles(a, b, l)
        @test length(sols) >= 1
        @test all(s -> isapprox(distance(s.center, a), s.r; atol=1e-6) &&
                       isapprox(distance(s.center, b), s.r; atol=1e-6) && tangent_to_line(s, l), sols)
        @test tangent_circles(l, a, b) == sols
        cpp = APCircle2(APPoint(10.0, 0.0), 3.0)
        sols2 = tangent_circles(a, b, cpp)
        @test all(s -> isapprox(distance(s.center, a), s.r; atol=1e-6) &&
                       isapprox(distance(s.center, b), s.r; atol=1e-6) && tangent_to_circle(s, cpp), sols2)
        l1 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
        l2 = APLine(APPoint(0.0, 0.0), APPoint(0.0, 1.0))
        p = APPoint(3.0, 3.0)
        sols3 = tangent_circles(l1, l2, p)
        @test length(sols3) == 2
        @test all(s -> isapprox(distance(s.center, p), s.r; atol=1e-6) &&
                       tangent_to_line(s, l1) && tangent_to_line(s, l2), sols3)
        c1 = APCircle2(APPoint(0.0, 0.0), 3.0)
        c2 = APCircle2(APPoint(10.0, 0.0), 3.0)
        p2 = APPoint(5.0, 5.0)
        sols4 = tangent_circles(c1, c2, p2)
        @test length(sols4) == 4
        @test all(s -> isapprox(distance(s.center, p2), s.r; atol=1e-6) &&
                       tangent_to_circle(s, c1) && tangent_to_circle(s, c2), sols4)
        @test tangent_circles(c2, c1, p2) isa Vector
        sols5 = tangent_circles(l1, c1, p2)
        @test all(s -> isapprox(distance(s.center, p2), s.r; atol=1e-6) &&
                       tangent_to_line(s, l1) && tangent_to_circle(s, c1), sols5)
        @test tangent_circles(c1, l1, p2) == sols5
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
        u1 = APCircle2(APPoint(0.0, 0.0), 1.0)
        u2 = APCircle2(APPoint(2.0, 0.0), 1.0)
        u3 = APCircle2(APPoint(1.0, sqrt(3)), 1.0)
        gaps = interstices(u1, u2, u3)
        @test length(gaps) == 1
        @test area(gaps[1]) ≈ sqrt(3) - 3 * (0.5 * 1 * (pi / 3)) atol = 1e-6
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
        @test isapprox(angle_measure_at(p1, p2, t306090.c), pi / 6; atol=1e-6)
        @test isapprox(angle_measure_at(p2, p1, t306090.c), pi / 3; atol=1e-6)
        tgen = triangle_on_segment(p1, p2, deg2rad(40.0), deg2rad(60.0))
        @test isapprox(angle_measure_at(p1, p2, tgen.c), deg2rad(40.0); atol=1e-9)
        @test isapprox(angle_measure_at(p2, p1, tgen.c), deg2rad(60.0); atol=1e-9)
        @test area(tgen) > 0
        tgen_cw = triangle_on_segment(p1, p2, deg2rad(40.0), deg2rad(60.0); ccw=false)
        @test isapprox(angle_measure_at(p1, p2, tgen_cw.c), deg2rad(40.0); atol=1e-9)
        @test tgen_cw.c[2] < 0 < tgen.c[2]   # opposite sides of the [p1,p2] base
        @test triangle_on_segment(APSegment(p1, p2), deg2rad(40.0), deg2rad(60.0)) == tgen
        @test_throws ArgumentError triangle_on_segment(p1, p2, deg2rad(100.0), deg2rad(100.0))   # sum >= π
        @test_throws ArgumentError triangle_on_segment(p1, p2, 0.0, deg2rad(60.0))
        @test_throws ArgumentError triangle_on_segment(p1, p2, deg2rad(40.0), pi)
        tsss = triangle_on_segment_sss(p1, p2, 3.0, 4.0)
        @test isapprox(distance(p1, tsss.c), 3.0; atol=1e-9) && isapprox(distance(p2, tsss.c), 4.0; atol=1e-9)
        @test tsss.c[2] > 0
        @test triangle_on_segment_sss(p1, p2, 3.0, 4.0; ccw=false).c[2] < 0
        @test triangle_on_segment_sss(APSegment(p1, p2), 3.0, 4.0) == tsss
        @test_throws ArgumentError triangle_on_segment_sss(p1, p2, 0.5, 0.5)   # too short to reach
        tsas_a = triangle_on_segment_sas(p1, p2, deg2rad(40.0), 3.0)
        @test isapprox(angle_measure_at(p1, p2, tsas_a.c), deg2rad(40.0); atol=1e-9)
        @test isapprox(distance(p1, tsas_a.c), 3.0; atol=1e-9)
        tsas_b = triangle_on_segment_sas(p1, p2, deg2rad(40.0), 3.0; at=:b)
        @test isapprox(angle_measure_at(p2, p1, tsas_b.c), deg2rad(40.0); atol=1e-9)
        @test isapprox(distance(p2, tsas_b.c), 3.0; atol=1e-9)
        @test tsas_a.c[2] > 0 && tsas_b.c[2] > 0
        @test triangle_on_segment_sas(APSegment(p1, p2), deg2rad(40.0), 3.0) == tsas_a
        @test_throws ArgumentError triangle_on_segment_sas(p1, p2, deg2rad(40.0), 3.0; at=:c)
        @test_throws ArgumentError triangle_on_segment_sas(p1, p2, pi, 3.0)
        tssa1 = triangle_on_segment_ssa(p1, p2, deg2rad(30.0), 3.0)
        tssa2 = triangle_on_segment_ssa(p1, p2, deg2rad(30.0), 3.0; second_solution=true)
        @test isapprox(angle_measure_at(p1, p2, tssa1.c), deg2rad(30.0); atol=1e-9)
        @test isapprox(distance(p2, tssa1.c), 3.0; atol=1e-9)
        @test isapprox(angle_measure_at(p1, p2, tssa2.c), deg2rad(30.0); atol=1e-9)
        @test isapprox(distance(p2, tssa2.c), 3.0; atol=1e-9)
        @test !(tssa1 ≈ tssa2)
        @test angle_measure_at(p2, p1, tssa1.c) >= angle_measure_at(p2, p1, tssa2.c)   # primary has the larger base angle
        @test triangle_on_segment_ssa(APSegment(p1, p2), deg2rad(30.0), 3.0) == tssa1
        @test_throws ArgumentError triangle_on_segment_ssa(p1, p2, deg2rad(30.0), 0.1)   # too short to reach
        h = distance(p1, p2) * sin(deg2rad(30.0))
        tssa_tangent = triangle_on_segment_ssa(p1, p2, deg2rad(30.0), h)
        @test isapprox(angle_measure_at(tssa_tangent.c, p1, p2), pi / 2; atol=1e-6)
        isoright = isosceles_right_triangle_on_segment(p1, p2)
        @test isapprox(distance(p1, isoright.c), distance(p2, isoright.c); atol=1e-6)
        @test isapprox(angle_measure_at(isoright.c, p1, p2), pi / 2; atol=1e-6)
        golden = golden_triangle_on_segment(p1, p2)
        @test isapprox(angle_measure_at(p1, p2, golden.c), 72 * pi / 180; atol=1e-6)
        @test isapprox(angle_measure_at(p2, p1, golden.c), 72 * pi / 180; atol=1e-6)
        gnomon = golden_gnomon_on_segment(p1, p2)
        @test isapprox(angle_measure_at(p1, p2, gnomon.c), 36 * pi / 180; atol=1e-6)
        @test isapprox(angle_measure_at(p2, p1, gnomon.c), 36 * pi / 180; atol=1e-6)
        egy = egyptian_triangle_on_segment(p1, p2)
        @test isapprox(distance(p2, egy.c), 0.75 * 4.0; atol=1e-9)
        @test isapprox(angle_measure_at(p2, p1, egy.c), pi / 2; atol=1e-6)
        @test isapprox(distance(p1, egy.c), 5.0; atol=1e-6)
        e0 = APEllipse2(APPoint(1.0, 2.0), 5.0, 3.0, 0.4)
        pts5 = [point_on(e0, t) for t in (0.0, 1.0, 2.0, 3.0, 4.0)]
        fitted = conic_through_points(pts5...)
        @test fitted isa APEllipse2
        @test isapprox(fitted.a, e0.a; atol=1e-6) && isapprox(fitted.b, e0.b; atol=1e-6)
        @test isapprox(fitted.center, e0.center; atol=1e-6)
        @test all(p -> is_on_ellipse(p, fitted; atol=1e-6), pts5)
        h0 = APHyperbola2(APPoint(0.0, 0.0), 4.0, 2.0, 0.2)
        ptsh = [point_on(h0, t; branch=1) for t in (-1.0, -0.5, 0.0, 0.5, 1.0)]
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
        circ = APCircle2(APPoint(2.0, 3.0), 4.0)
        @test reflection(circ, APPoint(0.0, 0.0)) == APCircle2(APPoint(-2.0, -3.0), 4.0)
        @test reflection(circ, l) == APCircle2(APPoint(2.0, -3.0), 4.0)
        @test rotate(APPoint(1.0, 0.0), pi / 2) ≈ APPoint(0.0, 1.0) atol = 1e-12
        @test homothety(APPoint(1.0, 1.0), 2.0) == APPoint(2.0, 2.0)
        @test barycenter([p1, p2], [1.0, 1.0]) == APPoint(2.0, 0.0)
        tri_bary = APTriangle(APPoint(1.0, 1.0), APPoint(6.0, 3.0), APPoint(2.0, 6.0))
        @test barycenter(vertices(tri_bary), [1.0, 1.0, 2.0]) ≈ APPoint(2.75, 4.0)
        @test barycenter([p1, p2], (1.0, 1.0)) == APPoint(2.0, 0.0)
        pb = perpendicular_bisector(p1, p2)
        @test is_on_line(APPoint(2.0, 7.0), pb)
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
        @test is_on_segment(b, s)
        @test !is_on_segment(APPoint(3.0, 0.0), s)
        @test side_of_line(APPoint(0.5, 1.0), l1) == 1
        @test side_of_line(APPoint(0.5, -1.0), l1) == -1
        @test side_of_line(APPoint(0.5, 0.0), l1) == 0
        circ = APCircle2(APPoint(0.0, 0.0), 5.0)
        on_circ(t) = circ.center + circ.r * APVector(cos(t), sin(t))
        @test is_concyclic(on_circ(0.1), on_circ(1.5), on_circ(3.0), on_circ(4.5))
        @test !is_concyclic(on_circ(0.1), on_circ(1.5), on_circ(3.0), APPoint(100.0, 100.0))
        @test is_concyclic(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(2.0, 0.0), APPoint(3.0, 0.0))
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
        @test is_collinear(circumcenter(t), centroid(t), orthocenter(t); atol=1e-9)
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
        el = euler_line(t)
        @test is_on_line(orthocenter(t), el)
        @test distance(nine_point_center(t), circumcenter(t)) ≈ distance(orthocenter(t), circumcenter(t)) / 2 atol = 1e-9
        @test nine_point_circle(t).r ≈ circumradius(t) / 2 atol = 1e-9
        @test barycentric_coordinates(t, t[1]) == (1.0, 0.0, 0.0)
        α, β, γ = barycentric_coordinates(t, centroid(t))
        @test α ≈ 1 / 3 && β ≈ 1 / 3 && γ ≈ 1 / 3
        p = APPoint(1.0, 1.0)
        α, β, γ = barycentric_coordinates(t, p)
        @test α + β + γ ≈ 1.0
        @test barycentric_point(t, α, β, γ) ≈ p
        x, y, z = trilinear_coordinates(t, incenter(t))
        @test x ≈ inradius(t) && y ≈ inradius(t) && z ≈ inradius(t)
        @test trilinear_point(t, 1.0, 1.0, 1.0) ≈ incenter(t)
        x2, y2, z2 = trilinear_coordinates(t, p)
        @test trilinear_point(t, x2, y2, z2) ≈ p
        for i in 1:3
            @test is_on_line(orthocenter(t), altitude(t, i); atol=1e-9)
            @test is_on_line(centroid(t), median(t, i); atol=1e-9)
            @test is_on_line(incenter(t), bisector(t, i); atol=1e-9)
            @test is_on_line(circumcenter(t), mediator(t, i); atol=1e-9)
            @test is_perpendicular(bisector(t, i), bisector_ext(t, i))
        end
        ext1 = bisector_ext(t, 1)
        ec_local = excenters(t)
        @test is_on_line(ec_local.B, ext1; atol=1e-9)
        @test is_on_line(ec_local.C, ext1; atol=1e-9)
        @test !is_on_line(ec_local.A, ext1; atol=1e-9)
        others = ((2, 3), (1, 3), (1, 2))
        for i in 1:3
            j, k = others[i]
            full = angle_measure_at(t[i], t[j], t[k])
            rays = trisector(t, i)
            @test length(rays) == 2
            r1, r2 = rays
            @test r1.origin == t[i] && r2.origin == t[i]
            @test angle_measure_at(t[i], t[j], r1.through) ≈ full / 3 atol = 1e-9
            @test angle_measure_at(t[i], r1.through, r2.through) ≈ full / 3 atol = 1e-9
            @test angle_measure_at(t[i], r2.through, t[k]) ≈ full / 3 atol = 1e-9
        end
        @test spieker_center(t) ≈ midpoint(incenter(t), nagel_point(t))
        ec = excenters(t)
        lA = APLine(ec.A, midpoint(t[2], t[3]))
        lB = APLine(ec.B, midpoint(t[1], t[3]))
        @test only(intersection(lA, lB)) ≈ mittenpunkt(t)
        @test_throws ArgumentError clawson_point(t)   # t is the 3-4-5 right triangle: X(19) is undefined here
        scalene = APTriangle(APPoint(0.0, 0.0), APPoint(7.0, 0.0), APPoint(2.0, 4.0))
        A, B, C = angle_measure_at(scalene[1], scalene[2], scalene[3]), angle_measure_at(scalene[2], scalene[1], scalene[3]), angle_measure_at(scalene[3], scalene[1], scalene[2])
        cw = clawson_point(scalene)
        xA, xB, xC = trilinear_coordinates(scalene, cw)   # X(19) has trilinears tan A : tan B : tan C
        @test xA / tan(A) ≈ xB / tan(B) atol = 1e-9
        @test xB / tan(B) ≈ xC / tan(C) atol = 1e-9
        @test cw ≈ trilinear_point(scalene, tan(A), tan(B), tan(C))
        eq = APTriangle(APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(1.0, sqrt(3.0)))
        g = centroid(eq)
        for center in (circumcenter(eq), incenter(eq), orthocenter(eq),
                       nagel_point(eq), gergonne_point(eq), spieker_center(eq),
                       symmedian_point(eq), mittenpunkt(eq))
            @test center ≈ g atol = 1e-9
        end
        p_on_circ = t[1]
        sl = simson_line(t, p_on_circ)
        f3 = projection(p_on_circ, APLine(t[3], t[1]))
        @test is_on_line(f3, sl; atol=1e-9)
        npc = nine_point_circle(t)
        for ep in euler_points(t)
            @test distance(ep, npc.center) ≈ npc.r atol = 1e-9
        end
        oax = orthic_axis(t)
        @test is_perpendicular(oax, euler_line(t))
        cc = circumcircle(t)
        @test power_of_point(oax.p1, cc) ≈ power_of_point(oax.p1, npc) atol = 1e-6
        bax = brocard_axis(t)
        @test is_on_line(circumcenter(t), bax; atol=1e-9)
        @test is_on_line(symmedian_point(t), bax; atol=1e-9)
        @test lemoine_axis(t) ≈ polar_line(cc, symmedian_point(t))
        r1 = reflection(p_on_circ, APLine(t[1], t[2]))
        r2 = reflection(p_on_circ, APLine(t[2], t[3]))
        r3 = reflection(p_on_circ, APLine(t[3], t[1]))
        stl = steiner_line(t, p_on_circ)
        @test is_collinear(r1, r2, r3; atol=1e-9)
        @test is_on_line(r3, stl; atol=1e-9)
        @test is_on_line(orthocenter(t), stl; atol=1e-9)
    end
    @testset "more triangle centers and derived triangles" begin
        t = APTriangle(APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(2.0, 4.0))
        dl = de_longchamps_point(t)
        @test is_on_line(dl, euler_line(t))
        @test midpoint(orthocenter(t), dl) ≈ circumcenter(t)
        bp = bevan_point(t)
        ec = excenters(t)
        @test distance(bp, ec.A) ≈ distance(bp, ec.B) atol = 1e-9
        @test distance(bp, ec.B) ≈ distance(bp, ec.C) atol = 1e-9
        fp = feuerbach_point(t)
        @test distance(fp, incenter(t)) ≈ inradius(t) atol = 1e-9
        @test distance(fp, nine_point_center(t)) ≈ circumradius(t) / 2 atol = 1e-9
        A, B, C = t[1], t[2], t[3]
        apex(P, Q, other) = begin
            cand = rotate(Q, pi / 3, P)
            side_of_line(cand, APLine(P, Q)) == side_of_line(other, APLine(P, Q)) ? rotate(Q, -pi / 3, P) : cand
        end
        C2 = apex(A, B, C)
        @test fermat_point(t) ≈ only(intersection(APLine(C, C2), APLine(A, apex(B, C, A))))
        j1, j2 = isodynamic_points(t)
        fp2 = second_fermat_point(t)
        @test fp2 ≈ isogonal_conjugate(t, j1) || fp2 ≈ isogonal_conjugate(t, j2)
        @test fermat_axis(t) ≈ APLine(fermat_point(t), fp2)
        eq = APTriangle(APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(1.0, sqrt(3.0)))
        g = centroid(eq)
        for center in (de_longchamps_point(eq), bevan_point(eq), fermat_point(eq))
            @test center ≈ g atol = 1e-9
        end
        med = medial_triangle(t)
        @test area(med) ≈ area(t) / 4 atol = 1e-9
        @test Set([med[1], med[2], med[3]]) == Set([midpoint(B, C), midpoint(A, C), midpoint(A, B)])
        orth = orthic_triangle(t)
        @test is_on_segment(orth[1], APSegment(B, C))
        @test is_on_segment(orth[2], APSegment(C, A))
        @test is_on_segment(orth[3], APSegment(A, B))
        @test is_perpendicular(APLine(A, orth[1]), APLine(B, C))
        ext = excentral_triangle(t)
        @test Set([ext[1], ext[2], ext[3]]) == Set([ec.A, ec.B, ec.C])
        ct = contact_triangle(t)
        for (v, side) in zip((ct[1], ct[2], ct[3]), (APSegment(B, C), APSegment(C, A), APSegment(A, B)))
            @test distance(v, incenter(t)) ≈ inradius(t) atol = 1e-9
            @test is_on_segment(v, side)
        end
        et = extouch_triangle(t)
        er = exradii(t)
        @test distance(et[1], ec.A) ≈ er.A atol = 1e-9
        @test distance(et[2], ec.B) ≈ er.B atol = 1e-9
        @test distance(et[3], ec.C) ≈ er.C atol = 1e-9
        tan_t = tangential_triangle(t)
        O, R = circumcenter(t), circumradius(t)
        @test distance(O, APLine(tan_t[1], tan_t[2])) ≈ R atol = 1e-6
        spc = spieker_circle(t)
        @test spc.center ≈ spieker_center(t)
        @test spc.center ≈ incenter(medial_triangle(t))
        @test spc.r ≈ inradius(medial_triangle(t))
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
        for i in 1:3
            others = ((2, 3), (1, 3), (1, 2))
            j, k = others[i]
            sq = square_inscribed(t, i)
            sides_sq = (distance(sq[1], sq[2]), distance(sq[2], sq[3]), distance(sq[3], sq[4]), distance(sq[4], sq[1]))
            @test all(x -> isapprox(x, sides_sq[1]; atol=1e-9), sides_sq)
            @test is_perpendicular(APLine(sq[1], sq[2]), APLine(sq[2], sq[3]))
            @test is_on_line(sq[1], APLine(t[j], t[k]); atol=1e-9)
            @test is_on_line(sq[2], APLine(t[j], t[k]); atol=1e-9)
            @test is_on_line(sq[3], APLine(t[i], t[k]); atol=1e-9)
            @test is_on_line(sq[4], APLine(t[i], t[j]); atol=1e-9)
        end
        morley = morley_triangle(t)
        m1, m2, m3 = distance(morley[1], morley[2]), distance(morley[2], morley[3]), distance(morley[3], morley[1])
        @test m1 ≈ m2 atol = 1e-9
        @test m2 ≈ m3 atol = 1e-9
        o1, o2 = first_brocard_point(t), second_brocard_point(t)
        ω = angle_measure_brocard(t)
        @test angle_measure_at(A, o1, B) ≈ ω atol = 1e-9
        @test angle_measure_at(B, o1, C) ≈ ω atol = 1e-9
        @test angle_measure_at(C, o1, A) ≈ ω atol = 1e-9
        @test angle_measure_at(B, o2, A) ≈ ω atol = 1e-9
        @test angle_measure_at(C, o2, B) ≈ ω atol = 1e-9
        @test angle_measure_at(A, o2, C) ≈ ω atol = 1e-9
        @test !(o1 ≈ o2)
        bc = brocard_circle(t)
        @test bc.center ≈ midpoint(circumcenter(t), symmedian_point(t))
        @test distance(bc.center, o1) ≈ bc.r atol = 1e-9
        @test distance(bc.center, o2) ≈ bc.r atol = 1e-9
        eq2 = APTriangle(APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(1.0, sqrt(3.0)))
        @test first_brocard_point(eq2) ≈ centroid(eq2) atol = 1e-9
        @test second_brocard_point(eq2) ≈ centroid(eq2) atol = 1e-9
        @test angle_measure_brocard(eq2) ≈ pi / 6 atol = 1e-9
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
        adp = adams_points(t)
        @test length(adp) == 6
        adc = adams_circle(t)
        @test adc.center == incenter(t)
        for p in adp
            @test distance(adc.center, p) ≈ adc.r atol = 1e-9
        end
        slc = second_lemoine_circle(t)
        @test slc.center ≈ symmedian_point(t)
        @test slc.r ≈ a * b * c / (a^2 + b^2 + c^2) atol = 1e-9
        symc = symmedial_circle(t)
        @test symc ≈ circumcircle(cevian_triangle(t, symmedian_point(t))) atol = 1e-9
        base = three_tangent_circles(t)
        @test base[1].center == A && base[1].r ≈ s - a
        @test base[2].center == B && base[2].r ≈ s - b
        @test base[3].center == C && base[3].r ≈ s - c
        @test distance(base[1].center, base[2].center) ≈ base[1].r + base[2].r atol = 1e-9
        @test distance(base[2].center, base[3].center) ≈ base[2].r + base[3].r atol = 1e-9
        @test distance(base[3].center, base[1].center) ≈ base[3].r + base[1].r atol = 1e-9
        sc = soddy_circles(t)
        @test sc.inner.r < sc.outer.r
        for base_c in base
            din = distance(sc.inner.center, base_c.center)
            @test din ≈ sc.inner.r + base_c.r atol = 1e-6
            dout = distance(sc.outer.center, base_c.center)
            @test dout ≈ sc.outer.r - base_c.r atol = 1e-6
        end
        eq = APTriangle(APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(1.0, sqrt(3.0)))
        sceq = soddy_circles(eq)
        @test sceq.inner.center ≈ centroid(eq) atol = 1e-9
        @test sceq.outer.center ≈ centroid(eq) atol = 1e-9
        @test soddy_center(t) == sc.inner.center
        @test soddy_center(t; outer=true) == sc.outer.center
        sp = soddy_points(t)
        @test sp.inner == sc.inner.center && sp.outer == sc.outer.center
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
        eq = APTriangle(APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(1.0, sqrt(3.0)))
        @test_throws ArgumentError isodynamic_points(eq)
        l = APLine(APPoint(-2.0, 3.0), APPoint(5.0, -1.0))
        op = orthopole(l, t)
        lA = perpendicular_through(APLine(B, C), projection(A, l))
        lB = perpendicular_through(APLine(C, A), projection(B, l))
        lC = perpendicular_through(APLine(A, B), projection(C, l))
        @test is_on_line(op, lA; atol=1e-9)
        @test is_on_line(op, lB; atol=1e-9)
        @test is_on_line(op, lC; atol=1e-9)
        D = APPoint(5.0, -2.0)
        pp = poncelet_point(t, D)
        for tri in (APTriangle(B, C, D), APTriangle(A, C, D), APTriangle(A, B, D), t)
            npc = nine_point_circle(tri)
            @test distance(pp, npc.center) ≈ npc.r atol = 1e-6
        end
    end
    @testset "apollonius_circle_of_triangle / apollonius_point_of_triangle (Kimberling X181)" begin
        for t in (APTriangle(APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(2.0, 4.0)),
            APTriangle(APPoint(0.0, 0.0), APPoint(10.0, 0.0), APPoint(1.0, 2.0)),
            APTriangle(APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(1.0, sqrt(3.0))),
            APTriangle(APPoint(1.0, 1.0), APPoint(9.0, 2.0), APPoint(4.0, 8.0)))
            ec = excircles(t)
            E = apollonius_circle_of_triangle(t)
            for c in (ec.A, ec.B, ec.C)
                @test E.r > c.r
                @test distance(E.center, c.center) ≈ E.r - c.r atol = 1e-6   # internally tangent, c inside E
            end
            tangency(small) = small.center + small.r * normalize(small.center - E.center)
            lA = APLine(t[1], tangency(ec.A))
            lB = APLine(t[2], tangency(ec.B))
            lC = APLine(t[3], tangency(ec.C))
            apt = apollonius_point_of_triangle(t)
            @test is_on_line(apt, lA; atol=1e-6)
            @test is_on_line(apt, lB; atol=1e-6)
            @test is_on_line(apt, lC; atol=1e-6)
            a, b, c = distance(t[2], t[3]), distance(t[1], t[3]), distance(t[1], t[2])
            x181 = trilinear_point(t, (a * (b + c)^2) / (b + c - a), (b * (c + a)^2) / (c + a - b), (c * (a + b)^2) / (a + b - c))
            @test apt ≈ x181 atol = 1e-6
        end
    end
    @testset "Kenmotu and MacBeath points" begin
        t = APTriangle(APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(2.0, 4.0))
        A, B, C = t[1], t[2], t[3]
        angA, angB, angC = angle_measure_at(A, B, C), angle_measure_at(B, C, A), angle_measure_at(C, A, B)
        kp = kenmotu_point(t)
        x, y, z = trilinear_coordinates(t, kp)
        r1, r2, r3 = cos(angA - pi / 4), cos(angB - pi / 4), cos(angC - pi / 4)
        @test x / r1 ≈ y / r2 atol = 1e-9
        @test y / r2 ≈ z / r3 atol = 1e-9
        eq = APTriangle(APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(1.0, sqrt(3.0)))
        @test kenmotu_point(eq) ≈ centroid(eq) atol = 1e-9
        mp = macbeath_point(t)
        @test mp ≈ isotomic_conjugate(t, circumcenter(t))
        @test isotomic_conjugate(t, mp) ≈ circumcenter(t) atol = 1e-6
    end
    @testset "brocard midpoint" begin
        t = APTriangle(APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(2.0, 4.0))
        bm = brocard_midpoint(t)
        @test bm ≈ midpoint(first_brocard_point(t), second_brocard_point(t))
        eq = APTriangle(APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(1.0, sqrt(3.0)))
        @test brocard_midpoint(eq) ≈ centroid(eq) atol = 1e-9
    end
    @testset "Steiner ellipses" begin
        t = APTriangle(APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(2.0, 4.0))
        A, B, C = t[1], t[2], t[3]
        g = centroid(t)
        inell = steiner_inellipse(t)
        @test inell.center ≈ g atol = 1e-9
        @test is_on_ellipse(midpoint(A, B), inell)
        @test is_on_ellipse(midpoint(B, C), inell)
        @test is_on_ellipse(midpoint(C, A), inell)
        circumell = steiner_circumellipse(t)
        @test circumell isa APEllipse2
        @test circumell.center ≈ g atol = 1e-9
        @test is_on_ellipse(A, circumell)
        @test is_on_ellipse(B, circumell)
        @test is_on_ellipse(C, circumell)
        @test circumell.a ≈ 2 * inell.a atol = 1e-6
        @test circumell.b ≈ 2 * inell.b atol = 1e-6
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
        @test_throws ArgumentError APEllipse2(f1, f2, distance(f1, f2) / 2)
        p = APPoint(4.0, 7.0)
        e2 = APEllipse2(f1, f2, p)
        @test is_on_ellipse(p, e2)
        @test e2.a ≈ (distance(p, f1) + distance(p, f2)) / 2
        h = APHyperbola2(f1, f2, 2.0)
        hf1, hf2 = foci(h)
        @test (hf1 ≈ f1 && hf2 ≈ f2) || (hf1 ≈ f2 && hf2 ≈ f1)
        @test h.a == 2.0
        @test_throws ArgumentError APHyperbola2(f1, f2, distance(f1, f2) / 2 + 1.0)
        ph = point_on(h, 0.6)
        h2 = APHyperbola2(f1, f2, ph)
        @test is_on_hyperbola(ph, h2)
        @test h2.a ≈ abs(distance(ph, f1) - distance(ph, f2)) / 2
    end
    @testset "conic through 5 points" begin
        e_true = APEllipse2(APPoint(2.0, 3.0), 5.0, 3.0, 0.4)
        pts = [point_on(e_true, t) for t in (0.1, 1.0, 2.0, 3.3, 4.7)]
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
        ptsh = vcat([point_on(h_true, t; branch=1) for t in (0.3, 1.0, 1.7)],
                    [point_on(h_true, t; branch=-1) for t in (0.5, 1.2)])
        fith = conic_through_points(ptsh...)
        @test fith isa APHyperbola2
        @test fith.center ≈ h_true.center
        @test fith.a ≈ h_true.a
        @test fith.b ≈ h_true.b
        @test fith.angle ≈ h_true.angle
        for p in ptsh
            @test is_on_hyperbola(p, fith; atol=1e-6)
        end
        @test_throws ArgumentError conic_through_points(
            APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(2.0, 0.0), APPoint(3.0, 0.0), APPoint(4.0, 0.0))
        circ = APCircle2(APPoint(1.0, 1.0), 3.0)
        cpts = [circ.center + circ.r * APVector(cos(t), sin(t)) for t in (0.2, 1.1, 2.3, 3.5, 5.0)]
        fitc = conic_through_points(cpts...)
        @test fitc isa APEllipse2
        @test fitc.a ≈ fitc.b ≈ circ.r
        @test fitc.center ≈ circ.center
    end
    @testset "isogonal and isotomic conjugates" begin
        t = APTriangle(APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(2.0, 4.0))
        @test isogonal_conjugate(t, orthocenter(t)) ≈ circumcenter(t) atol = 1e-6
        @test isogonal_conjugate(t, circumcenter(t)) ≈ orthocenter(t) atol = 1e-6
        @test isogonal_conjugate(t, centroid(t)) ≈ symmedian_point(t) atol = 1e-6
        @test isogonal_conjugate(t, symmedian_point(t)) ≈ centroid(t) atol = 1e-6
        @test isogonal_conjugate(t, incenter(t)) ≈ incenter(t) atol = 1e-6
        @test isotomic_conjugate(t, centroid(t)) ≈ centroid(t) atol = 1e-6
        p = APPoint(2.0, 1.5)
        @test isogonal_conjugate(t, isogonal_conjugate(t, p)) ≈ p atol = 1e-6
        @test isotomic_conjugate(t, isotomic_conjugate(t, p)) ≈ p atol = 1e-6
    end
    @testset "general point-parametrized derived triangles" begin
        t = APTriangle(APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(2.0, 4.0))
        pt1, pt2, pt3 = pedal_triangle(t, orthocenter(t)), pedal_triangle(t, orthocenter(t)), pedal_triangle(t, incenter(t))
        ot, ct = orthic_triangle(t), contact_triangle(t)
        for i in 1:3
            @test pt1[i] ≈ ot[i] atol = 1e-9
            @test pt3[i] ≈ ct[i] atol = 1e-9
        end
        @test pedal_circle(t, orthocenter(t)) ≈ circumcircle(ot) atol = 1e-9
        p_ped = APPoint(2.0, 1.5)
        pc = pedal_circle(t, p_ped)
        @test all(v -> isapprox(distance(v, pc.center), pc.r; atol=1e-9), pedal_triangle(t, p_ped))
        cvt = cevian_triangle(t, centroid(t))
        mt = medial_triangle(t)
        for i in 1:3
            @test cvt[i] ≈ mt[i] atol = 1e-9
        end
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
            @test distance(m.center, cc.center) ≈ cc.r - m.r atol = 1e-6
            @test side_of_line(m.center, l1) == side_of_line(other2, l1)
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
                @test distance(s.center, cc.center) ≈ cc.r - s.r atol = 1e-6
                @test side_of_line(s.center, cevian) == side_of_line(ref, cevian)
                @test side_of_line(s.center, side_line) == side_of_line(A, side_line)
            end
            @test is_on_line(incenter(t), APLine(th.near_b.center, th.near_c.center); atol=1e-9)
        end
    end
    @testset "invert" begin
        c = APCircle2(APPoint(0.0, 0.0), 2.0)
        p = APPoint(4.0, 0.0)
        p2 = invert(p, c)
        @test p2 ≈ APPoint(1.0, 0.0)
        @test invert(p2, c) ≈ p
        @test_throws ArgumentError invert(c.center, c)
        center = APPoint(1.0, 2.0)
        point_on(circ, t) = circ.center + circ.r * APVector(cos(t), sin(t))
        l = APLine(APPoint(-10.0, 5.0), APPoint(10.0, 5.0))
        il = invert(l, center)
        @test distance(center, il.center) ≈ il.r atol = 1e-9
        for t in (0.0, 1.1, 3.0)
            @test is_on_line(invert(point_on(il, t), APCircle2(center, 1.0)), l; atol=1e-6)
        end
        @test_throws ArgumentError invert(APLine(center, center + APVector(1.0, 0.0)), center)
        c0 = APCircle2(APPoint(6.0, 8.0), 2.0)
        ic0 = invert(c0, center)
        for t in (0.0, 1.3, 2.7)
            img = invert(point_on(c0, t), APCircle2(center, 1.0))
            @test abs(distance(img, ic0.center) - ic0.r) <= 1e-6
        end
        c_through = APCircle2(center, 3.0)
        p_center = center + APVector(3.0, 0.0)
        img_line = invert(c_through, p_center)
        @test img_line isa APLine
        for t in (0.3, 1.7, 2.5, 4.1)
            p = point_on(c_through, t)
            isapprox(p, p_center; atol=1e-6) && continue
            pimg = invert(p, APCircle2(p_center, 1.0))
            @test is_on_line(pimg, img_line; atol=1e-6)
        end
        same_center_img = invert(APCircle2(center, 4.0), center; k=2.0)
        @test same_center_img.center == center
        @test same_center_img.r ≈ 2.0^2 / 4.0
        @test invert(APPoint(4.0, 0.0), APPoint(0.0, 0.0); k=2.0) ≈ invert(APPoint(4.0, 0.0), APCircle2(APPoint(0.0, 0.0), 2.0))
        @test_throws ArgumentError invert(APPoint(1.0, 2.0), APPoint(1.0, 2.0))
    end
    @testset "invert(APSegment/APTriangle/APStraightNgon), APCurvilinearNgon2" begin
        center = APPoint(0.0, 0.0)
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
                        push!(pts, point_on(side, t))
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
            p1, p2 = APPoint(5.0, 2.0), APPoint(8.0, 6.0)
            arc = invert(APSegment(p1, p2), center)
            @test arc isa APCircularArc2
            @test distance(arc.circle.center, center) ≈ arc.circle.r atol = 1e-9
            for t in (0.0, 0.3, 0.7, 1.0)
                p = p1 + t * (p2 - p1)
                ip = invert(p, APCircle2(center, 1.0))
                @test distance(ip, arc.circle.center) ≈ arc.circle.r atol = 1e-9
            end
            @test arc.p1 ≈ invert(p1, APCircle2(center, 1.0))
            @test arc.p2 ≈ invert(p2, APCircle2(center, 1.0))
            p3, p4 = APPoint(3.0, 0.0), APPoint(8.0, 0.0)
            seg = invert(APSegment(p3, p4), center)
            @test seg isa APSegment
            @test seg[1] ≈ invert(p3, APCircle2(center, 1.0))
            @test seg[2] ≈ invert(p4, APCircle2(center, 1.0))
        end
        @testset "invert(APTriangle) -> APCurvilinearNgon2" begin
            t = APTriangle(APPoint(5.0, 2.0), APPoint(9.0, 3.0), APPoint(6.0, 8.0))
            cp = invert(t, center)
            @test cp isa APCurvilinearNgon2
            @test length(cp) == 3
            @test all(s -> s isa APCircularArc2, cp.sides)
            pts = boundary_samples(cp.sides)
            @test area(cp) ≈ shoelace(pts) atol = 1e-6
            @test perimeter(cp) ≈ sum(distance(pts[i], pts[mod1(i + 1, length(pts))]) for i in eachindex(pts)) atol = 1e-3
            on_original(p; atol=1e-4) =
                min(distance(p, APLine(t[1], t[2])), distance(p, APLine(t[2], t[3])), distance(p, APLine(t[3], t[1]))) < atol
            @test all(on_original, invert(p, APCircle2(center, 1.0)) for p in pts[1:200:end])
            t2 = APTriangle(APPoint(-3.0, 0.0), APPoint(5.0, 0.0), APPoint(2.0, 4.0))
            cp2 = invert(t2, center)
            @test count(s -> s isa APSegment, cp2.sides) == 1
            @test count(s -> s isa APCircularArc2, cp2.sides) == 2
            pts2 = boundary_samples(cp2.sides)
            @test area(cp2) ≈ shoelace(pts2) atol = 1e-6
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
        @test distance(vh[1], vh[2]) ≈ 1.0 atol = 1e-9
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
        @test abs(rev) ≈ pi / 2
        @test !is_direct(rev)
        @test reverse(ang) == rev
        @test reverse(reverse(ang)) == ang
        @test ang == APAngle2(vertex, a, b)
        @test ang ≈ APAngle2(vertex, a, b)
        rot = rotate(ang, pi / 3)
        @test measure(rot) ≈ measure(ang)
        @test rot.vertex ≈ rotate(vertex, pi / 3)
        hom = homothety(ang, -2.0, APPoint(0.5, 0.5))
        @test measure(hom) ≈ measure(ang)
        refl = reflection(ang, APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)))
        @test measure(refl) ≈ measure(ang)
        @test abs(refl) ≈ abs(ang)
        zero_ang = APAngle2(vertex, APPoint(2.0, 0.0), APPoint(5.0, 0.0))
        @test measure(zero_ang) ≈ 0.0 atol = 1e-9
        @test abs(zero_ang) ≈ 0.0 atol = 1e-9
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
        @test centroid(q) ≈ a + ((b - a) + (c - a) + (d - a)) / 4
        @test area(q) ≈ 10.5
        @test perimeter(q) ≈ distance(a, b) + distance(b, c) + distance(c, d) + distance(d, a)
        @test is_convex(q)
        @test !is_cyclic(q)
        @test point_in_polygon(APPoint(2.0, 1.5), q)
        @test !point_in_polygon(APPoint(10.0, 10.0), q)
        bb = APBoundingBox(q)
        @test bb.min == APPoint(0.0, 0.0) && bb.max == APPoint(4.0, 3.0)
        sq = square_on_segment(APPoint(0.0, 0.0), APPoint(2.0, 0.0))
        @test sq isa APQuadrilateral
        @test is_cyclic(sq)
        dart = APQuadrilateral(APPoint(0.0, 0.0), APPoint(2.0, 1.0), APPoint(0.0, 2.0), APPoint(0.5, 1.0))
        @test !is_convex(dart)
        rot = rotate(q, pi / 6, APPoint(1.0, 1.0))
        @test rot == APQuadrilateral(rotate(a, pi / 6, APPoint(1.0, 1.0)), rotate(b, pi / 6, APPoint(1.0, 1.0)),
            rotate(c, pi / 6, APPoint(1.0, 1.0)), rotate(d, pi / 6, APPoint(1.0, 1.0)))
        @test area(rot) ≈ area(q) atol = 1e-9
        hom = homothety(q, -2.0)
        @test area(hom) ≈ 4 * area(q) atol = 1e-9
        refl = reflection(q, APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)))
        @test area(refl) ≈ area(q) atol = 1e-9
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
        composed = hm ∘ rm
        @test composed(p) ≈ hm(rm(p)) atol = 1e-9
        src = (APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
        dst = map(rm, src)
        recovered = affine_map(src, dst)
        @test recovered(p) ≈ rm(p) atol = 1e-9
        t = APTriangle(APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(0.0, 2.0))
        @test rm(t) == APTriangle(rm(t[1]), rm(t[2]), rm(t[3]))
        q = APQuadrilateral(APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(2.0, 2.0), APPoint(0.0, 2.0))
        @test rm(q) == APQuadrilateral(rm(q.a), rm(q.b), rm(q.c), rm(q.d))
        ang = APAngle2(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
        @test rm(ang) == APAngle2(rm(ang.vertex), rm(ang.a), rm(ang.b))
        skew = APAffineMap(2.0, 0.5, -0.3, 1.4, 3.0, -1.0)
        c = APCircle2(APPoint(1.0, 2.0), 5.0)
        e = skew(c)
        @test e isa APEllipse2
        @test e.center ≈ skew(c.center)
        for θ in (0.0, 1.0, 2.5, 4.7)
            p = c.center + c.r * APVector(cos(θ), sin(θ))
            @test is_on_ellipse(skew(p), e; atol=1e-6)
        end
        e2 = rm(c)
        @test e2 isa APCircle2
        @test e2.r ≈ c.r atol = 1e-9
        @test rotation_map(pi / 3, APPoint(0.0, 0.0))(APCircularArc2(c, APPoint(6.0, 2.0), APPoint(1.0, 7.0))) isa APCircularArc2
        @test reflection_map(APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)))(APCircularArc2(c, APPoint(6.0, 2.0), APPoint(1.0, 7.0))) ≈ reflection(APCircularArc2(c, APPoint(6.0, 2.0), APPoint(1.0, 7.0)), APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)))
        @test e2.center ≈ rm(c.center)
        @test_throws ArgumentError affine_map((APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(2.0, 0.0)), dst)
    end
    @testset "ellipse" begin
        e = APEllipse2(APPoint(0.0, 0.0), 2.0, 1.0)
        @test is_on_ellipse(APPoint(2.0, 0.0), e)
        @test is_on_ellipse(APPoint(0.0, 1.0), e)
        @test !is_on_ellipse(APPoint(2.0, 1.0), e)
        @test is_on_ellipse(point_on(e, 0.7), e)
        @test area(e) ≈ pi * 2.0 * 1.0
        f1, f2 = foci(e)
        c = sqrt(2.0^2 - 1.0^2)
        @test f1 ≈ APPoint(c, 0.0)
        @test f2 ≈ APPoint(-c, 0.0)
        p = point_on(e, 0.4)
        @test distance(p, f1) + distance(p, f2) ≈ 2 * e.a atol = 1e-9
        pts = intersection(APLine(APPoint(-3.0, 0.0), APPoint(3.0, 0.0)), e)
        @test length(pts) == 2
        @test APPoint(2.0, 0.0) in pts
        @test APPoint(-2.0, 0.0) in pts
        tangent = APLine(APPoint(-1.0, 1.0), APPoint(1.0, 1.0))
        @test only(intersection(tangent, e)) ≈ APPoint(0.0, 1.0)
        far = APLine(APPoint(-1.0, 5.0), APPoint(1.0, 5.0))
        @test isempty(intersection(far, e))
        rot_e = APEllipse2(APPoint(1.0, 1.0), 2.0, 1.0, pi / 4)
        @test is_on_ellipse(point_on(rot_e, 1.1), rot_e)
        rot_e2 = APEllipse2(APPoint(1.0, 1.0), 3.0, 2.0, pi / 6)
        pext = APPoint(8.0, 5.0)
        tpts = tangent_points(rot_e2, pext)
        @test length(tpts) == 2
        for tp in tpts
            @test is_on_ellipse(tp, rot_e2)
            @test only(intersection(APLine(pext, tp), rot_e2)) ≈ tp
        end
        @test tangent_lines(rot_e2, pext) == [APLine(pext, tp) for tp in tpts]
        @test tangent_points(pext, rot_e2) == tpts
        @test isempty(tangent_points(e, e.center))
        @test isempty(tangent_points(e, e.center + APVector(0.1, 0.1)))
        p_on = point_on(rot_e2, 0.4)
        tl_on = only(tangent_lines(rot_e2, p_on))
        @test tl_on.p1 != tl_on.p2
        @test all(cand -> distance(cand, p_on) < 1e-6, intersection(tl_on, rot_e2))
        e3 = APEllipse2(APPoint(1.0, 2.0), 5.0, 3.0, 0.3)
        oc = orthoptic(e3)
        @test oc.center == e3.center
        @test oc.r ≈ sqrt(e3.a^2 + e3.b^2)
        p_oc = e3.center + oc.r * APVector(cos(0.7), sin(0.7))
        tl_oc = tangent_lines(e3, p_oc)
        @test length(tl_oc) == 2
        @test dot(direction(tl_oc[1]), direction(tl_oc[2])) ≈ 0.0 atol = 1e-9
        circle_e = APEllipse2(APPoint(0.0, 0.0), 3.0, 3.0)
        @test perimeter(circle_e) ≈ 2 * pi * 3.0 atol = 1e-9
        function poly_perimeter(e; n=20_000)
            total = 0.0
            prev = point_on(e, 0.0)
            for i in 1:n
                cur = point_on(e, 2pi * i / n)
                total += distance(prev, cur)
                prev = cur
            end
            return total
        end
        @test perimeter(rot_e2) ≈ poly_perimeter(rot_e2) atol = 1e-3
        rot = rotate(e, pi / 5, APPoint(1.0, 0.0))
        @test rot.center ≈ rotate(e.center, pi / 5, APPoint(1.0, 0.0))
        @test rot.a ≈ e.a && rot.b ≈ e.b
        @test rot.angle ≈ e.angle + pi / 5
        hom_neg = homothety(e, -1.5)
        @test hom_neg.a ≈ 1.5 * e.a && hom_neg.b ≈ 1.5 * e.b
        @test hom_neg.angle ≈ e.angle
        refl_pt = reflection(e, APPoint(2.0, -3.0))
        @test refl_pt.angle ≈ e.angle
        @test refl_pt.a ≈ e.a && refl_pt.b ≈ e.b
        line_about = APLine(APPoint(0.0, 0.0), APPoint(1.0, 2.0))
        refl_line = reflection(e, line_about)
        φ = atan(direction(line_about)[2], direction(line_about)[1])
        @test refl_line.angle ≈ 2φ - e.angle
        for t in (0.0, 1.3, 3.1)
            @test is_on_ellipse(reflection(point_on(e, t), line_about), refl_line; atol=1e-6)
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
        @test is_on_line(rc, l12; atol=1e-9)
        @test is_on_line(rc, l23; atol=1e-9)
        @test is_on_line(rc, l13; atol=1e-9)
        @test power_of_point(rc, c1) ≈ power_of_point(rc, c2) atol = 1e-9
        @test power_of_point(rc, c2) ≈ power_of_point(rc, c3) atol = 1e-9
        @test is_perpendicular(l12, APLine(c1.center, c2.center))
        c4, c5 = APCircle2(APPoint(0.0, 0.0), 1.0), APCircle2(APPoint(6.0, 0.0), 1.0)
        @test radical_axis(c4, c5) ≈ perpendicular_bisector(c4.center, c5.center)
        c6, c7 = APCircle2(APPoint(0.0, 0.0), 2.0), APCircle2(APPoint(3.0, 0.0), 2.0)
        for p in intersection(c6, c7)
            @test is_on_line(p, radical_axis(c6, c7); atol=1e-6)
        end
        @test_throws ArgumentError radical_axis(c, APCircle2(c.center, 5.0))
        far1 = APCircle2(APPoint(0.0, 0.0), 2.0)
        far2 = APCircle2(APPoint(8.0, 0.0), 1.5)
        far3 = APCircle2(APPoint(2.0, 9.0), 1.0)
        rcirc = radical_circle(far1, far2, far3)
        for cc in (far1, far2, far3)
            d = distance(rcirc.center, cc.center)
            @test d^2 ≈ rcirc.r^2 + cc.r^2 atol = 1e-9
        end
        @test rcirc.center ≈ radical_center(far1, far2, far3)
        inside1 = APCircle2(APPoint(0.0, 0.0), 5.0)
        inside2 = APCircle2(APPoint(1.0, 0.0), 5.0)
        inside3 = APCircle2(APPoint(0.0, 1.0), 5.0)
        @test_throws ArgumentError radical_circle(inside1, inside2, inside3)
        @testset "orthogonal_circle" begin
            oc0 = APCircle2(APPoint(0.0, 0.0), 5.0)
            p = APPoint(13.0, 0.0)
            oc1 = orthogonal_circle(oc0, p)
            @test oc1.center == p
            @test distance(oc0.center, oc1.center)^2 ≈ oc0.r^2 + oc1.r^2 atol = 1e-9
            @test_throws ArgumentError orthogonal_circle(oc0, APPoint(3.0, 0.0))
            @test_throws ArgumentError orthogonal_circle(oc0, APPoint(5.0, 0.0))
            p1, p2 = APPoint(8.0, 3.0), APPoint(-4.0, 6.0)
            oc2 = orthogonal_circle(oc0, p1, p2)
            @test distance(oc0.center, oc2.center)^2 ≈ oc0.r^2 + oc2.r^2 atol = 1e-9
            @test isapprox(distance(p1, oc2.center), oc2.r; atol=1e-9)
            @test isapprox(distance(p2, oc2.center), oc2.r; atol=1e-9)
            @test_throws ArgumentError orthogonal_circle(oc0, APPoint(5.0, 0.0), APPoint(-4.0, 6.0))
            pinv = APPoint(10.0, 0.0)
            @test_throws ArgumentError orthogonal_circle(oc0, pinv, invert(pinv, oc0))
        end
        @testset "midcircle" begin
            swaps(c1, c2, M) = invert(c1, M.center; k=M.r) ≈ c2
            swaps_line(c, l, M) = invert(c, M.center; k=M.r) ≈ l
            c1 = APCircle2(APPoint(0.0, 0.0), 2.0)
            c2 = APCircle2(APPoint(10.0, 0.0), 3.0)
            @test circles_position(c1, c2) == :disjoint_ext
            m1 = midcircle(c1, c2)
            @test length(m1) == 1 && swaps(c1, c2, m1[1])
            ct1 = APCircle2(APPoint(0.0, 0.0), 2.0)
            ct2 = APCircle2(APPoint(5.0, 0.0), 3.0)
            @test circles_position(ct1, ct2) == :tangent_ext
            mt = midcircle(ct1, ct2)
            @test length(mt) == 1 && swaps(ct1, ct2, mt[1])
            cs1 = APCircle2(APPoint(0.0, 0.0), 5.0)
            cs2 = APCircle2(APPoint(6.0, 0.0), 4.0)
            @test circles_position(cs1, cs2) == :secant
            ms = midcircle(cs1, cs2)
            @test length(ms) == 2 && all(M -> swaps(cs1, cs2, M), ms)
            ci1 = APCircle2(APPoint(0.0, 0.0), 8.0)
            ci2 = APCircle2(APPoint(3.0, 0.0), 2.0)
            @test circles_position(ci1, ci2) == :disjoint_int
            mi = midcircle(ci1, ci2)
            @test length(mi) == 1 && swaps(ci1, ci2, mi[1])
            cit1 = APCircle2(APPoint(0.0, 0.0), 8.0)
            cit2 = APCircle2(APPoint(5.0, 0.0), 3.0)
            @test circles_position(cit1, cit2) == :tangent_int
            mit = midcircle(cit1, cit2)
            @test length(mit) == 1 && swaps(cit1, cit2, mit[1])
            @test only(midcircle(ci1, ci2)) ≈ only(midcircle(ci2, ci1)) atol = 1e-9   # order-independent internally
            @test_throws ArgumentError midcircle(c1, APCircle2(c1.center, c1.r))
            @test_throws ArgumentError midcircle(c1, APCircle2(c1.center, 9.0))
            cl = APCircle2(APPoint(0.0, 0.0), 3.0)
            l_disjoint = APLine(APPoint(-10.0, 8.0), APPoint(10.0, 8.0))
            @test line_circle_position(l_disjoint, cl) == :disjoint
            md = midcircle(cl, l_disjoint)
            @test length(md) == 1 && swaps_line(cl, l_disjoint, md[1])
            @test midcircle(l_disjoint, cl) == md
            l_tangent = APLine(APPoint(-10.0, 3.0), APPoint(10.0, 3.0))
            @test line_circle_position(l_tangent, cl) == :tangent
            mtl = midcircle(cl, l_tangent)
            @test length(mtl) == 1 && swaps_line(cl, l_tangent, mtl[1])
            l_secant = APLine(APPoint(-10.0, 1.0), APPoint(10.0, 1.0))
            @test line_circle_position(l_secant, cl) == :secant
            msl = midcircle(cl, l_secant)
            @test length(msl) == 2 && all(M -> swaps_line(cl, l_secant, M), msl)
        end
    end
    @testset "apollonius: circle through 2 points tangent to a line/circle" begin
        a, b = APPoint(1.0, 3.0), APPoint(5.0, 4.0)
        l = APLine(APPoint(-10.0, 0.0), APPoint(10.0, 0.7))
        lpp = tangent_circles(a, b, l)
        @test length(lpp) == 2
        for c in lpp
            @test distance(c.center, a) ≈ c.r atol = 1e-6
            @test distance(c.center, b) ≈ c.r atol = 1e-6
            @test distance(c.center, l) ≈ c.r atol = 1e-6
        end
        a2, b2 = APPoint(0.0, 2.0), APPoint(4.0, 2.0)
        l2 = APLine(APPoint(-10.0, 0.0), APPoint(10.0, 0.0))
        lpp2 = tangent_circles(a2, b2, l2)
        @test length(lpp2) == 1
        @test lpp2[1].center ≈ APPoint(2.0, 2.0)
        @test lpp2[1].r ≈ 2.0
        c = APCircle2(APPoint(8.0, 2.0), 2.0)
        cpp = tangent_circles(APPoint(1.0, 1.0), APPoint(2.0, 4.0), c)
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
        @test angle_measure_at(v, p1, rays[1].through) ≈ pi / 6 atol = 1e-9
        @test angle_measure_at(v, rays[1].through, rays[2].through) ≈ pi / 6 atol = 1e-9
        @test angle_measure_at(v, rays[2].through, p2) ≈ pi / 6 atol = 1e-9
        rays_rev = angle_trisectors(v, p2, p1)
        @test angle_measure_at(v, p2, rays_rev[1].through) ≈ pi / 6 atol = 1e-9
        @test angle_measure_at(v, rays_rev[2].through, p1) ≈ pi / 6 atol = 1e-9
    end
    @testset "apollonius: circle tangent to 2 lines through a point (LLP)" begin
        l1 = APLine(APPoint(0.0, 0.0), APPoint(3.0, 1.0))
        l2 = APLine(APPoint(0.0, 0.0), APPoint(-1.0, 2.0))
        p = APPoint(2.0, 5.0)
        sols = tangent_circles(l1, l2, p)
        @test !isempty(sols)
        for c in sols
            @test distance(c.center, l1) ≈ c.r atol = 1e-6
            @test distance(c.center, l2) ≈ c.r atol = 1e-6
            @test distance(c.center, p) ≈ c.r atol = 1e-6
        end
        pl1 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
        pl2 = APLine(APPoint(0.0, 4.0), APPoint(1.0, 4.0))
        p2 = APPoint(10.0, 1.0)
        psols = tangent_circles(pl1, pl2, p2)
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
        ccp = tangent_circles(C1, C2, P)
        @test length(ccp) == 4
        for sol in ccp
            @test distance(sol.center, P) ≈ sol.r atol = 1e-6
            for c in (C1, C2)
                d = distance(sol.center, c.center)
                @test abs(d - (c.r + sol.r)) <= 1e-6 || abs(d - abs(c.r - sol.r)) <= 1e-6
            end
        end
        @test length(tangent_circles(C2, C1, P)) == 4
        L = APLine(APPoint(-10.0, 0.0), APPoint(10.0, 0.0))
        C = APCircle2(APPoint(3.0, 6.0), 2.0)
        Pl = APPoint(-2.0, 4.0)
        clp = tangent_circles(L, C, Pl)
        @test !isempty(clp)
        for sol in clp
            @test distance(sol.center, Pl) ≈ sol.r atol = 1e-6
            @test distance(sol.center, L) ≈ sol.r atol = 1e-6
            d = distance(sol.center, C.center)
            @test abs(d - (C.r + sol.r)) <= 1e-6 || abs(d - abs(C.r - sol.r)) <= 1e-6
        end
        @test length(tangent_circles(C, L, Pl)) == length(clp)
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
        eqc1 = APCircle2(APPoint(0.0, 0.0), 1.0)
        eqc2 = APCircle2(APPoint(2.0, 0.0), 1.0)
        eqc3 = APCircle2(APPoint(1.0, sqrt(3.0)), 1.0)
        nestled = tangent_circles(eqc1, eqc2, eqc3)
        @test any(sol -> sol.center ≈ APPoint(1.0, sqrt(3.0) / 3) && sol.r < 1.0, nestled)
        @test length(nestled) == 2
        for c0 in (eqc1, eqc2, eqc3)
            @test !any(sol -> sol.center ≈ c0.center && sol.r ≈ c0.r, nestled)
        end
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
        @test any(sol -> sol.center ≈ k3.center && sol.r ≈ k3.r, sols)
    end
    @testset "APCircularArc2" begin
        circ = APCircle2(APPoint(1.0, 2.0), 5.0)
        p1 = circ.center + APVector(5.0, 0.0)
        p2 = circ.center + APVector(0.0, 5.0)
        arc = APCircularArc2(circ, p1, p2)
        @test measure(arc) ≈ pi / 2 atol = 1e-9
        @test arc_length(arc) ≈ 5.0 * pi / 2 atol = 1e-9
        @test point_on(arc, 0.0) ≈ p1
        @test point_on(arc, 1.0) ≈ p2
        @test midpoint(arc) ≈ circ.center + APVector(5.0 * cos(pi / 4), 5.0 * sin(pi / 4))
        rev = APCircularArc2(circ, p2, p1)
        @test measure(rev) ≈ 3pi / 2 atol = 1e-9
        @test arc ≈ APCircularArc2(circ, p1, p2)
        @test !(arc ≈ rev)
        @test reverse(arc) == rev
        @test reverse(reverse(arc)) == arc
        deg = APCircularArc2(circ, p1, p1)
        @test measure(deg) ≈ 0.0 atol = 1e-9
        @test arc_length(deg) ≈ 0.0 atol = 1e-9
        @test midpoint(deg) ≈ p1
        antip = circ.center - (p1 - circ.center)
        half = APCircularArc2(circ, p1, antip)
        @test measure(half) ≈ pi atol = 1e-9
        rot = rotate(arc, pi / 3, APPoint(1.0, 1.0))
        @test measure(rot) ≈ measure(arc) atol = 1e-9
        @test rot.p1 ≈ rotate(p1, pi / 3, APPoint(1.0, 1.0))
        hom = homothety(arc, 2.5, APPoint(1.0, 1.0))
        @test measure(hom) ≈ measure(arc) atol = 1e-9
        @test hom.circle.r ≈ 2.5 * circ.r
        hom_neg = homothety(arc, -1.0, APPoint(1.0, 1.0))
        @test measure(hom_neg) ≈ measure(arc) atol = 1e-9
        about_pt = APPoint(3.0, -1.0)
        refl_pt = reflection(arc, about_pt)
        @test measure(refl_pt) ≈ measure(arc) atol = 1e-9
        @test distance(reflection(midpoint(arc), about_pt), refl_pt.circle.center) ≈ refl_pt.circle.r atol = 1e-9
        about_line = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
        refl_line = reflection(arc, about_line)
        @test measure(refl_line) ≈ measure(arc) atol = 1e-9
        @test point_on(refl_line, 0.5) ≈ reflection(midpoint(arc), about_line) atol = 1e-6
    end
    @testset "APCircularSector2 and APCircularSegment2" begin
        circ = APCircle2(APPoint(2.0, -1.0), 5.0)
        p1 = circ.center + APVector(5.0, 0.0)
        for θ in (2.3, 4.5)
            p2 = circ.center + APVector(5.0 * cos(θ), 5.0 * sin(θ))
            arc = APCircularArc2(circ, p1, p2)
            sec = APCircularSector2(arc)
            @test sec == APCircularSector2(circ, p1, p2)
            @test area(sec) ≈ 0.5 * circ.r^2 * θ atol = 1e-9
            @test perimeter(sec) ≈ 2 * circ.r + arc_length(arc) atol = 1e-9
            @test circ.center in sec
            @test midpoint(arc) in sec
            @test !(circ.center + APVector(5.0 * cos(θ + 0.5), 5.0 * sin(θ + 0.5)) in sec)
            @test !((circ.center + 6.0 * (midpoint(arc) - circ.center) / circ.r) in sec)
            seg = APCircularSegment2(arc)
            @test seg == APCircularSegment2(circ, p1, p2)
            @test area(seg) ≈ 0.5 * circ.r^2 * (θ - sin(θ)) atol = 1e-9
            @test perimeter(seg) ≈ arc_length(arc) + distance(p1, p2) atol = 1e-9
            @test midpoint(arc) in seg
            @test (circ.center in seg) == (θ > pi)
        end
        θ = 2.3
        p2 = circ.center + APVector(5.0 * cos(θ), 5.0 * sin(θ))
        arc = APCircularArc2(circ, p1, p2)
        tri = APTriangle(circ.center, p1, p2)
        @test area(APCircularSector2(arc)) ≈ area(APCircularSegment2(arc)) + area(tri) atol = 1e-9
        deg_arc = APCircularArc2(circ, p1, p1)
        @test area(APCircularSector2(deg_arc)) ≈ 0.0 atol = 1e-9
        @test area(APCircularSegment2(deg_arc)) ≈ 0.0 atol = 1e-9
        p_diam = circ.center - (p1 - circ.center)
        half_arc = APCircularArc2(circ, p1, p_diam)
        @test area(APCircularSegment2(half_arc)) ≈ pi * circ.r^2 / 2 atol = 1e-9
        @test area(APCircularSector2(half_arc)) ≈ pi * circ.r^2 / 2 atol = 1e-9
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
        c2 = Apollonius.APCircle2(APPoint(90.0, 0.0), 50.0)
        locus1 = Apollonius.APCircle2(c1.center, c1.r + 35.0)
        locus2 = Apollonius.APCircle2(c2.center, c2.r + 35.0)
        c3 = Apollonius.APCircle2(intersection(locus1, locus2)[1], 35.0)
        @test distance(c1.center, c3.center) ≈ c1.r + c3.r atol = 1e-6
        @test distance(c2.center, c3.center) ≈ c2.r + c3.r atol = 1e-6
        gaps = interstices(c1, c2, c3)
        @test length(gaps) == 1
        g = gaps[1]
        @test _forms_closed_triangle(g)
        arc_circles = [a.circle for a in g]
        for c in (c1, c2, c3)
            @test any(ac -> ac.center ≈ c.center && ac.r ≈ c.r, arc_circles)
        end
        @test length(interstices(c2, c3, c1)) == 1
        @test length(interstices(c3, c1, c2)) == 1
        @test_throws ArgumentError interstices(Apollonius.APCircle2(APPoint(0.0, 0.0), 1.0), Apollonius.APCircle2(APPoint(5.0, 0.0), 1.0), Apollonius.APCircle2(APPoint(0.0, 5.0), 1.0))
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
                    push!(pts, point_on(a, t))
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
        r = 10.0
        e1 = Apollonius.APCircle2(APPoint(0.0, 0.0), r)
        e2 = Apollonius.APCircle2(APPoint(2r, 0.0), r)
        e3 = Apollonius.APCircle2(APPoint(r, r * sqrt(3.0)), r)
        eg = only(interstices(e1, e2, e3))
        @test _forms_closed_triangle(eg)
        @test area(eg) ≈ shoelace_area(eg) atol = 1e-3
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
        @test !(gaps[1] ≈ gaps[2])
        function measure_on(g, c)
            for a in g
                a.circle.center ≈ c.center && a.circle.r ≈ c.r && return measure(a)
            end
            return nothing
        end
        m1, m2 = measure_on(gaps[1], Cc), measure_on(gaps[2], Cc)
        @test m1 + m2 ≈ 2π atol = 1e-6
        @test length(interstices(A, B, Cc)) == 2
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
        @test APParabola2(APPoint(0.0, 0.0), focus) ≈ par
        @test_throws ArgumentError APParabola2(focus, focus)
        v = vertex(par)
        @test distance(v, focus) ≈ distance(v, directrix)
        @test is_on_parabola(v, par)
        p = point_on(par, 3.0)
        @test is_on_parabola(p, par)
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
        pext = APPoint(5.0, 5.0)
        tpts = tangent_points(par, pext)
        @test length(tpts) == 2
        for tp in tpts
            @test is_on_parabola(tp, par)
            @test only(intersection(APLine(pext, tp), par)) ≈ tp
        end
        @test tangent_lines(par, pext) == [APLine(pext, tp) for tp in tpts]
        @test tangent_points(pext, par) == tpts
        @test isempty(tangent_points(par, par.focus))
        p_on_par = point_on(par, 1.5)
        tl_on = only(tangent_lines(par, p_on_par))
        @test tl_on.p1 != tl_on.p2
        @test length(intersection(tl_on, par)) == 1
        @test orthoptic(par) == par.directrix
        p_on_directrix = APPoint(3.0, -1.0)
        tl_dir = tangent_lines(par, p_on_directrix)
        @test length(tl_dir) == 2
        @test dot(direction(tl_dir[1]), direction(tl_dir[2])) ≈ 0.0 atol = 1e-9
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
        @test is_on_hyperbola(APPoint(2.0, 0.0), h)
        @test is_on_hyperbola(APPoint(-2.0, 0.0), h)
        @test !is_on_hyperbola(APPoint(0.0, 0.0), h)
        @test is_on_hyperbola(point_on(h, 0.6), h)
        @test is_on_hyperbola(point_on(h, 0.6; branch=-1), h)
        @test point_on(h, 0.6; branch=-1)[1] < 0
        @test APPoint(2.0, 0.0) in h
        @test APPoint(3.0, 0.0) in h
        @test APPoint(-3.0, 0.0) in h
        @test !(APPoint(0.0, 0.0) in h)
        @test !(APPoint(1.0, 0.0) in h)
        f1, f2 = foci(h)
        c = sqrt(2.0^2 + 1.0^2)
        @test f1 ≈ APPoint(c, 0.0)
        @test f2 ≈ APPoint(-c, 0.0)
        p = point_on(h, 0.5)
        @test abs(distance(p, f1) - distance(p, f2)) ≈ 2 * h.a atol = 1e-9
        a1, a2 = asymptotes(h)
        @test is_on_line(h.center, a1) && is_on_line(h.center, a2)
        far = point_on(h, 6.0)
        @test min(distance(far, a1), distance(far, a2)) < 1e-2
        pts = intersection(APLine(APPoint(-10.0, 0.0), APPoint(10.0, 0.0)), h)
        @test length(pts) == 2
        @test APPoint(2.0, 0.0) in pts
        @test APPoint(-2.0, 0.0) in pts
        @test isempty(intersection(APLine(APPoint(0.0, -10.0), APPoint(0.0, 10.0)), h))
        rot_h = APHyperbola2(APPoint(1.0, 1.0), 2.0, 1.0, pi / 4)
        @test is_on_hyperbola(point_on(rot_h, 0.6), rot_h)
        pext = APPoint(10.0, 20.0)
        tpts = tangent_points(h, pext)
        @test length(tpts) == 2
        for tp in tpts
            @test is_on_hyperbola(tp, h)
            @test any(cand -> distance(cand, tp) < 1e-5, intersection(APLine(pext, tp), h))
        end
        @test tangent_lines(h, pext) == [APLine(pext, tp) for tp in tpts]
        @test tangent_points(pext, h) == tpts
        @test isempty(tangent_points(h, APPoint(20.0, 1.0)))
        p_on_h = point_on(h, 0.5)
        tl_on = only(tangent_lines(h, p_on_h))
        @test tl_on.p1 != tl_on.p2
        @test any(cand -> distance(cand, p_on_h) < 1e-6, intersection(tl_on, h))
        h2 = APHyperbola2(APPoint(0.0, 0.0), 5.0, 3.0, 0.2)
        oc = orthoptic(h2)
        @test oc.center == h2.center
        @test oc.r ≈ sqrt(h2.a^2 - h2.b^2)
        p_oc = h2.center + oc.r * APVector(cos(1.1), sin(1.1))
        tl_oc = tangent_lines(h2, p_oc)
        @test length(tl_oc) == 2
        @test dot(direction(tl_oc[1]), direction(tl_oc[2])) ≈ 0.0 atol = 1e-9
        @test_throws ArgumentError orthoptic(APHyperbola2(APPoint(0.0, 0.0), 2.0, 5.0))
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
            @test is_on_hyperbola(reflection(point_on(h, t; branch=branch), line_about), refl_line; atol=1e-6)
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
            @test is_on_line(sc.inner.center, sl)
            @test is_on_line(sc.outer.center, sl)
        end
        @testset "Kiepert hyperbola/parabola" begin
            kh = kiepert_hyperbola(t)
            @test kh isa APHyperbola2
            a1, a2 = asymptotes(kh)
            @test dot(direction(a1), direction(a2)) ≈ 0.0 atol = 1e-6
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
        @testset "invert_neg / invert_neg" begin
            p = APPoint(10.0, 0.0)
            ci = APCircle2(APPoint(0.0, 0.0), 5.0)
            @test invert_neg(p, ci) ≈ APPoint(-2.5, 0.0)
            @test invert_neg(p, ci) ≈ reflection(invert(p, ci), ci.center)
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
            @test angle_measure_at(p1, p2, r306090[3]) ≈ deg2rad(30) atol = 1e-9
            @test angle_measure_at(p2, p1, r306090[3]) ≈ deg2rad(60) atol = 1e-9
            @test angle_measure_at(r306090[3], p1, p2) ≈ deg2rad(90) atol = 1e-9
            thales = isosceles_right_triangle_on_segment(p1, p2)
            @test angle_measure_at(thales[3], p1, p2) ≈ deg2rad(90) atol = 1e-9
            @test distance(p1, thales[3]) ≈ distance(p2, thales[3])
            golden = golden_triangle_on_segment(p1, p2)
            @test angle_measure_at(p1, p2, golden[3]) ≈ deg2rad(72) atol = 1e-9
            @test angle_measure_at(p2, p1, golden[3]) ≈ deg2rad(72) atol = 1e-9
            @test angle_measure_at(golden[3], p1, p2) ≈ deg2rad(36) atol = 1e-9
            gnomon = golden_gnomon_on_segment(p1, p2)
            @test angle_measure_at(p1, p2, gnomon[3]) ≈ deg2rad(36) atol = 1e-9
            @test angle_measure_at(p2, p1, gnomon[3]) ≈ deg2rad(36) atol = 1e-9
            @test angle_measure_at(gnomon[3], p1, p2) ≈ deg2rad(108) atol = 1e-9
            egy = egyptian_triangle_on_segment(p1, p2)
            @test angle_measure_at(p2, p1, egy[3]) ≈ deg2rad(90) atol = 1e-9
            @test distance(p2, egy[3]) / distance(p1, p2) ≈ 0.75 atol = 1e-9
            @test distance(p1, egy[3]) / distance(p1, p2) ≈ 1.25 atol = 1e-9
        end
    end
    @testset "Julia idioms: in / == / ≈ / show" begin
        bb = APBoundingBox([APPoint(0.0, 0.0), APPoint(4.0, 2.0)])
        @test APPoint(2.0, 1.0) in bb
        @test !(APPoint(5.0, 1.0) in bb)
        e = APEllipse2(APPoint(0.0, 0.0), 2.0, 1.0)
        @test APPoint(0.0, 0.0) in e
        @test APPoint(2.0, 0.0) in e
        @test !(APPoint(3.0, 0.0) in e)
        par = APParabola2(APPoint(0.0, 1.0), APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0)))
        @test APPoint(0.0, 5.0) in par
        @test !(APPoint(0.0, -5.0) in par)
        l1, l2 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)), APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0 + 1e-12))
        @test l1 == APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
        @test l1 ≈ l2
        @test rotation_map(0.3, APPoint(0.0, 0.0)) ≈ rotation_map(0.3 + 1e-13, APPoint(0.0, 0.0))
        @test APEllipse2(APPoint(0.0, 0.0), 2.0, 1.0) == e
        @test par ≈ APParabola2(APPoint(0.0, 1.0 + 1e-13), APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0)))
        f1, f2 = APPoint(-3.0, 0.0), APPoint(3.0, 0.0)
        @test APEllipse2(f1, f2, 5.0) ≈ APEllipse2(f2, f1, 5.0)   # foci swapped: angle differs by exactly π, same ellipse
        @test !(APEllipse2(f1, f2, 5.0) == APEllipse2(f2, f1, 5.0))   # == stays field-exact, like APLine's
        @test !(APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0, 0.3) ≈ APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0, 0.3 + pi / 2))
        @test APHyperbola2(f1, f2, 2.0) ≈ APHyperbola2(f2, f1, 2.0)   # same foci-swap equivalence as APEllipse2
        @test !(APHyperbola2(APPoint(0.0, 0.0), 2.0, 3.0, 0.3) ≈ APHyperbola2(APPoint(0.0, 0.0), 2.0, 3.0, 1.0))
        @test !occursin("APLine{Float64}(", sprint(show, l1))
        @test occursin("APLine(", sprint(show, l1))
        @test occursin("APRay(", sprint(show, APRay(APPoint(0.0, 0.0), APPoint(1.0, 0.0))))
        @test occursin("APBoundingBox(", sprint(show, bb))
        @test occursin("APEllipse2(", sprint(show, e))
        @test occursin("APParabola2(", sprint(show, par))
        @test occursin("APHyperbola2(", sprint(show, APHyperbola2(APPoint(0.0, 0.0), 2.0, 1.0)))
        @test occursin("APAffineMap(", sprint(show, rotation_map(0.3, APPoint(0.0, 0.0))))
    end
    @testset "type promotion: mixed Int/Float64 construction" begin
        @test APCircle2(APPoint(5, 10), 10) isa APCircle2{Int}
        @test APCircle2(APPoint(5, 10), 10.0) isa APCircle2{Float64}
        C, A = APPoint(300, 250), APPoint(150, 350)
        radio = distance(C, A)
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
        @test APEllipse2(APPoint(0, 0), APPoint(4.0, 0.0), 5) isa APEllipse2
        @test APHyperbola2(APPoint(0, 0), 2, 1.0, 0.1) isa APHyperbola2
        @test APHyperbola2(APPoint(0, 0), APPoint(10.0, 0.0), 2) isa APHyperbola2
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
        @test convert(APPoint{2,Float64}, APPoint(1, 2)) === APPoint(1.0, 2.0)
        @test convert(APVector{2,Float64}, APVector(1, 2)) === APVector(1.0, 2.0)
        @test convert(APLine{2,Float64}, APLine(APPoint(0, 0), APPoint(1, 1))) == APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
        @test convert(APCircle2{Float64}, APCircle2(APPoint(0, 0), 5)) == APCircle2(APPoint(0.0, 0.0), 5.0)
    end
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
        @test APPoint((5, 10)) isa APPoint{2,Int}
        @test APPoint((5, 10.0)) == APPoint(5.0, 10.0)
    end
    @testset "vectors" begin
        u, v = APPoint(1.0, 0.0), APPoint(0.0, 1.0)
        @test norm(u) == 1.0
        @test dot(u, v) == 0.0
        @test angle_measure_between(u, v) ≈ pi / 2
        @test angle_measure_at(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0)) ≈ pi / 2
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
        on_c = c.center + c.r * APVector(1.0, 0.0)
        tl_on = only(tangent_lines(c, on_c))
        @test tl_on.p1 != tl_on.p2
        @test is_perpendicular(tl_on, APLine(c.center, on_c))
        @test is_on_line(on_c, tl_on)
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
        cd1, cd2 = APCircle2(APPoint(500.0, 400.0), 200.0), APCircle2(APPoint(900.0, 200.0), 100.0)
        for l in external_tangent_lines(cd1, cd2)
            @test distance(l.p1, cd1.center) ≈ cd1.r atol = 1e-9
            @test distance(l.p2, cd2.center) ≈ cd2.r atol = 1e-9
        end
        for l in internal_tangent_lines(cd1, cd2)
            @test distance(l.p1, cd1.center) ≈ cd1.r atol = 1e-9
            @test distance(l.p2, cd2.center) ≈ cd2.r atol = 1e-9
        end
        same_point = APCircle2(APPoint(0.0, 0.0), 1.0)
        @test eltype(external_tangent_lines(same_point, same_point)) == APLine{2,Float64}
        touching = APCircle2(APPoint(0.0, 0.0), 0.0)
        @test eltype(internal_tangent_lines(touching, touching)) == APLine{2,Float64}
        cA, cB = APCircle2(APPoint(0.0, 0.0), 2.0), APCircle2(APPoint(10.0, 0.0), 3.0)
        ext_sim = external_similitude_center(cA, cB)
        int_sim = internal_similitude_center(cA, cB)
        @test distance(ext_sim, cA.center) / distance(ext_sim, cB.center) ≈ cA.r / cB.r atol = 1e-9
        @test distance(int_sim, cA.center) / distance(int_sim, cB.center) ≈ cA.r / cB.r atol = 1e-9
        @test is_on_line(int_sim, APLine(cA.center, cB.center))
        @test is_on_segment(int_sim, APSegment(cA.center, cB.center))
        @test !is_on_segment(ext_sim, APSegment(cA.center, cB.center))
        @test_throws ArgumentError external_similitude_center(c1, c2)
        circ = APCircle2(APPoint(1.0, 2.0), 3.0)
        pext = APPoint(8.0, 5.0)
        pl = polar_line(circ, pext)
        @test pole(circ, pl) ≈ pext atol = 1e-6
        l2 = APLine(APPoint(4.0, 1.0), APPoint(6.0, 7.0))
        p_of_l2 = pole(circ, l2)
        @test is_on_line(l2.p1, polar_line(circ, p_of_l2); atol=1e-6)
        @test polar_line(circ, circ.center) === nothing
        @test Apollonius._tangent_lines_via_polar(c, on_c) == tangent_lines(c, on_c)
        @test is_on_line(l2.p2, polar_line(circ, p_of_l2); atol=1e-6)
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
        u = bbox_union(bb, bb2)
        @test u.min == APPoint(0.0, -1.0)
        @test u.max == APPoint(6.0, 3.0)
        u_far = bbox_union(bb, far)
        @test u_far.min == APPoint(0.0, 0.0) && u_far.max == APPoint(11.0, 11.0)
        @test bb.min in u && bb.max in u && bb2.min in u && bb2.max in u
        scaled = bb * 2.0
        @test scaled.min == APPoint(0.0, 0.0)
        @test scaled.max == APPoint(8.0, 6.0)
        neg = bb * -1.0
        @test neg.min == APPoint(-4.0, -3.0)
        @test neg.max == APPoint(0.0, 0.0)
        @test bbox_width(neg) == 4.0
        @test bbox_height(neg) == 3.0
        @test APPoint(-2.0, -1.0) in neg
        @testset "@boundingbox macro" begin
            bb1 = @boundingbox begin
                mc = APCircle2(APPoint(0.0, 0.0), 2.0)
                ms = APSegment(APPoint(5.0, 5.0), APPoint(6.0, 7.0))
            end
            @test bb1 == bbox_union(APBoundingBox(APCircle2(APPoint(0.0, 0.0), 2.0)), APBoundingBox(APSegment(APPoint(5.0, 5.0), APPoint(6.0, 7.0))))
            @test mc == APCircle2(APPoint(0.0, 0.0), 2.0)
            @test ms == APSegment(APPoint(5.0, 5.0), APPoint(6.0, 7.0))
            mc2 = APCircle2(APPoint(10.0, 10.0), 1.0)
            ms2 = APSegment(APPoint(-3.0, -3.0), APPoint(-1.0, -1.0))
            bb2 = @boundingbox begin
                mc2
                ms2
            end
            @test bb2 == bbox_union(APBoundingBox(mc2), APBoundingBox(ms2))
            mt3 = APTriangle(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
            bb3 = @boundingbox begin
                mt3
                me3 = APEllipse2(APPoint(20.0, 20.0), 3.0, 1.0, 0.5)
            end
            @test bb3 == bbox_union(APBoundingBox(mt3), APBoundingBox(me3))
            c1, c2 = APCircle2(APPoint(0.0, 0.0), 2.0), APCircle2(APPoint(10.0, 0.0), 1.0)
            bb4 = @boundingbox begin
                p1, p2 = external_tangent_lines(c1, c2)
            end
            @test bb4 == bbox_union(APBoundingBox(p1), APBoundingBox(p2))
            @test isempty(bb4)
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
            mc4 = APCircle2(APPoint(7.0, 7.0), 1.0)
            @test (@boundingbox mc4) == APBoundingBox(mc4)
            bb5 = @boundingbox mc5 = APCircle2(APPoint(9.0, 9.0), 2.0)
            @test bb5 == APBoundingBox(mc5)
            @test mc5 == APCircle2(APPoint(9.0, 9.0), 2.0)
        end
        @testset "@prepare_to_picture / @prepare_to_picture!" begin
            fresh() = (APCircle2(APPoint(3.0, -1.0), 5.0), APSegment(APPoint(-2.0, 4.0), APPoint(6.0, -3.0)))
            c, s = fresh()
            (w, h), (c2, s2) = @prepare_to_picture flip = false begin
                c
                s
            end
            @test (w, h) == (10.0, 10.0)
            @test c == APCircle2(APPoint(3.0, -1.0), 5.0)
            @test c2 == APCircle2(APPoint(0.0, 0.0), 5.0)
            @test s2 == APSegment(APPoint(-5.0, 5.0), APPoint(3.0, -2.0))
            @test bbox_union(APBoundingBox(c2), APBoundingBox(s2)) ==
                  APBoundingBox(APPoint(-w / 2, -h / 2), APPoint(w / 2, h / 2))
            c, s = fresh()
            sz, _ = @prepare_to_picture begin
                c
                s
            end
            @test sz isa NamedTuple{(:width, :height, :fct, :bb)}
            @test sz.width == 10.0 && sz.height == 10.0
            @test sz.bb == APBoundingBox(APPoint(-5.0, -5.0), APPoint(5.0, 5.0))
            c, s = fresh()
            sz2 = @prepare_to_picture! width = 50.0 begin
                c
                s
            end
            @test sz2 isa NamedTuple{(:width, :height, :fct, :bb)}
            @test sz2.width == 50.0 && sz2.height == 50.0
            @test sz2.bb == APBoundingBox(APPoint(-25.0, -25.0), APPoint(25.0, 25.0))
            c, s = fresh()
            sz2m = @prepare_to_picture! width = 500.0 height = 240.0 margin = 20.0 begin
                c
                s
            end
            @test sz2m.bb == APBoundingBox(APPoint(-230.0, -100.0), APPoint(230.0, 100.0))
            @test bbox_width(sz2m.bb) == sz2m.width - 40.0 && bbox_height(sz2m.bb) == sz2m.height - 40.0
            c, s = fresh()
            sz3, obj3 = @prepare_to_picture begin
                c
            end
            c2 = obj3.c
            @test keys(obj3) == (:c,)
            @test sz3.fct(c) == c2
            c, s = fresh()
            original_center = c.center
            sz4 = @prepare_to_picture! begin
                c
                s
            end
            @test sz4.fct(original_center) == c.center
            @testset "discarding a destructured name with _ inside the block" begin
                c, s = fresh()
                sz5 = @prepare_to_picture! begin
                    c
                    s
                    _, only_kept = midpoint(s.p1, s.p2), s.p2
                end
                @test only_kept == s.p2
            end
            @testset "a name bound to a Tuple of shapes (e.g. broadcasting over vertices(t)) gets transformed too" begin
                d = 100.0
                t = equilateral_triangle_on_segment(APPoint(0.0, 0.0), APPoint(d, 0.0))
                sz6 = @prepare_to_picture! width = 500.0 height = 240.0 margin = 20.0 begin
                    t
                    c = APCircle2.(vertices(t), d / 2)
                end
                @test c isa Tuple
                @test all(cc -> cc.center in [v for v in vertices(t)], c)
                @test all(cc -> cc.r ≈ c[1].r, c)
                @test c[1].r > d / 2
            end
            c, s = fresh()
            (_, (c2, s2)) = @prepare_to_picture begin
                c
                s
            end
            (_, (c2f, s2f)) = @prepare_to_picture flip = false begin
                c
                s
            end
            @test c2 == APCircle2(APPoint(c2f.center[1], -c2f.center[2]), c2f.r)
            @test s2 == APSegment(APPoint(s2f.p1[1], -s2f.p1[2]), APPoint(s2f.p2[1], -s2f.p2[2]))
            @test c2f == APCircle2(APPoint(0.0, 0.0), 5.0)
            @test s2f == APSegment(APPoint(-5.0, 5.0), APPoint(3.0, -2.0))
            @test s2 == APSegment(APPoint(-5.0, -5.0), APPoint(3.0, 2.0))
            c, s = fresh()
            (w, h), _ = @prepare_to_picture width = 400.0 begin
                c
                s
            end
            @test (w, h) == (400.0, 400.0)
            c, s = fresh()
            (w, h), _ = @prepare_to_picture scale = 2.0 begin
                c
                s
            end
            @test (w, h) == (20.0, 20.0)
            c, s = fresh()
            (w, h), (c2, s2) = @prepare_to_picture margin = 3.0 flip = false begin
                c
                s
            end
            @test (w, h) == (16.0, 16.0)
            @test c2 == APCircle2(APPoint(0.0, 0.0), 5.0)
            @test s2 == APSegment(APPoint(-5.0, 5.0), APPoint(3.0, -2.0))
            c, s = fresh()
            (w, h), (c2, s2) = @prepare_to_picture width = 100.0 margin = 5.0 flip = false begin
                c
                s
            end
            @test (w, h) == (100.0, 100.0)
            @test c2 == APCircle2(APPoint(0.0, 0.0), 45.0)
            @test s2 == APSegment(APPoint(-45.0, 45.0), APPoint(27.0, -18.0))
            c, s = fresh()
            (w, h), (c2, s2) = @prepare_to_picture width = 400.0 height = 200.0 flip = false begin
                c
                s
            end
            @test (w, h) == (400.0, 200.0)
            @test c2 isa APCircle2
            @test c2 == APCircle2(APPoint(0.0, 0.0), 100.0)
            @test s2 == APSegment(APPoint(-100.0, 100.0), APPoint(60.0, -40.0))
            c1 = APCircle2(APPoint(0.0, 0.0), 1.0)
            @test_throws LoadError eval(:(@prepare_to_picture scale = 2.0 width = 10.0 c1))
            @test_throws ArgumentError @prepare_to_picture begin end
            c, s = fresh()
            (w, h) = @prepare_to_picture! width = 50.0 flip = false begin
                c
                s
            end
            @test (w, h) == (50.0, 50.0)
            @test c == APCircle2(APPoint(0.0, 0.0), 25.0)
            @test s == APSegment(APPoint(-25.0, 25.0), APPoint(15.0, -10.0))
            function _prepare_to_picture_unnamed_mutating_test()
                c = APCircle2(APPoint(0.0, 0.0), 1.0)
                @prepare_to_picture! begin
                    c
                    APCircle2(APPoint(1.0, 1.0), 1.0)
                end
            end
            @test_throws ArgumentError _prepare_to_picture_unnamed_mutating_test()
            c, _ = fresh()
            (w, h), obj_c = @prepare_to_picture c
            @test (w, h) == (10.0, 10.0)
            @test obj_c.c == APCircle2(APPoint(0.0, 0.0), 5.0)
            centro = APPoint(2.0, 1.0)
            radio = 5.0
            circle = APCircle2(centro, radio)
            (w, h) = @prepare_to_picture! width = 400.0 height = 300.0 begin
                centro
                radio
                circle
            end
            @test (w, h) == (400.0, 300.0)
            @test radio == 5.0
            @test centro == APPoint(0.0, 0.0)
            @test circle == APCircle2(APPoint(0.0, 0.0), 150.0)
            A_dom, B_dom = APPoint(1.0, 1.0), APPoint(3.0, 3.0)
            @prepare_to_picture! width = 500.0 height = 240.0 margin = 20.0 begin
                A_dom
                B_dom
                huge_dom = APCircle2(APPoint(0.0, 0.0), 1000.0)
            end
            @test norm(direction(APLine(A_dom, B_dom))) < 1.0
            A_ub, B_ub = APPoint(1.0, 1.0), APPoint(3.0, 3.0)
            huge_ub = APCircle2(APPoint(0.0, 0.0), 1000.0)
            @prepare_to_picture! width = 500.0 height = 240.0 margin = 20.0 begin
                A_ub
                B_ub
                huge_ub = @unbounded APCircle2(APPoint(0.0, 0.0), 1000.0)
            end
            @test norm(direction(APLine(A_ub, B_ub))) > 1.0
            @test huge_ub.r > 1.0
            A_ub2, B_ub2 = APPoint(1.0, 1.0), APPoint(3.0, 3.0)
            @prepare_to_picture! width = 500.0 height = 240.0 margin = 20.0 begin
                A_ub2
                B_ub2
                @unbounded huge_ub2 = APCircle2(APPoint(0.0, 0.0), 1000.0)
            end
            @test A_ub2 ≈ A_ub && B_ub2 ≈ B_ub && huge_ub2.r ≈ huge_ub.r
            @test (@unbounded 5.0 + 3.0) == 8.0
            @test_throws ArgumentError @prepare_to_picture begin
                z = @unbounded APCircle2(APPoint(0.0, 0.0), 5.0)
            end
            from0 = APPoint(2.0, 3.0)
            v0 = APVector(1.0, -1.0)
            tip0 = from0 + v0
            (_, (from_, v_, tip_)) = @prepare_to_picture width = 500.0 height = 240.0 begin
                from0
                v0
                tip0
            end
            @test v_ isa APVector
            @test norm(v_) > norm(v0)
            @test from_ + v_ ≈ tip_
            @test_throws ArgumentError @prepare_to_picture begin
                num = 5.0
                vec = APVector(1.0, 0.0)
            end
            single_pt = APPoint(1.0, 2.0)
            @test_throws ArgumentError @prepare_to_picture width = 100.0 begin
                single_pt
            end   # a single point has no extent to scale to a width
            _, sp = @prepare_to_picture begin
                single_pt
            end   # without a width or height there is nothing to divide by
            @test sp.single_pt ≈ APPoint(0.0, 0.0)
            # the second value is a NamedTuple with one field per name in the block
            sz_nt, objs_nt = @prepare_to_picture width = 200.0 begin
                nt_a = APPoint(0.0, 0.0)
                nt_c = APCircle2(nt_a, 2.0)
                nt_p, nt_q = intersection(nt_c, APLine(nt_a, APPoint(1.0, 0.0)))
                @unbounded nt_l = APLine(nt_a, APPoint(0.0, 1.0))
            end
            @test objs_nt isa NamedTuple && keys(objs_nt) == (:nt_a, :nt_c, :nt_p, :nt_q, :nt_l)
            @test keys(sz_nt) == (:width, :height, :fct, :bb)
            @test objs_nt.nt_c isa APCircle2 && objs_nt.nt_l isa APLine
            @test sz_nt.fct(nt_c) == objs_nt.nt_c && sz_nt.fct(nt_p) ≈ objs_nt.nt_p
            (; nt_a, nt_q) = objs_nt
            @test nt_a isa APPoint && nt_q isa APPoint
            @test all(values(objs_nt)[k] == objs_nt[k] for k in 1:5)      # positional access still works
            # an unnamed expression has no name to be returned under
            @test_throws ArgumentError @prepare_to_picture begin
                nt_a2 = APPoint(0.0, 0.0)
                APCircle2(nt_a2, 1.0)
            end
            @test_throws ArgumentError @prepare_to_picture! begin
                nt_a3 = APPoint(0.0, 0.0)
                APCircle2(nt_a3, 1.0)
            end
            # a name assigned twice keeps its last value (the first value still counts for the size of the canvas)
            _, dup = @prepare_to_picture begin
                dup_a = APPoint(0.0, 0.0)
                dup_b = APPoint(4.0, 0.0)
                dup_a = APPoint(2.0, 0.0)
            end
            @test keys(dup) == (:dup_a, :dup_b) && isapprox(dup.dup_a, APPoint(0.0, 0.0); atol=1e-9)
            c1 = APCircle2(APPoint(0.0, 0.0), 3.0)
            c2 = APCircle2(APPoint(10.0, 0.0), 3.0)
            (w, h) = @prepare_to_picture! width = 200.0 flip = false begin
                c1
                c2
                el1, el2 = external_tangent_lines(c1, c2)
            end
            @test (w, h) == (200.0, 75.0)
            @test c1 == APCircle2(APPoint(-62.5, 0.0), 37.5)
            @test c2 == APCircle2(APPoint(62.5, 0.0), 37.5)
            @test el1 == APLine(APPoint(-62.5, 37.5), APPoint(62.5, 37.5))
            @test el2 == APLine(APPoint(-62.5, -37.5), APPoint(62.5, -37.5))
            cc1 = APCircle2(APPoint(0.0, 0.0), 3.0)
            cc2 = APCircle2(APPoint(10.0, 0.0), 3.0)
            (w2, h2) = @prepare_to_picture! width = 200.0 begin
                cc1
                cc2
                ee1, ee2 = external_tangent_lines(cc1, cc2)
                P1, P2 = intersection.(ee1, [cc1, cc2])
            end
            @test (w2, h2) == (200.0, 75.0)
            @test P1 == [ee1.p1] && P2 == [ee1.p2]
        end
        @testset "@translate/@rotate/@homothety/@reflection macros" begin
            v = APVector(3.0, -2.0)
            C1, S1, R1 = @translate v begin
                tc = APCircle2(APPoint(0.0, 0.0), 2.0)
                ts = APSegment(APPoint(1.0, 1.0), APPoint(2.0, 2.0))
                tr = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
            end
            @test tc == APCircle2(APPoint(0.0, 0.0), 2.0)
            @test C1 == translate(APCircle2(APPoint(0.0, 0.0), 2.0), v)
            @test S1 == translate(ts, v)
            @test R1 == translate(tr, v)
            p = APPoint(1.0, 0.0)
            @test (@translate v p) == translate(p, v)
            @test p == APPoint(1.0, 0.0)
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
            c1, c2 = APCircle2(APPoint(0.0, 0.0), 2.0), APCircle2(APPoint(10.0, 0.0), 1.0)
            l1, l2 = external_tangent_lines(c1, c2)
            D1, D2 = @translate v begin
                dl1, dl2 = external_tangent_lines(c1, c2)
            end
            @test D1 == translate(l1, v) && D2 == translate(l2, v)
            @test dl1 == l1 && dl2 == l2
            @translate! v begin
                dl1, dl2 = external_tangent_lines(c1, c2)
            end
            @test dl1 == translate(l1, v) && dl2 == translate(l2, v)
            @test isapprox((@rotate (pi / 2) p), rotate(p, pi / 2); atol=1e-9)
            @test isapprox((@rotate (pi / 2) APPoint(1.0, 1.0) p), rotate(p, pi / 2, APPoint(1.0, 1.0)); atol=1e-9)
            p1, p2 = APPoint(1.0, 0.0), APPoint(0.0, 1.0)
            @rotate! (pi / 2) begin
                p1
                p2
            end
            @test isapprox(p1, APPoint(0.0, 1.0); atol=1e-9)
            @test isapprox(p2, APPoint(-1.0, 0.0); atol=1e-9)
            @test (@homothety 2.0 p) == homothety(p, 2.0)
            @test (@homothety 2.0 APPoint(1.0, 1.0) p) == homothety(p, 2.0, APPoint(1.0, 1.0))
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
            L1, C1 = @invert center begin
                il = l
                ic = c1
            end
            @test L1 == invert(l, center)
            @test C1 == invert(c1, center)
            @test il == l && ic == c1
            @test (@invert center 2.0 l) == invert(l, center; k=2.0)
            l2 = APLine(APPoint(2.0, 0.0), APPoint(2.0, 1.0))
            @invert! center l2
            @test l2 == invert(APLine(APPoint(2.0, 0.0), APPoint(2.0, 1.0)), center)
            @test l2 isa APCircle2
            @test (@invert_neg center l) == invert_neg(l, center)
            @test (@invert_neg center 2.0 l) == invert_neg(l, center; k=2.0)
            l3 = APLine(APPoint(2.0, 0.0), APPoint(2.0, 1.0))
            @invert_neg! center l3
            @test l3 == invert_neg(APLine(APPoint(2.0, 0.0), APPoint(2.0, 1.0)), center)
            m = APAffineMap(1.3, 0.4, -0.2, 0.9, 2.0, -1.0)
            t = APTriangle(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
            @test (@affinemap m t) == m(t)
            @test t == APTriangle(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
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
        @test isempty(intersection(s1, s3))
        s4 = APSegment(APPoint(0.0, 1.0), APPoint(2.0, 3.0))
        @test isempty(intersection(s1, s4))
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
        p = APPoint(2.0, 0.0)
        q = harmonic_conjugate(a, b, p)
        @test is_collinear(a, b, q)
        @test_throws ArgumentError harmonic_conjugate(a, b, midpoint(a, b))
    end
    @testset "polar_point" begin
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
        @testset "is_collinear / is_degenerate" begin
            a = APPoint(1234.5678, 9876.5432)
            dir = APVector(cos(0.37), sin(0.37))
            b = a + 5000.0 * dir
            c = a + 12345.678 * dir
            @test is_collinear(a, b, c)
            @test is_degenerate(APTriangle(a, b, c))
            d = a + APVector(0.001, 12345.0)
            @test !is_collinear(a, b, d)
            @test !is_degenerate(APTriangle(a, b, d))
        end
        @testset "is_concyclic" begin
            scale = 1e7
            center = APPoint(2.5, -1.5) * scale
            pts = [center + scale * APVector(cos(t), sin(t)) for t in (0.3, 1.1, 2.4, 4.0)]
            @test is_concyclic(pts...)
        end
        @testset "is_on_line" begin
            scale = 1e8
            a = APPoint(2.5, -1.5) * scale
            dir = APVector(cos(0.37), sin(0.37))
            l = APLine(a, a + scale * dir)
            @test is_on_line(a + 0.3 * scale * dir, l)
        end
        @testset "intersection(APLine, APLine) with short direction vectors" begin
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
                pts = [point_on(e_true, t) for t in (0.1, 1.3, 2.5, 3.7, 5.0)]
                fit = conic_through_points(pts...)
                @test fit.center ≈ e_true.center rtol = 1e-6
                @test fit.a ≈ e_true.a rtol = 1e-6
                @test fit.b ≈ e_true.b rtol = 1e-6
            end
        end
        @testset "APEllipse2/APHyperbola2/APParabola2 polar_line stays well-defined at large scale" begin
            scale = 1e6
            off = APPoint(1.7, -0.9) * scale
            e = APEllipse2(off, 5.0 * scale, 3.0 * scale, 0.3)
            pe = point_on(e, 0.5)
            le = polar_line(e, pe)
            @test distance(le.p1, le.p2) > 1e-3 * scale
            @test any(pt -> distance(pt, pe) <= 1e-3 * scale, intersection(le, e))
            h = APHyperbola2(off, 4.0 * scale, 2.0 * scale, 0.2)
            ph = point_on(h, 0.4)
            lh = polar_line(h, ph)
            @test distance(lh.p1, lh.p2) > 1e-3 * scale
            @test any(pt -> distance(pt, ph) <= 1e-3 * scale, intersection(lh, h))
            par = APParabola2(off, APLine(off + APVector(-5.0, -3.0) * scale, off + APVector(5.0, -3.0) * scale))
            pp = point_on(par, 2.0 * scale)
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
            p1 = point_on(par, 0.5 * scale)
            p2 = point_on(par, -0.8 * scale)
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
            @test invert(c, p_on) isa APLine
            @test polar_line(c, center) === nothing
            l_through_center = APLine(center, center + scale * APVector(1.0, 0.3))
            @test_throws ArgumentError invert(l_through_center, center)
        end
    end
    @testset "scale robustness: small objects far from the origin" begin
        # every case above scales the offset WITH the object (radius/scale grow together), which
        # never actually exercises `tol = sqrt(atol) * max(local_size, norm(center), 1.0)`-style
        # formulas: local_size and norm(center) stay comparable, so norm(center) never dominates.
        # A small, fixed-size object sitting FAR from the origin is the case that broke: found via
        # `intersection(::APCircle2,::APCircle2)` silently collapsing 2 real points into 1.
        offset = 1e6
        off = APPoint(offset, offset)
        @testset "intersection(APCircle2, APCircle2)" begin
            c1 = APCircle2(off, 5.0)
            c2 = APCircle2(off + APVector(6.0, 0.0), 7.0)
            @test length(intersection(c1, c2)) == 2
        end
        @testset "intersection(APLine, APCircle2)" begin
            c = APCircle2(off, 5.0)
            l = APLine(off + APVector(-10.0, 2.0), off + APVector(10.0, 2.0))
            @test length(intersection(l, c)) == 2
        end
        @testset "radical_axis on non-concentric circles" begin
            c1 = APCircle2(off, 5.0)
            c2 = APCircle2(off + APVector(8.0, 0.0), 5.0)
            @test radical_axis(c1, c2) isa APLine
        end
        @testset "p in APCircularArc2" begin
            c = APCircle2(off, 5.0)
            arc = APCircularArc2(c, off + APVector(5.0, 0.0), off + APVector(-5.0, 0.0))
            @test !(off + APVector(0.0, 5.3) in arc)
            @test off + APVector(0.0, 5.0) in arc
        end
        @testset "is_on_line" begin
            l = APLine(off, off + APVector(10.0, 0.0))
            @test !is_on_line(off + APVector(3.0, 0.3), l)
            @test is_on_line(off + APVector(3.0, 0.0), l)
        end
        @testset "line_circle_position / circles_position" begin
            c = APCircle2(off, 5.0)
            secant = APLine(off + APVector(-10.0, 2.0), off + APVector(10.0, 2.0))
            @test line_circle_position(secant, c) == :secant
            c1 = APCircle2(off, 5.0)
            c2 = APCircle2(off + APVector(6.0, 0.0), 7.0)
            @test circles_position(c1, c2) == :secant
        end
        @testset "is_on_parabola / polar_line(APParabola2)" begin
            par = APParabola2(off, APLine(off + APVector(-5.0, -3.0), off + APVector(5.0, -3.0)))
            p_off_curve = off + APVector(0.0, 3.3)
            @test !is_on_parabola(p_off_curve, par)
            @test is_on_parabola(point_on(par, 2.0), par)
            @test polar_line(par, off + APVector(1.0, 5.0)) isa APLine
        end
        @testset "is_concyclic on distinct (not accidentally-concentric-looking) points" begin
            c = APCircle2(off, 5.0)
            pts = [c.center + c.r * APVector(cos(t), sin(t)) for t in (0.3, 1.1, 2.4, 4.0)]
            @test is_concyclic(pts...)
            @test !is_concyclic(pts[1], pts[2], pts[3], off + APVector(5.3, 0.0))
        end
        @testset "triangle_on_segment_sss / apollonius_circle_of_triangle" begin
            p1, p2 = off, off + APVector(6.0, 0.0)
            t3 = triangle_on_segment_sss(p1, p2, 5.0, 7.0)
            @test isapprox(distance(p1, t3.c), 5.0; atol=1e-6) && isapprox(distance(p2, t3.c), 7.0; atol=1e-6)
            tt = APTriangle(p1, p2, off + APVector(2.0, 5.0))
            @test apollonius_circle_of_triangle(tt).r > 0
        end
    end
    @testset "boundary and degenerate configurations" begin
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
            @test isempty(intersection(outer, inner))
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
            @test point_on(e, pi / 2) ≈ APPoint(0.0, 3.0) atol = 1e-9
            f1, f2 = foci(e)
            @test f1 ≈ e.center && f2 ≈ e.center
        end
        @testset "polygon with fewer than 3 distinct vertices" begin
            @test !is_convex(APStraightNgon([APPoint(0.0, 0.0), APPoint(1.0, 0.0)]))
            @test !is_convex(APStraightNgon([APPoint(0.0, 0.0)]))
        end
        @testset "equilateral triangle: coincident centers collapse several axes" begin
            t = APTriangle(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.5, sqrt(3.0) / 2))
            @test circumcircle(t).center ≈ nine_point_circle(t).center
            @test_throws ArgumentError orthic_axis(t)
            @test_throws ArgumentError radical_axis(circumcircle(t), nine_point_circle(t))
            @test lemoine_axis(t) === nothing
            ba = brocard_axis(t)
            @test ba.p1 ≈ ba.p2
        end
    end
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
            @test distance(c, c2) ≈ 3.0
            c2b = Apollonius.APCircle2(APPoint(2.0 + 3.0, -1.0), 2.0)
            @test distance(c, c2b) ≈ 0.0
            c3 = Apollonius.APCircle2(APPoint(20.0, -1.0), 3.0)
            @test distance(c, c3) ≈ 10.0
        end
        @testset "ellipse / hyperbola / parabola (Newton, brute-force checked)" begin
            e = Apollonius.APEllipse2(APPoint(1.0, 2.0), 5.0, 3.0, 0.4)
            for (px, py) in [(20.0, 15.0), (2.0, 2.5), (1.0, 2.0), (6.0, 2.0)]
                p = APPoint(px, py)
                bf = minimum(distance(p, point_on(e, t)) for t in range(0, 2pi; length=20_000))
                @test isapprox(distance(p, e), bf; atol=1e-2)
            end
            ecirc = Apollonius.APEllipse2(APPoint(0.0, 0.0), 5.0, 5.0, 0.0)
            @test isapprox(distance(APPoint(10.0, 0.0), ecirc), 5.0; atol=1e-9)
            h = Apollonius.APHyperbola2(APPoint(0.0, 0.0), 4.0, 2.0, 0.3)
            for (px, py) in [(20.0, 5.0), (0.0, 10.0), (0.0, 0.0)]
                p = APPoint(px, py)
                bf = minimum(distance(p, point_on(h, t; branch=b)) for t in range(-5, 5; length=10_000), b in (1, -1))
                @test isapprox(distance(p, h), bf; atol=2e-2)
            end
            par = Apollonius.APParabola2(APPoint(0.0, 1.0), APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0)))
            for (px, py) in [(20.0, 20.0), (0.0, 0.0), (-5.0, 10.0)]
                p = APPoint(px, py)
                bf = minimum(distance(p, point_on(par, s)) for s in range(-30, 30; length=20_000))
                @test isapprox(distance(p, par), bf; atol=2e-2)
            end
        end
        @testset "conic arcs (range-restricted, brute-force checked)" begin
            c = Apollonius.APCircle2(APPoint(2.0, -1.0), 5.0)
            arc = APCircularArc2(c, c.center + APVector(5.0, 0.0), c.center + APVector(5.0 * cos(2.3), 5.0 * sin(2.3)))
            for p in [APPoint(2.0, -1.0), APPoint(20.0, 10.0), APPoint(-5.0, -8.0)]
                bf = minimum(distance(p, point_on(arc, t)) for t in range(0, 1; length=20_000))
                @test isapprox(distance(p, arc), bf; atol=1e-2)
            end
            e = Apollonius.APEllipse2(APPoint(1.0, 2.0), 5.0, 3.0, 0.4)
            earc = APEllipticArc2(e, point_on(e, 0.3), point_on(e, 3.5))
            for p in [APPoint(15.0, 10.0), APPoint(-10.0, -5.0)]
                bf = minimum(distance(p, point_on(earc, t)) for t in range(0, 1; length=20_000))
                @test isapprox(distance(p, earc), bf; atol=2e-2)
            end
            h = Apollonius.APHyperbola2(APPoint(0.0, 0.0), 2.0, 1.0, 0.1)
            harc = APHyperbolicArc2(h, point_on(h, 0.2; branch=1), point_on(h, 1.5; branch=1))
            for p in [APPoint(4.93, -0.33), APPoint(10.0, -5.0)]
                bf = minimum(distance(p, point_on(harc, t)) for t in range(0, 1; length=20_000))
                @test isapprox(distance(p, harc), bf; atol=5e-2)
            end
            par = Apollonius.APParabola2(APPoint(0.0, 1.0), APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0)))
            parc = APParabolicArc2(par, point_on(par, -3.0), point_on(par, 4.0))
            for p in [APPoint(10.0, 10.0), APPoint(-8.0, 5.0)]
                bf = minimum(distance(p, point_on(parc, t)) for t in range(0, 1; length=20_000))
                @test isapprox(distance(p, parc), bf; atol=5e-2)
            end
        end
        @testset "polygon family (mode=:region/:boundary)" begin
            t = APTriangle(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 3.0))
            @test distance(APPoint(1.0, 1.0), t; mode=:region) == 0.0
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
            @test distance(APPoint(1.0, 1.0), sec; mode=:region) == 0.0
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
            ang = APAngle2(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
            @test distance(APPoint(0.5, 0.5), ang; mode=:region) == 0.0
            @test distance(APPoint(-1.0, -1.0), ang; mode=:region) ≈ distance(APPoint(-1.0, -1.0), ang; mode=:boundary)
            @test distance(APPoint(-1.0, -1.0), ang; mode=:boundary) ≈ sqrt(2.0)
            ang_reflex = APAngle2(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(-1.0, -0.001))
            @test Apollonius.normalized_measure(ang_reflex) > pi
            p = APPoint(0.0, -5.0)
            bf = min(distance(p, APRay(ang_reflex.vertex, ang_reflex.a)), distance(p, APRay(ang_reflex.vertex, ang_reflex.b)))
            @test isapprox(distance(p, ang_reflex; mode=:boundary), bf)
        end
    end
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
                @test isapprox(point_on(te, t), point_on(e, t) + v; atol=1e-9)
            end
            h = APHyperbola2(APPoint(0.0, 0.0), 2.0, 1.0, 0.1)
            th = translate(h, v)
            @test isapprox(point_on(th, 0.5; branch=1), point_on(h, 0.5; branch=1) + v; atol=1e-9)
            par = APParabola2(APPoint(0.0, 1.0), APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0)))
            tpar = translate(par, v)
            @test isapprox(point_on(tpar, 2.0), point_on(par, 2.0) + v; atol=1e-9)
            arc = APCircularArc2(c, c.center + APVector(5.0, 0.0), c.center + APVector(0.0, 5.0))
            tarc = translate(arc, v)
            @test isapprox(point_on(tarc, 0.3), point_on(arc, 0.3) + v; atol=1e-9)
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
            @test isapprox(point_on(sides(tg)[1], 0.4), point_on(sides(g)[1], 0.4) + v; atol=1e-6)
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
            m = APAffineMap(1.3, 0.4, -0.2, 0.9, 2.0, -1.0)
            e = APEllipse2(APPoint(1.0, 2.0), 5.0, 3.0, 0.4)
            te = m(e)
            for t in range(0, 2pi; length=15)
                @test is_on_ellipse(m(point_on(e, t)), te; atol=1e-6)
            end
            h = APHyperbola2(APPoint(0.0, 0.0), 2.0, 1.0, 0.1)
            th = m(h)
            for t in range(-2, 2; length=15), br in (1, -1)
                @test is_on_hyperbola(m(point_on(h, t; branch=br)), th; atol=1e-6)
            end
            par = APParabola2(APPoint(0.0, 1.0), APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0)))
            tpar = m(par)
            for s in range(-5, 5; length=15)
                @test is_on_parabola(m(point_on(par, s)), tpar; atol=1e-6)
            end
        end
        @testset "APAffineMap: conic arcs, incl. orientation-reversing maps" begin
            m_orient_preserving = APAffineMap(1.3, 0.4, -0.2, 0.9, 2.0, -1.0)
            m_orient_reversing = APAffineMap(1.3, 0.4, 0.2, -0.9, 2.0, -1.0)
            for m in (m_orient_preserving, m_orient_reversing)
                c = APCircle2(APPoint(2.0, -1.0), 5.0)
                arc = APCircularArc2(c, c.center + APVector(5.0, 0.0), c.center + APVector(5.0 * cos(2.3), 5.0 * sin(2.3)))
                tarc = m(arc)
                @test tarc isa APEllipticArc2
                t1 = Apollonius._ellipse_param(tarc.ellipse, tarc.p1)
                for t in range(0, 1; length=10)
                    q = m(point_on(arc, t))
                    tp = Apollonius._ellipse_param(tarc.ellipse, q)
                    delta = mod(tp - t1, 2pi)
                    @test (delta <= measure(tarc) + 1e-6) || (delta >= 2pi - 1e-6)
                end
                h = APHyperbola2(APPoint(0.0, 0.0), 2.0, 1.0, 0.1)
                harc = APHyperbolicArc2(h, point_on(h, 0.2; branch=1), point_on(h, 1.3; branch=1))
                tharc = m(harc)
                @test isapprox(m(point_on(harc, 0.5)), point_on(tharc, 0.5); atol=1e-6)
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
            arc = APCircularArc2(c, point_on(e0, 0.2), point_on(e0, 2.0))
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
    @testset "bounding box extension (ellipse, conic arcs, curved regions)" begin
        @testset "APEllipse2" begin
            e = APEllipse2(APPoint(1.0, 2.0), 5.0, 3.0, 0.4)
            bb = APBoundingBox(e)
            for t in range(0, 2pi; length=30)
                p = point_on(e, t)
                @test bb.min[1] - 1e-6 <= p[1] <= bb.max[1] + 1e-6
                @test bb.min[2] - 1e-6 <= p[2] <= bb.max[2] + 1e-6
            end
            e0 = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0, 0.0)
            @test APBoundingBox(e0) == APBoundingBox(APPoint(-5.0, -3.0), APPoint(5.0, 3.0))
        end
        @testset "conic arcs stay within their own bounding box" begin
            c = APCircle2(APPoint(1.0, -2.0), 5.0)
            e0 = APEllipse2(c.center, c.r, c.r, 0.0)
            arc = APCircularArc2(c, point_on(e0, 0.3), point_on(e0, 2.5))
            bb = APBoundingBox(arc)
            for t in range(0, 1; length=20)
                p = point_on(arc, t)
                @test bb.min[1] - 1e-6 <= p[1] <= bb.max[1] + 1e-6 && bb.min[2] - 1e-6 <= p[2] <= bb.max[2] + 1e-6
            end
            e = APEllipse2(APPoint(2.0, 1.0), 3.0, 1.5, 0.3)
            earc = APEllipticArc2(e, point_on(e, 0.2), point_on(e, 3.5))
            bb2 = APBoundingBox(earc)
            for t in range(0, 1; length=20)
                p = point_on(earc, t)
                @test bb2.min[1] - 1e-6 <= p[1] <= bb2.max[1] + 1e-6 && bb2.min[2] - 1e-6 <= p[2] <= bb2.max[2] + 1e-6
            end
            h = APHyperbola2(APPoint(0.0, 0.0), 2.0, 1.0, 0.1)
            harc = APHyperbolicArc2(h, point_on(h, -1.0; branch=1), point_on(h, 1.5; branch=1))
            bb3 = APBoundingBox(harc)
            for t in range(0, 1; length=20)
                p = point_on(harc, t)
                @test bb3.min[1] - 1e-6 <= p[1] <= bb3.max[1] + 1e-6 && bb3.min[2] - 1e-6 <= p[2] <= bb3.max[2] + 1e-6
            end
            par = APParabola2(APPoint(0.0, 1.0), APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0)))
            parc = APParabolicArc2(par, point_on(par, -3.0), point_on(par, 4.0))
            bb4 = APBoundingBox(parc)
            for t in range(0, 1; length=20)
                p = point_on(parc, t)
                @test bb4.min[1] - 1e-6 <= p[1] <= bb4.max[1] + 1e-6 && bb4.min[2] - 1e-6 <= p[2] <= bb4.max[2] + 1e-6
            end
        end
        @testset "curved regions (via sides -- vertices(p) is now derived from sides(p))" begin
            point_on_arc_or_seg(s::APSegment, t) = s.p1 + t * (s.p2 - s.p1)
            point_on_arc_or_seg(s, t) = point_on(s, t)
            c = APCircle2(APPoint(1.0, -2.0), 5.0)
            e0 = APEllipse2(c.center, c.r, c.r, 0.0)
            arc = APCircularArc2(c, point_on(e0, 0.3), point_on(e0, 2.5))
            sec = APCircularSector2(arc)
            bb_sec = APBoundingBox(sec)
            for side in sides(sec), t in range(0, 1; length=15)
                p = point_on_arc_or_seg(side, t)
                @test bb_sec.min[1] - 1e-6 <= p[1] <= bb_sec.max[1] + 1e-6 && bb_sec.min[2] - 1e-6 <= p[2] <= bb_sec.max[2] + 1e-6
            end
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
                p = point_on(side, t)
                @test bb_g.min[1] - 1e-6 <= p[1] <= bb_g.max[1] + 1e-6 && bb_g.min[2] - 1e-6 <= p[2] <= bb_g.max[2] + 1e-6
            end
        end
    end
    @testset "Base.in coverage: every APCurve/APPolygon type, not just the named predicates" begin
        @testset "APSegment / APLine / APRay: in matches is_on_segment/is_on_line/is_on_ray" begin
            s = APSegment(APPoint(0.0, 0.0), APPoint(4.0, 4.0))
            l = APLine(APPoint(0.0, 0.0), APPoint(4.0, 4.0))
            r = APRay(APPoint(0.0, 0.0), APPoint(4.0, 4.0))
            mid = APPoint(2.0, 2.0)
            beyond = APPoint(6.0, 6.0)
            behind = APPoint(-2.0, -2.0)
            off_line = APPoint(2.0, 3.0)
            @test mid in s
            @test !(off_line in s)
            @test !(beyond in s)
            @test (mid in s) == is_on_segment(mid, s)
            @test (beyond in s) == is_on_segment(beyond, s)
            @test mid in l
            @test beyond in l
            @test !(off_line in l)
            @test (mid in l) == is_on_line(mid, l)
            @test mid in r
            @test beyond in r
            @test !(behind in r)
            @test is_on_ray(mid, r) && is_on_ray(beyond, r) && !is_on_ray(behind, r)
            @test (mid in r) == is_on_ray(mid, r)
        end
        @testset "conic arcs: in tests the arc's own sweep, not the full curve" begin
            circ = APCircle2(APPoint(0.0, 0.0), 5.0)
            carc = APCircularArc2(circ, APPoint(5.0, 0.0), APPoint(0.0, 5.0))
            @test APPoint(5 / sqrt(2), 5 / sqrt(2)) in carc
            @test !(APPoint(-5.0, 0.0) in carc)
            @test !(APPoint(3.0, 3.0) in carc)
            ell = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
            earc = APEllipticArc2(ell, point_on(ell, 0.2), point_on(ell, 2.0))
            @test point_on(earc, 0.5) in earc
            @test !(point_on(ell, 4.0) in earc)
            par = APParabola2(APPoint(0.0, 1.0), APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0)))
            parc = APParabolicArc2(par, point_on(par, -3.0), point_on(par, 3.0))
            @test point_on(parc, 0.5) in parc
            @test !(point_on(par, 10.0) in parc)
            hyp = APHyperbola2(APPoint(0.0, 0.0), 3.0, 4.0)
            harc = APHyperbolicArc2(hyp, point_on(hyp, -0.5), point_on(hyp, 0.5))
            @test point_on(harc, 0.5) in harc
            @test !(point_on(hyp, 0.5; branch=-1) in harc)
        end
        @testset "curved regions: in/distance work via sides(), agree with the bespoke sector/segment methods" begin
            circ = APCircle2(APPoint(0.0, 0.0), 5.0)
            carc = APCircularArc2(circ, APPoint(5.0, 0.0), APPoint(0.0, 5.0))
            sector = APCircularSector2(carc)
            asec = APAnnularSector2(carc, 2.0)
            @test APPoint(3.5 / sqrt(2), 3.5 / sqrt(2)) in asec
            @test !(APPoint(1 / sqrt(2), 1 / sqrt(2)) in asec)
            @test !(APPoint(7 / sqrt(2), 7 / sqrt(2)) in asec)
            @test !(APPoint(-3.5, 0.0) in asec)
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
            ct = APCurvilinearTriangle2(radius, carc, chord)
            cngon = APCurvilinearNgon2([radius, carc, chord])
            for x in -6.0:1.5:6.0, y in -6.0:1.5:6.0
                p = APPoint(x, y)
                @test (p in ct) == (p in sector)
                @test (p in cngon) == (p in sector)
            end
        end
    end
    if false
    @testset "3D geometry (Phase 1: plane/sphere foundation)" begin
        @testset "APPlane3 construction, distance, projection, reflection" begin
            xy = APPlane3(APPoint(0.0, 0.0, 0.0), APVector(0.0, 0.0, 1.0))
            @test xy.normal ≈ APVector(0.0, 0.0, 1.0)
            pl2 = APPlane3(APPoint(0.0, 0.0, 0.0), APVector(0.0, 0.0, 5.0))
            @test pl2.normal ≈ APVector(0.0, 0.0, 1.0)
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
            @test rotate(APPoint(1.0, 0.0, 5.0), pi / 2, zaxis) ≈ APPoint(0.0, 1.0, 5.0) atol = 1e-12
            @test rotate(APPoint(1.0, 0.0, 0.0), 2pi, zaxis) ≈ APPoint(1.0, 0.0, 0.0) atol = 1e-9
            axis = APLine(APPoint(1.0, 0.0, 0.0), APPoint(1.0, 0.0, 1.0))
            @test rotate(APPoint(2.0, 0.0, 0.0), pi / 2, axis) ≈ APPoint(1.0, 1.0, 0.0) atol = 1e-12
            @test rotate(APPoint(1.0, 0.0, 7.0), pi / 3, axis) ≈ APPoint(1.0, 0.0, 7.0) atol = 1e-12
            seg = APSegment(APPoint(2.0, 0.0, 0.0), APPoint(2.0, 0.0, 5.0))
            rseg = rotate(seg, pi / 2, axis)
            @test rseg.p1 ≈ APPoint(1.0, 1.0, 0.0) atol = 1e-12
            @test rseg.p2 ≈ APPoint(1.0, 1.0, 5.0) atol = 1e-12
            v = APVector(0.0, 0.0, 10.0)
            @test translate(seg, v).p1 ≈ APPoint(2.0, 0.0, 10.0)
            @test homothety(seg, 2.0, APPoint(0.0, 0.0, 0.0)).p2 ≈ APPoint(4.0, 0.0, 10.0)
            xy = APPlane3(APPoint(0.0, 0.0, 0.0), APVector(0.0, 0.0, 1.0))
            @test reflection(seg, xy).p2 ≈ APPoint(2.0, 0.0, -5.0)
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
            @test is_on_line(APPoint(0.0, 0.0, 0.0), iline)
            @test is_on_line(APPoint(7.0, 0.0, 0.0), iline)
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
            xy = APPlane3(APPoint(0.0, 0.0, 0.0), APVector(0.0, 0.0, 1.0))
            gc = intersection(xy, sph)
            @test gc isa APCircle3
            @test gc.r ≈ 5.0
            @test gc.center ≈ APPoint(0.0, 0.0, 0.0)
            tangent_pl = APPlane3(APPoint(0.0, 0.0, 5.0), APVector(0.0, 0.0, 1.0))
            tp = intersection(tangent_pl, sph)
            @test tp isa APPoint
            @test tp ≈ APPoint(0.0, 0.0, 5.0)
            far_pl = APPlane3(APPoint(0.0, 0.0, 10.0), APVector(0.0, 0.0, 1.0))
            @test intersection(far_pl, sph) === nothing
            s1 = APSphere3(APPoint(0.0, 0.0, 0.0), 5.0)
            s2 = APSphere3(APPoint(6.0, 0.0, 0.0), 5.0)
            circ = intersection(s1, s2)
            @test circ isa APCircle3
            @test circ.center ≈ APPoint(3.0, 0.0, 0.0)
            @test circ.r ≈ 4.0
            @test all(isapprox.(distance.(Ref(circ.center), (s1.center, s2.center)), (3.0, 3.0)))
            s3 = APSphere3(APPoint(10.0, 0.0, 0.0), 5.0)
            tangent_pt = intersection(s1, s3)
            @test tangent_pt isa APPoint
            @test tangent_pt ≈ APPoint(5.0, 0.0, 0.0)
            s4 = APSphere3(APPoint(100.0, 0.0, 0.0), 5.0)
            @test intersection(s1, s4) === nothing
            s5 = APSphere3(APPoint(0.0, 0.0, 0.0), 2.0)
            @test intersection(s1, s5) === nothing
        end
        @testset "APAffineMap3: rotation_map/homothety_map/reflection_map/translation_map, ∘, affine_map" begin
            axis = APLine(APPoint(0.0, 0.0, 0.0), APPoint(0.0, 0.0, 1.0))
            p = APPoint(1.0, 0.0, 0.0)
            rm = rotation_map(pi / 2, axis)
            @test rm(p) ≈ rotate(p, pi / 2, axis) atol = 1e-12
            @test rm(APVector(1.0, 0.0, 0.0)) ≈ APVector(0.0, 1.0, 0.0) atol = 1e-12
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
            composed = rm ∘ tm
            @test composed(APPoint(0.0, 0.0, 0.0)) ≈ rm(tm(APPoint(0.0, 0.0, 0.0))) atol = 1e-12
            @test composed isa APAffineMap3
            seg = APSegment(APPoint(1.0, 0.0, 0.0), APPoint(2.0, 0.0, 0.0))
            @test rm(seg).p1 ≈ APPoint(0.0, 1.0, 0.0) atol = 1e-12
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
            @test APPoint(0.0, 0.0, 0.0) in hs
            @test distance(APPoint(0.0, 0.0, 3.0), hs) == 0.0
            @test distance(APPoint(0.0, 0.0, 3.0), hs; mode=:boundary) ≈ 3.0
            @test distance(APPoint(0.0, 0.0, -3.0), hs) ≈ 3.0
            @test_throws ArgumentError APHalfSpace3(xy, APPoint(1.0, 1.0, 0.0))
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
            @test measure(reflection(d, xy)) ≈ pi / 2
            @test measure(reflection(d, APPoint(0.0, 0.0, 0.0))) ≈ pi / 2
            @test measure(homothety(d, -1.0, APPoint(0.0, 0.0, 0.0))) ≈ pi / 2
            @test measure(homothety(d, 2.0, APPoint(0.0, 0.0, 0.0))) ≈ pi / 2
        end
        @testset "APPolyhedralAngle3 (n=3 is the 'triedro')" begin
            vertex = APPoint(0.0, 0.0, 0.0)
            rays = [APPoint(1.0, 0.0, 0.0), APPoint(0.0, 1.0, 0.0), APPoint(0.0, 0.0, 1.0)]
            pa = APPolyhedralAngle3(vertex, rays)
            @test solid_angle(pa) ≈ pi / 2
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
            t2 = APTetrahedron3(APPoint(0.0, 0.0, 1.0), APPoint(0.0, 0.0, 0.0), APPoint(1.0, 0.0, 0.0), APPoint(0.0, 1.0, 0.0))
            @test volume(t2) ≈ 1 / 6
            @test centroid(t2) ≈ APPoint(0.25, 0.25, 0.25)
            axis = APLine(APPoint(0.0, 0.0, 0.0), APPoint(0.0, 0.0, 1.0))
            @test volume(rotate(t, pi / 3, axis)) ≈ volume(t)
            @test volume(translate(t, APVector(10.0, 20.0, 30.0))) ≈ volume(t)
            @test volume(homothety(t, 2.0, APPoint(0.0, 0.0, 0.0))) ≈ volume(t) * 8
            @test volume(homothety(t, -2.0, APPoint(0.0, 0.0, 0.0))) ≈ volume(t) * 8
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
            @test volume(pyr) ≈ 4.0
            c = centroid(pyr)
            @test c[3] ≈ 0.75
            @test c[1] ≈ 0.0 atol = 1e-12
            @test c[2] ≈ 0.0 atol = 1e-12
            @test length(faces(pyr)) == 5
        end
        @testset "APPrism3" begin
            base_sq = APStraightNgon([APPoint(-1.0, -1.0, 0.0), APPoint(1.0, -1.0, 0.0), APPoint(1.0, 1.0, 0.0), APPoint(-1.0, 1.0, 0.0)])
            prism = APPrism3(base_sq, APVector(0.0, 0.0, 5.0))
            @test volume(prism) ≈ 20.0
            @test centroid(prism) ≈ APPoint(0.0, 0.0, 2.5)
            @test surface_area(prism) ≈ 2 * 4 + 4 * (2 * 5)
            @test length(faces(prism)) == 6
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
            @test !(APPoint(3.0, 0.0, 5.0) in cyl)
            @test !(APPoint(1.0, 0.0, 15.0) in cyl)
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
            @test APPoint(2.0, 0.0, 0.0) in cone
            @test APPoint(0.0, 0.0, 9.0) in cone
            @test !(APPoint(2.0, 0.0, 8.0) in cone)
            @test base(cone).r == 3.0
        end
    end
    @testset "3D geometry (correctness fixes and coverage gaps)" begin
        @testset "centroid/is_convex/point_in_polygon/is_planar for APPolygon{3}" begin
            tri3 = APTriangle(APPoint(0.0, 0.0, 0.0), APPoint(4.0, 0.0, 0.0), APPoint(0.0, 4.0, 0.0))
            @test centroid(tri3) ≈ APPoint(4 / 3, 4 / 3, 0.0)
            @test is_convex(tri3)
            @test area(tri3) ≈ 8.0
            sq = APStraightNgon([APPoint(0.0, 0.0, 0.0), APPoint(1.0, 0.0, 1.0), APPoint(1.0, 1.0, 1.0), APPoint(0.0, 1.0, 0.0)])
            @test is_planar(sq)
            @test area(sq) ≈ sqrt(2.0)
            @test centroid(sq) ≈ APPoint(0.5, 0.5, 0.5)
            @test is_convex(sq)
            @test centroid(sq) in sq
            @test !(APPoint(5.0, 5.0, 5.0) in sq)
            non_planar = APStraightNgon([APPoint(0.0, 0.0, 0.0), APPoint(1.0, 0.0, 0.0), APPoint(1.0, 1.0, 1.0), APPoint(0.0, 1.0, 0.0)])
            @test !is_planar(non_planar)
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
            @test distance(APPoint(0.0, 0.0, 5.0), cyl) == 0.0
            @test distance(APPoint(0.0, 0.0, 5.0), cyl; mode=:boundary) ≈ 2.0
            @test distance(APPoint(5.0, 0.0, 5.0), cyl) ≈ 3.0
            @test distance(APPoint(0.0, 0.0, 15.0), cyl) ≈ 5.0
            @test distance(APPoint(5.0, 0.0, 15.0), cyl) ≈ sqrt(3.0^2 + 5.0^2)
            @test (distance(APPoint(0.0, 0.0, 5.0), cyl) == 0.0) == (APPoint(0.0, 0.0, 5.0) in cyl)
            cone = APCone3(APPoint(0.0, 0.0, 9.0), APPoint(0.0, 0.0, 0.0), 3.0)
            @test distance(APPoint(0.0, 0.0, 3.0), cone) == 0.0
            @test distance(APPoint(0.0, 0.0, 0.0), cone; mode=:boundary) == 0.0
            @test distance(APPoint(100.0, 0.0, 0.0), cone) ≈ 97.0
        end
    end
    @testset "3D conics (APEllipse3/APParabola3/APHyperbola3 + arcs)" begin
        @testset "APCircle3 fuller API" begin
            c = APCircle3(APPoint(0.0, 0.0, 5.0), 3.0, APVector(0.0, 0.0, 1.0))
            p0 = point_on_circle3(c, 0.0)
            @test is_on_circle3(p0, c)
            @test distance(p0, c.center) ≈ 3.0
            @test point_on_circle3(c, pi / 2)[3] == 5.0
        end
        @testset "APEllipse3" begin
            e = APEllipse3(APPoint(1.0, 1.0, 1.0), 5.0, 3.0, APVector(0.0, 0.0, 1.0), APVector(1.0, 0.0, 0.0))
            @test area(e) ≈ pi * 15
            p_on = point_on_ellipse3(e, 0.7)
            @test is_on_ellipse3(p_on, e)
            @test p_on[3] ≈ 1.0
            f1, f2 = foci(e)
            @test distance(p_on, f1) + distance(p_on, f2) ≈ 10.0
            @test distance(e.center, e) ≈ 3.0
            e2 = APEllipse3(APPoint(0.0, 0.0, 0.0), 4.0, 2.0, APVector(1.0, 1.0, 1.0), APVector(1.0, -1.0, 0.0))
            @test dot(e2.u, e2.normal) ≈ 0.0 atol = 1e-12
            @test norm(e2.u) ≈ 1.0
            @test norm(e2.normal) ≈ 1.0
            p2 = point_on_ellipse3(e2, 1.3)
            @test is_on_ellipse3(p2, e2)
            @test on_plane(p2, plane(e2))
            f1b, f2b = APPoint(-3.0, 0.0, 0.0), APPoint(3.0, 0.0, 0.0)
            pb = APPoint(0.0, 4.0, 0.0)
            eb = APEllipse3(f1b, f2b, pb)
            @test is_on_ellipse3(pb, eb)
            @test eb.a ≈ 5.0
            ec = APEllipse3(f1b, f2b, 5.0, APVector(0.0, 0.0, 1.0))
            @test ec.b ≈ 4.0
            @test_throws ArgumentError APEllipse3(f1b, f2b, 2.0, APVector(0.0, 0.0, 1.0))
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
            @test is_on_line(h.center, asym1)
            @test is_on_line(h.center, asym2)
            f1b, f2b = APPoint(-5.0, 0.0, 0.0), APPoint(5.0, 0.0, 0.0)
            pb = APPoint(3.0, 0.0, 0.0)
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
        @testset "Arcs: measure/arc_length/reverse/point_on/Base.in" begin
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
            @test point_on(earc, 0.0) ≈ p1e
            @test point_on(earc, 1.0) ≈ p2e
            @test arc_length(earc) > distance(p1e, p2e)
            par = APParabola3(APPoint(0.0, 1.0, 0.0), APLine(APPoint(-5.0, -1.0, 0.0), APPoint(5.0, -1.0, 0.0)))
            parc = APParabolicArc3(par, point_on_parabola3(par, -3.0), point_on_parabola3(par, 3.0))
            @test arc_length(parc) > distance(parc.p1, parc.p2)
            hyp = APHyperbola3(APPoint(0.0, 0.0, 0.0), 3.0, 4.0, APVector(0.0, 0.0, 1.0), APVector(1.0, 0.0, 0.0))
            harc = APHyperbolicArc3(hyp, point_on_hyperbola3(hyp, -0.5), point_on_hyperbola3(hyp, 0.5))
            @test harc isa APHyperbolicArc3
            @test point_on(harc, 0.0) ≈ harc.p1 atol = 1e-9
        end
    end
    @testset "Quadric surfaces" begin
        @testset "APEllipsoid3" begin
            e = APEllipsoid3(APPoint(0.0, 0.0, 0.0), 3.0, 4.0, 5.0, APVector(1.0, 0.0, 0.0), APVector(0.0, 1.0, 0.0))
            @test volume(e) ≈ (4 / 3) * pi * 60.0
            sph_like = APEllipsoid3(APPoint(0.0, 0.0, 0.0), 2.0, 2.0, 2.0, APVector(1.0, 0.0, 0.0), APVector(0.0, 1.0, 0.0))
            @test surface_area(sph_like) ≈ 4 * pi * 4.0
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
            @test sign(dot(pa - h2.center, w)) != sign(dot(pb - h2.center, w))
            @test_throws ArgumentError APHyperboloid3(APPoint(0.0, 0.0, 0.0), 1.0, 1.0, 1.0, APVector(1.0, 0.0, 0.0), APVector(0.0, 1.0, 0.0); sheets=3)
        end
        @testset "APHyperbolicParaboloid3 (the saddle)" begin
            hp = APHyperbolicParaboloid3(APPoint(0.0, 0.0, 0.0), 2.0, 3.0, APVector(0.0, 0.0, 1.0), APVector(1.0, 0.0, 0.0))
            @test is_on_hyperbolic_paraboloid3(point_on_hyperbolic_paraboloid3(hp, 1.0, 1.0), hp)
            along_x = point_on_hyperbolic_paraboloid3(hp, 2.0, 0.0)
            along_y = point_on_hyperbolic_paraboloid3(hp, 0.0, 2.0)
            @test dot(along_x - hp.vertex, hp.axis) > 0
            @test dot(along_y - hp.vertex, hp.axis) < 0
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
    end
    @testset "APEquipollentVector" begin
        ev = APEquipollentVector(APVector(3.0, 4.0), APPoint(1.0, 2.0))
        @test tip(ev) ≈ APPoint(4.0, 6.0)
        @test direction(ev) == ev.vector
        @test !isempty(APBoundingBox(ev))
        @test APBoundingBox(ev) == APBoundingBox(APPoint(1.0, 2.0), APPoint(4.0, 6.0))
        @test APEquipollentVector(APVector(3.0, 4.0)).point == APPoint(0.0, 0.0)
        @test norm(ev) ≈ 5.0
        @test normalize(ev).point == ev.point
        @test normalize(ev).vector ≈ APVector(0.6, 0.8)
        @test dot(ev, APVector(1.0, 0.0)) ≈ 3.0
        @test dot(APVector(1.0, 0.0), ev) ≈ 3.0
        @test dot(ev, APEquipollentVector(APVector(0.0, 1.0), APPoint(5.0, 5.0))) ≈ 4.0
        @test (ev + APVector(1.0, 1.0)).point == ev.point
        @test (ev + APVector(1.0, 1.0)).vector ≈ APVector(4.0, 5.0)
        @test APVector(1.0, 1.0) + ev == ev + APVector(1.0, 1.0)
        @test (ev - APVector(1.0, 1.0)).vector ≈ APVector(2.0, 3.0)
        q = APPoint(10.0, 20.0)
        @test q + ev == q + ev.vector
        @test ev + q == q + ev
        @test q + ev ≈ APPoint(13.0, 24.0)
        evt = translate(ev, APVector(10.0, 10.0))
        @test evt.point ≈ APPoint(11.0, 12.0)
        @test evt.vector == ev.vector
        @test APVector(ev) == ev.vector
        @test APVector(ev) === ev.vector
        w = APEquipollentVector(APVector(3.0, 4.0), APPoint(100.0, 100.0))
        p = APPoint(1.0, 2.0)
        @test translate(p, w) ≈ APPoint(4.0, 6.0)
        s = APSegment(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
        @test translate(s, w) == APSegment(APPoint(3.0, 4.0), APPoint(4.0, 4.0))
        evw = translate(ev, w)
        @test evw.point ≈ APPoint(4.0, 6.0)
        @test evw.vector == ev.vector
        evr = rotate(ev, pi / 2, APPoint(0.0, 0.0))
        @test evr.point ≈ APPoint(-2.0, 1.0)
        @test evr.vector ≈ APVector(-4.0, 3.0)
        evh = homothety(ev, 2.0, APPoint(0.0, 0.0))
        @test evh.point ≈ APPoint(2.0, 4.0)
        @test evh.vector ≈ APVector(6.0, 8.0)
        evhneg = homothety(ev, -1.0, APPoint(0.0, 0.0))
        @test evhneg.point ≈ APPoint(-1.0, -2.0)
        @test evhneg.vector ≈ APVector(-3.0, -4.0)
        refl_pt = reflection(ev, APPoint(0.0, 0.0))
        @test refl_pt.point ≈ APPoint(-1.0, -2.0)
        @test refl_pt.vector ≈ APVector(-3.0, -4.0)
        refl_line = reflection(ev, APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0)))
        @test refl_line.point ≈ APPoint(1.0, -2.0)
        @test refl_line.vector ≈ APVector(3.0, -4.0)
        ev3d = APEquipollentVector(APVector(1.0, 0.0, 0.0), APPoint(1.0, 2.0, 3.0))
        axis = APLine(APPoint(0.0, 0.0, 0.0), APPoint(0.0, 0.0, 1.0))
        ev3dr = rotate(ev3d, pi / 2, axis)
        @test ev3dr.point ≈ APPoint(-2.0, 1.0, 3.0) atol = 1e-12
        @test ev3dr.vector ≈ APVector(0.0, 1.0, 0.0) atol = 1e-12
        ev3dh = homothety(ev3d, 3.0, APPoint(0.0, 0.0, 0.0))
        @test ev3dh.point ≈ APPoint(3.0, 6.0, 9.0)
        @test ev3dh.vector ≈ APVector(3.0, 0.0, 0.0)
        raw = APEquipollentVector(direction(APLine(APPoint(3.0, 4.0), APPoint(0.0, 0.0))), APPoint(0.0, 0.0))
        sz, ev_placed = @prepare_to_picture width=500 height=240 margin=20 begin
            evp = raw
        end
        @test norm(ev_placed.evp.vector) > norm(raw.vector)
    end
    @testset "Luxor extension" begin
        @test isempty(methods(path))
        using Luxor
        @test Base.get_extension(Apollonius, :ApolloniusLuxorExt) !== nothing
        @test !isempty(methods(path))
        mktempdir() do dir
            Luxor.Drawing(200, 200, joinpath(dir, "test.png"))
            Luxor.origin()
            t = APTriangle(APPoint(-80.0, 60.0), APPoint(80.0, 60.0), APPoint(-20.0, -80.0))
            ang = APAngle2(t[1], t[2], t[3])
            Luxor.sethue("red")
            path(t; action=:stroke)
            path(circumcircle(t); action=:stroke)
            path(incenter(t); action=:fill)
            path(APSegment(APPoint(0.0, 0.0), APPoint(50.0, 50.0)); action=:stroke)
            path(APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)); action=:stroke)
            path(APRay(APPoint(0.0, 0.0), APPoint(1.0, 1.0)); action=:stroke)
            path(Apollonius.APBoundingBox(t); action=:stroke)
            path(APEllipse2(APPoint(0.0, 0.0), 40.0, 20.0, pi / 6); action=:stroke)
            path(APParabola2(APPoint(0.0, 20.0), APLine(APPoint(-50.0, -20.0), APPoint(50.0, -20.0))); action=:stroke)
            path(APHyperbola2(APPoint(0.0, 0.0), 20.0, 10.0); action=:stroke)
            path(ang; as=:rays, action=:stroke)
            path(only(marks(ang)); action=:stroke)
            path(APCircularSector2(only(marks(ang))); action=:fill)
            path(only(marks(ang; style=:parallelogram)); action=:stroke)
            path(APQuadrilateral(ang.vertex, only(marks(ang; style=:parallelogram)).vertices...); action=:fill)
            path(ang; as=:region, action=:fill)
            path(ang; as=:region, action=:fillstroke)
            @test_throws ArgumentError path(ang; as=:bogus)
            hp0 = APHalfPlane2(APLine(APPoint(0.0, -5.0), APPoint(0.0, 5.0)), APPoint(1.0, 0.0))
            path(hp0; action=:fill)
            path(hp0; action=:fillstroke)
            st0 = APStrip2(APLine(APPoint(-10.0, -1.0), APPoint(10.0, -1.0)), APLine(APPoint(-10.0, 1.0), APPoint(10.0, 1.0)))
            path(st0; action=:fill)
            u0 = APUnboundedPolygon2(APRay(APPoint(0.0, 3.0), APPoint(1.0, 3.0)), APPoint{2,Float64}[], APRay(APPoint(0.0, 0.0), APPoint(1.0, 0.0)))
            path(u0; action=:fill)
            path(u0; action=:fillstroke)
            arc = APCircularArc2(Apollonius.APCircle2(APPoint(0.0, 0.0), 30.0), APPoint(30.0, 0.0), APPoint(0.0, 30.0))
            path(arc; action=:stroke)
            path(APPolyline2(APPoint(-50.0, -50.0), APPoint(-20.0, 20.0), APPoint(10.0, -30.0)); action=:stroke)
            path(APCurvilinearPolyline2([APSegment(APPoint(-60.0, 0.0), APPoint(30.0, 0.0)), arc]); action=:stroke)
            path(marks(APSegment(APPoint(-40.0, -40.0), APPoint(40.0, -40.0)); count=2); action=:stroke)
            path(marks(arc; style=:chevron); action=:stroke)
            shown = mediator_construction(APPoint(-50.0, -40.0), APPoint(50.0, -40.0))
            path(shown.arcs; action=:stroke)
            path(shown.result; action=:stroke)
            Luxor.label("a", label_anchor(APSegment(APPoint(-50.0, -40.0), APPoint(50.0, -40.0)))...)   # splats into Luxor's label(txt, alignment, pos)
            path(brace(APPoint(-40.0, 60.0), APPoint(40.0, 60.0)); action=:stroke)
            path(arrow_head(APSegment(APPoint(-40.0, 30.0), APPoint(40.0, 30.0))); action=:fill)
            path(arrow_head(arc; at=1.0, place=:tip); action=:fill)
            path(arrow_head(arc; at=0.5, style=:stealth); action=:fill)
            path(arrow_head(arc; at=0.2, style=:open); action=:stroke)
            Luxor.label("80", brace_anchor(APPoint(-40.0, 60.0), APPoint(40.0, 60.0))...)
            path(coordinate_guides(APPoint(30.0, -20.0)); action=:stroke)
            @testset "arrows at one end or both" begin
                sa = APSegment(APPoint(-40.0, 50.0), APPoint(40.0, 50.0))
                for kw in (NamedTuple(), (as=:arrow,), (as=:doublearrow,), (as=:arrow, startarrow=true), (as=:arrow, startarrow=true, finisharrow=false),
                           (as=:doublearrow, arrowheadlength=15, linewidth=3))
                    @test (path(sa; kw...); true)
                end
                @test (path(APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)); extend=30.0, as=:doublearrow); true)
                @test (path(APRay(APPoint(0.0, 0.0), APPoint(1.0, 1.0)); extend=30.0, as=:doublearrow); true)
                @test (path(APVector(20.0, 10.0); as=:doublearrow); true)
                @test (path(APEquipollentVector(APVector(20.0, 10.0), APPoint(5.0, 5.0)); as=:doublearrow); true)
            end
            @testset "Luxor.Point(::APPoint)" begin
                lp = Luxor.Point(APPoint(3.0, -4.0))
                @test lp isa Luxor.Point && lp.x == 3.0 && lp.y == -4.0
            end
            @testset "point shapes, dimension and tickline" begin
                for shape in (:circle, :square, :cross, :plus)
                    path(APPoint(0.0, 0.0); as=shape, radius=4, action=:stroke)
                end
                Luxor.newpath()
                path(APPoint(10.0, 10.0); as=:cross, radius=4, action=:path)
                cross = first(Luxor.pathtopoly())
                @test length(cross) == 4   # two strokes, two points each
                @test isapprox(Luxor.distance(cross[1], cross[2]), 8.0; atol=0.05)   # each arm is `radius` long on both sides
                Luxor.newpath()
                @test_throws ArgumentError path(APPoint(0.0, 0.0); as=:bogus)
                d, txt = Luxor.dimension(APPoint(-40.0, 70.0), APPoint(40.0, 70.0); offset=10)
                @test d ≈ 80.0 && txt == "80.0"
                d2, _ = Luxor.dimension(APSegment(APPoint(-30.0, 90.0), APPoint(30.0, 90.0)))
                @test d2 ≈ 60.0
                major, minor = Luxor.tickline(APPoint(-50.0, 80.0), APPoint(50.0, 80.0); major=3, minor=1, vertices=true)
                @test length(major) == 5 && length(minor) == 9 && all(q -> q isa APPoint, major)
                @test isapprox(major[1], APPoint(-50.0, 80.0); atol=1e-9) && isapprox(major[end], APPoint(50.0, 80.0); atol=1e-9)
            end
            @testset "reverse=true traverses the same path backwards" begin
                pts_of(obj; kwargs...) = (Luxor.newpath(); path(obj; action=:path, kwargs...); first(Luxor.pathtopoly()))
                near(p, x, y) = isapprox(p.x, x; atol=0.02) && isapprox(p.y, y; atol=0.02)   # Cairo stores path points in 1/256 units
                seg = APSegment(APPoint(0.0, 0.0), APPoint(50.0, 50.0))
                fw, bw = pts_of(seg), pts_of(seg; reverse=true)
                @test near(first(fw), 0, 0) && near(last(fw), 50, 50)
                @test near(first(bw), 50, 50) && near(last(bw), 0, 0)
                cfw, cbw = pts_of(arc), pts_of(arc; reverse=true)   # arc: (30,0) -> (0,30) on the origin-centered circle
                @test near(first(cfw), 30, 0) && near(last(cfw), 0, 30)
                @test near(first(cbw), 0, 30) && near(last(cbw), 30, 0)
                @test all(p -> isapprox(hypot(p.x, p.y), 30.0; atol=0.1), cbw)   # still on the same circle
                e2 = APEllipse2(APPoint(0.0, 0.0), 40.0, 20.0)
                earc = APEllipticArc2(e2, point_on(e2, 0.2), point_on(e2, 1.4))
                efw, ebw = pts_of(earc), pts_of(earc; reverse=true)
                @test near(first(efw), earc.p1[1], earc.p1[2]) && near(first(ebw), earc.p2[1], earc.p2[2])
                @test near(last(ebw), earc.p1[1], earc.p1[2])
                pl = APPolyline2(APPoint(-50.0, -50.0), APPoint(-20.0, 20.0), APPoint(10.0, -30.0))
                @test near(first(pts_of(pl; reverse=true)), 10, -30)
                cpl = APCurvilinearPolyline2([APSegment(APPoint(-60.0, 0.0), APPoint(30.0, 0.0)), arc])
                cfwd, cbwd = pts_of(cpl), pts_of(cpl; reverse=true)
                @test near(first(cfwd), -60, 0) && near(last(cfwd), 0, 30)
                @test near(first(cbwd), 0, 30) && near(last(cbwd), -60, 0)
                circ = APCircle2(APPoint(0.0, 0.0), 30.0)
                @test Luxor.ispolyclockwise(pts_of(circ)) != Luxor.ispolyclockwise(pts_of(circ; reverse=true))
                @test Luxor.ispolyclockwise(pts_of(e2)) != Luxor.ispolyclockwise(pts_of(e2; reverse=true))
                tri = APTriangle(APPoint(-50.0, 40.0), APPoint(50.0, 40.0), APPoint(0.0, -40.0))
                @test Luxor.ispolyclockwise(pts_of(tri)) != Luxor.ispolyclockwise(pts_of(tri; reverse=true))
                sec = APCircularSector2(arc)   # a closed curved region: same start point, opposite orientation
                @test Luxor.ispolyclockwise(pts_of(sec)) != Luxor.ispolyclockwise(pts_of(sec; reverse=true))
                aline = APLine(APPoint(0.0, 0.0), APPoint(10.0, 0.0))
                addfw, addbw = pts_of(aline; add=0.2), pts_of(aline; add=(0.5, 0.0), reverse=true)
                @test near(first(addfw), -2, 0) && near(last(addfw), 12, 0)   # add is relative to distance(p1, p2)
                @test near(first(addbw), 10, 0) && near(last(addbw), -5, 0)
                @test near(first(pts_of(aline; add=0.2, extend=99.0)), -2, 0)   # add replaces extend
                @test near(first(pts_of(aline; extend=(0.0, 3.0))), 0, 0)      # extend is unchanged
                path(aline; add=(0.1, 0.1), as=:arrow)
                aray = APRay(APPoint(0.0, 0.0), APPoint(10.0, 0.0))
                @test near(first(pts_of(aray; add=(0.5, 0.2))), -5, 0) && near(last(pts_of(aray; add=(0.5, 0.2))), 12, 0)
                @test near(last(pts_of(aray; add=0.3)), 13, 0) && near(first(pts_of(aray; add=0.3)), -3, 0)
                @test near(last(pts_of(aray; extend=4.0)), 14, 0)   # extend is unchanged
                @test near(first(pts_of(APHalfPlane2(aline, APPoint(0.0, 5.0)); add=0.2)), -2, 0)
                path(APStrip2(aline, APLine(APPoint(0.0, 3.0), APPoint(10.0, 3.0))); add=0.1)
                Luxor.newpath()
                path(seg; as=:arrow, reverse=true)   # arrows: runs without error, the head goes to p1
                path([seg, APPoint(1.0, 1.0)]; reverse=true, action=:stroke)   # a vector mixing curves and points
                Luxor.newpath()
            end
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
            Luxor.sethue("blue")
            path(t)
            Luxor.strokepath()
            e2 = APEllipse2(APPoint(0.0, 0.0), 40.0, 20.0, pi / 6)
            earc = APEllipticArc2(e2, point_on(e2, 0.2), point_on(e2, 2.0))
            path(earc; action=:stroke)
            par2 = APParabola2(APPoint(0.0, 20.0), APLine(APPoint(-50.0, -20.0), APPoint(50.0, -20.0)))
            parc = APParabolicArc2(par2, point_on(par2, -30.0), point_on(par2, 30.0))
            path(parc; action=:stroke)
            hyp2 = APHyperbola2(APPoint(0.0, 0.0), 20.0, 10.0)
            hyparc = APHyperbolicArc2(hyp2, point_on(hyp2, -0.5; branch=1), point_on(hyp2, 0.5; branch=1))
            path(hyparc; action=:stroke)
            pcurve = APParametricCurve2(t -> APPoint(30 * cos(t), 15 * sin(2t)), (0.0, 2pi))
            path(pcurve; action=:stroke)
            apex = APPoint(-60.0, -60.0)
            curv_tri = APCurvilinearTriangle2(APSegment(earc.p2, apex), APSegment(apex, earc.p1), earc)
            path(curv_tri; action=:stroke)
            path(APSegment(APPoint(0.0, 0.0), APPoint(50.0, 30.0)); as=:arrow)
            path(APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)); extend=0.0, as=:arrow)
            path(APRay(APPoint(0.0, 0.0), APPoint(1.0, 1.0)); extend=0.0, as=:arrow, arrowheadlength=15)
            path(APVector(1.0, 1.0); action=:stroke)
            path(APVector(1.0, 1.0), APPoint(10.0, 10.0); action=:stroke)
            path(APVector(1.0, 1.0), APPoint(10.0, 10.0); as=:arrow)
            path(APHalfPlane2(APLine(APPoint(0.0, 0.0), APPoint(0.0, 1.0)), APPoint(1.0, 0.0)); action=:stroke)
            path(APStrip2(APLine(APPoint(-20.0, 0.0), APPoint(-20.0, 1.0)), APLine(APPoint(20.0, 0.0), APPoint(20.0, 1.0))); action=:stroke)
            Luxor.label("I", :N, incenter(t))
            Luxor.label("O", pi / 4, circumcenter(t); offset=10)
            Luxor.text("a", Apollonius.midpoint(t[2], t[3]))
            Luxor.text("b", Apollonius.midpoint(t[1], t[3]); halign=:center, valign=:middle, angle=0.3)
            Luxor.text("v", Apollonius.midpoint(t[1], t[2]); direction=APVector(3.0, 4.0))
            Luxor.text("s", Apollonius.midpoint(t[1], t[3]); direction=APSegment(t[3], t[1]), upright=true)
            Luxor.text("e", t[1]; direction=APEquipollentVector(APVector(1.0, 1.0), t[1]))
            @test_throws ArgumentError Luxor.text("x", t[1]; angle=0.1, direction=0.2)
            path([APPoint(0.0, 0.0), APPoint(10.0, 10.0)]; action=:fill)
            path(intersection(APLine(APPoint(-50.0, 0.0), APPoint(50.0, 0.0)), circumcircle(t)); action=:fill)
            path(APPoint{2,Float64}[]; action=:fill)
            path(vertices(t); action=:fill)
            c_ta, c_tb = APCircle2(APPoint(0.0, 0.0), 20.0), APCircle2(APPoint(90.0, 0.0), 30.0)
            ext_ta = external_tangent_lines(c_ta, c_tb)
            int_ta = internal_tangent_lines(c_ta, c_tb)
            path([ext_ta int_ta]; action=:stroke)
            Luxor.finish()
            @test isfile(joinpath(dir, "test.png"))
        end
        @testset "as=:arrow inherits the active setline() width" begin
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
                @test count(==(6.0), widths) == 2
                @test count(==(2.0), widths) == 1
            end
        end
        @testset "path(::Vector) batches into one path without a stray connecting line" begin
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
                @test !occursin(" L ", svg)
            end
        end
        @testset "the preserve actions keep the path" begin
            Luxor.Drawing(100, 100, :image); Luxor.origin(); Luxor.background("white")
            circle_p = APCircle2(APPoint(0.0, 0.0), 30.0)
            Luxor.sethue("red"); path(circle_p; action=:fillpreserve)
            Luxor.sethue("green"); Luxor.fillpath()   # the path is still there
            m_pre = Luxor.image_as_matrix()
            Luxor.finish()
            @test Luxor.Colors.green(m_pre[50, 50]) > 0.4 && Luxor.Colors.red(m_pre[50, 50]) < 0.1
            for obj in (APPoint(0.0, 0.0), APSegment(APPoint(0.0, 0.0), APPoint(10.0, 5.0)), APEllipse2(APPoint(0.0, 0.0), 20.0, 10.0),
                        APTriangle(APPoint(0.0, 0.0), APPoint(20.0, 0.0), APPoint(0.0, 20.0)))
                for act in (:fillpreserve, :strokepreserve)
                    Luxor.Drawing(50, 50, :image); Luxor.origin()
                    path(obj; action=act)
                    @test length(Luxor.getpath()) > 0
                    Luxor.finish()
                end
            end
        end
        @testset "clip_out keeps only the outside of a shape (pixel check)" begin
            painted(m, x, y) = Luxor.Colors.red(m[y, x]) > 0.5 && Luxor.Colors.green(m[y, x]) < 0.5   # red, not white
            Luxor.Drawing(200, 200, :image)
            Luxor.origin()
            Luxor.background("white")
            clip_out(APCircle2(APPoint(-50.0, 0.0), 30.0))
            clip_out(APCircle2(APPoint(50.0, 0.0), 30.0))   # a second call narrows further: outside both circles
            Luxor.sethue("red")
            Luxor.paint()
            m = Luxor.image_as_matrix()
            Luxor.finish()
            @test !painted(m, 50, 101) && !painted(m, 150, 101)   # centers of the two circles stay white
            @test painted(m, 100, 101) && painted(m, 10, 10)      # between them and in a corner: painted
            Luxor.Drawing(200, 200, :image)   # restores the previous fill rule and works on a polygon and a vector
            Luxor.origin()
            Luxor.background("white")
            @test Luxor.getfillrule() == :winding
            clip_out([APTriangle(APPoint(-40.0, 40.0), APPoint(40.0, 40.0), APPoint(0.0, -40.0)), APCircle2(APPoint(0.0, 0.0), 10.0)])
            @test Luxor.getfillrule() == :winding
            Luxor.sethue("red"); Luxor.paint()
            m2 = Luxor.image_as_matrix()
            Luxor.finish()
            @test !painted(m2, 100, 130) && painted(m2, 10, 10)   # a point inside the triangle is protected
            @test !painted(m2, 100, 101)   # and so is the nested circle's interior (one clip per shape, no even-odd toggling)
            Luxor.Drawing(200, 200, :image)   # an angle's marker (wrapped as APQuadrilateral) and circular sectors are closed shapes too
            Luxor.origin(); Luxor.background("white")
            wedge = APAngle2(APPoint(0.0, 0.0), APPoint(60.0, 0.0), APPoint(0.0, -60.0))   # canvas: right/up quadrant
            wedge_poly = only(marks(wedge; style=:parallelogram, size=50.0))
            clip_out(APQuadrilateral(wedge.vertex, wedge_poly.vertices...))
            clip_out(APCircularSector2(APCircularArc2(APCircle2(APPoint(0.0, 0.0), 50.0), APPoint(50.0, 0.0), APPoint(0.0, 50.0))))
            Luxor.sethue("red"); Luxor.paint()
            m3 = Luxor.image_as_matrix()
            Luxor.finish()
            @test !painted(m3, 125, 75) && !painted(m3, 125, 125)   # inside the wedge and inside the sector
            @test painted(m3, 75, 75) && painted(m3, 10, 10)        # elsewhere
        end
        @testset "filling an unbounded region: half-plane, strip, angle, unbounded polygon" begin
            mktempdir() do dir
                Luxor.Drawing(200, 200, joinpath(dir, "fill_bbox.png"))
                Luxor.origin()
                hp = APHalfPlane2(APLine(APPoint(0.0, -5.0), APPoint(0.0, 5.0)), APPoint(1.0, 0.0))
                path(hp; action=:fillpreserve, bound=50.0)
                @test current_path_bbox() ≈ Apollonius.APBoundingBox(APPoint(0.0, -50.0), APPoint(50.0, 50.0))
                Luxor.newpath()
                s = APStrip2(APLine(APPoint(-10.0, -1.0), APPoint(10.0, -1.0)), APLine(APPoint(-10.0, 1.0), APPoint(10.0, 1.0)))
                path(s; action=:fillpreserve, bound=50.0)
                @test current_path_bbox() ≈ Apollonius.APBoundingBox(APPoint(-50.0, -1.0), APPoint(50.0, 1.0))
                Luxor.newpath()
                ang = APAngle2(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 4.0))
                path(ang; as=:region, action=:fillpreserve, bound=50.0)
                @test current_path_bbox() ≈ Apollonius.APBoundingBox(APPoint(0.0, 0.0), APPoint(50.0, 50.0))
                Luxor.finish()
            end
            painted(m, x, y) = Luxor.Colors.red(m[y, x]) > 0.5 && Luxor.Colors.green(m[y, x]) < 0.5
            Luxor.Drawing(200, 200, :image)
            Luxor.origin()
            Luxor.background("white")
            reflex = APAngle2(APPoint(0.0, 0.0), APPoint(0.0, 4.0), APPoint(4.0, 0.0))   # excludes the first quadrant
            Luxor.sethue("red")
            path(reflex; as=:region, action=:fill, bound=90.0)
            m = Luxor.image_as_matrix()
            Luxor.finish()
            @test !painted(m, 130, 130) && painted(m, 70, 130) && painted(m, 70, 70) && painted(m, 130, 70)
            Luxor.Drawing(200, 200, :image)
            Luxor.origin()
            Luxor.background("white")
            u = APUnboundedPolygon2(APRay(APPoint(0.0, 30.0), APPoint(1.0, 30.0)), APPoint{2,Float64}[], APRay(APPoint(0.0, 0.0), APPoint(1.0, 0.0)))
            Luxor.sethue("red")
            path(u; action=:fill, bound=90.0)
            m2 = Luxor.image_as_matrix()
            Luxor.finish()
            @test painted(m2, 150, 115) && !painted(m2, 50, 115) && !painted(m2, 150, 50)
        end
        @testset "clipping to/out of an unbounded region: half-plane, angle, unbounded polygon (pixel check)" begin
            painted(m, x, y) = Luxor.Colors.red(m[y, x]) > 0.5 && Luxor.Colors.green(m[y, x]) < 0.5
            hp = APHalfPlane2(APLine(APPoint(0.0, -5.0), APPoint(0.0, 5.0)), APPoint(1.0, 0.0))   # x >= 0
            Luxor.Drawing(200, 200, :image)
            Luxor.origin(); Luxor.background("white")
            path(hp; action=:clip)
            Luxor.sethue("red"); Luxor.paint()
            m = Luxor.image_as_matrix()
            Luxor.finish()
            @test painted(m, 150, 100) && !painted(m, 50, 100)
            ang = APAngle2(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 4.0))
            Luxor.Drawing(200, 200, :image)
            Luxor.origin(); Luxor.background("white")
            path(ang; as=:region, action=:clip)
            Luxor.sethue("red"); Luxor.paint()
            m2 = Luxor.image_as_matrix()
            Luxor.finish()
            @test painted(m2, 150, 150) && !painted(m2, 50, 50)
            u = APUnboundedPolygon2(APRay(APPoint(0.0, 30.0), APPoint(1.0, 30.0)), APPoint{2,Float64}[], APRay(APPoint(0.0, 0.0), APPoint(1.0, 0.0)))
            Luxor.Drawing(200, 200, :image)
            Luxor.origin(); Luxor.background("white")
            path(u; action=:clip)
            Luxor.sethue("red"); Luxor.paint()
            m3 = Luxor.image_as_matrix()
            Luxor.finish()
            @test painted(m3, 150, 115) && !painted(m3, 50, 115)
            Luxor.Drawing(200, 200, :image)
            Luxor.origin(); Luxor.background("white")
            clip_out(hp)
            Luxor.sethue("red"); Luxor.paint()
            m4 = Luxor.image_as_matrix()
            Luxor.finish()
            @test painted(m4, 50, 100) && !painted(m4, 150, 100)
            Luxor.Drawing(200, 200, :image)
            Luxor.origin(); Luxor.background("white")
            clip_out(ang)
            Luxor.sethue("red"); Luxor.paint()
            m5 = Luxor.image_as_matrix()
            Luxor.finish()
            @test painted(m5, 50, 50) && !painted(m5, 150, 150)
        end
        @testset "marks(::APAngle2; style=:parallelogram) -- the parallelogram-law angle marker" begin
            ang90 = APAngle2(APPoint(0.0, 0.0), APPoint(50.0, 0.0), APPoint(0.0, 50.0))
            poly90 = only(marks(ang90; style=:parallelogram, size=20.0))
            @test Apollonius.APBoundingBox(poly90.vertices) ≈ Apollonius.APBoundingBox(APPoint(0.0, 0.0), APPoint(20.0, 20.0))
            q90 = APQuadrilateral(ang90.vertex, poly90.vertices...)
            @test Apollonius.APBoundingBox(vertices(q90)) ≈ Apollonius.APBoundingBox(APPoint(0.0, 0.0), APPoint(20.0, 20.0))
            ang60 = APAngle2(APPoint(0.0, 0.0), APPoint(50.0, 0.0), Apollonius.rotate(APPoint(50.0, 0.0), pi / 3))
            vertex, a, b = ang60.vertex, ang60.a, ang60.b
            r = 15.0
            pa = vertex + r * (a - vertex) / norm(a - vertex)
            pb = vertex + r * (b - vertex) / norm(b - vertex)
            pc = pa + (pb - vertex)
            @test Apollonius.distance(pa, pc) ≈ r && Apollonius.distance(pb, pc) ≈ r
            @test !is_perpendicular(APLine(vertex, pa), APLine(vertex, pb))
            poly60 = only(marks(ang60; style=:parallelogram, size=r))
            @test poly60.vertices ≈ [pa, pc, pb]
        end
        @testset "path(::APLine) with a 2-tuple extend" begin
            l = APLine(APPoint(0.0, 0.0), APPoint(10.0, 0.0))
            mktempdir() do dir
                Luxor.Drawing(200, 200, joinpath(dir, "extend.png"))
                Luxor.origin()
                path(l; extend=(0.0, 5.0), action=:path)
                @test current_path_bbox() ≈ Apollonius.APBoundingBox(APPoint(0.0, 0.0), APPoint(15.0, 0.0))
                Luxor.strokepath()
                path(l; extend=5.0, action=:path)
                @test current_path_bbox() ≈ Apollonius.APBoundingBox(APPoint(-5.0, 0.0), APPoint(15.0, 0.0))
                Luxor.strokepath()
                Luxor.finish()
            end
        end
        @testset "current_path_bbox and @prepare_to_picture together" begin
            t = APTriangle(APPoint(2.0, -5.0), APPoint(9.0, 3.0), APPoint(-1.0, 6.0))
            circ = Apollonius.APCircle2(APPoint(4.0, 1.0), 4.0)
            (w, h), (t2, c2) = @prepare_to_picture width = 300.0 margin = 10.0 begin
                t
                circ
            end
            mktempdir() do dir
                Luxor.Drawing(w, h, joinpath(dir, "picture.png"))
                Luxor.origin()
                path(t2; action=:path)
                path(c2; action=:path)
                expected = bbox_union(Apollonius.APBoundingBox(t2), Apollonius.APBoundingBox(c2))
                @test current_path_bbox() ≈ expected
                Luxor.strokepath()
                @test current_path_bbox() == Apollonius.APBoundingBox(APPoint(0.0, 0.0), APPoint(0.0, 0.0))
                Luxor.finish()
            end
        end
    end
end

@testset "affine map on chains, vectors and parametric curves; similarities keep circles" begin
    O = APPoint(0.0, 0.0)
    ch = APCurvilinearPolyline2([APSegment(APPoint(0.0, -5.0), APPoint(3.0, -5.0)), APCircularArc2(APCircle2(APPoint(3.0, -3.0), 2.0), APPoint(3.0, -5.0), APPoint(5.0, -3.0))])
    for m in (APAffineMap(1.0, 0.5, 0.2, -1.0, 1.0, 2.0), APAffineMap(1.0, 0.5, 0.2, 1.0, 1.0, 2.0))
        @test m(ch) isa APCurvilinearPolyline2
    end
    m = APAffineMap(1.0, 0.5, 0.2, 1.0, 1.0, 2.0)
    @test m(APPolyline2(O, APPoint(1.0, 1.0), APPoint(2.0, 0.0))) ≈ APPolyline2(m(O), m(APPoint(1.0, 1.0)), m(APPoint(2.0, 0.0)))
    e = m(APEquipollentVector(APVector(1.0, 0.0), O))
    @test e.vector ≈ APVector(1.0, 0.2) && e.point ≈ APPoint(1.0, 2.0)
    @test m(APParametricCurve2(x -> APPoint(x, sin(x)), (0.0, 1.0))).f(0.5) ≈ m(APPoint(0.5, sin(0.5)))
    c = APCircle2(APPoint(1.0, 2.0), 3.0)
    s = rotation_map(0.3, O) ∘ homothety_map(2.0, O)
    @test s(c) isa APCircle2 && s(c).r ≈ 6.0
    sec = APCircularSector2(APCircularArc2(c, APPoint(4.0, 2.0), APPoint(1.0, 5.0)))
    @test s(sec) isa APCircularSector2
    @test m(sec) isa APCurvilinearTriangle2
end

@testset "triangle centers, centroid and area far from the origin" begin
    P(x, y) = APPoint(x, y)
    for b in (1e6, 1e8, 1e10)
        t = APTriangle(P(b, b), P(b + 3.0, b), P(b, b + 4.0))
        q = APStraightNgon([P(b, b), P(b + 4.0, b), P(b + 4.0, b + 3.0), P(b + 1.0, b + 3.0)])
        @test circumcenter(t) ≈ P(b + 1.5, b + 2.0) atol = 1e-4
        @test orthocenter(t) ≈ P(b, b) atol = 1e-4
        @test centroid(t) ≈ P(b + 1.0, b + 4 / 3) atol = 1e-4
        @test area(t) ≈ 6.0
        @test area(q) ≈ 10.5
    end
end

@testset "intersection of composite objects, points and parametric curves" begin
    P(x, y) = APPoint(x, y)
    pg = APStraightNgon([P(0.0, 0.0), P(5.0, 0.0), P(6.0, 3.0), P(2.0, 4.0), P(-1.0, 2.0)])
    l = APLine(P(-2.0, 1.0), P(7.0, 2.5))
    pts = intersection(pg, l)
    @test length(pts) == 2 && all(p -> is_on_line(p, l) && Apollonius.distance(p, pg; mode=:boundary) < 1e-9, pts)
    @test length(intersection(l, pg)) == 2
    # a vertex shared by two sides is reported once
    @test length(intersection(pg, APLine(P(-1.0, 2.0), P(0.0, 0.0)))) == 2
    pg2 = APStraightNgon([P(3.0, -1.0), P(8.0, -1.0), P(8.0, 2.0), P(3.0, 2.0)])
    @test length(intersection(pg, pg2)) == 2
    @test length(intersection(APBoundingBox(pg), l)) == 2
    @test length(intersection(APPolyline2(P(0.0, -1.0), P(2.0, 5.0), P(4.0, -1.0)), pg)) == 4
    # since Phase 2 (see ap_conic_region_intersections.jl), these two are the part of the
    # circle INSIDE the region (an arc), not boundary-crossing points
    @test only(intersection(APAngle2(P(0.0, 0.0), P(4.0, 0.0), P(0.0, 4.0)), APCircle2(P(0.0, 0.0), 2.0))) isa APCircularArc2
    @test only(intersection(APStrip2(APLine(P(0.0, 0.0), P(1.0, 0.0)), APLine(P(0.0, 3.0), P(1.0, 3.0))), APCircle2(P(0.0, 1.0), 2.0))) isa APCircularArc2
    sec = APCircularSector2(APCircularArc2(APCircle2(P(0.0, 0.0), 3.0), P(3.0, 0.0), P(0.0, 3.0)))
    @test length(intersection(sec, APLine(P(-4.0, 1.0), P(4.0, 1.0)))) == 2
    @test length(intersection(pg, APCircle2(P(2.0, 2.0), 2.0))) == 4
    @test isempty(intersection(pg, APCircle2(P(40.0, 40.0), 1.0)))
    # points
    @test intersection(P(1.0, 0.0), APSegment(P(0.0, 0.0), P(2.0, 0.0))) == [P(1.0, 0.0)]
    @test isempty(intersection(P(1.0, 1.0), APSegment(P(0.0, 0.0), P(2.0, 0.0))))
    @test isempty(intersection(P(4.0, 0.0), pg2))
    @test length(intersection(P(3.0, 0.5), pg2)) == 1
    @test intersection(P(0.0, 0.0), P(0.0, 0.0)) == [P(0.0, 0.0)]
    # parametric curves
    sine = APParametricCurve2(x -> P(x, sin(x)), (0.0, 6.0))
    ps = intersection(sine, APLine(P(0.0, 0.5), P(1.0, 0.5)))
    @test length(ps) == 2 && all(p -> abs(p[2] - 0.5) < 1e-9 && abs(sin(p[1]) - 0.5) < 1e-9, ps)
    @test length(intersection(sine, APCircle2(P(3.0, 0.0), 1.0))) == 2
    @test length(intersection(sine, pg2)) == 1
    @test length(intersection(APRay(P(3.0, -1.0), P(3.0, 0.0)), sine)) == 1
end

@testset "parametric curves against conics and arcs" begin
    P(x, y) = APPoint(x, y)
    sine = APParametricCurve2(x -> P(x, sin(x)), (0.0, 6.0))
    e = APEllipse2(P(3.0, 0.0), 2.0, 0.8)
    @test length(intersection(sine, e)) == 2 && all(p -> is_on_ellipse(p, e; atol=1e-6), intersection(e, sine))
    par = APParabola2(P(3.0, 2.0), APLine(P(0.0, -2.0), P(1.0, -2.0)))
    @test all(p -> is_on_parabola(p, par; atol=1e-6), intersection(sine, par))
    arc = APCircularArc2(APCircle2(P(3.0, 0.0), 1.0), P(2.0, 0.0), P(4.0, 0.0))
    @test length(intersection(sine, arc)) == 1
end

@testset "more constructions far from the origin" begin
    P(b, x, y) = APPoint(x + b, y + b)
    for b in (1e6, 1e8, 1e10)
        pg = APStraightNgon([P(b, 0.0, 0.0), P(b, 5.0, 0.0), P(b, 6.0, 3.0), P(b, 2.0, 4.0), P(b, -1.0, 2.0)])
        @test length(intersection(pg, APLine(P(b, -1.0, 1.0), P(b, 5.0, 2.0)))) == 2
        t = APTriangle(P(b, 0.0, 0.0), P(b, 8.0, 0.0), P(b, 3.0, 6.0))
        e0 = steiner_inellipse(APTriangle(P(0.0, 0.0, 0.0), P(0.0, 8.0, 0.0), P(0.0, 3.0, 6.0)))
        e = steiner_inellipse(t)
        @test isapprox(e.a, e0.a; rtol=1e-5) && isapprox(e.b, e0.b; rtol=1e-5)
        ec = excircles(t)
        sols = tangent_circles(ec.A, ec.B, ec.C)
        @test length(sols) == 5
        @test apollonius_circle_of_triangle(t).r ≈ apollonius_circle_of_triangle(APTriangle(P(0.0, 0.0, 0.0), P(0.0, 8.0, 0.0), P(0.0, 3.0, 6.0))).r rtol = 1e-5
        @test is_collinear(P(b, 0.0, 0.0), P(b, 1.0, 1.0), P(b, 2.0, 2.0))
        @test !is_collinear(P(b, 0.0, 0.0), P(b, 1.0, 1.0), P(b, 2.0, 2.5))
    end
end

@testset "circle_with_diameter" begin
    a, b = APPoint(0.0, 0.0), APPoint(6.0, 2.0)
    c = circle_with_diameter(a, b)
    @test c.center ≈ APPoint(3.0, 1.0) && c.r ≈ sqrt(10)
    @test circle_with_diameter(APSegment(a, b)) == c
    @test angle_measure_at(point_on(c, 1.0), a, b) ≈ pi / 2
    @test circle_with_diameter(APPoint(0, 0), APPoint(4, 0)) ≈ APCircle2(APPoint(2.0, 0.0), 2.0)
end

@testset "shape constructors" begin
    P(x, y) = APPoint(x, y)
    O = P(0.0, 0.0)
    near(a, b) = isapprox(a, b; atol=1e-9)
    @testset "lines, points, angles" begin
        @test APLine(P(1.0, 1.0), APVector(1.0, 2.0)) == APLine(P(1.0, 1.0), P(2.0, 3.0))
        @test is_parallel(APLine(O, pi / 4), APLine(O, P(1.0, 1.0)))
        @test near(APRay(O, pi / 2).through, P(0.0, 1.0))
        @test APSegment(P(1.0, 1.0), APVector(2.0, 0.0)) == APSegment(P(1.0, 1.0), P(3.0, 1.0))
        @test Apollonius.distance(APSegment(O, 5.0, pi / 3).p1, APSegment(O, 5.0, pi / 3).p2) ≈ 5.0
        @test_throws ArgumentError APLine(O, APVector(0.0, 0.0))
        s = APSegment(O, P(3.0, 4.0))
        @test point_at_distance(s, 2.5) ≈ P(1.5, 2.0)
        @test point_at_distance(APRay(O, P(0.0, 2.0)), 3.0) ≈ P(0.0, 3.0)
        @test divide_segment(APSegment(O, P(6.0, 0.0)), 3) ≈ [P(2.0, 0.0), P(4.0, 0.0)]
        @test divide_segment(APSegment(O, P(6.0, 0.0)), 1, 2) ≈ P(2.0, 0.0)
        @test divide_segment(APSegment(O, P(6.0, 0.0)), 3, -1) ≈ P(9.0, 0.0)
        @test length(equally_spaced_points(APCircle2(O, 1.0), 6)) == 6
        @test equally_spaced_points(APSegment(O, P(6.0, 0.0)), 4)[2] ≈ P(2.0, 0.0)
        arc = APCircularArc2(APCircle2(O, 1.0), P(1.0, 0.0), P(0.0, 1.0))
        @test near(equally_spaced_points(arc, 3)[2], P(sqrt(0.5), sqrt(0.5)))
        @test length(equally_spaced_points(APEllipse2(O, 3.0, 2.0), 5)) == 5
        @test measure(angle_with_measure(O, P(1.0, 0.0), pi / 3)) ≈ pi / 3
        @test measure(APAngle2(APLine(O, P(1.0, 0.0)), APLine(O, P(1.0, 1.0)))) ≈ pi / 4
        @test_throws ArgumentError APAngle2(APLine(O, P(1.0, 0.0)), APLine(P(0.0, 1.0), P(1.0, 1.0)))
    end
    @testset "fillet and round_corners" begin
        for b in (P(4.0, 5.0), P(4.0, -5.0))
            f = fillet(P(0.0, 0.0), P(6.0, 0.0), b, 1.5)
            @test measure(f.arc) < pi
            @test Apollonius.distance(f.center, APLine(P(0.0, 0.0), P(6.0, 0.0))) ≈ 1.5
            @test Apollonius.distance(f.center, APLine(P(6.0, 0.0), b)) ≈ 1.5
        end
        @test_throws ArgumentError fillet(O, P(1.0, 0.0), P(2.0, 0.0), 0.5)
        @test_throws ArgumentError fillet(O, P(1.0, 0.0), P(1.0, 1.0), 5.0)
        sq = APStraightNgon([P(0.0, 0.0), P(4.0, 0.0), P(4.0, 4.0), P(0.0, 4.0)])
        rc = round_corners(sq, 1.0)
        @test length(sides(rc)) == 8 && area(rc) ≈ 16 - (4 - pi)
        @test area(round_corners(APStraightNgon(reverse(collect(vertices(sq)))), 1.0)) ≈ 16 - (4 - pi)
        @test_throws ArgumentError round_corners(APStraightNgon([P(0.0, 0.0), P(4.0, 0.0), P(1.0, 1.0), P(0.0, 4.0)]), 0.2)
        @test length(sides(round_corners(APPolyline2(P(0.0, 0.0), P(4.0, 0.0), P(4.0, 4.0), P(0.0, 4.0)), 1.0))) == 5
        @test length(sides(round_corners(APPolyline2(P(0.0, 0.0), P(4.0, 0.0), P(4.0, -4.0)), 1.0))) == 3
        @test_throws ArgumentError round_corners(APPolyline2(P(0.0, 0.0), P(4.0, 0.0), P(4.0, 4.0), P(8.0, 4.0)), 1.0)
    end
    @testset "tangent_line and normal_line" begin
        c = APCircle2(O, 5.0)
        @test is_perpendicular(tangent_line(c, P(3.0, 4.0)), APLine(O, P(3.0, 4.0)))
        @test_throws ArgumentError tangent_line(c, P(1.0, 1.0))
        e = APEllipse2(O, 5.0, 3.0)
        pe = point_on(e, 1.0)
        @test is_on_line(pe, tangent_line(e, pe)) && is_on_line(O, normal_line(c, P(3.0, 4.0)))
        h = APHyperbola2(O, 3.0, 2.0)
        ph = point_on(h, 0.5)
        @test is_on_line(ph, tangent_line(h, ph)) && line_circle_position(tangent_line(c, P(3.0, 4.0)), c) == :tangent
        par = APParabola2(P(0.0, 1.0), APLine(P(0.0, -1.0), P(1.0, -1.0)))
        pp = point_on(par, 2.0)
        @test is_on_line(pp, tangent_line(par, pp))
        arc = APCircularArc2(c, P(5.0, 0.0), P(0.0, 5.0))
        @test tangent_line(arc, P(3.0, 4.0)) ≈ tangent_line(c, P(3.0, 4.0))
        @test_throws ArgumentError tangent_line(arc, P(-3.0, 4.0))
        @test tangent_line(APSegment(O, P(2.0, 0.0)), P(1.0, 0.0)) ≈ APLine(O, P(1.0, 0.0))
    end
    @testset "polygons" begin
        h = regular_polygon_on_segment(P(0.0, 0.0), P(2.0, 0.0), 6)
        @test near(vertices(h)[2], P(2.0, 0.0)) && area(h) ≈ 6sqrt(3)
        h2 = regular_polygon_on_segment(P(0.0, 0.0), P(2.0, 0.0), 5; ccw=false)
        @test near(vertices(h2)[2], P(2.0, 0.0)) && vertices(h2)[3][2] < 0
        @test area(rhombus_on_segment(O, P(2.0, 0.0), pi / 3)) ≈ 4sin(pi / 3)
        @test isapprox(rhombus_on_segment(O, P(2.0, 0.0), pi / 2), square_on_segment(O, P(2.0, 0.0)); atol=1e-9)
        sq = square_from_diagonal(O, P(2.0, 2.0))
        @test area(sq) ≈ 4 && near(sq.b, P(2.0, 0.0))
        r = rectangle_from_diagonal(O, P(4.0, 3.0), 0.3)
        @test near(r.c, P(4.0, 3.0)) && is_perpendicular(APLine(r.a, r.b), APLine(r.b, r.c)) && area(r) ≈ 25 * sin(0.3) * cos(0.3)
        @test isapprox(rectangle_from_diagonal(O, P(2.0, 2.0), pi / 4), sq; atol=1e-9)
        @test area(rectangle_with_center(P(1.0, 1.0), 4.0, 2.0; angle=0.4)) ≈ 8 && near(centroid(rectangle_with_center(P(1.0, 1.0), 4.0, 2.0; angle=0.4)), P(1.0, 1.0))
        @test area(square_with_center(P(1.0, 1.0), 3.0)) ≈ 9
        @test area(isosceles_trapezoid_on_segment(O, P(6.0, 0.0), 2.0, 3.0)) ≈ 12
        tr = right_trapezoid_on_segment(O, P(6.0, 0.0), 2.0, 3.0)
        @test area(tr) ≈ 12 && near(tr.d, P(0.0, 3.0))
        k = kite_on_diagonal(O, P(0.0, 6.0), 0.4, 2.0)
        @test is_convex(k) && area(k) ≈ 12
        @test length(vertices(star_polygon(O, P(3.0, 0.0), 5, 2))) == 5
        @test_throws ArgumentError star_polygon(O, P(3.0, 0.0), 6, 2)
        sqr = APStraightNgon([P(0.0, 0.0), P(4.0, 0.0), P(4.0, 4.0), P(0.0, 4.0)])
        @test area(offset_polygon(sqr, 1.0)) ≈ 36 && area(offset_polygon(sqr, -1.0)) ≈ 4
        @test area(offset_polygon(APStraightNgon(reverse(collect(vertices(sqr)))), 1.0)) ≈ 36
        @test circumcircle(APQuadrilateral(P(1.0, 0.0), P(0.0, 1.0), P(-1.0, 0.0), P(0.0, -1.0))) ≈ APCircle2(O, 1.0)
        @test circumcircle(regular_polygon(P(1.0, 1.0), P(3.0, 1.0), 7)).r ≈ 2
        @test_throws ArgumentError circumcircle(APQuadrilateral(P(0.0, 0.0), P(4.0, 0.0), P(4.0, 3.0), P(0.0, 5.0)))
        @test incircle(APQuadrilateral(P(0.0, 0.0), P(2.0, 0.0), P(2.0, 2.0), P(0.0, 2.0))) ≈ APCircle2(P(1.0, 1.0), 1.0)
        @test incircle(regular_polygon(O, P(2.0, 0.0), 6)).r ≈ 2cos(pi / 6)
        @test_throws ArgumentError incircle(APQuadrilateral(P(0.0, 0.0), P(4.0, 0.0), P(4.0, 1.0), P(0.0, 3.0)))
        c = APCircle2(O, 1.0)
        t = circumscribed_triangle(c, point_on(c, 0.5), point_on(c, 2.5), point_on(c, 4.5))
        @test isapprox(incircle(t), c; atol=1e-9)
        @test_throws ArgumentError circumscribed_triangle(c, P(1.0, 0.0), P(-1.0, 0.0), P(0.0, 1.0))
    end
    @testset "circles and arcs" begin
        @test offset_circle(APCircle2(O, 3.0), 1.0).r == 4.0 && offset_circle(APCircle2(O, 3.0), -1.0).r == 2.0
        @test_throws ArgumentError offset_circle(APCircle2(O, 3.0), -3.0)
        @test near(chord(APCircle2(O, 1.0), 0.0, pi).p2, P(-1.0, 0.0))
        @test Apollonius.distance(diameter(APCircle2(O, 2.0)).p1, diameter(APCircle2(O, 2.0)).p2) ≈ 4
        a = arc_through_points(P(1.0, 0.0), P(0.0, 1.0), P(-1.0, 0.0))
        @test a.p1 ≈ P(1.0, 0.0) && measure(a) ≈ pi
        b = arc_through_points(P(1.0, 0.0), P(0.0, -1.0), P(-1.0, 0.0))
        @test P(0.0, -1.0) in b
        @test_throws ArgumentError arc_through_points(O, P(1.0, 0.0), P(2.0, 0.0))
        s = arc_with_radius(O, P(2.0, 0.0), 2.0)
        @test near(s.circle.center, P(1.0, sqrt(3))) && measure(s) < pi
        @test measure(arc_with_radius(O, P(2.0, 0.0), 2.0; large=true)) > pi
        @test_throws ArgumentError arc_with_radius(O, P(2.0, 0.0), 0.5)
        l = APLine(O, P(1.0, 0.0))
        tc = tangent_circle_at_point(l, P(2.0, 0.0), P(0.0, 2.0))
        @test tc.center ≈ P(2.0, 2.0) && line_circle_position(l, tc) == :tangent
        @test [c.center for c in tangent_circles_at_point(l, P(2.0, 0.0), 1.5)] ≈ [P(2.0, 1.5), P(2.0, -1.5)]
        @test_throws ArgumentError tangent_circle_at_point(l, P(2.0, 1.0), P(0.0, 2.0))
    end
    @testset "maps" begin
        @test near(similarity_map(2.0, pi / 2)(P(1.0, 0.0)), P(0.0, 2.0))
        @test near(similarity_map(1.0, pi, P(1.0, 1.0))(P(2.0, 1.0)), P(0.0, 1.0))
        m = similarity_map(O => P(1.0, 1.0), P(1.0, 0.0) => P(1.0, 2.0))
        @test near(m(O), P(1.0, 1.0)) && near(m(P(1.0, 0.0)), P(1.0, 2.0))
        @test similarity_map(2.0, 0.3)(APCircle2(P(1.0, 1.0), 1.0)) isa APCircle2
        @test_throws ArgumentError similarity_map(O => O, O => P(1.0, 0.0))
        @test scaling_map(2.0, 3.0)(P(1.0, 1.0)) ≈ P(2.0, 3.0) && scaling_map(2.0, 3.0, P(1.0, 1.0))(P(2.0, 2.0)) ≈ P(3.0, 4.0)
        @test scaling_map(2.0, 3.0)(APCircle2(O, 1.0)) isa APEllipse2
        @test shear_map(1.0)(P(0.0, 2.0)) ≈ P(2.0, 2.0) && shear_map(0.0, 1.0)(P(2.0, 0.0)) ≈ P(2.0, 2.0)
        @test shear_map(1.0, 0.0, P(0.0, 1.0))(P(0.0, 2.0)) ≈ P(1.0, 2.0)
    end
    @testset "conics" begin
        F, d = O, APLine(P(4.0, -1.0), P(4.0, 1.0))
        e = conic_with_focus(F, d, 0.5)
        @test e isa APEllipse2 && all(t -> (p = point_on(e, t); Apollonius.distance(p, F) ≈ 0.5 * Apollonius.distance(p, d)), 0:0.7:6)
        @test conic_with_focus(F, d, 1.0) isa APParabola2
        h = conic_with_focus(F, d, 2.0)
        @test h isa APHyperbola2 && all(t -> (p = point_on(h, t); Apollonius.distance(p, F) ≈ 2 * Apollonius.distance(p, d)), -1:0.5:1)
        @test all(t -> (p = point_on(h, t; branch=-1); Apollonius.distance(p, F) ≈ 2 * Apollonius.distance(p, d)), -1:0.5:1)
        @test_throws ArgumentError conic_with_focus(P(4.0, 0.0), d, 0.5)
        el = ellipse_with_axis(O, P(5.0, 0.0), P(3.0, 2.4))
        @test el.a ≈ 5 && el.b ≈ 3 && is_on_ellipse(P(3.0, 2.4), el)
        @test is_on_ellipse(P(3.0, 1.0), ellipse_with_axis(O, P(0.0, 2.0), P(3.0, 1.0)))
        @test_throws ArgumentError ellipse_with_axis(O, P(5.0, 0.0), P(6.0, 1.0))
        hy = hyperbola_with_asymptotes(APLine(O, P(1.0, 1.0)), APLine(O, P(1.0, -1.0)), P(2.0, 0.0))
        @test hy.a ≈ 2 && hy.b ≈ 2 && is_on_hyperbola(P(2.0, 0.0), hy)
        hr = hyperbola_with_asymptotes(APLine(P(1.0, 1.0), P(3.0, 2.0)), APLine(P(1.0, 1.0), P(3.0, 0.0)), P(0.0, 1.0))
        @test is_on_hyperbola(P(0.0, 1.0), hr)
        @test_throws ArgumentError hyperbola_with_asymptotes(APLine(O, P(1.0, 0.0)), APLine(P(0.0, 1.0), P(1.0, 1.0)), P(2.0, 2.0))
        pa = parabola_through_points(P(-2.0, 4.0), O, P(1.0, 1.0), APVector(0.0, 1.0))
        @test is_on_parabola(P(-2.0, 4.0), pa) && is_on_parabola(P(1.0, 1.0), pa) && pa.focus ≈ P(0.0, 0.25)
        pt = parabola_through_points(O, P(2.0, 1.0), P(-1.0, 3.0), APVector(1.0, 1.0))
        @test all(p -> is_on_parabola(p, pt; atol=1e-6), [O, P(2.0, 1.0), P(-1.0, 3.0)])
        @test_throws ArgumentError parabola_through_points(O, P(1.0, 1.0), P(2.0, 2.0), APVector(0.0, 1.0))
    end
    @testset "regions and boxes" begin
        s = APStrip2(APLine(O, P(1.0, 0.0)), 2.0)
        @test P(0.0, 1.0) in s && !(P(0.0, 3.0) in s) && strip_width(s) ≈ 2
        hp = APHalfPlane2(P(0.0, 1.0), APVector(0.0, 1.0))
        @test P(0.0, 2.0) in hp && !(P(0.0, 0.0) in hp)
        bb = APBoundingBox(P(1.0, 1.0), 4.0, 2.0)
        @test bb == APBoundingBox(P(-1.0, 0.0), P(3.0, 2.0))
        @test inflate(bb, 1.0) == APBoundingBox(P(-2.0, -1.0), P(4.0, 3.0))
        @test inflate(bb, 1.0, 0.5) == APBoundingBox(P(-2.0, -0.5), P(4.0, 2.5))
        @test isempty(inflate(APBoundingBox(), 1.0))
    end
end

@testset "circle through three points and ellipse membership far from the origin" begin
    for b in (1e6, 1e8, 1e10)
        c = APCircle2(APPoint(b + 1.0, b), APPoint(b, b + 1.0), APPoint(b - 1.0, b))
        @test isapprox(c.center[1] - b, 0.0; atol=1e-4) && isapprox(c.center[2] - b, 0.0; atol=1e-4) && isapprox(c.r, 1.0; rtol=1e-4)
        e = APEllipse2(APPoint(b, b), 5.0, 3.0)
        @test all(t -> is_on_ellipse(point_on(e, t), e), 0.0:0.9:6.0)
    end
end

@testset "vertical and horizontal lines" begin
    P(x, y) = APPoint(x, y)
    @test vertical_line(3.0) ≈ vertical_line(P(3.0, -8.0))
    @test is_on_line(P(3.0, 100.0), vertical_line(3.0)) && !is_on_line(P(3.1, 0.0), vertical_line(3.0))
    @test horizontal_line(-2.0) ≈ horizontal_line(P(7.0, -2.0))
    @test is_on_line(P(-40.0, -2.0), horizontal_line(-2.0)) && !is_on_line(P(0.0, -2.1), horizontal_line(-2.0))
    @test is_perpendicular(vertical_line(1.0), horizontal_line(1.0))
end

@testset "elementary operations" begin
    P(x, y) = APPoint(x, y)
    O = P(0.0, 0.0)
    @test Apollonius.distance(P(2.0, 0.0), APEquipollentVector(APVector(4.0, 0.0), O)) ≈ 0.0 atol = 1e-12
    @test Apollonius.distance(P(0.0, 2.0), APEquipollentVector(APVector(4.0, 0.0), O)) ≈ 2.0
    @test Apollonius.distance(APEquipollentVector(APVector(4.0, 0.0), O), P(0.0, 2.0)) ≈ 2.0
    @testset "direction and angle of vectors" begin
        @test direction(APVector(1.0, 2.0)) == APVector(1.0, 2.0)
        @test slope_angle(APVector(0.0, 2.0)) ≈ π / 2
        @test slope_angle(APVector(-1.0, 0.0)) ≈ π
        @test slope_angle(APEquipollentVector(APVector(1.0, 1.0), P(5.0, 5.0))) ≈ π / 4
        @test polar_angle(P(0.0, 3.0)) ≈ π / 2
        @test polar_angle(P(3.0, 4.0), P(3.0, 1.0)) ≈ π / 2
        p = P(2.0, -1.0)
        @test polar_point(Apollonius.distance(O, p), polar_angle(p), O) ≈ p
    end
    @testset "equipollent vector arithmetic" begin
        ev = APEquipollentVector(APVector(1.0, 2.0), P(1.0, 1.0))
        @test (-ev).vector == APVector(-1.0, -2.0) && (-ev).point == ev.point
        @test (2.0 * ev).vector == APVector(2.0, 4.0) && (ev * 2.0).vector == APVector(2.0, 4.0)
        @test (ev / 2.0).vector == APVector(0.5, 1.0)
        @test orthogonal(ev).vector == orthogonal(ev.vector)
    end
    @testset "center, radius, centroid" begin
        c = APCircle2(P(1.0, 2.0), 3.0)
        arc = APCircularArc2(c, P(4.0, 2.0), P(1.0, 5.0))
        e = APEllipse2(P(1.0, 1.0), 5.0, 3.0)
        @test center(c) == c.center && radius(c) == 3.0 && centroid(c) == c.center
        @test center(arc) == c.center && radius(arc) == 3.0
        @test center(e) == e.center && centroid(e) == e.center
        @test center(APHyperbola2(P(2.0, 2.0), 3.0, 2.0)) == P(2.0, 2.0)
        @test center(APBoundingBox(O, P(2.0, 4.0))) == P(1.0, 2.0)
        @test centroid(APSegment(O, P(2.0, 4.0))) == P(1.0, 2.0)
        @test centroid(P(1.0, 1.0)) == P(1.0, 1.0)
        @test centroid(APPolyline2(O, P(2.0, 0.0), P(2.0, 2.0))) ≈ P(1.5, 0.5)
    end
    @testset "comparison" begin
        e = APEllipse2(O, 5.0, 3.0)
        a1 = APEllipticArc2(e, P(5.0, 0.0), P(0.0, 3.0))
        a2 = APEllipticArc2(e, P(5.0, 0.0), P(0.0, 3.0))
        @test a1 == a2 && isapprox(a1, a2)
        f = t -> P(cos(t), sin(t))
        c1, c2 = APParametricCurve2(f, (0.0, 1.0)), APParametricCurve2(f, (0.0, 1.0))
        @test c1 == c2 && isapprox(c1, c2)
        @test !isapprox(c1, APParametricCurve2(t -> P(cos(t), 2sin(t)), (0.0, 1.0)))
    end
    @testset "polylines and parametric curves" begin
        pl = APPolyline2(O, P(2.0, 0.0), P(2.0, 2.0))
        @test point_on(pl, 0.0) ≈ O && point_on(pl, 1.0) ≈ P(2.0, 2.0) && point_on(pl, 0.5) ≈ P(2.0, 0.0)
        @test_throws ArgumentError point_on(pl, 1.5)
        @test tangent_line(pl, P(1.0, 0.0)) ≈ APLine(O, P(1.0, 0.0))
        @test tangent_line(pl, P(2.0, 1.0)) ≈ APLine(P(2.0, 0.0), P(2.0, 1.0))
        @test_throws ArgumentError tangent_line(pl, P(5.0, 5.0))
        cu = APParametricCurve2(t -> P(cos(t), sin(t)), (0.0, 2π))
        tg = tangent_at(cu, π / 2)
        @test isapprox(tg.point, P(0.0, 1.0); atol=1e-12) && isapprox(tg.vector[1], -1.0; atol=1e-6) && isapprox(tg.vector[2], 0.0; atol=1e-6)
        @test isapprox(Apollonius.distance(P(2.0, 0.0), cu), 1.0; atol=1e-6)
        @test isapprox(Apollonius.distance(cu, P(0.0, 3.0)), 2.0; atol=1e-6)
        @test is_perpendicular(tangent_line(cu, P(0.0, 1.0)), APLine(O, P(0.0, 1.0)))
        @test_throws ArgumentError tangent_line(cu, P(5.0, 5.0))
    end
    @testset "convert element type" begin
        pts = [O, P(1.0, 0.0), P(1.0, 1.0), P(0.0, 1.0)]
        for x in (APTriangle(pts[1], pts[2], pts[3]), APQuadrilateral(pts...), APStraightNgon(pts), APPolyline2(pts),
                  APBoundingBox(O, P(2.0, 3.0)), APAngle2(O, pts[2], pts[4]), APEquipollentVector(APVector(1.0, 2.0), O))
            T = typeof(x)
            tgt = T.name.wrapper{T.parameters[1:end-1]..., Float32}
            @test convert(tgt, x) isa tgt
        end
    end
end

@testset "metrics" begin
    P(x, y) = APPoint(x, y)
    O = P(0.0, 0.0)
    e, h = APEllipse2(O, 3.0, 5.0), APHyperbola2(O, 3.0, 4.0)
    pa = APParabola2(P(0.0, 1.0), APLine(P(0.0, -1.0), P(1.0, -1.0)))
    @test eccentricity(APCircle2(O, 1.0)) == 0 && eccentricity(pa) == 1
    @test eccentricity(e) ≈ 0.8 && eccentricity(h) ≈ 5 / 3
    @test linear_eccentricity(e) ≈ 4 && linear_eccentricity(h) ≈ 5
    @test semi_major(e) == 5 && semi_minor(e) == 3
    @test curvature(APCircle2(O, 2.0)) ≈ 0.5
    @test curvature(e, P(3.0, 0.0)) ≈ 3 / 25 && curvature(e, P(0.0, 5.0)) ≈ 5 / 9
    @test curvature(h, P(3.0, 0.0)) ≈ 3 / 16
    @test curvature(pa, O) ≈ 0.5 && curvature(pa, P(2.0, 1.0)) ≈ 4 / 8^1.5
    @test_throws ArgumentError curvature(e, P(9.0, 9.0))
    ar = APCircularArc2(APCircle2(O, 2.0), P(2.0, 0.0), P(-2.0, 0.0))
    @test chord_length(ar) ≈ 4 && sagitta(ar) ≈ 2 && curvature(ar) ≈ 0.5
    @test arc_length(APSegment(O, P(3.0, 4.0))) ≈ 5
    sq = [O, P(1.0, 0.0), P(1.0, 1.0), P(0.0, 1.0)]
    @test signed_area(APQuadrilateral(sq...)) ≈ 1 && signed_area(APQuadrilateral(reverse(sq)...)) ≈ -1
    @test all(a -> a isa APAngle2, interior_angles(APQuadrilateral(sq...))) && normalized_measure.(interior_angles(APQuadrilateral(sq...))) ≈ fill(π / 2, 4)
    L = APStraightNgon([O, P(2.0, 0.0), P(2.0, 1.0), P(1.0, 1.0), P(1.0, 2.0), P(0.0, 2.0)])
    @test sum(normalized_measure.(interior_angles(L))) ≈ 4π && count(>(π), normalized_measure.(interior_angles(L))) == 1
    @test interior_angles(L)[1] == APAngle2(O, P(2.0, 0.0), P(0.0, 2.0))
    @test sum(normalized_measure.(interior_angles(APStraightNgon(reverse(vertices(L)))))) ≈ 4π
    @test side_lengths(L) ≈ [2.0, 1.0, 1.0, 1.0, 1.0, 2.0] && semiperimeter(L) ≈ 4
    bb = APBoundingBox(O, P(2.0, 3.0))
    @test area(bb) ≈ 6 && perimeter(bb) ≈ 10
    arc90 = APCircularArc2(APCircle2(O, 2.0), P(2.0, 0.0), P(0.0, 2.0))
    sec = APCircularSector2(arc90)
    @test signed_area(sec) ≈ π && normalized_measure.(interior_angles(sec)) ≈ [π / 2, π / 2, π / 2]
    @test normalized_measure.(interior_angles(APCircularSegment2(arc90))) ≈ [π / 4, π / 4]
    @test signed_area(APAnnularSector2(arc90, 1.0)) ≈ area(APAnnularSector2(arc90, 1.0))
    cvt = APCurvilinearTriangle2(APSegment(O, P(4.0, 0.0)), APCircularArc2(APCircle2(P(4.0, 2.0), 2.0), P(4.0, 0.0), P(4.0, 4.0)), APSegment(P(4.0, 4.0), O))
    @test signed_area(cvt) ≈ 8 + 2π && normalized_measure.(interior_angles(cvt)) ≈ [π / 4, π, 3π / 4]
    sq = APStraightNgon([O, P(1.0, 0.0), P(1.0, 1.0), P(0.0, 1.0)])
    cw = APCurvilinearNgon2(collect(reverse(sides(sq))))
    @test signed_area(cw) ≈ signed_area(sq) && all(≈(π / 2), normalized_measure.(interior_angles(cw)))
    circ = APParametricCurve2(t -> P(2cos(t), 2sin(t)), (0.0, 2π))
    @test isapprox(curvature(circ, 1.0), 0.5; rtol=1e-6) && isapprox(signed_curvature(circ, 0.3), 0.5; rtol=1e-6)
    cw = APParametricCurve2(t -> P(2cos(-t), 2sin(-t)), (0.0, 2π))
    @test isapprox(signed_curvature(cw, 0.3), -0.5; rtol=1e-6)
    par = APParametricCurve2(t -> P(t, t^2), (-2.0, 2.0))
    @test isapprox(curvature(par, 0.0), 2.0; rtol=1e-6) && isapprox(curvature(par, 2.0), 2 / 17^1.5; rtol=1e-6)
    @test isapprox(curvature(par, -2.0), 2 / 17^1.5; rtol=1e-6)
    @test isapprox(signed_curvature(APParametricCurve2(t -> P(t, 2t), (0.0, 1.0)), 0.5), 0.0; atol=1e-6)
    @test_throws ArgumentError curvature(par, 3.0)
end
