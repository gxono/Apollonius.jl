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
        "Drawing with Luxor.jl" => "drawing.md",
        "Points, Lines & Rays" => "points_lines.md",
        "Circles" => "circles.md",
        "Triangles & Triangle Centers" => "triangles.md",
        "Tangency & Apollonius Problems" => "tangency.md",
        "Polygons & Bounding Boxes" => "polygons.md",
        "Conics: Ellipse, Parabola & Hyperbola" => "conics.md",
        "Unbounded Regions" => "unbounded_sets.md",
        "Affine Maps" => "affine_maps.md",
        "Transforming in Bulk: Macros" => "macros.md",
        "Examples" => "examples.md",
        "API Reference" => "api.md",
    ],
)
deploydocs(;
    repo="github.com/gxono/Apollonius.jl",
    devbranch="master",
)
