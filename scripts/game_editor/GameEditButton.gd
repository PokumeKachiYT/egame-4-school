extends Button

var tween = Tween.new()
onready var root = get_tree().root.get_child(0)
export var toggled: bool = false

onready var panel: Panel = root.get_node("EditPanel")
onready var pointer: Label = root.get_node("Pointer")

func on_click() -> void:
	if root.paused or root.delete_mode or root.get_node("Add").toggled:
		return
	
	root.paused = true
	
	tween.remove(panel,'rect_position:x')
	tween.interpolate_property(
		panel,'rect_position:x',
		panel.rect_position.x,1920 if toggled else 135,
		.5,Tween.TRANS_QUART,Tween.EASE_IN_OUT
	)
	
	tween.remove(pointer,'modulate')
	tween.interpolate_property(
		pointer,'modulate',
		pointer.modulate,Color(1,1,1,1) if toggled else Color(5,1,1,1),
		.5,Tween.TRANS_QUART,Tween.EASE_IN_OUT
	)
	tween.start()
	
	if not toggled:
		panel.show()
	
	toggled = not toggled
	
	root.edit_mode = toggled
	
	yield(get_tree().create_timer(.5),"timeout")
	
	root.paused = false
	
	if not toggled:
		panel.hide()

func on_hover(is_hovering) -> void:
	pass

func _ready() -> void:
	add_child(tween)
	connect('mouse_entered',self,'on_hover',[true])
	connect('mouse_exited',self,'on_hover',[false])
	connect('button_up',self,'on_click')
