extends Control

# finding the confirm and deny labels
@onready var confirm = $Background/Confirm
@onready var deny = $Background/Deny

func _input(event):
	# when the player confirms to enter the game, add a small delay and move scenes
	if event.is_action_pressed("Confirm"):
		# precaution to remove other menu text line
		deny.hide()
		confirm.show()
		
		await get_tree().create_timer(3.0).timeout # 3 second timer
		get_tree().change_scene_to_file("res://Scenes/GameScene.tscn") # change scene
	
	# when the player confirms to enter the game, add a small delay and quit the game
	if event.is_action_pressed("Deny"):
		# precaution to remove other menu text line
		confirm.hide()
		deny.show()
		
		await get_tree().create_timer(3.0).timeout # 3 second timer
		get_tree().quit() # quit
