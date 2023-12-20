extends Node2D

onready var path = "user://contests/" + ProjectSettings.get("selected_game") + ".res"
export var GameMap: Resource = DataLoader.new()
export var paused: bool = true
export var state: String = "waiting"

onready var advertiser = get_node("ServerAdvertiser")

onready var start_screen: Node2D = get_node("StartScreen")
onready var start_button: Button = start_screen.get_node('Start')

onready var control_screen: Node2D = get_node("ControlScreen")

onready var player_list: ScrollContainer = get_node('Players')
onready var submission_container = control_screen.get_node('Controls/question/Scroll/VBox')

onready var validate_button: Label = control_screen.get_node('Controls/question/Scroll/VBox/Reserved')

onready var camera: Camera2D = get_node("Camera")
onready var load_circle = $LoadCircle
onready var background = $MainBackground
var tween: Tween = Tween.new()

var server: TCP_Server = TCP_Server.new()
var port = 49152
export var clients = []

export var current_block_index = -1
export var current_block_info = {}

class sort_hehe:
	static func custom_sort(a,b):
		return a.score < b.score
var sort = sort_hehe.new()

func get_data(client):
	var bytes = client.stream.get_available_bytes()
	if bytes > 0:
		var info = client.stream.get_var(bytes)
		
		if info:
			client.packets.append(info)
			print("KUIZ" + String(info))
func send_data(client,packet):
	while client.stream.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		pass
	client.stream.put_var(packet,true)

func host():
	while true:
		var result = server.listen(port)
		if result == OK:
			break
		port += 1
		if port > 65535:
			start_screen.get_node("Message").text = Main.translate('FAILED TO HOST GAME')
			return
	start_screen.get_node("Message").text = Main.translate('HOSTED ON PORT ') + String(port)
	start_button.text = Main.translate('START')
	tween.interpolate_property(
		start_screen.get_node("Message"),'rect_position:x',
		start_screen.get_node("Message").rect_position.x,275,
		1.5,Tween.TRANS_QUINT,Tween.EASE_IN_OUT
	)
	tween.interpolate_property(
		start_screen.get_node("Message"),'rect_size',
		start_screen.get_node("Message").rect_size,Vector2(675,800),
		1.5,Tween.TRANS_QUINT,Tween.EASE_IN_OUT
	)
	tween.interpolate_property(
		player_list,'rect_position:x',
		player_list.rect_position.x,-950,
		1.5,Tween.TRANS_QUINT,Tween.EASE_IN_OUT
	)
	tween.interpolate_property(
		player_list,'rect_size:x',
		0,player_list.rect_size.x,
		1.5,Tween.TRANS_QUART,Tween.EASE_IN_OUT
	)
	tween.interpolate_property(
		start_button,'rect_position:x',
		start_button.rect_position.x,275,
		1.5,Tween.TRANS_QUART,Tween.EASE_IN_OUT
	)
	tween.interpolate_property(
		start_button,'rect_size:x',
		0,start_button.rect_size.x,
		1.5,Tween.TRANS_QUART,Tween.EASE_IN_OUT
	)
	tween.interpolate_property(
		background,'modulate',
		background.modulate,Color8(60,25,25),
		2,Tween.TRANS_SINE,Tween.EASE_IN_OUT
	)
	tween.start()
	
	start_button.show()
	player_list.show()

func auto_validate() -> void:
	var info = {
		'info_type' : 'solve',
		'multiple_choice' : true,
		'pattern' : []
	}
	for answer in current_block_info.question.answers:
		info.pattern.append(answer.correct)
	
	for client in clients:
		send_data(client,info)
	
		if client.answer != null and current_block_info.question.answers[int(client.answer)].correct:
			if current_block_info.question.score == 0:
				continue
			client.score += current_block_info.question.score
			
			for client2 in clients:
				send_data(client2,{
				'info_type' : 'score',
				'player' : client.name,
				'score' : client.score
			})
		else:
			if current_block_info.question.penalty == 0:
				continue
			client.score -= current_block_info.question.penalty
			
			for client2 in clients:
				send_data(client2,{
				'info_type' : 'score',
				'player' : client.name,
				'score' : client.score
			})
		client.answer = null
		player_list.get_node('VBox').get_node(client.name).get_node('Points').text = String(client.score)
	state = 'proceedable'

