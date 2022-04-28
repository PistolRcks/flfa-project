extends Area2D
class_name Hitbox

# Nodes
onready var collisionShape : CollisionShape2D = $"CollisionShape2D"
onready var shape := collisionShape.shape
onready var debugShape := $DebugShape

# Custom Signals
signal color_changed(color) 	# Fired whenever the `debugColor` variable is set
signal hitbox_entered(area, type, team, metadata)	# Fired whenever a Hitbox collides with another Hitbox

# Exports
""" The type of Hitbox to use.

	Hitboxes deal damage, while hurtboxes recieve damage.
"""
export(String, "HIT", "HURT") var type

""" The team that the Hitbox is on.

	A hurtbox must not be on the same team as the hitbox to receive damage.
"""
export(String) var team

""" The color of the Hitbox as it will be displayed in debug mode.
"""
export(Color) var debugColor setget setDebugColor, getDebugColor

""" The metadata of the specific Hitbox.

	Often, this should contain damage statistics or anything else that 
	one might want to give to the Entity being hit.
"""
export(Dictionary) var metadata

# Getters/Setters
""" Sets the color of the debug rectangle of the Hitbox.
"""
func setDebugColor(c : Color):
	debugColor = c
	emit_signal("color_changed", c)

""" Gets the color of the debug rectangle of the Hitbox.
"""
func getDebugColor() -> Color:
	return debugColor

""" Determines the size of the Hitbox.

	Parameters:
		`float` w - The new width of the Hitbox.
		`float` h - The new height of the Hitbox.
"""
func setSize(w : float, h : float):
	# Divided by 20 due to the extents doubling the width and height
	scale = Vector2(w/20, h/20)

""" Determines the radius of the Hitbox.

	Parameters:
		`float` r - The new radius of the Hitbox.
"""
func setRadius(r : float):
	scale = Vector2(r/10, r/10)

# Wrapper function to fire the area entered to give hitbox stats
func _on_Hitbox_area_entered(area):
	# If it's actually a hitbox, it'll have a type
	if area.has_meta("type"):
		var hb = area as Hitbox
		emit_signal("hitbox_entered", area, hb.type, hb.team, hb.metadata)

func _ready():
	# TODO: This should probably be able to be set during runtime
	# Set debug visibility
	match type:
		"HIT":
			debugShape.visible = $"/root/Globals".SHOW_HITBOXES
		"HURT":
			debugShape.visible = $"/root/Globals".SHOW_HURTBOXES



