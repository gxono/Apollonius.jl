include("../default_config.jl")

lxm, lxo = @to_luxor_picture width=500 height=320 margin=30 begin
    a, b, c = APPoint(0.0, 0.0), APPoint(5.0, 0.0), APPoint(1.0, 4.0)
    t = APTriangle(a, b, c)
    circ = circumcircle(t)
    G = centroid(t)
    I = incenter(t)
    foot = projection(c, APLine(a, b))
    height = APSegment(c, foot)
    right = APAngle2(foot, b, c)
end
(; a, b, c, t, circ, G, I, foot, height, right) = lxo

@svg_doc(lxm, @__FILE__, begin
    Luxor.fontsize(15)
    sethue(julia_purple)
    path(circ, action=:stroke)
    path(height, action=:stroke)
    sethue(julia_green)
    path(right; as=:rarc, radius=12, action=:stroke)
    sethue(julia_blue)
    path(t, action=:stroke)
    sethue(julia_red)
    label("A", :SW, a)
    label("B", :SE, b)
    label("C", :NW, c)
    label("G", :NE, G)
    label("I", :SW, I)
    path([a, b, c]); plot_point(julia_blue)
    path([G, I, foot]); plot_point(julia_purple)
end)