func on_submission_score_change(submission_node: Label,add: bool,player_name: String) -> void:
	for client in clients:
		if client.name != player_name:
			continue
		
		client.answer_score += 5 if add else -5
		var submission: Label = submission_container.get_node_or_null(player_name)
		if submission:
			submission.get_node('Points').text = String(client.answer_score)
		
		return

func on_submission_click(event: InputEvent,player_name: String) -> void:
	if not event is InputEventMouseButton or not event.pressed or event.button_index != BUTTON_LEFT:
		return
	
	for client in clients:
		if client.name != player_name:
			continue
		
		client.correct = not client.correct
		var submission: Label = submission_container.get_node_or_null(player_name)
		if submission:
			var stylebox = submission.get_stylebox('normal')
			tween.remove(stylebox,'bg_color')
			tween.interpolate_property(
					stylebox,'bg_color',
					stylebox.bg_color,Color8(50,255,75) if client.correct else Color8(255,50,50),
					.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT
				)
			tween.start()
		
		return

func validate() -> void:
	if state == 'question':
		state = 'none'
		
		for client in clients:
			var info = {
				'info_type' : 'answer_lock',
				'answer' : client.answer,
			}
			var submission_label: Label = submission_container.get_node_or_null(client.name)
			if typeof(submission_label) == TYPE_NIL:
				info.answer = ''
				
				submission_label = submission_container.get_node('Template').duplicate()
				submission_label.name = client.name
				submission_label.add_stylebox_override('normal',submission_label.get_stylebox('normal').duplicate())
				submission_container.add_child(submission_label)
				submission_container.move_child(submission_label,submission_container.get_child_count() - 2)
				submission_label.text = Main.translate('[EMPTY SUBMISSION]')
				submission_label.show()
			
			submission_label.get_node('Time').text = '%.2f' % client.answer_time
			
			send_data(client,info)
		
		for submission in submission_container.get_children():
			if submission.name != 'Template' and submission.name != 'Reserved':
				tween.remove(submission.get_stylebox('normal'),'bg_color')
				tween.interpolate_property(
					submission.get_stylebox('normal'),'bg_color',
					submission.get_stylebox('normal').bg_color,Color8(255,50,50),
					.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT
				)
				tween.interpolate_property(
					submission,'rect_size:x',
					submission.rect_size.x,1075,
					.5,Tween.TRANS_CIRC,Tween.EASE_OUT
				)
				submission.connect('gui_input',self,'on_submission_click',[submission.name])
				submission.get_node('Subtract').connect('pressed',self,'on_submission_score_change',[submission,false,submission.name])
				submission.get_node('Add').connect('pressed',self,'on_submission_score_change',[submission,true,submission.name])
		tween.start()
		
		validate_button.text = Main.translate('APPLY SCORE')
		
		state = 'validating'
	elif state == 'validating':
		state = 'none'
		
		for client in clients:
			client.score += client.answer_score
			var info = {
				'info_type' : 'score',
				'player' : client.name,
				'score' : client.score
			}
				
			for client2 in clients:
				send_data(client2,info)
			
			send_data(client,{
				'info_type' : 'solve',
				'multiple_choice' : false,
				'correct' : client.correct
			})
			client.correct = false
			client.answer_score = 0
			client.answer = null
			player_list.get_node('VBox').get_node(client.name).get_node('Points').text = String(client.score)
		validate_button.text = Main.translate('CLOSE SUBMISSION')
		
		submissions = 0
		
		state = 'proceedable'

var validate_toggled = false
onready var validate_button_stylebox = validate_button.get_stylebox('normal')
var not_now = false

func on_validate_button_click(event: InputEvent) -> void:
	if not event is InputEventMouseButton or event.pressed or event.button_index != BUTTON_LEFT or not_now:
		return
	not_now = true
	
	tween.remove(validate_button_stylebox,'bg_color')
	tween.interpolate_property(
		validate_button_stylebox,'bg_color',
		validate_button_stylebox.bg_color,Color8(15,150,25) if not validate_toggled else Color8(100,100,100),
		.5,Tween.TRANS_CIRC,Tween.EASE_OUT
	)
	tween.start()
	
	if validate_toggled:
		validate()
	
	validate_toggled = not validate_toggled
	
	yield(get_tree().create_timer(.5),'timeout')
	
	not_now = false

