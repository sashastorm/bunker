extends Node

# door enumerators for setting states
enum DoorType {SLIDING, ROTATING}
enum ForwardDirection {X, Y, Z}
enum DoorStatus {OPEN, CLOSED}

# finding the main player
@onready var player = self.get_parent().get_parent().find_child("Player")

# exporting settings for the door
@export_group("Door Settings")
@export var door_type : DoorType # var for enum DoorType
@export var forward_direction : ForwardDirection # which linear direction does the door move forward in
@export var door_size : Vector3
@export var movement_direction : Vector3
@export var rotation : Vector3 = Vector3(0, 1, 0) # which axis the door rotates on
@export var rotation_amount : float = 90.0 # how much the door opens

@export_group("Close Settings")
@export var close_automatically : bool = false
@export var close_time : float = 2.0

@export_group("Tween Settings")
@export var speed : float = 0.5 # how fast the door speed can change via the tween function
@export var transition : Tween.TransitionType # what kind of tweens transition is used
@export var easing : Tween.EaseType # what kind of tween ease style is used

# defining variables and enumerators
var parent
var orig_pos : Vector3
var orig_rot : Vector3
var rotation_adjustment : float
var door_direction : Vector3
var door_status : DoorStatus = DoorStatus.CLOSED

# when ready, find the parent and log its original position and connect it to the connect_parent() function
func _ready() -> void:
	parent = get_parent()
	orig_pos = parent.position
	parent.ready.connect(connect_parent)

# connect the check_door() function to the singal to interact with the door
func connect_parent() -> void:
	parent.connect("interacted", Callable(self, "check_door"))

func open_door() -> void:
	# changing states and assigning tween
	door_status = DoorStatus.OPEN 
	var tween = get_tree().create_tween()
	
	# changing animation based on door type
	match door_type:
		DoorType.SLIDING:
			tween.tween_property(parent, "position", orig_pos + (movement_direction * door_size), speed).set_trans(transition).set_ease(easing)
		DoorType.ROTATING:
			tween.tween_property(parent, "rotation", orig_rot + (rotation * deg_to_rad(rotation_amount)), speed).set_trans(transition).set_ease(easing)
	
	# checking for close_automatically
	if close_automatically:
		tween.tween_interval(close_time)
		tween.tween_callback(close_door)

func close_door() -> void:
	# changing states and assigning tween
	door_status = DoorStatus.CLOSED
	var tween = get_tree().create_tween()
	
	# changing animation based on door type
	match door_type:
		DoorType.SLIDING:
			tween.tween_property(parent, "position", orig_pos, speed).set_trans(transition).set_ease(easing)
		DoorType.ROTATING:
			tween.tween_property(parent, "rotation", orig_rot, speed).set_trans(transition).set_ease(easing)

func check_door() -> void:
	# checking for the opening direction of the door
	match forward_direction:
		ForwardDirection.X:
			door_direction = parent.global_transform.basis.x
		ForwardDirection.Y:
			door_direction = parent.global_transform.basis.y
		ForwardDirection.Z:
			door_direction = parent.global_transform.basis.z
	
	# checking for the player's relative position (redundant)
	#var door_position : Vector3 = parent.global_position
	#var player_position : Vector3 = player.global_position
	#var direction_to_player : Vector3 = door_position.direction_to(player_position)
	#var door_dot : float = direction_to_player.dot(door_direction)
	#if door_dot < 0:
		#rotation_adjustment = 1
	#else:
	
	# setting the rotation constant (in this case, to nothing)
	rotation_adjustment = 1
	
	# checking whether the door is open or closed, and acting accordingly
	match door_status:
		DoorStatus.CLOSED:
			open_door()
		DoorStatus.OPEN:
			close_door()
