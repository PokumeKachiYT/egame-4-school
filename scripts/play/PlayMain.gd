extends Node2D

export var paused: bool = true

onready var start_screen: Node2D = $StartScreen
onready var play_screen: Node2D = $PlayScreen
onready var game_over_screen: Node2D = $GameOverScreen
onready var foreground: ColorRect = $Foreground

onready var intro_screen: Control = play_screen.get_node('intro')
onready var question_screen: Control = play_screen.get_node('question')
onready var timer: Label = question_screen.get_node('Timer')

onready var player_list = $Players

onready var camera: Camera2D = $Camera
onready var load_circle: Sprite = $LoadCircle
var tween = Tween.new()

onready var my_score = player_list.get_node('VBox/Reserved')

var client: StreamPeerTCP = StreamPeerTCP.new()
var port = ProjectSettings.get("port")
var username = ProjectSettings.get("name")

export var packets: Array

export var state: String = 'connecting'

var directory = Directory.new()

var stream: String = ''

func get_data():
	var bytes = client.get_available_bytes()
	if bytes > 0:
		var info = client.get_var(true)
		
		if info:
			packets.append(info)
			print("KUIZ" + String(info))
func send_data(packet):
	while client.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		pass
	client.put_var(packet,true)

var cache = []

func end() -> void:
	question_info = null
	for screen in play_screen.get_children():
		var clone = screen.duplicate()
		add_child(clone)
		cache.append(clone)
		screen.hide()
		
		tween.interpolate_property(
			clone,'rect_position',
			clone.rect_position,Vector2(0,1080),
			.5,Tween.TRANS_CIRC,Tween.EASE_IN
		)
	
	question_screen.get_node('Answer').text = ''
	question_screen.get_node('Answer').show()
	question_screen.get_node('Submit').show()
	question_screen.get_node('AnswerLabel').hide()
	
	tween.start()
	
	yield(get_tree().create_timer(1),'timeout')
	
	for screen in cache:
		screen.queue_free()
	
	cache.clear()

func intro(intro_info):
	intro_screen.get_node('title').text = intro_info.title
	intro_screen.get_node('title/subtitle').text = intro_info.subtitle
	intro_screen.rect_scale = Vector2(25,20)
	tween.interpolate_property(
		intro_screen,'rect_scale',
		intro_screen.rect_scale,Vector2(1,1),
		.5,Tween.TRANS_CIRC,Tween.EASE_OUT
	)
	tween.start()
	intro_screen.show()
	
	yield(get_tree().create_timer(1),'timeout')
	
	send_data({'info_type':'check'})

var current_answer_index: int = -1
var current_answer_node: Label

func select_answer(event: InputEvent,answer_index: int,answer_node: Label) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.is_pressed():
			if current_answer_index != -1:
				var clone = question_screen.get_node('TemplatePair/FirstAnswer').get_stylebox('normal').duplicate()
				current_answer_node.add_stylebox_override('normal',clone)
			current_answer_index = answer_index
			current_answer_node = answer_node
			
			var clone = question_screen.get_node('TemplatePair/FirstAnswer').get_stylebox('normal').duplicate()
			clone.bg_color = Color8(50,70,0)
			current_answer_node.add_stylebox_override('normal',clone)

var question_info

func submit() -> void:
	var info = {
		'info_type' : 'answr',
		'answer' : -1,
	}
	if question_info.answers.size():
		if current_answer_index == -1:
			return
		info.answer = current_answer_index
		var clone = question_screen.get_node('TemplatePair/FirstAnswer').get_stylebox('normal').duplicate()
		current_answer_node.add_stylebox_override('normal',clone)
		current_answer_index = -1
		current_answer_node = null
	else:
		if question_screen.get_node('Answer').text.length() == 0:
			return
		info.answer = question_screen.get_node('Answer').text
	send_data(info)

