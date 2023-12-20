extends Button

var tween = Tween.new()
onready var root = get_parent().get_parent()

onready var player_list = root.get_node('Players')
onready var start_screen: Node2D = root.get_node("StartScreen")
onready var control_screen: Node2D = root.get_node("ControlScreen")

func on_hover(is_hovering: bool) -> void:
	tween.remove(self,'rect_position:y')
	tween.interpolate_property(
		self,'rect_position:y',
		self.rect_position.y,295 if is_hovering else 310,
		.25,Tween.TRANS_EXPO,Tween.EASE_OUT
	)
	tween.start()

func on_click() -> void:
	if root.clients.size() == 0 or root.paused:
		return
	
	for client in root.clients:
		if typeof(client.name) == TYPE_NIL:
			return
	
	root.paused = true
	
	var index = 0
	
	var names = {
		'info_type' : 'start',
		'names' : []
	}
	
	for client in root.clients:
		names.names.append(client.name)
	
	for client in root.clients:
		var info = names.duplicate(true)
		info.names.remove(index)
		root.send_data(client,info)
		index += 1
	
	root.get_node("ServerAdvertiser").queue_free()
	root.get_node("ControlScreen").show()
	
	tween.interpolate_property(
		start_screen,'global_position:y',
		start_screen.global_position.y,1080,
		1,Tween.TRANS_EXPO,Tween.EASE_IN_OUT
	)
	tween.interpolate_property(
		control_screen,'global_position:x',
		control_screen.global_position.x,0,
		1,Tween.TRANS_EXPO,Tween.EASE_IN_OUT
	)
	tween.interpolate_property(
		player_list,'rect_position',
		player_list.rect_position,Vector2(-1825,-540),
		1,Tween.TRANS_EXPO,Tween.EASE_IN_OUT
	)
	tween.interpolate_property(
		player_list,'rect_size',
		player_list.rect_size,Vector2(1025,1080),
		1,Tween.TRANS_EXPO,Tween.EASE_IN_OUT
	)
	
	for player in player_list.get_node('VBox').get_children():
		if player.visible:
			tween.interpolate_property(
				player,'rect_min_size:x',
				player.rect_min_size.x,850,#375,
				1,Tween.TRANS_EXPO,Tween.EASE_IN_OUT
			)
	tween.start()
	
	yield(get_tree().create_timer(1),"timeout")
	
	queue_free()
	root.get_node("StartScreen").queue_free()
	
	root.state = 'proceedable'
	root.paused = false
	player_list.enabled = true

func _ready() -> void:
	add_child(tween)
	connect("mouse_entered",self,'on_hover',[true])
	connect("mouse_exited",self,'on_hover',[false])
	connect("button_up",self,'on_click')
