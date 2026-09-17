include("default_config.jl")

sz = @to_luxor_picture! width=500 height=240 margin=20 begin

end


@svg_doc(sz, @__FILE__, begin

end)
