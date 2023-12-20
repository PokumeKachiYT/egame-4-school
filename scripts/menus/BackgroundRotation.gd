extends Sprite

export var multiplier: float = 0.2

func _process(delta):
	rotation_degrees += delta * multiplier
