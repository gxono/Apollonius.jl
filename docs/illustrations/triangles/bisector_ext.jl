include("../default_config.jl")
A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
t = APTriangle(A, B, C)
ll = bisector_ext.(t, 1:3)
ii = reduce(hcat, intersection.(ll, circshift(ll, 1))) |> vec
lxm, lxo = @prepare_to_picture width=500 height=240 margin=20 begin
    A; B; C; t; ll; ii
end
(; A, B, C, t, ll, ii) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple)
path(ll, action=:stroke)
sethue(julia_blue)
path(t, action=:stroke)
sethue("white"); path(vertices(t), action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path(ii, action=:fillpreserve); sethue(julia_purple); strokepath()
end)
