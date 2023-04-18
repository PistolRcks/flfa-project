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

class PlayerInfo:
	var username : String
	var is_ready : bool
	var is_loaded : bool
	
	func _init(_username : String, _is_ready : bool = false, _is_loaded : bool = false):
		username = _username
		is_ready = _is_ready
		is_loaded = _is_loaded

# Vars
var message_history : Array = []
var username = "User"
var port : int = 3000
var self_id = 0		# the unique id of the multiplayer client
var game_beginning = false	# required to be set while beginning game due to weird doubleshot 

# Dictionary of int keys (which are the ids) and PlayerInfo values which give info about players
var player_info = {}

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
	var self_player_info = player_info.get(self_id)
	
	# Set button text to reflect game start timer
	if not $"%BeginTimer".is_stopped():
		$"%StartGameButton".text = "Starting in %d..." % ceil($"%BeginTimer".time_left)
	# Basically `self_player_info?.is_ready`
	elif self_player_info.is_ready if self_player_info else false:
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

# Joins a multiplayer server at the given address `addr` as a client
func join_as_client(addr : String):
	print("Joining as client!")
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(addr, port)
	get_tree().network_peer = peer
	
	self_id = get_tree().get_network_unique_id()
	sync_player_info_from_server()

# Appends a new item to the player_info table
remotesync func append_player_info(id : int, username : String):
	player_info[id] = PlayerInfo.new(username)
	print("Adding new player info from id " + String(id))

# The server is assumed to be the source of truth; get info from that
remote func sync_player_info_from_server():
	print("Syncing info...")
	rpc_id(1, "send_player_info_to_client", self_id)
	print("New info: " + String(player_info))

# Sends player_info to clients.
remote func send_player_info_to_client(id : int):
	for player_id in player_info.keys():
		rpc_id(id, "append_player_info", player_id, player_info[player_id].username)

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
	rpc("append_player_info", self_id, new_username)
	
	if self_id != 1:
		sync_player_info_from_server()
	
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
	SyncManager.add_peer(id)
	
	# Undisable join button
	$"%StartGameButton".disabled = false

func _on_player_disconnected(id):
	print("Player with ID " + String(id) + " disconnected!")
	
	player_info.erase(id)
	SyncManager.remove_peer(id)
	
	# Redisable join button
	$"%StartGameButton".disabled = true

func _on_client_connected_ok():
	print("Connected to server successfully!")
	sync_player_info_from_server()

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
	player_info[id].is_ready = is_ready
	
	var all_players_ready = true
	print(player_info)
	for player in player_info.values():
		if not player.is_ready:
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
	print("Setting that " + String(id) + " is loaded")
	player_info[id].is_loaded = is_loaded
	
	# Find if all players are loaded
	var all_players_loaded = true
	for id in player_info.keys():
		if not player_info[id].is_loaded:
			all_players_loaded = false
			break
	
	if all_players_loaded:
		# Setup SyncManager
		# Only the server should start sync
		if self_id == 1:
			SyncManager.start()
		
		# Now we can start
		game_node.begin_round()

remotesync func begin_game():
	# Pause until we're all finished
	game_beginning = true
	
	# Instance scene, set as child
	print("Instancing scene...")
	game_node = game_scene.instance()
	add_child(game_node)
	
	print("Setting up inputs...")
	
	# Setup UI and Inputs
	for id in player_info.keys():	
		var player : int
		if id == 1: 	# Server is always player 1
			player = 0	# Player 1 is controller 0
			game_node.get_combat_ui().update_name(1, player_info[id].username)
		else:			# Client is always player 2
			player = 1
			game_node.get_combat_ui().update_name(2, player_info[id].username)
		
		# -1 means controlled by the server
		game_node.get_player(player).update_combo_controller(player if id == self_id else -1)

	# For some reason this isn't being synced?
	rpc("set_loaded", self_id, true)
