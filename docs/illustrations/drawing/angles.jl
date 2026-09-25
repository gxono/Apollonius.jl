include("../default_config.jl")
lxm, lxo = @prepare_to_picture flip=false width=500 height=240 margin=20 begin
    t = APTriangle(APPoint(-80.0, 60.0), APPoint(80.0, 60.0), APPoint(-20.0, -80.0))
    ang = APAngle2(t[2], t[1], t[3])
    tv = Apollonius.translate.(t, APVector.([0, 200, 400, 600, 800], 0))
    angv = Apollonius.translate.(ang, APVector.([0, 200, 400, 600, 800], 0))
end
(; t, ang, tv, angv) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(tv, action=:stroke)
sethue(julia_purple)
path(angv[1]; as=:rays, action=:stroke)
path(angv[2]; as=:region, action=:fill)
path(only(marks(angv[3])); action=:stroke)
path(APCircularSector2(only(marks(angv[4]))); action=:fill)
path(only(marks(angv[5]; style=:parallelogram)); action=:stroke)
end)
