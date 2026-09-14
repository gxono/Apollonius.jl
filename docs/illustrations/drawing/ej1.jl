using EuclideanGeometry, Luxor

t = EGTriangle(EGPoint(-80.0, 60.0), EGPoint(80.0, 60.0), EGPoint(-20.0, -80.0))

Drawing(250, 250, "ej1.png")
origin()
background("white")

sethue(Luxor.julia_blue)
path(t; action=:stroke)
path(circumcircle(t); action=:stroke)

sethue(Luxor.julia_red) 
path([incenter(t), vertices(t)...], action=:fill)

finish()
preview()