func _ready() -> void:
	start_screen.get_node("Message").text = Main.translate('HOSTING...')
	randomize()
	get_tree().auto_accept_quit = false
	add_child(tween)
	
	if GameMap.save_exists(path):
		GameMap = GameMap.load_data(path)
	
	load_circle.show()
	
	yield(get_tree().create_timer(.1),'timeout')
	
	tween.interpolate_property(
		load_circle,'scale',
		load_circle.scale,Vector2(0,0),
		.5,Tween.TRANS_EXPO,Tween.EASE_OUT
	)
	tween.start()

	yield(get_tree().create_timer(.6),"timeout")
	
	paused = false
	
	host()
	advertiser.broadcast_interval = 0.3
	advertiser.serverInfo.name = "olympia" + ProjectSettings.get("selected_game")
	advertiser.serverInfo.port = port
	advertiser.start()
	
	var index = 0
	
	for block_info in GameMap.blocks:
		var block_node = get_node('Templates').get_node(block_info.type).duplicate()
		block_node.transform.origin = Vector2(210 + 210 * index,0)
		block_node.show()
		control_screen.get_node('Blocks').add_child(block_node)
		index += 1
	control_screen.get_node('Blocks/End').transform.origin.x = 210 + 210 * GameMap.blocks.size()
	
	validate_button.connect('gui_input',self,'on_validate_button_click')

var submissions = 0
var submission_start = 0

