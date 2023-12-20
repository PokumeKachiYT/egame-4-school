extends Node2D

export var paused = true

export onready var GameMap: Resource = DataLoader.new()
onready var path = "user://contests/" + ProjectSettings.get("selected_game") + ".res"

onready var camera: Camera2D = get_node('Camera')
var tween: Tween = Tween.new()
onready var main_background: Sprite = get_node('MainBackground')
onready var load_circle: Sprite = $LoadCircle

onready var UI: Control = get_node("UI")
onready var menu_button: Button = UI.get_node("Back")

onready var add_gui: Panel = get_node("Add")
onready var add_button_rotation: Node2D = add_gui.get_node("RotationHelper")
onready var add_button: Button = add_button_rotation.get_node("Button")

onready var save_button: Button = UI.get_node("Save")
onready var edit_panel: Panel = get_node("EditPanel")
onready var pointer: Label = get_node('Pointer')

onready var blocks: Node2D = get_node("Blocks")
onready var templates: Node = get_node("Templates")
onready var start_block: Polygon2D = blocks.get_node('Start')
onready var end_block: Polygon2D = blocks.get_node("End")

onready var hovering_sprite: Sprite = null
onready var hovering_block: Polygon2D = null

func map(v,a,b,x,y):
	return float(v - a) / (float(b) - float(a)) * (float(y) - float(x)) + float(x)

func save():
	GameMap.save_data(path)
	
	save_button.disabled = true

func load_game() -> void:
	if GameMap.save_exists(path):
		GameMap = GameMap.load_data(path)

func enable_save(_man) -> void:
	save_button.disabled = false

func select_block(selecting: bool) -> void:
	if selecting:
		tween.remove(edit_panel,'rect_size:x')
		tween.remove(edit_panel,'rect_position:x')
		
		tween.interpolate_property(
			edit_panel,'rect_size:x',
			0,1750,
			.5,Tween.TRANS_EXPO,Tween.EASE_OUT
		)
		tween.interpolate_property(
			edit_panel,'rect_position:x',
			960,(1920 - 1750) / 2,
			.5,Tween.TRANS_EXPO,Tween.EASE_OUT
		)
		tween.start()
	else:
		tween.remove(edit_panel,'rect_size:x')
		tween.remove(edit_panel,'rect_position:x')
		
		tween.interpolate_property(
			edit_panel,'rect_size:x',
			edit_panel.rect_size.x,0,
			.5,Tween.TRANS_EXPO,Tween.EASE_OUT
		)
		tween.interpolate_property(
			edit_panel,'rect_position:x',
			edit_panel.rect_position.x,960,
			.5,Tween.TRANS_EXPO,Tween.EASE_OUT
		)
		tween.start()

func delete():
	GameMap.blocks.remove(hovering_block.get_index() - 2)
	hovering_block.call_deferred('free')
	hovering_block = null
	enable_save("deleted")

func on_mouse_click(mouse_position: Vector2) -> void:
	var target: Polygon2D
	
	for block_node in blocks.get_children():
		if !block_node.visible or block_node.name == "End" or !weakref(block_node).get_ref():
			continue
		if Geometry.is_point_in_polygon(mouse_position - block_node.global_position,block_node.get_polygon()):
			target = block_node
	
	if target != null and weakref(target).get_ref():
		if target != start_block:
			select_block(true)
			edit_panel.call_deferred('set_block',target)
		else:
			select_block(false)
			edit_panel.call_deferred('set_block',null)

func on_menu_button_click() -> void:
	if paused:
		return
	paused = true
	
	tween.remove(load_circle,'scale')
	tween.interpolate_property(
		load_circle,"scale",
		load_circle.scale,Vector2(3,3),
		.5,Tween.TRANS_EXPO,Tween.EASE_IN
	)
	tween.start()
	save()
	yield(get_tree().create_timer(.6),'timeout')
	get_tree().change_scene("res://scenes/menus/CreateMenu.tscn")

func menu_button_init() -> void:
	menu_button.connect('pressed',self,'on_menu_button_click')

func on_new_block_button_click(type:String) -> void:
	if not add_gui.toggled:
		return
	var new_block = block.new()
	new_block.type = type
	
	match type:
		"intro":
			pass
		"question":
			pass
	GameMap.blocks.append(new_block)
	enable_save('')

onready var new_block_buttons = add_gui.get_node("Background/Options")

func new_block_button_init() -> void:
	new_block_buttons.get_node("Intro").connect('pressed',self,"on_new_block_button_click",["intro"])
	new_block_buttons.get_node("Question").connect('pressed',self,"on_new_block_button_click",["question"])

