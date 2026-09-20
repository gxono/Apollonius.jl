include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=240 margin=20 begin
    A, B, C = APPoint(0.0,0), APPoint(10,0), APPoint(7,5)
    triangle =  APTriangle(A, B, C)
    G = centroid(triangle)
    O = circumcenter(triangle)
    I = incenter(triangle)
    H = orthocenter(triangle)
    l = euler_line(triangle)
    lados = APLine.(sides(triangle))
    @unbounded cc = circumcircle(triangle)
    ic = incircle(triangle)
    iv = projection.(I, lados)
    npc = nine_point_circle(triangle)
    npc_c = nine_point_center(triangle)
    ep = collect(euler_points(triangle))
    ips = reduce(vcat, intersection.(npc, lados))
end
(; A, B, C, triangle, G, O, I, H, l, lados, cc, ic, iv, npc, npc_c, ep, ips) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue("gray80")
@layer begin
	setline(1); setdash(:dash)
	path([cc, ic, APSegment.([O,I], [A,iv[2]])...], action=:stroke)
end

sethue(julia_purple)
path([l, npc], action=:stroke)
sethue(julia_blue)
path(triangle, action=:stroke)

sethue("white")
path([G,O,I,H,[iv; ips; ep]...], action=:fillpreserve)
sethue(julia_purple); strokepath()
sethue("white")
path([A,B,C], action=:fillpreserve)
sethue(julia_blue); strokepath()
sethue("white")
path(npc_c, action=:fillpreserve)
sethue("gray80"); strokepath()
end)

