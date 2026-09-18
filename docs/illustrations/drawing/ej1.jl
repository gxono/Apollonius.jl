include("../default_config.jl")

t = APTriangle(APPoint(-80.0, 60.0), APPoint(80.0, 60.0), APPoint(-20.0, -80.0))

Drawing(250, 250, "docs/src/assets/img/drawing/ej1.png")
origin()
background("white")

sethue(julia_blue)
path(t; action=:stroke)
path(circumcircle(t); action=:stroke)

sethue(julia_red)
path([incenter(t), vertices(t)...], action=:fill)

finish()
preview()
