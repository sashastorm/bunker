extends Node3D

# define the peer and the player/world scenes
var peer = ENetMultiplayerPeer.new()
@export var world : PackedScene
@export var player_scene : PackedScene

# when the host button is pressed, start a server on port 1027
func _on_host_pressed():
	peer.create_server(1027)
	
	# connect multiplayer peer/player scene
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	add_player()
	
	# hide menu
	$HostMenu.hide()

# when the join button is pressed, join client on local IP and port 
func _on_join_pressed():
	peer.create_client("192.168.1.4", 1027)
	multiplayer.multiplayer_peer = peer
	
	# hide menu
	$HostMenu.hide()

# adding the first player to the game
func add_player(id = 1):
	# add player and set id and call the player scene to the server instance
	var player = player_scene.instantiate()
	player.name = str(id)
	call_deferred("add_child", player)
	
	# add the game scene to the server
	var scene = preload("res://Scenes/world.tscn").instantiate()
	add_child(scene)

# delete the player from the client of set id
func exit_game(id):
	multiplayer.peer_disconnected.connect(del_player)
	del_player(id)

# send a signal to the server to delete the player
func del_player(id):
	rpc("_del_player", id)

# recieve the signal and remove all the instances of the player
@rpc("any_peer","call_local")
func _del_player(id):
	get_node(str(id)).queue_free()
