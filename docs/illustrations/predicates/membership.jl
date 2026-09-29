include("../default_config.jl")
lxm = @prepare_to_picture! width=520 height=300 margin=30 begin
    d, p1, p2  = APVector(0.0, -3.0), APPoint(0.0, 0.0), APPoint(6.0, 0.0)
    l = APLine(p1, p2)
    r = APRay(p1, p2) |> translate(d)
    s = APSegment(p1, p2) |> translate(2d)
    tl = [APPoint(x, y) for (x, y) in ((-2.0, 0.0), (3.0, 0.0), (8.0, 0.0), (3.0, 1.0))]
    tr = translate.(tl, d)
    ts = translate.(tl, 2d)
    puntos = vcat(tl, tr, ts)
end




@svg_doc(lxm, @__FILE__, begin
fontsize(15)

sethue(julia_blue)
path([l, r, s], action=:stroke)

sethue(julia_red)
for (t, v) in (("is_on_line", tl), ("is_on_ray", tr), ("is_on_line", ts))
    label(t, :NE, v[1], offset=8)
end

sethue("white")
path([p for p in puntos if any(x -> p in x, [l, r, s])], action=:fillpreserve);
sethue(julia_green); strokepath()
sethue("white");
path([p for p in puntos if all(x -> !in(p, x), [l, r, s])], action=:fillpreserve);
sethue("gray80"); strokepath()
sethue("white"); path([r.origin, s.p1, s.p2], action=:fillpreserve); 
sethue(julia_blue); strokepath()
end)


