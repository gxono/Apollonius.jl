using EuclideanGeometry
using Documenter

DocMeta.setdocmeta!(EuclideanGeometry, :DocTestSetup, :(using EuclideanGeometry); recursive=true)

makedocs(;
    modules=[EuclideanGeometry],
    authors="Jonatan Perren",
    sitename="EuclideanGeometry.jl",
    format=Documenter.HTML(;
        canonical="https://gxono.github.io/EuclideanGeometry.jl",
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
        "Affine Maps" => "affine_maps.md",
        "API Reference" => "api.md",
        "Drawing with Luxor.jl" => "drawing.md",
    ],
)

deploydocs(;
    repo="github.com/gxono/EuclideanGeometry.jl",
    devbranch="master",
)
