extends Control

# messages are unsafe lol
class Message:
	var sender : String
	var message : String
	# Defines whether to use `<user> <message>` or
	# `[<user>]: <message>` when formatting text
	var is_me_style : bool 
	
	func _init(_is_me_style : bool, _sender : String, _message : String):
		is_me_style = _is_me_style
		sender = _sender
		message = _message
	
	func format_message() -> String:
		if is_me_style:
			return sender + " " + message
		return "[" + sender + "]: " + message

# Vars
var message_history : Array = []
var username = "User"
var port : int = 3000
var self_id = 0		# the unique id of the multiplayer client
var game_beginning = false	# required to be set while beginning game due to weird doubleshot 

# Dictionary of int keys and bool values staating which players are ready
var readied_players : Dictionary = {}
var loaded_players : Dictionary = {}

# Scenes
const game_scene = preload("res://level/basic_arena/TestingArena.tscn")
var game_node : Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	$"%HostPopup".popup()
	get_tree().connect("network_peer_connected", self, "_on_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")
	get_tree().connect("connected_to_server", self, "_on_client_connected_ok")
	get_tree().connect("connection_failed", self, "_on_client_connected_fail")
	get_tree().connect("server_disconnected", self, "_on_server_disconnected")

func _process(delta):
	# Set button text to reflect game start timer
	if not $"%BeginTimer".is_stopped():
		$"%StartGameButton".text = "Starting in %d..." % ceil($"%BeginTimer".time_left)
	elif readied_players.get(self_id):
		$"%StartGameButton".text = "Waiting..."
	else:
		$"%StartGameButton".text = "Start Game!"

## Chatting ##
# Sends a message to the chat client.
remotesync func send_message(message : String, is_me_style : bool = false, 
		user : String = username):
	
	message_history.append(Message.new(is_me_style, user, message))
	update_text_box()

# Updates the textbox with new info.
func update_text_box():
	$"%TextOutput".text = ""
	
	for message in message_history:
		$"%TextOutput".text += message.format_message() + "\n"

## Multiplayer ##
# Creates a multiplayer server
func join_as_host():
	print("Joining as host...")
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(port, 2)
	get_tree().network_peer = peer
	
	self_id = get_tree().get_network_unique_id()
	readied_players[self_id] = false

# Joins a multiplayer server at the given address `addr` as a client
func join_as_client(addr : String):
	print("Joining as client!")
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(addr, port)
	get_tree().network_peer = peer
	
	self_id = get_tree().get_network_unique_id()
	readied_players[self_id] = false

# Disconnects from the network.
func _handle_disconnect():
	rpc("send_message", "disconnected from the server.", true, username)
	get_tree().network_peer = null

## Handlers ##
# Handle pressing enter or the submit button in the UsernamePopup
func _handle_username_input(new_username : String):
	# Should check that usernames are one character or greater, but I honestly don't really care
	username = new_username
	$"%UsernamePopup".hide()
	rpc("send_message", "just joined the server!", true, username)
	$"%TextInput".grab_focus()

func _handle_port_input(is_host : bool, new_port : String):
	# After entering the port, should hide this popup and do the other one
	port = int(new_port)
	
	if is_host:
		join_as_host()
	else:
		if $"%ClientAddressInput".text:
			join_as_client($"%ClientAddressInput".text)
		else:
			printerr("ClientAddressInput was empty, try again...")
			return
	
	# Close this popup and put in the other one
	$"%HostPopup".hide()
	$"%UsernamePopup".popup()

## Multiplayer ##
func _on_player_connected(id):
	print("Player with ID " + String(id) + " connected!")
	
	# Add new player
	readied_players[id] = false
	loaded_players[id] = false
	SyncManager.add_peer(id)
	
	# Undisable join button
	$"%StartGameButton".disabled = false

func _on_player_disconnected(id):
	print("Player with ID " + String(id) + " disconnected!")
	
	readied_players.erase(id)
	loaded_players.erase(id)
	SyncManager.remove_peer(id)
	
	# Redisable join button
	$"%StartGameButton".disabled = true

func _on_client_connected_ok():
	print("Connected to server successfully!")

func _on_client_connected_fail():
	print("Failed to connect to server!")

func _on_server_disconnected():
	send_message("disconnected.", true, "Server")

## Chat Windows ##
# Connect to when the user presses enter when typing into the chat window
func _on_TextInput_text_entered(new_text : String):
	rpc("send_message", new_text, false, username)
	$"%TextInput".clear()

## Username Popup ##
# Connects to when the user presses enter when inputting a username
func _on_UsernameInput_text_entered(new_text : String):
	_handle_username_input(new_text)

# Connects to when the user presses the button after inputting a username
func _on_SubmitButton_pressed():
	_handle_username_input($"%UsernameInput".text)

# Connects to the Main Menu button (either on the HostPopup or the UsernamePopup)
func _on_MainMenuButton_pressed():
	get_tree().change_scene("res://ui/MainMenu.tscn")

## Client Input ##
# Connects to when the user presses enter when inputting a username
func _on_ClientAddressInput_text_entered(new_address : String):
	# Change focus to port entry
	$"%ClientPortInput".grab_focus()

# Connects to when the user presses enter when inputting a username
func _on_ClientPortInput_text_entered(new_port : String):
	_handle_port_input(false, new_port)

# Connects to when the user presses the "Join" button after inputting an address and port
func _on_ClientSubmit_pressed():
	_handle_port_input(false, $"%ClientPortInput".text)

## Host Input ##
# Connects to when the user presses enter when inputting a port for the host
func _on_HostPortInput_text_entered(new_port : String):
	_handle_port_input(true, new_port)

# Connects to when the user presses the "Host" button after inputting a port
func _on_HostSubmit_pressed():
	_handle_port_input(true, $"%HostPortInput".text)

## Game Start ##
func _on_StartGameButton_toggled(button_pressed):
	rpc("set_readied", self_id, button_pressed)
	
	# Send a "ready up" message
	if button_pressed:
		rpc("send_message", "is readied up!", true, username)
	else:
		rpc("send_message", "is wussying out...", true, username)

# Sets if a player with the RPC id `id` is ready
remotesync func set_readied(id : int, is_ready : bool):
	readied_players[id] = is_ready
	
	var all_players_ready = true
	print(readied_players)
	for player_ready in readied_players.values():
		if not player_ready:
			all_players_ready = false
			break
	
	if all_players_ready:
		# Start launch countdown
		$"%BeginTimer".start(3)
	else:
		# Cancel launch countdown
		$"%BeginTimer".stop()

# Starts the game once the timer is over
func _on_BeginTimer_timeout():
	print("We are finished! Beginning game...")
	if not game_beginning:
		rpc("begin_game")

# Sets if a player with the RPC id `id` is ready
remotesync func set_loaded(id : int, is_loaded : bool):
	loaded_players[id] = is_loaded

remotesync func begin_game():
	# Pause until we're all finished
	game_beginning = true
	get_tree().set_pause(true)
	
	# Instance scene, set as child
	game_node = game_scene.instance()
	add_child(game_node)
	
	# Setup SyncManager
	# Only the server should start sync
	if self_id == 1:
		SyncManager.start()

	rpc("set_loaded", self_id, true)
	
	# Busy wait until we're all loaded
	var all_players_loaded = false
	while not all_players_loaded:
		all_players_loaded = true
		for loaded in readied_players.values():
			if not loaded:
				all_players_loaded = false
				break
	
	# Now we can start
	get_tree().set_pause(false)
	
