extends Node2D

signal block_changed

var paused:bool = true

var tween: Tween = Tween.new()
onready var camera: Camera2D = get_node('Camera')
onready var load_circle: Sprite = $LoadCircle

onready var create_game_frame = get_node('MainUI')
onready var game_name_input: TextEdit = create_game_frame.get_node('NewGame/Input')

onready var action_buttons: HBoxContainer = create_game_frame.get_node("ActionButtons")

var directory: Directory = Directory.new()

func on_game_button_click(event: InputEvent,game_name) -> void:
	if paused:
		return
	if event is InputEventMouseButton:
		if not event.is_pressed() or event.button_index != BUTTON_LEFT:
			return
	elif event is InputEventScreenTouch:
		if not event.is_pressed():
			return
	else:
		return
	
	var selected_game = ProjectSettings.get("selected_game")
	var template: Label = create_game_frame.get_node('Background/Scroll/VBox/Template')
	var background: Panel = template.get_node('Background')
	
	var clone: StyleBoxFlat = background.get_stylebox('panel').duplicate()
	var old_stylebox: StyleBoxFlat = background.get_stylebox('panel').duplicate()
	clone.bg_color = Color8(150,75,0,200)
	
	if selected_game == game_name:
		return
	if selected_game != null:
		var current_selected_button: Label = create_game_frame.get_node('Background/Scroll/VBox').get_node(selected_game)
		var background_2: Panel = current_selected_button.get_node('Background')
		tween.remove(background_2,'rect_size:x')
		background_2.rect_size.x = background.rect_size.x
		background_2.add_stylebox_override('panel',background.get_stylebox('panel'))
	
	ProjectSettings.set("selected_game",game_name)
	
	emit_signal('block_changed')
	
	var current_selected_button: Label = create_game_frame.get_node('Background/Scroll/VBox').get_node(game_name)
	background = current_selected_button.get_node('Background')
	
	var effect_background: Panel = background.duplicate()
	effect_background.add_stylebox_override('panel',old_stylebox)
	background.get_parent().add_child(effect_background)
	background.get_parent().move_child(effect_background,0)
	tween.interpolate_property(
		background,'rect_size:x',
		0,background.rect_size.x,
		.5,Tween.TRANS_EXPO,Tween.EASE_OUT
	)
	tween.start()
	background.add_stylebox_override('panel',clone)
	
	yield(get_tree().create_timer(25),'timeout')
	
	effect_background.queue_free()

func on_game_button_hover(game_name,is_hovering) -> void:
	var game_button: Label = create_game_frame.get_node('Background/Scroll/VBox').get_node(game_name)
	
	tween.remove(game_button,"rect_position:x")
	tween.interpolate_property(
		game_button,"rect_position:x",
		game_button.rect_position.x,5 if is_hovering else 0,
		.05,Tween.TRANS_SINE,Tween.EASE_OUT
	)
	tween.start()

const chars_per_line = 52

func add_game(file_name:String) -> void:
	var scrolling_frame = create_game_frame.get_node('Background/Scroll/VBox')
	var game_button = scrolling_frame.get_node('Template').duplicate()
	game_button.name = file_name
	game_button.text = file_name
	scrolling_frame.add_child(game_button)
	
	game_button.call_deferred("connect",'mouse_entered',self,'on_game_button_hover',[game_button.name,true])
	game_button.call_deferred("connect",'mouse_exited',self,'on_game_button_hover',[game_button.name,false])
	game_button.connect('gui_input',self,'on_game_button_click',[game_button.name,])
	game_button.show()
	call_deferred('set_background',game_button)

func set_background(game_button) -> void:
	game_button.get_node('Background').rect_size.y = game_button.rect_size.y

func create_game_frame_init() -> void:
	if not directory.dir_exists("user://contests"):
		directory.make_dir("user://contests")
	directory.open("user://contests")
	
	directory.list_dir_begin(true)
	var file_name = directory.get_next()
	
	while file_name != "":
		if not directory.current_is_dir():
			add_game(file_name.substr(0,file_name.length() - 4))
		file_name = directory.get_next()
	directory.list_dir_end()

func _ready() -> void:
	ProjectSettings.set("selected_game",null)
	add_child(tween)
	
	create_game_frame_init()
	
	load_circle.show()
	
	yield(get_tree().create_timer(.1),'timeout')
	
	tween.interpolate_property(
		load_circle,'scale',
		load_circle.scale,Vector2(0,0),
		.5,Tween.TRANS_EXPO,Tween.EASE_OUT
	)
	tween.start()
	
	paused = false

func _process(delta):
	if game_name_input.text.length() > 200:
		game_name_input.text = game_name_input.text.substr(0,200)
