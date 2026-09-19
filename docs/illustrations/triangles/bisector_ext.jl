include("../default_config.jl")
A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
t = APTriangle(A, B, C)
ll = bisector_ext.(t, 1:3)
ii = reduce(hcat, intersection.(ll, circshift(ll, 1))) |> vec
lxm, lxo = @to_luxor_picture width=500 height=240 margin=20 begin
    A; B; C; t; ll; ii
end
(; A, B, C, t, ll, ii) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple)
path(ll, action=:stroke)
sethue(julia_blue)
path(t, action=:stroke)
path(vertices(t))
plot_point(julia_blue)
path(ii)
plot_point(julia_purple)
end)
