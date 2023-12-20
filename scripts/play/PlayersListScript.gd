extends ScrollContainer

var tween = Tween.new()

func on_hover(hovering: bool):
	tween.remove(self,'rect_position:x')
	tween.interpolate_property(
		self,'rect_position:x',
		self.rect_position.x,-960 if hovering else -1825,
		.25,Tween.TRANS_QUAD,Tween.EASE_IN_OUT
	)
	tween.start()

func _ready():
	add_child(tween)
	get_parent().get_node('PlayerListToggle').connect('mouse_entered',self,'on_hover',[true])
	get_parent().get_node('PlayerListToggle').connect('mouse_exited',self,'on_hover',[false])
