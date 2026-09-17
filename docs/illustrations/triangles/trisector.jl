include("../default_config.jl")



A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
t = APTriangle(A, B, C)
ll = collect(Iterators.flatten(trisector.(t, 1:3)))

sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    A; B; C; t; ll
end








@svg_doc(sz, @__FILE__, begin

sethue(julia_purple)
path(ll, action=:stroke)

sethue(julia_blue)
path(t, action=:stroke)

path(vertices(t))
setpoint(julia_red)

end)
