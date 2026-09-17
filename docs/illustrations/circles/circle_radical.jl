include("../default_config.jl")



sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    c1 = APCircle2(APPoint(0.0, 0.0), 3.0)
    c2 = APCircle2(APPoint(8.0, 0.0), 2.0)
    c3 = APCircle2(APPoint(3.0, 6.0), 4.0)

    ra1 = radical_axis(c1, c2)
    ra2 = radical_axis(c2, c3)
    ra3 = radical_axis(c3, c1)
    rc = radical_center(c1, c2, c3)
    rcirc = radical_circle(c1, c2, c3)
end



@svg_doc(sz, @__FILE__, begin

sethue("gray80")
setdash(:dash)
path(APSegment(c1.center, c3.center), action=:stroke)
path(APSegment(c2.center, c3.center), action=:stroke)
path([ra2, ra3], action=:stroke)

sethue(julia_purple)
path(APSegment(c1.center, c2.center), action=:stroke)
setdash(:solid)

sethue(julia_blue)
path([c1,c2,c3], action=:stroke)


sethue(julia_purple)
path(rcirc, action=:stroke)
path(ra1, action=:stroke)

path(rc)
setpoint(julia_purple)

path([c1.center, c2.center, c3.center])
setpoint(julia_red)
end)
