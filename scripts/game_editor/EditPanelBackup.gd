extends Panel

onready var root = get_parent()
onready var tween = Tween.new()

onready var blocks: Node2D = root.get_node("Blocks")
onready var pointer: Label = root.get_node("Pointer")
onready var current_block: Polygon2D
var current_block_info: block

onready var question_container = get_node("question/VBox/HBox")
onready var intro_container = get_node("intro/VBox")

onready var answer_template = question_container.get_node('Settings/MultipleChoice/AnswerTemplate')
onready var new_answer_button = question_container.get_node('Settings/MultipleChoice/NewAnswer')

export var switching = false

func on_title_text_change(hhe) -> void:
	if switching:
		return
	root.enable_save("yeea1")
	current_block_info.intro.title = intro_container.get_node("TitleBox").text

func on_subtitle_text_change() -> void:
	if switching:
		return
	root.enable_save("yeea2")
	current_block_info.intro.subtitle = intro_container.get_node("SubtitleBox").text

func on_content_type_change(pressed) -> void:
	if switching:
		return
	question_container.get_node('Content/ContentType').text = "image" if pressed else "text"
	current_block_info.question.content_type = "image" if pressed else "text"
	root.enable_save('content type changed')

func on_text_content_change() -> void:
	if switching:
		return
	root.enable_save("yeea3")
	current_block_info.question.text_content = question_container.get_node('Content/TextContent').text

func on_submission_limit_change(he) -> void:
	if switching:
		return
	if question_container.get_node('Settings/Limit/Submission').text != '' and current_block_info.question.limit.submission != int(question_container.get_node('Settings/Limit/Submission').text):
		root.enable_save("yeea4")
		current_block_info.question.limit.submission = int(question_container.get_node('Settings/Limit/Submission').text)
func on_time_limit_change(he) -> void:
	if switching:
		return
	if question_container.get_node('Settings/Limit/Time').text != '' and current_block_info.question.limit.time != int(question_container.get_node('Settings/Limit/Time').text):
		root.enable_save("yeea5")
		current_block_info.question.limit.time = int(question_container.get_node('Settings/Limit/Time').text)

func on_score_change(he) -> void:
	if switching:
		return
	print('yea')
	if question_container.get_node('Settings/Score').text != '' and current_block_info.question.score != int(question_container.get_node('Settings/Score').text):
		root.enable_save("yeea6")
		current_block_info.question.score = int(question_container.get_node('Settings/Score').text)

func on_penalty_change(he) -> void:
	if switching:
		return
	print('yea')
	if question_container.get_node('Settings/Penalty').text != '' and current_block_info.question.penalty != int(question_container.get_node('Settings/Penalty').text):
		root.enable_save("yeea6")
		current_block_info.question.penalty = int(question_container.get_node('Settings/Penalty').text)

func on_resubmission_enabled(he) -> void:
	if switching:
		return
	root.enable_save("yeea6")
	current_block_info.question.resubmission = question_container.get_node('Settings/Resubmission').pressed

func on_multiple_choice_enabled(he) -> void:
	if switching:
		return
	root.enable_save("yeea6")
	current_block_info.question.multiple_choice = question_container.get_node('Settings/MuitipleChoiceButton').pressed
	question_container.get_node('Settings/Separator').visible = current_block_info.question.multiple_choice
	question_container.get_node('Settings/Score').visible = current_block_info.question.multiple_choice
	question_container.get_node('Settings/Penalty').visible = current_block_info.question.multiple_choice

func new_answer() -> void:
	if current_block_info.type != 'question':
		return
	
	var answer = answer_template.duplicate()
	question_container.get_node('Settings/MultipleChoice').add_child(answer)
	question_container.get_node('Settings/MultipleChoice').move_child(answer,question_container.get_node('Settings/MultipleChoice').get_child_count() - 2)
	
	current_block_info.question.answers.append({
		'content' : '',
		'correct' : false
	})
	
	answer.get_node("Answer").connect('text_changed',self,'on_answer_change',[answer])
	answer.get_node("Validity").connect('button_up',self,'on_validity_change',[answer])
	answer.get_node("Delete").connect('button_up',self,'delete_answer',[answer])
	
	answer.visible = true
	root.enable_save('new answer created')

