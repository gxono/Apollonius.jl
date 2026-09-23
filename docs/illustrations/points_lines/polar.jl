include("../default_config.jl")

lxm = @to_luxor_picture! width=500 height=260 margin=30 begin
    O = APPoint(0.0, 0.0)
    B = polar_point_deg(4.0, 40.0)
    radio = APSegment(O, B)
    xaxis = APSegment(O, APPoint(5.0, 0.0))
    ang = APAngle2(O, APPoint(4.0, 0.0), B)
end


@svg_doc(lxm, @__FILE__, begin
fontsize(15)

@layer begin
    sethue(julia_green); setdash(:dash); setline(1)
    path(radio, action=:stroke)
end

@layer begin
    sethue(julia_blue); setopacity(0.5)
    path(ang, action=:fill, as=:sector)
    
    setopacity(1)
    path(ang, action=:stroke)
    path(brace(O, B), action=:stroke)
end

@layer begin
    setline(1); setdash(:dash); sethue("gray80")
    path(xaxis, action=:stroke)
end


sethue(julia_red)
label("40°", label_anchor(ang; dist=50)...)
text("r = 4", brace_anchor(O, B).point, direction=B-O, halign=:center)

sethue("white")
path(B, action=:fillpreserve)
sethue(julia_purple); strokepath()

sethue("white")
path(O, action=:fillpreserve)
plot_point(julia_blue); strokepath()
end)