func update_score(score_info) -> void:
	var player = score_info.player
	var new_score = int(score_info.score)
	
	var player_node = my_score
	
	if player != username:
		player_node = player_list.get_node('VBox').get_node(player)
	
	var current_score = int(player_node.get_node('Points').text)
	
	if current_score == new_score:
		return
	
	var effect = get_node('ScoreEffect').duplicate()
	
	if new_score > current_score:
		effect.get_node('Text').text = "+" + String(new_score - current_score)
		effect.get_node('Text').add_color_override('font_color',Color8(100,200,75))
		effect.get_node('Particle').process_material.color = Color8(100,255,75)
	else:
		effect.get_node('Text').text = "-" + String(current_score - new_score)
		effect.get_node('Text').add_color_override('font_color',Color8(200,50,75))
		effect.get_node('Particle').process_material.color = Color8(255,115,75)
	
	add_child(effect)
	effect.global_position.y = player_node.rect_global_position.y + 62.5
	effect.show()
	tween.interpolate_property(
		effect,'global_position:x',
		effect.global_position.x,effect.global_position.x + 400 + (randi() % 50),
		1,Tween.TRANS_QUAD,Tween.EASE_OUT
	)
	tween.interpolate_property(
		effect,'rotation_degrees',
		effect.rotation_degrees,rand_range(-45.0,45.0),
		1,Tween.TRANS_QUAD,Tween.EASE_IN_OUT
	)
	tween.interpolate_property(
		effect,'scale',
		Vector2.ZERO,effect.scale,
		.5,Tween.TRANS_QUAD,Tween.EASE_OUT
	)
	tween.start()
	
	effect.get_node('Particle').restart()
	
	yield(get_tree().create_timer(.2),'timeout')
	
	player_node.get_node('Points').text = String(new_score)
	
	yield(get_tree().create_timer(.3),'timeout')
	tween.interpolate_property(
		effect,'scale',
		effect.scale,Vector2.ZERO,
		.5,Tween.TRANS_QUINT,Tween.EASE_IN
	)
	tween.start()
	
	yield(get_tree().create_timer(.5),'timeout')
	
	effect.queue_free()

var counting: bool = false
var start_time: float

func question(packet) -> void:
	question_info = packet
	
	question_screen.get_node('Content/Text').visible = (question_info.content_type == 'text')
	question_screen.get_node('Content/Image').visible = (question_info.content_type == 'image')
	
	question_screen.get_node('Answer').visible = (question_info.answers.size() == 0)
	question_screen.get_node('MultipleChoice').visible = (question_info.answers.size() != 0)
	
	if question_info.content_type == 'text':
		question_screen.get_node('Content/Text').text = question_info.content
	if question_info.content_type == 'image':
		var image = Image.new()
		image.create_from_data(question_info.image_info.width,question_info.image_info.height,question_info.image_info.mipmaps,question_info.image_info.format,question_info.content)
		
		var texture = ImageTexture.new()
		texture.create_from_image(image)
		question_screen.get_node('Content/Image').texture = texture
	
	if question_info.time_limit:
		counting = true
		start_time = Time.get_ticks_msec()
	
	if question_info.answers.size() > 0:
		current_answer_index = -1
		var multiple_choice_box = question_screen.get_node('MultipleChoice/VBox')
		for child in multiple_choice_box.get_children():
			multiple_choice_box.remove_child(child)
			child.queue_free()
		
		var index = 0
		
		while index < question_info.answers.size():
			var pair = question_screen.get_node('TemplatePair').duplicate()
			pair.get_node('FirstAnswer').text = question_info.answers[index]
			pair.get_node('FirstAnswer').connect('gui_input',self,'select_answer',[index,pair.get_node('FirstAnswer')])
			if question_info.answers.size() - index > 1:
				pair.get_node('SecondAnswer').text = question_info.answers[index + 1]
				pair.get_node('SecondAnswer').connect('gui_input',self,'select_answer',[index + 1,pair.get_node('SecondAnswer')])
				pair.get_node('SecondAnswer').show()
			pair.show()
			multiple_choice_box.add_child(pair)
			index += 2
	else:
		pass
	
	question_screen.rect_scale = Vector2(20,25)
	tween.interpolate_property(
		question_screen,'rect_scale',
		question_screen.rect_scale,Vector2(1,1),
		.5,Tween.TRANS_QUART,Tween.EASE_OUT
	)
	tween.start()
	
	question_screen.show()

func answer_lock(packet) -> void:
	var answer_label: Label = question_screen.get_node('AnswerLabel')
	answer_label.text = packet.answer
	question_screen.get_node('Answer').hide()
	question_screen.get_node('Submit').hide()
	answer_label.show()
	
	tween.interpolate_property(
		answer_label.get_stylebox('normal'),'bg_color',
		answer_label.get_stylebox('normal').bg_color,Color8(15,45,65),
		.5,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT
	)
	tween.start()

func solve(packet) -> void:
	counting = false
	
	if packet.multiple_choice:
		var pattern: Array = packet.pattern
		var answer_box = question_screen.get_node('MultipleChoice/VBox')
		
		for index in range(pattern.size()):
			var answer_node = answer_box.get_child(index/2).get_node('FirstAnswer' if (index % 2 == 0) else 'SecondAnswer')
			var style_box = answer_node.get_stylebox('normal').duplicate()
			answer_node.add_stylebox_override('normal',style_box)
			answer_node.disconnect('gui_input',self,'select_answer')
			
			tween.interpolate_property(
				style_box,'bg_color',
				style_box.bg_color,Color8(255 if not pattern[index] else 100,255 if pattern[index] else 100,75),
				.5,Tween.TRANS_LINEAR,Tween.EASE_OUT
			)
		tween.start()
	else:
		var stylebox = question_screen.get_node('AnswerLabel').get_stylebox('normal')
		
		tween.remove(stylebox,'bg_color')
		tween.interpolate_property(
			stylebox,'bg_color',
			stylebox.bg_color,Color8(75,200,15) if packet.correct else Color8(200,35,25),
			.5,Tween.TRANS_LINEAR,Tween.EASE_OUT
		)
		tween.start()

