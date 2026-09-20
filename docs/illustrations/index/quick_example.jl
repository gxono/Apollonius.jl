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
    
    #circle and height
    sethue(julia_purple)
    path([circ, height], action=:stroke)
    
    #angle mark
    sethue(julia_green)
    path(right; as=:rarc, radius=12, action=:stroke)
    
    #triangle
    sethue(julia_blue)
    path(t, action=:stroke)
    
    #points
    sethue("white")
    path([a, b, c], action=:fillpreserve)
    sethue(julia_blue); strokepath()
    sethue("white")
    path([G, I, foot], action=:fillpreserve)
    sethue(julia_purple); strokepath()
    
    #labels 
    sethue(julia_red)
    label("A", :SW, a, offset=8)
    label("B", :SE, b, offset=8)
    label("C", :NW, c, offset=8)
    label("G", :NE, G, offset=8)
    label("I", :SW, I, offset=8)
end)