func _process(delta):
	if paused:
		return
	
	get_node('ControlScreen/Blocks').transform.origin.x = lerp(
		get_node('ControlScreen/Blocks').transform.origin.x,
		(current_block_index + 1) * -210,
		10 * delta
	)
	
	for client in clients:
		get_data(client)
	match state:
		'proceedable':
			pass
		'transition':
			var control_panel = control_screen.get_node('Controls').get_node_or_null(current_block_info.type)
			
			if control_panel:
				match current_block_info.type:
					'intro':
						var info = {
							'info_type' : 'intro',
							'title' : current_block_info.intro.title,
							'subtitle' : current_block_info.intro.subtitle,
						}
						
						control_panel.get_node('Title').text = current_block_info.intro.title
						control_panel.get_node('Subtitle').text = current_block_info.intro.subtitle
						
						for client in clients:
							send_data(client,info)
						state = 'intro'
					'question':
						control_panel.get_node('Content/Text').visible = (current_block_info.question.content_type == 'text')
						control_panel.get_node('Content/Image').visible = (current_block_info.question.content_type == 'image')
						control_panel.get_node('Scroll').visible = not current_block_info.question.multiple_choice
						
						for child in submission_container.get_children():
							if child.name != 'Template' and child.name != 'Reserved':
								child.queue_free()
						if current_block_info.question.content_type == 'text':
							control_panel.get_node('Content/Text').text = current_block_info.question.text_content
						if current_block_info.question.content_type == 'image':
							var image = Image.new()
							image.load(current_block_info.question.image_content)
							
							var texture = ImageTexture.new()
							texture.create_from_image(image)
							control_panel.get_node('Content/Image').texture = texture
						var info = {
							'info_type' : 'question',
							'content_type' : current_block_info.question.content_type,
							'content' : current_block_info.question.text_content,
							'image_info' : {
								'width' : 0,
								'height' : 0,
								'mipmaps' : false,
								'format' : 0,
							},
							'image_type' : '',
							'answers' : [],
							'time_limit' : current_block_info.question.limit.time
						}
						if current_block_info.question.content_type != 'text':
							var image = Image.new()
							var err = image.load(current_block_info.question.image_content)
							
							if err == OK:
								info.image_info.width = image.get_width()
								info.image_info.height = image.get_height()
								info.image_info.mipmaps = image.has_mipmaps()
								info.image_info.format = image.get_format()
								info.content = image.get_data()
						if current_block_info.question.multiple_choice:
							for answer in current_block_info.question.answers:
								info.answers.append(answer.content)
						
						for client in clients:
							client.answer = null
							send_data(client,info)
						submissions = 0
						submission_start = Time.get_ticks_usec()
						state = 'question'
				
				control_panel.show()
		'validating':
			pass
		'question':
			if not current_block_info.question.multiple_choice:
				for client in clients:
					if typeof(client.answer) != TYPE_NIL:
						var submission_label: Label = submission_container.get_node_or_null(client.name)
						if not submission_label:
							submission_label = submission_container.get_node('Template').duplicate()
							submission_label.name = client.name
							submission_label.show()
							submission_label.add_stylebox_override('normal',submission_label.get_stylebox('normal').duplicate())
							submission_container.add_child(submission_label)
							submission_container.move_child(submission_label,submission_container.get_child_count() - 2)
						submission_label.text = client.answer
			
			if (submissions == clients.size()) or (current_block_info.question.limit.submission != 0 and submissions >= current_block_info.question.limit.submission) or (current_block_info.question.limit.time != 0 and Time.get_ticks_usec() - submission_start >= current_block_info.question.limit.time * 1000000):
				#print('ok! closing submission!')
				#print(submissions == clients.size())
				#print(current_block_info.question.limit.submission != 0 and submissions >= current_block_info.question.limit.submission)
				#print(current_block_info.question.limit.time != 0 and Time.get_ticks_usec() - submission_start >= current_block_info.question.limit.time)
				if current_block_info.question.multiple_choice:
					auto_validate()
				elif (current_block_info.question.limit.submission != 0 and submissions == current_block_info.question.limit.submission) or (current_block_info.question.limit.time != 0 and Time.get_ticks_usec() - submission_start == current_block_info.question.limit.time * 1000000):
					validate()
		'intro':
			var all_checked = true
			
			for client in clients:
				if not client.check:
					all_checked = false
					break
			
			if all_checked:
				state = 'proceedable'
				
				for client in clients:
					client.check = false
		'waiting':
			while server.is_connection_available() and clients.size() < GameMap.players:
				clients.append({
					'name' : null,
					'stream' : server.take_connection(),
					'packets' : [],
					'answer' : null,
					'correct' : false,
					'answer_score' : 0,
					'answer_time' : 0,
					'check' : false,
					'score' : 0,
				})
				print('KUIZ' + String(clients[clients.size() - 1]))
		'ending':
			var info = {
				'info_type' : 'game_over',
				'leaderboard' : [],
			}
			
			clients.sort_custom(sort,'custom_sort')
			
			for client in clients:
				info.leaderboard.append(
					{'name':client.name,'score':client.score}
				)
			
			for client in clients:
				send_data(client,info)
			
			state = 'none'
			
	var index = 0
			
	while index < clients.size():
		var client = clients[index]
		for packet in client.packets:
			match packet.info_type:
				'usrnm':
					var client_name = packet.name
					var no = false
					if client_name == "Template" or client_name == "Reserved":
						send_data(client,{'info_type':"q"})
						clients.remove(index)
						continue
					for client2 in clients:
						if client2 == client:
							continue
						if client2.name == client_name:
							send_data(client,{'info_type':"q"})
							clients.remove(index)
							no = true
							break
					if no:
						continue
					
					client.name = client_name
					
					var name_text = player_list.get_node('VBox/Template').duplicate()
					name_text.text = client.name
					name_text.name = client.name
					name_text.show()
					player_list.get_node('VBox').add_child(name_text)
				'answr':
					if current_block_info.question.limit.submission != 0 and submissions >= current_block_info.question.limit.submission:
						continue
					if state != 'question' or (typeof(client.answer) != TYPE_NIL and not current_block_info.question.resubmission):
						continue
					if typeof(client.answer) == TYPE_NIL:
						submissions += 1
					client.answer = packet.answer
					client.answer_time = round((Time.get_ticks_usec() - submission_start) / 10000)/100.0
				'q':
					player_list.get_node('VBox').get_node(client.name).queue_free()
					clients.remove(index)
					index -= 1
				'check':
					client.check = true
		client.packets.clear()
		index += 1

func _notification(what):
	if what == NOTIFICATION_WM_QUIT_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST or (what == NOTIFICATION_WM_FOCUS_OUT and OS.get_name() == 'Android'):
		for client in clients:
			send_data(client,{'info_type':"q"})
		get_tree().quit()
func _exit_tree():
	get_tree().auto_accept_quit = true
