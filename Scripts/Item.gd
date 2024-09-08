extends StaticBody3D
class_name Item

# exports for the item stats (redundant)
@export_enum("Weapon", "Consumable", "Loot")
var type = "Loot"

@export var icon: Texture2D

@export_multiline var description : String

func _ready():
	pass 

# functions for item use dependant on item stats (redundant)
func use():
	pass
