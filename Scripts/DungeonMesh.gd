@tool
extends Node3D

# defining variables for the gridmap and start function
@export var grid_map_path : NodePath
@onready var grid_map : GridMap = get_node(grid_map_path)

@export var start : bool = false : set = set_start

# when the exported start function is pressed, if the editor is open, create the dungeon tiles
func set_start(val:bool)->void:
	if Engine.is_editor_hint():
		create_dungeon()

# define the scene containing the dungeon scene
var dun_cell_scene : PackedScene = preload("res://Scenes/dungeon_cells.tscn")

# defining directions in Vector3i
var directions : Dictionary = {
	"up" : Vector3i.FORWARD,"down" : Vector3i.BACK,
	"left" : Vector3i.LEFT,"right" : Vector3i.RIGHT
}

func _ready():
	create_dungeon()

# depending on which gridmap tiles connect on what side, remove walls and floors: 0 = room, 1 = hall, 2 = door.
# eg. _12 = hallway connecting to a door tile
func handle_none(cell:Node3D,dir:String):
	pass
func handle_00(cell:Node3D,dir:String):
	cell.call("remove_wall_"+dir)
func handle_01(cell:Node3D,dir:String):
	pass
func handle_02(cell:Node3D,dir:String):
	cell.call("remove_wall_"+dir)
func handle_10(cell:Node3D,dir:String):
	pass
func handle_11(cell:Node3D,dir:String):
	cell.call("remove_wall_"+dir)
func handle_12(cell:Node3D,dir:String):
	cell.call("remove_wall_"+dir)
func handle_20(cell:Node3D,dir:String):
	cell.call("remove_wall_"+dir)
func handle_21(cell:Node3D,dir:String):
	cell.call("remove_wall_"+dir)
func handle_22(cell:Node3D,dir:String):
	cell.call("remove_wall_"+dir)

# creating each dungeon cell on each tile in the gridmap
func create_dungeon():
	# for each tile, queue a cell
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var t : int = 0
	
	# for each ready cell, place the scene in the correct location
	for cell in grid_map.get_used_cells():
		var cell_index : int = grid_map.get_cell_item(cell)
		if cell_index <=2\
		&& cell_index >=0:
			# create cell and set the owner correctly to remove walls
			var dun_cell : Node3D = dun_cell_scene.instantiate()
			dun_cell.position = Vector3(cell) + Vector3(0.5,0,0.5)
			add_child(dun_cell)
			dun_cell.set_owner(owner)
			t +=1
			
			# check interaction at each direction and remove walls accordingly
			for i in 4:
				var cell_n : Vector3i = cell + directions.values()[i]
				var cell_n_index : int = grid_map.get_cell_item(cell_n)
				if cell_n_index ==-1\
				|| cell_n_index == 3:
					handle_none(dun_cell,directions.keys()[i])
				else:
					var key : String = str(cell_index) + str(cell_n_index)
					call("handle_"+key,dun_cell,directions.keys()[i])
		
		# wait for everything to be checked, then return when finished
		if t%10 == 9 : await get_tree().create_timer(0).timeout
