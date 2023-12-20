extends Node2D

signal lang_changed

export var paused = true

var tween: Tween = Tween.new()

var directory: Directory = Directory.new()
var vietnamese_lang_path = 'user://vietnamese'

onready var load_circle: Sprite = $LoadCircle
onready var gamemodes = get_node('Gamemodes')
onready var play_button: Button = gamemodes.get_node('Play')
onready var create_button: Button = gamemodes.get_node('Create')
onready var language_button: Button = $Language

func lang_changed() -> void:
	if directory.file_exists(vietnamese_lang_path):
		language_button.get_node('Label').text = 'TIẾNG VIỆT'
		ProjectSettings.set('lang','vin')
	else:
		language_button.get_node('Label').text = 'ENGLISH'
		ProjectSettings.set('lang','eng')
	emit_signal('lang_changed')

func switch_lang() -> void:
	if paused:
		print('hehe')
		return
	
	var target_text = 'ENGLISH'
	if not directory.file_exists(vietnamese_lang_path):
		target_text = 'TIẾNG VIỆT'
		
		var file = File.new()
		file.open(vietnamese_lang_path,File.WRITE_READ)
		file.close()
	else:
		directory.remove(vietnamese_lang_path)
	tween.remove(language_button,'rect_size')
	tween.remove(language_button,'rect_position')
	tween.interpolate_property(
		language_button,'rect_size',
		language_button.rect_size + Vector2(10,10),language_button.rect_size,
		.5,Tween.TRANS_BACK,Tween.EASE_OUT
	)
	tween.interpolate_property(
		language_button,'rect_position',
		language_button.rect_position - Vector2(5,5),language_button.rect_position,
		.5,Tween.TRANS_BACK,Tween.EASE_OUT
	)
	tween.start()
	language_button.get_node('Label').text = target_text
	lang_changed()

func on_play_button_click() -> void:
	pass

func _ready():
	OS.window_fullscreen = true
	lang_changed()
	language_button.connect('pressed',self,'switch_lang')
	
	load_circle.show()
	add_child(tween)
	
	yield(get_tree().create_timer(.5),'timeout')
	
	tween.interpolate_property(
		load_circle,'scale',
		load_circle.scale,Vector2(0,0),
		.5,Tween.TRANS_EXPO,Tween.EASE_OUT
	)
	tween.start()
	
	yield(get_tree().create_timer(.6),'timeout')
	
	paused = false
