include("../default_config.jl")
import Apollonius: translate

lxm = @to_luxor_picture! flip=false width=500 height=240 margin=20 begin
    ta1 = APTriangle(APPoint(-80.0, 60.0), APPoint(80.0, 60.0), APPoint(-20.0, -80.0))
    ca = circumcenter(ta1)
		ta2 = homothety(ta1, 1/2, ca)
		tb1, cb, tb2 = translate.([ta1, ca, ta2], APVector(200.0, 0))
end
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
@layer begin
	setopacity(0.25)
	path([ta1])
	path(ta2)
	fillpath()
	
	path(tb1)
	path(tb2, reverse=true) #see fill-rule on Luxor doc.
	fillpath()
end

path([ta1, ta2, tb1, tb2], action=:stroke)

end)