func on_answer_change(answer) -> void:
	var answer_index = answer.get_index() - 1
	current_block_info.question.answers[answer_index].content = answer.get_node('Answer').text
	root.enable_save('answer content changed')

func on_validity_change(answer) -> void:
	var answer_index = answer.get_index() - 1
	current_block_info.question.answers[answer_index].correct = not current_block_info.question.answers[answer_index].correct
	answer.get_node("Validity").icon = preload('res://sprites/check.svg') if current_block_info.question.answers[answer_index].correct else preload('res://sprites/uncheck.svg')
	root.enable_save('answer validity changed')

func delete_answer(answer) -> void:
	var answer_index = answer.get_index() - 1
	current_block_info.question.answers.remove(answer_index)
	root.enable_save('answer deleted')
	
	answer.queue_free()

func _ready() -> void:
	if ProjectSettings.get('lang')  == 'vin':
		intro_container.get_node('TitleLabel').text = 'TIÊU ĐỀ'
		intro_container.get_node('SubtitleLabel').text = 'PHỤ ĐỀ'
		
		question_container.get_node('Settings/LimitLabel').text = '-----------------------------------'
	
	add_child(tween)
	question_container.get_node('Content/ImageContent/Load').connect('button_up',self,'select_image')
	
	root.get_node('LoadImage').connect('file_selected',self,'image_selected')
	
	intro_container.get_node("TitleBox").connect('text_changed',self,'on_title_text_change')
	intro_container.get_node("SubtitleBox").connect('text_changed',self,'on_subtitle_text_change')
	
	question_container.get_node('Content/ContentType').connect('toggled',self,'on_content_type_change')
	question_container.get_node('Content/TextContent').connect('text_changed',self,'on_text_content_change')
	
	question_container.get_node('Settings/Limit/Submission').connect('text_changed',self,'on_submission_limit_change')
	question_container.get_node('Settings/Limit/Time').connect('text_changed',self,'on_time_limit_change')
	
	question_container.get_node('Settings/Score').connect('text_changed',self,'on_score_change')
	question_container.get_node('Settings/Penalty').connect('text_changed',self,'on_penalty_change')
	
	question_container.get_node('Settings/Resubmission').connect('toggled',self,'on_resubmission_enabled')
	
	question_container.get_node('Settings/MuitipleChoiceButton').connect('toggled',self,'on_multiple_choice_enabled')
	new_answer_button.connect('button_up',self,'new_answer')

func select_image() -> void:
	root.get_node('LoadImage').popup_centered(Vector2(1920,1080))
func image_selected(path: String) -> void:
	if not current_block:
		return
	
	if path != '':
		var image = Image.new()
		var err = image.load(path)
		
		if err == OK:
			var texture: ImageTexture = ImageTexture.new()
			texture.create_from_image(image)
			question_container.get_node('Content/ImageContent').texture = texture
		else:
			path = ''
	if path == '':
		return
	if path != current_block_info.question.image_content:
		current_block_info.question.image_content = path
		root.enable_save('image content path changed')