func update_layout(delta:float) -> void:
	end_block.transform.origin.x = lerp(
		end_block.transform.origin.x,
		210 + GameMap.blocks.size() * 210,
		min(delta * 20,1)
	)
	var index = 2
	for block_info in GameMap.blocks:
		var block_node: Polygon2D
		if index >= blocks.get_child_count():
			block_node = templates.get_node(block_info.type).duplicate()
			block_node.transform.origin = Vector2(210 * index - 210,0)
			block_node.show()
			blocks.add_child(block_node)
		block_node = blocks.get_child(index)
		block_node.transform.origin.x = lerp(
			block_node.transform.origin.x,
			210 * index - 210,
			min(delta * 20,1)
		)
		index += 1

const scroll_offset = 50.0

func update_background(delta) -> void:
	main_background.global_position.x = lerp(
		main_background.global_position.x,
		blocks.transform.origin.x / scroll_offset,
		5.0 * delta
	)

var elapsed_time: float = 0.0

func camera_wobble(delta) -> void:
	camera.global_position = Vector2(960,540) + Vector2(
		sin(elapsed_time * .5) * 2.0,
		sin(elapsed_time * .5)
	)
	camera.rotation_degrees = sin(elapsed_time * .5) * .2

func block_handler(delta:float) -> void:
	if Input.is_action_pressed("rmb"):
		return
	var mouse_position:Vector2 = get_global_mouse_position()
	
	for block_node in blocks.get_children():
		if !block_node.visible or block_node.name == "End" or !weakref(block_node).get_ref():
			continue
		if Geometry.is_point_in_polygon(mouse_position - block_node.global_position,block_node.get_polygon()):
			if block_node != hovering_block:
				if hovering_sprite != null and weakref(hovering_sprite).get_ref():
					tween.remove(hovering_sprite,'modulate:a')
					tween.interpolate_property(
						hovering_sprite,'modulate:a',
						hovering_sprite.modulate.a,1,
						.1,Tween.TRANS_EXPO,Tween.EASE_OUT
					)
					tween.start()
				var sprite:Sprite = block_node.get_node("Sprite")
				hovering_sprite = sprite
				hovering_block = block_node
				
				tween.remove(sprite,'modulate:a')
				tween.interpolate_property(
					sprite,'modulate:a',
					sprite.modulate.a,.85,
					.1,Tween.TRANS_EXPO,Tween.EASE_OUT
				)
				tween.start()
			
			return
	
	if hovering_sprite != null and weakref(hovering_sprite).get_ref():
		tween.remove(hovering_sprite,'modulate:a')
		tween.interpolate_property(
			hovering_sprite,'modulate:a',
			hovering_sprite.modulate.a,1,
			.1,Tween.TRANS_QUINT,Tween.EASE_IN_OUT
		)
		tween.start()
		
		hovering_sprite = null
		hovering_block = null

func _ready() -> void:
	add_child(tween)
	
	pointer.add_color_override('font_color',Color(5,0,0))
	
	menu_button_init()
	new_block_button_init()
	
	load_game()
	save()
	update_layout(1.0/15.0)
	
	load_circle.show()
	
	yield(get_tree().create_timer(.1),'timeout')
	
	tween.interpolate_property(
		load_circle,'scale',
		load_circle.scale,Vector2(0,0),
		.5,Tween.TRANS_EXPO,Tween.EASE_OUT
	)
	tween.start()
	
	for node in Main.get_all_children(self):
		if node.get('text') and node.text.length():
			node.text = Main.translate(node.text)
	
	yield(get_tree().create_timer(.6),'timeout')
	
	paused = false
	
	save_button.connect("pressed",self,'save')

func _process(delta) -> void:
	elapsed_time += delta
	update_background(delta)
	camera_wobble(delta)
	if paused:
		return
	UI.rect_position.x = camera.global_position.x
	if Input.is_action_just_pressed("lmb"):
		on_mouse_click(get_global_mouse_position())
	block_handler(delta)
	update_layout(delta)
	
	if Input.is_action_just_pressed('save'):
		save()

func _unhandled_input(event: InputEvent) -> void:
	if paused:
		return
	if edit_panel.get_rect().has_point(get_global_mouse_position()):
		return
	if (event is InputEventMouseMotion and Input.is_action_pressed("rmb")) or (event is InputEventScreenDrag):
		blocks.global_position.x += event.relative.x
	
	if event is InputEventMouseButton and event.is_pressed():
		if edit_panel.get_rect().has_point(get_global_mouse_position()):
			return
		if event.button_index == BUTTON_WHEEL_DOWN:
			blocks.global_position.x += -50
		if event.button_index == BUTTON_WHEEL_UP:
			blocks.global_position.x += 50
	if event is InputEventScreenTouch and event.pressed:
		on_mouse_click(event.position)
