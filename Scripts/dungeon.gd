@tool # runs code in the editor
extends Node3D # attatches script to node

@onready var grid_map : GridMap = $GridMap # when editor starts, assign gridmap to the script

@export var start : bool = false : set = set_start # displays changable state in editor
func set_start(val:bool)->void: # calls a function that defaults to null but can be changed based on state of editor/runtime
	if Engine.is_editor_hint():
		generate()
		
@export_range(0,1) var survival_chance : float = 0.25
@export var border_size : int = 20 : set = set_border_size # allows us to manually change the border size based on an integer value of cell
func set_border_size(val : int)->void: # calls a function that sets the border size manually as the int value is changed in the editor, initially null
	border_size = val
	if Engine.is_editor_hint(): #  makes sure the code runs IN EDITOR and not in game, as generation should not be toggleable to players, only to debug
		visualise_border()

@export var room_number : int = 4 # number of rooms
@export var room_margain : int = 1 # distance apart from rooms
@export var room_recursion : int = 15 # maximum amount of failed generation attempts before returning
@export var min_room_size : int = 2 # min room size
@export var max_room_size : int = 4 # max room size
@export_multiline var custom_seed : String = "" : set = set_seed

# generate when ready
func _ready():
	generate()

# setting a custom seed based on text and hashing it to the properties of the generator
func set_seed(val:String)->void:
	custom_seed = val
	seed(val.hash())

var room_tiles : Array[PackedVector3Array]  = [] # logs below array in array
var room_positions : PackedVector3Array = [] # logs each cell stats in array

func visualise_border(): # allows us to see the size of our map generation
	grid_map.clear()
	for i in range(-1, border_size+1): #builds each axis of the borders, as item index 3 of the mesh library
		grid_map.set_cell_item(Vector3i(i,0,-1), 3) # indexes the value of the coordinates of each cell generated
		grid_map.set_cell_item(Vector3i(i,0,border_size), 3)
		grid_map.set_cell_item(Vector3i(border_size,0,i), 3)
		grid_map.set_cell_item(Vector3i(-1,0,i), 3)

func generate(): # generates the scene
	room_tiles.clear()
	room_positions.clear()
	if custom_seed : set_seed(custom_seed)
	visualise_border()
	for i in room_number:
		make_room(room_recursion)
	
	var rpv2 : PackedVector2Array = [] # vector2 array for hallway triangulation
	var del_graph : AStar2D = AStar2D.new() # graphs for triangulation
	var mst_graph : AStar2D = AStar2D.new() # graphs for triangulation
	
	for p in room_positions:
		rpv2.append(Vector2(p.x,p.z)) # appending room values to vector2 array
		del_graph.add_point(del_graph.get_available_point_id(),Vector2(p.x,p.z)) # adds points to the triangulation graphs
		mst_graph.add_point(mst_graph.get_available_point_id(),Vector2(p.x,p.z)) # adds points to the triangulation graphs
	
	var delaunay : Array = Array(Geometry2D.triangulate_delaunay(rpv2)) # passing array of vector2s, gives index of each triangulation in one array
	
	for i in delaunay.size()/3: # generates the graph connecting all of the rooms together
		var p1 : int = delaunay.pop_front()
		var p2 : int = delaunay.pop_front()
		var p3 : int = delaunay.pop_front()
		
		# connects said points
		del_graph.connect_points(p1,p2) 
		del_graph.connect_points(p2,p3)
		del_graph.connect_points(p1,p3)
	
	var visited_points : PackedInt32Array = [] # finding all visited points to connect
	visited_points.append(randi() % room_positions.size())
	
	# white the amount of found points is less than the maximum, check for points to connect together
	while visited_points.size() != mst_graph.get_point_count():
		var possible_connections : Array[PackedInt32Array] = []
		for vp in visited_points:
			for c in  del_graph.get_point_connections(vp):
				if !visited_points.has(c):
					var con : PackedInt32Array = [vp,c]
					possible_connections.append(con)
		
		# connect said points together at the most efficient distance
		var connection : PackedInt32Array =  possible_connections.pick_random()
		for pc in possible_connections:
			if rpv2[pc[0]].distance_squared_to(rpv2[pc[1]]) <\
			rpv2[connection[0]].distance_squared_to(rpv2[connection[1]]):
				connection = pc
		
		# connect the points in the hallway graph and disconnect the points in the doors graph
		visited_points.append(connection[1])
		mst_graph.connect_points(connection[0],connection[1])
		del_graph.disconnect_points(connection[0],connection[1])
	
	# assigning the hallway graph
	var hallway_graph : AStar2D = mst_graph
	
	# for each door function, check whether the hallway should be placed or not based on the survival chance
	for p in del_graph.get_point_ids():
		for c in  del_graph.get_point_connections(p):
			if c>p:
				var kill : float = randf()
				if survival_chance > kill:
					hallway_graph.connect_points(p,c)
					
	# create the hallways
	create_hallways(hallway_graph)

