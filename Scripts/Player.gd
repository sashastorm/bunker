extends CharacterBody3D

# setting variables for each aspect of player movement
@onready var head = $Head
@onready var standing_hitbox = $Standing_Hitbox
@onready var crouching_hitbox = $Crouching_Hitbox
@onready var crouch_ray_cast = $Crouch_RayCast
@onready var eyes = $Head/Eyes
@onready var camera_3d = $Head/Eyes/PlayerCamera
@onready var feet = $Head/Feet

# setting interact raycast settings
@export var interact_distance : float = 2
var interact_cast_result

# Player states
enum State {WALKING, SPRINTING, CROUCHING}
var state = null

# Speeds of player
var current_speed = 4.0
const walking_speed = 4.0
const sprinting_speed = 7.0
const crouching_speed = 2.0

# Jump velocity / gravity
const jump_velocity = 4.5
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Camera settings
const mouse_sensitivity = 0.1

# Head bobbing
const head_bobbing_sprinting_speed = 22.0
const head_bobbing_walking_speed = 14.0
const head_bobbing_crouching_speed = 10.0

const head_bobbing_crouching_intensity = 0.05
const head_bobbing_sprinting_intensity = 0.15
const head_bobbing_walking_intensity = 0.1

var head_bobbing_vector = Vector2.ZERO
var head_bobbing_index = 0.0
var head_bobbing_current_intensity = 0.0

# interpolation constant
var lerp_speed = 12.0

# final directional constants
var direction = Vector3.ZERO
var crouching_depth = -0.5

# when the new player instance enters, set their multiplayer authority
func _enter_tree():
	set_multiplayer_authority(name.to_int())

# when the player instance is ready, set the camera authority and place control to the client
func _ready():
	camera_3d.current = is_multiplayer_authority()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# if the player has no authority, cancel input event
	if not is_multiplayer_authority(): return
	
	# if the event is a mouse movement, change head rotation and clamp it to realistic axis
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	
	# if "E" is pressed, send an interaction signal using the function
	if event.is_action_pressed("Interact"):
		interact()
	
	# if the player presses a button, remove their respective player scene from the server
	if event.is_action_pressed("Quit"):
		$".".exit_game(name.to_int())
		get_tree().quit()

func _physics_process(delta): # Movement state handler
	if not is_multiplayer_authority(): return
	
	# get the input direction
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Back")
	
	# on delta, constantly check for player view raycast
	interact_cast()
	
	# handing movement/deceleration
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*lerp_speed)
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	if Input.is_action_pressed("Crouch"): # if the crouch button is pressed
		# set crouching state, and change hitbox
		state = State.CROUCHING
		standing_hitbox.disabled = true
		crouching_hitbox.disabled = false
		
		# change speed and head position using linear interpolation
		current_speed = lerp(current_speed, crouching_speed, delta*lerp_speed)
		head.position.y = lerp(head.position.y, 1.8 + crouching_depth, delta*lerp_speed)
		
	elif !crouch_ray_cast.is_colliding(): # Check to uncrouch player
		# set walking state, change hitbox
		state = State.WALKING
		standing_hitbox.disabled = false
		crouching_hitbox.disabled = true
		
		# change head position using linear interplation
		head.position.y = lerp(head.position.y, 1.8, delta*lerp_speed)
		
		# Speed up player when sprint is held
		if Input.is_action_pressed("Sprint"):
			state = State.SPRINTING
			current_speed = lerp(current_speed, sprinting_speed, delta*lerp_speed)
		else:
			state = State.WALKING
			current_speed = lerp(current_speed, walking_speed, delta*lerp_speed)
	
	# Headbob handler based on state
	match state:
		State.SPRINTING:
			head_bobbing_current_intensity = head_bobbing_sprinting_intensity
			head_bobbing_index += head_bobbing_sprinting_speed*delta
		State.WALKING:
			head_bobbing_current_intensity = head_bobbing_walking_intensity
			head_bobbing_index += head_bobbing_walking_speed*delta
		State.CROUCHING:
			head_bobbing_current_intensity = head_bobbing_crouching_intensity
			head_bobbing_index += head_bobbing_crouching_speed*delta
	
	# check if the player is on the floor, and if so, bob the head based on movement
	if is_on_floor() && input_dir != Vector2.ZERO:
		# create sine function for the head bobbing index
		head_bobbing_vector.y = sin(head_bobbing_index)
		head_bobbing_vector.x = sin(head_bobbing_index/4)+0.5
		
		# if head bob is about to hit the floor, play stepping sound effect
		if head_bobbing_vector.y < -0.97:
			foot_step()
		
		# interpolate camera position based on sine function
		eyes.position.y = lerp(eyes.position.y, head_bobbing_vector.y*(head_bobbing_current_intensity/2), delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x, head_bobbing_vector.x*head_bobbing_current_intensity, delta*lerp_speed)
	else:
		# if the player isn't moving, give them a small bob to indicate idle animation
		head_bobbing_vector.y = sin(head_bobbing_index/5)
		eyes.position.y = lerp(eyes.position.y, head_bobbing_vector.y*(head_bobbing_current_intensity/2), delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x, 0.0, delta*lerp_speed)

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		
		# move eyes to imitate preparing to jump
		eyes.position.y = lerp(eyes.position.y, 0.0, delta*lerp_speed)
		eyes.position.y = lerp(eyes.position.y, 1.0, delta*lerp_speed/5)
		eyes.position.y = lerp(eyes.position.y, 0.0, delta*lerp_speed)

	move_and_slide()

# play footstep at random pitch, connected to AudioStreamPlayer
func foot_step():
	feet.pitch_scale = randf_range(0.8, 1.2)
	feet.play()

func interact_cast() -> void:
	# find the center of the player's camera's origin
	var space_state = camera_3d.get_world_3d().get_direct_space_state()
	var screen_center = get_viewport().size / 5.5
	var origin = camera_3d.project_ray_origin(screen_center)
	
	# set raycast parameters (raycast length, collision), and create interact raycast
	var end = origin + camera_3d.project_ray_normal(screen_center) * interact_distance
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_bodies = true
	
	# define the result of the raycast
	var result = space_state.intersect_ray(query)
	var current_cast_result = result.get("collider")
	
	# set the emitted raycast result is equal to an object that has an interaction component
	if current_cast_result != interact_cast_result:
		if interact_cast_result and interact_cast_result.has_user_signal("unfocused"): # emit unfocused
			interact_cast_result.emit_signal("unfocused")
		
		interact_cast_result = current_cast_result # set cast result
		
		if interact_cast_result and interact_cast_result.has_user_signal("focused"): # emit focused
			interact_cast_result.emit_signal("focused")

# set the interact function, to send a signal that the object was interacted with
func interact() -> void:
	if interact_cast_result and interact_cast_result.has_user_signal("interacted"):
		interact_cast_result.emit_signal("interacted")
