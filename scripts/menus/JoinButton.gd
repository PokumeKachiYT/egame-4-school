extends Button

onready var tween = Tween.new()
onready var root = get_tree().root.get_child(0)
onready var camera = root.get_node("Camera")

onready var name_text = get_parent().get_node("Name")

func on_click() -> void:
	if root.paused or name_text.text == '':
		return
	
	var selected_host = ProjectSettings.get("selected_host")
	
	if not selected_host:
		return
	
	var selected_node = get_parent().get_node("Scroll/VBox").get_node(selected_host)
	
	ProjectSettings.set("ip",selected_node.ip)
	ProjectSettings.set("port",selected_node.port)
	ProjectSettings.set("name",name_text.text)
	root.paused = true
	tween.remove(camera,'global_position')
	tween.remove(camera,'rotation_degrees')
	tween.interpolate_property(
		camera,"global_position",
		camera.global_position,Vector2(0,-2080),
		.5,Tween.TRANS_SINE,Tween.EASE_IN
	)
	var stylebox:StyleBoxFlat = root.get_node("Create").get_node("Background").get_stylebox('normal')
	tween.interpolate_property(
		stylebox,"border_color",
		stylebox.border_color,Color8(0,75,55,stylebox.border_color.a * 255),
		.5,Tween.TRANS_SINE,Tween.EASE_IN
	)
	tween.start()
	
	yield(get_tree().create_timer(.5),'timeout')
	get_tree().change_scene("res://scenes/play/MainScene.tscn")

func on_hover(is_hovering) -> void:
	tween.remove(self,"rect_position:y")
	tween.interpolate_property(
		self,"rect_position:y",
		rect_position.y,-460 if is_hovering else -455,
		.05,Tween.TRANS_SINE,Tween.EASE_IN_OUT
	)
	tween.start()

func _ready():
	add_child(tween)
	
	connect('mouse_entered',self,"on_hover",[true])
	connect('mouse_exited',self,"on_hover",[false])
	connect('button_up',self,"on_click")
