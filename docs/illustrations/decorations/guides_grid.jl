include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=280 margin=30 begin
    grid = grid_lines(APBoundingBox(APPoint(-1.0, -1.0), APPoint(7.0, 5.0)); step=1.0)
    axes = axes_lines(APBoundingBox(APPoint(-1.0, -1.0), APPoint(7.0, 5.0)))
    P = APPoint(4.0, 3.0)
    guides = coordinate_guides(P)
end
(; grid, axes, P, guides) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(14)
sethue("gray80"); Luxor.setline(1)
path(grid, action=:stroke)
sethue(julia_blue); Luxor.setline(1.5)
path(axes, action=:stroke)
sethue(julia_purple); setdash("dot"); Luxor.setline(1)
path(guides, action=:stroke)
setdash("solid")
path(P)
plot_point(julia_blue)
sethue(julia_red)
label("P", :NE, P)
end)
