extends Node2D

signal block_changed

var paused:bool = true

var tween: Tween = Tween.new()
onready var camera: Camera2D = $Camera
onready var load_circle = $LoadCircle
onready var server_listener = $ServerListener

var directory: Directory = Directory.new()

onready var game_list = $Scroll/VBox
var game_cache = {}

var hash_key = "olympia"

func on_host_button_click(game_node) -> void:
	if not weakref(game_node).get_ref():
		return
	
	var selected_host = ProjectSettings.get("selected_host")
	
	if selected_host == game_node.name:
		return
	
	var template = game_list.get_node('Template')
	
	var clone = template.get_stylebox("normal").duplicate()
	clone.bg_color = Color8(180,80,0,255)
	if selected_host != null:
		var current_selected_button:Button = game_list.get_node(selected_host)
		
		current_selected_button.add_stylebox_override("normal",template.get_stylebox("normal"))
		current_selected_button.add_stylebox_override("hover",template.get_stylebox("hover"))
		current_selected_button.add_stylebox_override("pressed",template.get_stylebox("pressed"))
	
	ProjectSettings.set("selected_host",game_node.name)
	
	var current_selected_button:Button = game_list.get_node(game_node.name)
	current_selected_button.add_stylebox_override("normal",clone)
	current_selected_button.add_stylebox_override("hover",clone)
	current_selected_button.add_stylebox_override("pressed",clone)

func _on_new_server(server_info):
	if server_info.name.substr(0,hash_key.length()).to_lower() != hash_key:
		return
	
	var key = server_info.key
	
	var game_node: Button = game_list.get_node("Template").duplicate()
	game_node.get_node("Text").text = server_info.name.substr(7,server_info.name.length() - hash_key.length())
	game_node.name = hash_key
	game_node.connect("pressed",self,'on_host_button_click',[game_node])
	game_node.ip = server_info.ip
	game_node.port = server_info.port
	game_node.show()
	game_list.add_child(game_node)
	
	game_cache[key] = game_node

func _on_remove_server(key):
	if game_cache.has(key):
		game_cache[key].queue_free()

func _ready() -> void:
	server_listener.connect('new_server',self,'_on_new_server')
	server_listener.connect('remove_server',self,'_on_remove_server')
	server_listener.start()
	OS.window_maximized = true
	add_child(tween)
	ProjectSettings.set("selected_game",null)
	
	load_circle.show()
	
	yield(get_tree().create_timer(.1),'timeout')
	
	tween.interpolate_property(
		load_circle,'scale',
		load_circle.scale,Vector2(0,0),
		.5,Tween.TRANS_EXPO,Tween.EASE_OUT
	)
	tween.start()

	yield(get_tree().create_timer(.6),"timeout")
	
	print('KUIZpain')
	paused = false

func _process(delta):
	pass
