# A basic tuple-like class representing a combo
class_name Combo
extends Object

var inputs : String
var name : String
var metas : Array
var state : String
var lenience : String
var regex : RegEx	# A compiled regex for ease of searching

""" Constructor for the Combo class.

	Parameters:
		`String` _inputs - The inputs needed to perform the Combo (as a RegEx statement).
		`String` _name - A human-readable name for the Combo. This should correlate to an entry in
			the AnimationTree's Transition node for that state.
		`String` _state - The state required to be in to perform the combo; this is also the state 
				of the `AnimationNodeStateMachine` required to play the animation.
			Acceptable options are:
				"STAND" - In standing state
				"CROUCH" - In crouching state
				"AIR" - In air
		`String` _lenience - How lenient to be when determining state requirements.
			Acceptable options are:
				"STRICT" - Only accept the state listed in `_state`
				"GROUND" - Accept both grounded states (i.e. all but "AIR")
				"ALL" - Accept any state
		`Array` _metas - An Array containing the metadata for all Hitboxes this Combo produces in 
			its animation, in the order they are produced in the animation.
"""
func _init(_inputs: String, _name: String, _state: String, _lenience: String, _metas: Array):
	inputs = _inputs
	name = _name
	state = _state
	lenience = _lenience
	metas = _metas
	regex = RegEx.new()
	regex.compile(_inputs)
