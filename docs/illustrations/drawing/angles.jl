include("../default_config.jl")
sz = @to_luxor_picture! flip=false width=500 height=240 margin=20 begin
    t = APTriangle(APPoint(-80.0, 60.0), APPoint(80.0, 60.0), APPoint(-20.0, -80.0))
    ang = APAngle2(t[2], t[1], t[3])
    tv = Apollonius.translate.(t, APVector.([0, 200, 400, 600, 800], 0))
    angv = Apollonius.translate.(ang, APVector.([0, 200, 400, 600, 800], 0))
end
@svg_doc(sz, @__FILE__, begin
sethue(julia_blue)
path(tv, action=:stroke)
sethue(julia_purple)
path(angv[1]; as=:rays, action=:stroke)
path(angv[2]; as=:arc, action=:stroke)
path(angv[3]; as=:sector, action=:fill)
path(angv[4]; as=:rarc, action=:stroke)
path(angv[5]; as=:rsector, action=:fill)
end)
