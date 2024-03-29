extends Node2D

onready var p1 : PlayerEntity = $Player1
onready var p2 : PlayerEntity = $Player2

# Minimum and maximum zoom for the camera
const MIN_ZOOM = 0.15
const MAX_ZOOM = 0.5

# Distances required for zooming in/out
const MIN_ZOOM_DISTANCE = 100
const MAX_ZOOM_DISTANCE = 500

# Round end variables
var round_over = false

func _ready():
	# Listen to when a fighter dies, also don't allow movement until we start
	for fighter in get_tree().get_nodes_in_group("fighters"):
		fighter.connect("on_death", self, "_on_player_death")
		fighter.stop_all_processes()
	
	# Start if multiplayer isn't on
	if !get_tree().network_peer:
		begin_round()

func _process(delta):
	# Resolve facing
	var p1_x = p1.position.x
	var p2_x = p2.position.x
	
	# If player 1 is to the left of player 2
	if p1_x < p2_x:
		# Player 1 should be facing right, and player 2 should be facing left
		p1.update_facing(true)
		p2.update_facing(false)
	else:
		# Otherwise it's the other way around
		p1.update_facing(false)
		p2.update_facing(true)
	
	var state = p1.playback.get_current_node()
	
	$UI/CombatUI.set_debug_text(
		"p1_x: " + str(p1_x)
		+ " / p1_vel: " + str(p1.velocity)
		+ "\np2_x: " + str(p2_x)
		+ " / p2_vel: " + str(p2.velocity)
		+ "\nAnimation State: " + state
		+ "\nTransition: " + str(p1.animation_tree.get("parameters/" + state + "/Transition/current"))
		+ "\ncombo_being_performed: " + str(p1.combo_being_performed)
		+ "\nComboController ticks left: " + str(p1.get_combo_controller().input_holder.ticks_left)
	)
	
	# Place the camera in the middle, also adjust camera zoom
	$Camera.position.x = (p1_x + p2_x) / 2
	
	# Classic y = mx + b
	# Basically, we want to linearly shift between zooms of MAX_ZOOM and MIN_ZOOM, based on distance
	# It's just a clamped linear equation...
	var dist = abs(p1_x - p2_x)
	var dist_clamped = min(max(dist, MIN_ZOOM_DISTANCE), MAX_ZOOM_DISTANCE)
	var m = (MAX_ZOOM - MIN_ZOOM) / (MAX_ZOOM_DISTANCE - MIN_ZOOM_DISTANCE)
	var b = MIN_ZOOM - m * MIN_ZOOM_DISTANCE
	var zoom_mod = dist_clamped * m + b
	$Camera.zoom = Vector2(1, 1) * zoom_mod

func begin_round():
	get_combat_ui().begin_timer()
	
	for fighter in get_tree().get_nodes_in_group("fighters"):
		fighter.resume_all_processes()

func get_player(num: int) -> PlayerEntity:
	if num == 1: return p1
	else: return p2

func get_combat_ui() -> CombatUI:
	return ($UI/CombatUI as CombatUI)

# Handles a game end state
func _handle_endgame(gameover_text: String): 
	# Update UI
	get_tree().call_group("combat_ui", "pause_timer")
	get_tree().call_group("combat_ui", "set_gameover_text", gameover_text)
	
	# Stop players from doing anything (i.e. stop them from processing)
	get_tree().call_group("fighters", "stop_all_processes")

func _on_player_death(player):
	print("Being triggered")
	
	# Find winner
	var winner = 0
	if player == 1:
		winner = 2
	else: 
		winner = 1
	
	_handle_endgame("Player " + str(winner) + " won!")

func _on_round_draw():
	_handle_endgame("Draw by timeout!")
