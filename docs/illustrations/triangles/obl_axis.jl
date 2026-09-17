include("../default_config.jl")



sz = @to_luxor_picture! width=500 height=240 margin=75 begin
    A, B, C = APPoint(0.0,0), APPoint(10,0), APPoint(7,5)
    t =  APTriangle(A, B, C)
    oa = orthic_axis(t)
    ba = brocard_axis(t)
    la = lemoine_axis(t)
end




@svg_doc(sz, @__FILE__, begin

sethue(julia_purple)
path([oa, ba, la], action=:stroke)

sethue(julia_blue)
path(t, action=:stroke)



end)
