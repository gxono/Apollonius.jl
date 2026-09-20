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
        assets=["assets/examples.js"],
        size_threshold_ignore=["api.md"],
        example_size_threshold=16 * 1024,
        size_threshold_warn=400 * 1024,
        size_threshold=800 * 1024,
        search_size_threshold_warn=1024 * 1024,
    ),
    pages=[
        "Home" => "index.md",
        "Getting Started" => "getting_started.md",
        "Conventions & FAQ" => "conventions.md",
        "Workflow: From Construction to Figure" => "workflow.md",
        "Drawing with Luxor.jl" => "drawing.md",
        "Marks, Labels & Decorations" => "decorations.md",
        "Compass & Ruler Constructions" => "constructions.md",
        "Points, Lines & Rays" => "points_lines.md",
        "Predicates" => "predicates.md",
        "Measurements & Queries" => "measurements.md",
        "Intersections" => "intersections.md",
        "Numbers & Tolerances" => "numbers.md",
        "Types & Operations" => "types.md",
        "Cookbook" => "cookbook.md",
        "Euclid, Book I" => "euclid.md",
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
