extends Button

var tween = Tween.new()

onready var root = get_parent().get_parent()
onready var load_circle = root.get_node('LoadCircle')

func translate() -> void:
	get_node('Label').text = 'CREATE' if ProjectSettings.get('lang') == 'eng' else 'TẠO'

func on_click() -> void:
	if root.paused:
		return
	root.paused = true
	
	tween.interpolate_property(
		load_circle,'scale',
		load_circle.scale,Vector2(3,3),
		.5,Tween.TRANS_EXPO,Tween.EASE_IN
	)
	tween.start()
	
	yield(get_tree().create_timer(.6),'timeout')
	
	get_tree().change_scene("res://scenes/menus/CreateMenu.tscn")

func _ready():
	add_child(tween)
	
	connect('pressed',self,'on_click')
	root.connect('lang_changed',self,'translate')
