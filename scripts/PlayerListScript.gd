extends ScrollContainer

onready var root = get_tree().root.get_child(0)
var tween = Tween.new()

export var enabled = false

func _ready():
	add_child(tween)

func _process(delta):
	if not enabled:
		return
	rect_position.x = lerp(rect_position.x,-960 if get_global_mouse_position().x < -760 else -1825,10 * delta)
