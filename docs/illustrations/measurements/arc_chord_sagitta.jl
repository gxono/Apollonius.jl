include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=260 margin=30 begin
    arc = APCircularArc2(APCircle2(APPoint(0.0, 0.0), 3.0), polar_point(3.0, pi / 9), polar_point(3.0, 8pi / 9))
    chord = APSegment(arc.p1, arc.p2)
    top = midpoint(arc)
    sag = APSegment(midpoint(arc.p1, arc.p2), top)
end
(; arc, chord, top, sag) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(arc, action=:stroke)
sethue(julia_purple)
path([chord, sag], action=:stroke)
sethue(julia_red)
label("chord_length", :S, midpoint(chord.p1, chord.p2)); label("sagitta", :E, midpoint(sag.p1, sag.p2))
sethue("white"); path([arc.p1, arc.p2], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([top], action=:fillpreserve); sethue(julia_purple); strokepath()
end)
