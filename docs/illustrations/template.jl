include("default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=240 margin=20 begin
    # build the objects here: name = APObject(...)
end
# bring the fitted objects into scope: (; name1, name2) = lxo
@svg_doc(lxm, @__FILE__, begin
end)
