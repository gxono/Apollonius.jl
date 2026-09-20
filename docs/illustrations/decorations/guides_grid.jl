include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=280 margin=30 begin
    grid = grid_lines(APBoundingBox(APPoint(-1.0, -1.0), APPoint(7.0, 5.0)); step=1.0)
    axes = axes_lines(APBoundingBox(APPoint(-1.0, -1.0), APPoint(7.0, 5.0)))
    P = APPoint(4.0, 3.0)
    guides = coordinate_guides(P)
end
(; grid, axes, P, guides) = lxo
@svg_doc(lxm, @__FILE__, begin
@layer begin
setline(1); sethue("gray80")
path(grid, action=:stroke)
end

sethue(julia_blue)
path(axes, action=:stroke)

@layer begin
setline(5); setdash("dot"); sethue(julia_purple)
path(guides, action=:stroke)
end

sethue(julia_red)
label("P", :NE, P)

sethue("white")
path(P, action=:fillpreserve)
sethue(julia_blue); strokepath()
end)
