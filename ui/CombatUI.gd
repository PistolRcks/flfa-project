extends Control

onready var p1_health := $Padding/Grid/P1/Healthbar
onready var p1_name := $Padding/Grid/P1/Name

onready var p2_health := $Padding/Grid/P2/Healthbar
onready var p2_name := $Padding/Grid/P2/Name

onready var timer := $Timer
onready var timer_text := $Padding/Grid/Timer

signal round_over()		# Emits when the round is over (i.e. when Timer runs out)

# For testing purposes...
func _ready():
	begin_timer()

func _process(delta):
	if not timer.paused:
		timer_text.bbcode_text = "[center]%d[/center]" % timer.time_left

""" Update the name of the player as represented in the UI.
	Parameters:
		`int` player - The player whose name to update (1 or 2, default 2)
		`String` new_name - The new name to set the player to (BBCode accepted).
"""
func update_name(player: int, new_name: String):
	if player == 1:
		p1_name.bbcode_text = new_name
	else:
		p2_name.bbcode_text = "[right]" + new_name + "[/right]"

""" Update the health of the player as represented in the UI.
	Parameters:
		`int` player - The player whose health to update (1 or 2, default 2)
		`float` new_health - The new health (as a percent of the max health) to set the healthbar
			to.
"""
func update_health(player: int, new_health: float):
	if player == 1:
		p1_health.value = new_health
	else:
		p2_health.value = new_health

""" Initially starts the timer (usually at the beginning of the round). 
	Round length is controlled by the ROUND_LENGTH global.
"""
func begin_timer():
	timer.start($"/root/Globals".ROUND_LENGTH)

""" Pauses the timer. """
func pause_timer():
	timer.paused = true

""" Resumes the timer. """
func resume_timer():
	timer.paused = false


func _on_Timer_timeout():
	emit_signal("round_over")