func create_hallways(hallway_graph:AStar2D): # connects triangulated doors with hallways
	var hallways : Array[PackedVector3Array] = []
	
	# for each point, create hallway tiles
	for p in hallway_graph.get_point_ids():
		for c in hallway_graph.get_point_connections(p):
			if c>p:
				# define the hallway tile and doorway locations
				var room_from : PackedVector3Array = room_tiles[p]
				var room_to : PackedVector3Array = room_tiles[c]
				var tile_from  : Vector3 = room_from[0]
				var tile_to : Vector3 = room_to[0]
				
				# for each tile between the rooms, built to a centre point
				for t  in room_from:
					if t.distance_squared_to(room_positions[c])<\
					tile_from.distance_squared_to(room_positions[c]):
						tile_from = t
				for t  in room_to:
					if t.distance_squared_to(room_positions[p])<\
					tile_from.distance_squared_to(room_positions[p]):
						tile_to = t
						
				# append the hallway to the grid map and attach the tiles when defined
				var hallway : PackedVector3Array = [tile_from,tile_to]
				hallways.append(hallway)
				grid_map.set_cell_item(tile_from,2)
				grid_map.set_cell_item(tile_to,2)
	
	# forcing the grid to place the cell items in a way that removes diagonal tile placing
	var astar : AStarGrid2D = AStarGrid2D.new()
	astar.size = Vector2i.ONE * border_size
	astar.update()
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	
	# finding points between diagonals
	for t in grid_map.get_used_cells_by_item(0):
		astar.set_point_solid(Vector2i(t.x,t.z))
	
	# placing a block between them, making sure there aren't visible blocks in the way
	for h in hallways:
		var pos_from : Vector2i = Vector2i(h[0].x,h[0].z)
		var pos_to : Vector2i = Vector2i(h[1].x,h[1].z)
		var hall : PackedVector2Array = astar.get_point_path(pos_from,pos_to)
		
		for t in hall:
			var pos : Vector3i = Vector3i(t.x,0,t.y)
			if grid_map.get_cell_item(pos) < 0:
				grid_map.set_cell_item(pos,1)

func make_room(rec:int): # makes rooms
	if !rec>0: # if recursion occurs too often, cancel operation in order to not crash game
		return 
	
	var width : int = (randi() % (max_room_size - min_room_size)) + min_room_size # defining width
	var height : int = (randi() % (max_room_size - min_room_size)) + min_room_size  # defining height
	
	var start_pos : Vector3i # define where to generate our rooms
	start_pos.x = randi() % (border_size - width + 1)  
	start_pos.z = randi() % (border_size - height + 1)
	
	for r in range(-room_margain,height+room_margain): # expanding our starting position 
		for c in range(-room_margain,height+room_margain):
			var pos : Vector3i = start_pos + Vector3i(c,0,r) # find start position of room generation
			if grid_map.get_cell_item(pos) == 0:
				make_room(rec-1)
				return
	
	var room : PackedVector3Array  = []
	
	for r in height: # for each row of cells
		for c in width: # for each column of cells
			var pos : Vector3i = start_pos + Vector3i(c,0,r) # find start position of room generation
			grid_map.set_cell_item(pos,0)
			room.append(pos) # log pos
	room_tiles.append(room) # log for each tile
	var avg_x : float = start_pos.x + (float(width)/2)
	var avg_z : float = start_pos.z + (float(height)/2)
	var pos : Vector3 = Vector3(avg_x,0,avg_z)
	room_positions.append(pos) # append room positions to the graph
