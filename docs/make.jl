using Apollonius
using Documenter

DocMeta.setdocmeta!(Apollonius, :DocTestSetup, :(using Apollonius); recursive=true)

makedocs(;
    modules=[Apollonius],
    authors="Jonatan Perren",
    sitename="Apollonius.jl",
    format=Documenter.HTML(;
        canonical="https://gxono.github.io/Apollonius.jl",
        edit_link="master",
        assets=String[],
        size_threshold_ignore=["api.md"],
    ),
    pages=[
        "Home" => "index.md",
        "Points, Lines & Rays" => "points_lines.md",
        "Circles" => "circles.md",
        "Triangles & Triangle Centers" => "triangles.md",
        "Tangency & Apollonius Problems" => "tangency.md",
        "Polygons & Bounding Boxes" => "polygons.md",
        "Conics: Ellipse, Parabola & Hyperbola" => "conics.md",
        "Unbounded Regions" => "unbounded_sets.md",
        "Affine Maps" => "affine_maps.md",
        "Transforming in Bulk: Macros" => "macros.md",
        # 3D Geometry pages -- paused along with the rest of 3D (the source
        # files are untracked, see .gitignore), so left out of the nav here.
        # "3D Geometry" => [
        #     "Points, Lines & Planes" => "geometry_3d_foundation.md",
        #     "Conics & Quadric Surfaces" => "geometry_3d_conics.md",
        #     "Polyhedra & Solids" => "geometry_3d_solids.md",
        #     "Unbounded Sets" => "geometry_3d_unbounded.md",
        # ],
        "API Reference" => "api.md",
        "Drawing with Luxor.jl" => "drawing.md",
    ],
)

deploydocs(;
    repo="github.com/gxono/Apollonius.jl",
    devbranch="master",
)
