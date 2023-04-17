class_name CombatUI
extends Control

onready var p1_health := $Padding/Grid/P1/Healthbar
onready var p1_name := $Padding/Grid/P1/Name
onready var p1_inputs := $Padding/Grid/P1/Inputs
onready var p1_combo := $Padding/Grid/P1/Combo

onready var p2_health := $Padding/Grid/P2/Healthbar
onready var p2_name := $Padding/Grid/P2/Name
onready var p2_inputs := $Padding/Grid/P2/Inputs
onready var p2_combo := $Padding/Grid/P2/Combo

onready var timer := $Timer
onready var timer_text := $Padding/Grid/Timer
onready var is_infinite_time : bool = ($"/root/Globals".ROUND_LENGTH == -1)

signal round_over()		# Emits when the round is over (i.e. when Timer runs out)

func _ready():
	# Should be infinite time if ROUND_LENGTH is set to -1, so don't set the timer
	if not is_infinite_time:
		begin_timer()

func _process(delta):
	if is_infinite_time:
		timer_text.bbcode_text = "[center]Infinite[/center]"
	else:
		if not timer.paused:
			timer_text.bbcode_text = "[center]%d[/center]" % timer.time_left
	
	if Input.is_action_just_pressed("show_debug_text"):
		$DebugPanel.visible = !$DebugPanel.visible

""" Update inputs pressed, reflected in the UI.
		`int` player - The player whose inputs to update (1 or 2, default 2)
		`String` new_text - The new text to change the input box to (BBCode accepted).
"""
func update_inputs(player: int, new_text: String):
	if player == 1:
		p1_inputs.bbcode_text = new_text
	else:
		p2_inputs.bbcode_text = new_text

""" Update combo reported, reflected in the UI.
		`int` player - The player whose inputs to update (1 or 2, default 2)
		`String` new_text - The new text to change the combo box to (BBCode accepted).
"""
func update_combo(player: int, new_text: String):
	if player == 1:
		p1_combo.bbcode_text = new_text
	else:
		p2_combo.bbcode_text = new_text

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

""" Sets the gameover text. Also, sets it to be visible.
	Parameters:
		`String` new_text - The text to set the gameover text to be.
"""
func set_gameover_text(new_text: String):
	$GameOverText.visible = true
	$GameOverText.bbcode_text = "[center]" + new_text + "[/center]"

func set_debug_text(new_text: String):
	$"%DebugText".text = new_text

func get_debug_text(new_text: String):
	return $"%DebugText".text

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
