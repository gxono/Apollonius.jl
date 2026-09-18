include("../default_config.jl")
using Apollonius: rotate, translate

sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    P, Q, C = APPoint(1.0, 1.0), APPoint(6.0, 3.0), APPoint(2.0, 6.0)
    
    R = rotate(C, pi / 2, P)
    angTR = APAngle2(P, C, R)
    
    H = homothety(C, 2.0, P)

    vecCT = APVector(1.0, -1.0)
    T = translate(C, vecCT)

    trian = APTriangle(P,Q,C)
    B = barycenter(vertices(trian), [1.0, 1.0, 2.0])
    m1, m2, m3 = midpoint.(sides(trian))
end




@svg_doc(sz, @__FILE__, begin
sethue("gray80")
#Barycenter

#median
path([APSegment(p,m) for (p,m) in zip([C,P,Q], [m1,m2,m3])], action = :stroke)    
path(APTriangle(P, Q, C), action=:stroke)

#Homothety
sethue(julia_purple)
path(APLine(C,P), action=:stroke)

#Rotation
sethue(julia_red)
path(APSegment(P,C), action=:stroke)

sethue(julia_purple)
path(angTR, action=:fill, as=:rsector)
path(APSegment(P,R), action=:stroke)

#Traslation
path(APEquipollentVector(vecCT, C), action=:stroke, as=:arrow)

path(P)
setpoint(julia_blue)

path([C,Q])
setpoint(julia_red)

path([R,H,T,B])
setpoint(julia_purple)

path([m1,m2,m3])
setpoint("gray80")

sethue("black")
label("Q", :E ,Q)
label("P", :SE ,P)
label("C", :NW ,C)
label("R", :W ,R)
label("H", :SE ,H)
label("T", :SE ,T)
label("B", :W ,B)
end)
