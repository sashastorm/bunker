extends Node

# define export variables
@export var mesh : MeshInstance3D
@export var context : String
@export var override_icon : bool
@export var new_icon : CurveTexture

# definine highlighting shader
var highlight_material = preload("res://Materials/highlight_material.tres")
var highlight_shader = preload("res://Shaders/highlight.gdshader")
var parent

# signal for item pickup
signal Item_Pickup(item)

# find the parent of the interact node and connect the signals to it
func _ready() -> void:
	parent = get_parent()
	connect_parent()

# when the player is set in range and raycasting to the object, set the highlight shader
func in_range() -> void:
	mesh.material_overlay = highlight_material
	MessageBus.interaction_focused.emit(context, new_icon, override_icon)

# remove the highlight shader when the raycast is not touching the interactable item
func not_in_range() -> void:
	mesh.material_overlay = null
	MessageBus.interaction_unfocused.emit()

# when the interact occurs, remove the item from view
func on_interact() -> void:
	if mesh.name == "ItemMesh":
		self.parent.find_child("ItemHitbox").disabled = true
		self.parent.visible = false

# connect the parent of the interact item to each signal for interaction
func connect_parent() -> void:
	parent.add_user_signal("focused")
	parent.add_user_signal("unfocused")
	parent.add_user_signal("interacted")
	parent.connect("focused", Callable(self, "in_range"))
	parent.connect("unfocused", Callable(self, "not_in_range"))
	parent.connect("interacted", Callable(self, "on_interact"))

# setting the default mesh for the interactable object before highlighting
func set_default_mesh() -> void:
	if mesh:
		pass
	else:
		for i in parent.get_children():
			if i is MeshInstance3D:
				mesh = i
