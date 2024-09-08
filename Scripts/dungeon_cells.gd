@tool # Allows script to work in editor
extends Node3D

# Functions set to remove other pieces of generation from map
func remove_floor():
	$yellow_floor.free()
func remove_ceiling():
	$yellow_ceiling.free()
func remove_wall_down():
	$yellow_wall_north.free()
func remove_wall_right():
	$yellow_wall_west.free()
func remove_wall_left():
	$yellow_wall_east.free()
func remove_wall_up():
	$yellow_wall_south.free()
