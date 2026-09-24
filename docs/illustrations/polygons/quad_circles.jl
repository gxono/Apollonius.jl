include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=560 height=260 margin=30 begin
    it = isosceles_trapezoid_on_segment(APPoint(0.0, 0.0), APPoint(6.0, 0.0), 2.0, 3.0)
    cc = circumcircle(it)
    kt = kite_on_diagonal(APPoint(10.0, -1.0), APPoint(10.0, 6.0), 0.35, 2.0)
    ic = incircle(kt)
end
(; it, cc, kt, ic) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path([it, kt], action=:stroke)
sethue(julia_purple)
path([cc, ic], action=:stroke)
end)
