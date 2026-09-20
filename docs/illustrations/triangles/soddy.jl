include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=340 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    base = collect(three_tangent_circles(t))
    sc = soddy_circles(t)
    @unbounded sdl = soddy_line(t)
    soddy_pts = [sc.inner.center, sc.outer.center]
    inner = sc.inner
end
(; A, B, C, t, base, sc, sdl, soddy_pts, inner) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue("gray80")
path(base, action=:stroke)
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_purple)
path(inner, action=:stroke)
path(sdl, action=:stroke, extend=30)
path([A, B, C]); plot_point(julia_blue)
path(soddy_pts); plot_point(julia_purple)
end)
