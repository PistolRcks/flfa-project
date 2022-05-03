# A basic tuple-like class representing a combo
class_name Combo
extends Object

var inputs : String
var name : String
var metas : Array
var regex : RegEx	# A compiled regex for ease of searching

""" Constructor for the Combo class.
	Parameters:
		`String` _inputs - The inputs needed to perform the Combo (as a RegEx statement).
		`String` _name - A human-readable name for the Combo. This should correlate to an entry in
			the AnimationTree's Transition node for that state.
		`Array` _metas - An Array containing the metadata for all Hitboxes this Combo produces in 
			its animation, in the order they are produced in the animation. 
"""
func _init(_inputs: String, _name: String, _metas: Array):
	inputs = _inputs
	name = _name
	metas = _metas
	regex = RegEx.new()
	regex.compile(_inputs)