func start(packet):
	for player_name in packet.names:
		var node = player_list.get_node('VBox/Template').duplicate()
		node.text = player_name
		node.name = player_name
		node.show()
		player_list.get_node('VBox').add_child(node)
	
	tween.interpolate_property(
		start_screen,'global_position:x',
		start_screen.global_position.x,-1920,
		1,Tween.TRANS_EXPO,Tween.EASE_IN
	)
	tween.interpolate_property(
		player_list,'rect_position:x',
		-2000,player_list.rect_position.x,
		1,Tween.TRANS_EXPO,Tween.EASE_OUT
	)
	tween.start()
	
	player_list.show()
	play_screen.show()
	
	yield(get_tree().create_timer(1),'timeout')
	
	start_screen.queue_free()

func game_over(packet) -> void:
	tween.interpolate_property(
		foreground,'color:a',
		foreground.color.a,1,
		3,Tween.TRANS_EXPO,Tween.EASE_IN
	)
	tween.start()
	
	yield(get_tree().create_timer(5),'timeout')
	
	game_over_screen.show()
	
	var index = 0
	
	for info in packet.leaderboard:
		var player_node: Label = game_over_screen.get_node('PlayerList/VBox/Template').duplicate()
		player_node.text = info.name
		player_node.get_node('Points').text = String(info.score)
		game_over_screen.get_node('PlayerList/VBox').add_child(player_node)
		
		var stylebox = player_node.get_stylebox('normal').duplicate()
		if index < 3:
			match index:
				0:
					stylebox.bg_color = Color8(200,200,50)
				1:
					stylebox.bg_color = Color8(150,150,150)
				2:
					stylebox.bg_color = Color8(150,75,25)
		else:
			if info.name == username:
				player_node.text = 'YOU'
				stylebox.bg_color = Color8(139,99,61)
			
		tween.interpolate_property(
			player_node,'modulate:a',
			0,1,
			.5,Tween.TRANS_QUART,Tween.EASE_OUT
		)
		
		player_node.add_stylebox_override('normal',stylebox)
		
		tween.start()
		player_node.show()
		
		if index < 3:
			yield(get_tree().create_timer(.25),'timeout')
		
		index += 1

func join() -> void:
	var ip = ProjectSettings.get("ip")
	var port = ProjectSettings.get("port")
	if not ip or not port:
		return
	while true:
		var result = client.connect_to_host(String(ip),int(port))

		if result == OK:
			break
		yield(get_tree().create_timer(.1),"timeout")
	start_screen.get_node("Message").text = "CONNECTED, THE GAME WILL START SOON"
	send_data({
			'info_type' : 'usrnm',
			'name' : username
			})
	print('hehe sent')
	state = 'waiting'

func _ready():
	get_tree().auto_accept_quit = false
	add_child(tween)
	
	load_circle.show()
	
	yield(get_tree().create_timer(.1),'timeout')
	
	tween.interpolate_property(
		load_circle,'scale',
		load_circle.scale,Vector2(0,0),
		.5,Tween.TRANS_EXPO,Tween.EASE_OUT
	)
	tween.start()

	yield(get_tree().create_timer(.6),"timeout")
	
	join()
	question_screen.get_node("Submit").connect('pressed',self,'submit')
	
	paused = false

func _process(delta):
	if paused:
		return
	get_data()
	for packet in packets:
		if packet.info_type.length():
			var info = packet.info_type
			
			match info:
				'start':
					start(packet)
				'intro':
					intro(packet)
				'question':
					question(packet)
				'answer_lock':
					answer_lock(packet)
				'solve':
					solve(packet)
				'score':
					update_score(packet)
				'game_over':
					game_over(packet)
				'end':
					end()
				'q':
					get_tree().change_scene('res://scenes/menus/MainScene.tscn')
	packets.clear()
	
	timer.visible = counting
	
	if counting:
		var time_left = question_info.time_limit * 1000 - (Time.get_ticks_msec() - start_time)
		timer.text = '%.2f' % (round(time_left / 10)/100.0)

func _notification(what):
	if what == NOTIFICATION_WM_QUIT_REQUEST:
		send_data({'info_type':"q"})
		get_tree().quit()
func _exit_tree():
	get_tree().auto_accept_quit = true