func set_block(new_block: Polygon2D) -> void:
	switching = true
	current_block = new_block
	if new_block == null:
		return
	current_block_info = root.GameMap.blocks[current_block.get_index() - 2]
	
	for answer in question_container.get_node('Settings/MultipleChoice').get_children():
		if answer != new_answer_button and answer != answer_template:
			answer.queue_free()
	match current_block_info.type:
		'intro':
			intro_container.get_node("TitleBox").text = current_block_info.intro.title
			intro_container.get_node("SubtitleBox").text = current_block_info.intro.subtitle
		'question':
			question_container.get_node('Content/ContentType').text = current_block_info.question.content_type
			question_container.get_node('Content/ContentType').pressed = (current_block_info.question.content_type == 'image')
			question_container.get_node('Content/TextContent').text = current_block_info.question.text_content
			if current_block_info.question.image_content != '':
				var image = Image.new()
				var err = image.load(current_block_info.question.image_content)
				
				if err == OK:
					var texture: ImageTexture = ImageTexture.new()
					texture.create_from_image(image)
					question_container.get_node('Content/ImageContent').texture = texture
				else:
					current_block_info.question.image_content = ''
					
					root.enable_save('image not valid, content discarded')
			question_container.get_node('Settings/Limit/Submission').text = ''
			question_container.get_node('Settings/Limit/Time').text = ''
			
			question_container.get_node('Settings/Resubmission').pressed = current_block_info.question.resubmission
			question_container.get_node('Settings/MuitipleChoiceButton').pressed = current_block_info.question.multiple_choice
			
			question_container.get_node('Settings/Separator').visible = current_block_info.question.multiple_choice
			question_container.get_node('Settings/Score').visible = current_block_info.question.multiple_choice
			question_container.get_node('Settings/Penalty').visible = current_block_info.question.multiple_choice

			
			if current_block_info.question.multiple_choice:
				for answer_info in current_block_info.question.answers:
					
					var answer = answer_template.duplicate()
					question_container.get_node('Settings/MultipleChoice').add_child(answer)
					question_container.get_node('Settings/MultipleChoice').move_child(answer,question_container.get_node('Settings/MultipleChoice').get_child_count() - 2)
					
					if answer_info.content != '':
						answer.get_node('Answer').text = answer_info.content
					if answer_info.correct:
						answer.get_node("Validity").icon = preload('res://sprites/check.svg') if answer_info.correct else preload('res://sprites/uncheck.svg')
					
					answer.get_node("Answer").connect('text_changed',self,'on_answer_change',[answer])
					answer.get_node("Validity").connect('button_up',self,'on_validity_change',[answer])
					answer.get_node("Delete").connect('button_up',self,'delete_answer',[answer])
					
					answer.visible = true
	switching = false

func _process(delta) -> void:
	if current_block == null or weakref(current_block).get_ref() == null:
		pointer.rect_position.x = lerp(pointer.rect_position.x,-10 + blocks.global_position.x,min(15 * delta,1))
		return
	if Input.is_action_pressed("ctrl") and Input.is_action_pressed("focus"):
		blocks.global_position.x = lerp(
			blocks.global_position.x,
			960 - 210 * (current_block.get_index() - 1),
			20 * delta
		)
	pointer.rect_position.x = lerp(pointer.rect_position.x,-10 + 210 * (current_block.get_index() - 1) + blocks.global_position.x,min(15 * delta,1))
	
	for container in get_children():
		if container == tween:
			continue
		container.visible = container.name == current_block_info.type
	
	match current_block_info.type:
		'question':
			question_container.get_node('Content/TextContent').visible = (question_container.get_node('Content/ContentType').text == 'text')
			question_container.get_node('Content/ImageContent').visible = (question_container.get_node('Content/ContentType').text == 'image')
			
			question_container.get_node('Settings/Limit/Submission').placeholder_text = "SUBMISSIONS: " + String(current_block_info.question.limit.submission)
			question_container.get_node('Settings/Limit/Time').placeholder_text = "TIME (s): " + String(current_block_info.question.limit.time)
			
			question_container.get_node('Settings/Score').placeholder_text = "SCORE: " + String(current_block_info.question.score)
			question_container.get_node('Settings/Penalty').placeholder_text = "PENALTY: " + String(current_block_info.question.penalty)
			
			question_container.get_node('Settings/MultipleChoice').visible = question_container.get_node('Settings/MuitipleChoiceButton').pressed
