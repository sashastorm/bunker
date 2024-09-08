extends CharacterBody3D

# set variables for the players, target and navigation map
var player = null
const speed = 4.0
@export var player_path : NodePath
@onready var nav_agent = $NavigationAgent3D

# find the node for the closest path to the player
func _ready():
	player = get_node(player_path)

# every set change in time, move the enemy toward the player's position 
func _process(delta):
	return
	velocity = Vector3.ZERO
	
	# set the best path using the navigation mesh
	nav_agent.set_target_position(player.global_transform.origin)
	var next_nav_point = nav_agent.get_next_path_position()
	
	# set the velocity based on normalised distance from navigation point
	velocity = (next_nav_point - global_transform.origin).normalized() * speed
	
	# look at the player
	look_at(Vector3(player.global_position.x, player.global_position.y, player.global_position.z), Vector3.UP)
	
	move_and_slide()
