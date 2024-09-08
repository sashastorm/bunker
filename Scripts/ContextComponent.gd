extends CenterContainer

# defining export variables
@export var icon : TextureRect
@export var context : Label
@export var default_icon : CurveTexture

# at ready, connect functions to the message bus, and reset the ui
func _ready() -> void:
	MessageBus.interaction_focused.connect(update)
	MessageBus.interaction_unfocused.connect(reset)
	reset()

# resets the ui to blank
func reset() -> void:
	icon.texture = null
	context.text = ""

# when an interaction update occurs, change the texture and label to fit the given context
func update(text, image = default_icon, override = false) -> void:
	context.text = "E"
	if override:
		icon.texture = image
	else:
		icon.texture = default_icon
