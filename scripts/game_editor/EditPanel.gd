extends Panel

onready var root = get_parent()
onready var tween = Tween.new()
onready var blocks: Node2D = root.get_node("Blocks")
onready var pointer: Label = root.get_node("Pointer")
onready var current_block: Polygon2D
var current_block_info

onready var question_container: VBoxContainer = get_node("question/VBox")
onready var intro_container: VBoxContainer = get_node("intro/VBox")

onready var current_container: VBoxContainer

export var switching = false

func new_answer(content: String,correct: bool) -> void:
	var answer = current_container.get_node('Normal/Misc/MultipleChoiceUI/AnswerTemplate').duplicate()
	current_container.get_node('Normal/Misc/MultipleChoiceUI').add_child(answer)
	current_container.get_node('Normal/Misc/MultipleChoiceUI').move_child(
		answer,
		current_container.get_node('Normal/Misc/MultipleChoiceUI').get_child_count() - 2
	)
	
	answer.get_node('Answer').text = content
	answer.get_node("Validity").icon = preload('res://sprites/check.svg') if correct else preload('res://sprites/uncheck.svg')
	
	answer.get_node("Answer").connect('text_changed',self,'on_answer_change',[answer])
	answer.get_node("Validity").connect('pressed',self,'on_validity_change',[answer])
	answer.get_node("Delete").connect('pressed',self,'delete_answer',[answer])
	
	answer.show()

func on_title_text_change(hhe) -> void:
	if switching:
		return
	root.enable_save("yeea1")
	current_block_info.intro.title = current_container.get_node("TitleBox").text

func on_subtitle_text_change() -> void:
	if switching:
		return
	root.enable_save("yeea2")
	current_block_info.intro.subtitle = current_container.get_node("SubtitleBox").text

func on_content_type_change(pressed) -> void:
	if switching:
		return
	var content_type = "image" if pressed else "text"
	current_container.get_node('Normal/Content/ContentType').text = Main.translate(content_type)
	current_block_info.normal_question.content_type = content_type
	current_container.get_node('Normal/Content/TextContent').visible = content_type == 'text'
	current_container.get_node('Normal/Content/ImageContent').visible = content_type == 'image'
	root.enable_save('content type changed')

func on_text_content_change() -> void:
	if switching:
		return
	root.enable_save("yeea3")
	current_block_info.normal_question.text_content = current_container.get_node('Normal/Content/TextContent').text

func on_submission_limit_change(he) -> void:
	if switching:
		return
	var text = current_container.get_node('Limit/Input/Submission').text
	if text.length() and current_block_info.question.limit.submission != int(text):
		root.enable_save("yeea5")
		current_block_info.question.limit.submission = int(text)
func on_resubmission_limit_change(he) -> void:
	if switching:
		return
	var text = current_container.get_node('Limit/Input/Resubmission').text
	if text.length() and current_block_info.question.limit.resubmission != int(text):
		root.enable_save("yeea5")
		current_block_info.question.limit.resubmission = int(text)
func on_time_limit_change(he) -> void:
	if switching:
		return
	var text = current_container.get_node('Limit/Input/Time').text
	if text.length() and current_block_info.question.limit.time != int(text):
		root.enable_save("yeea5")
		current_block_info.question.limit.time = int(text)

func on_score_change(he) -> void:
	if switching:
		return
	var text = current_container.get_node('Validation/Input/Score').text
	if text.length() and current_block_info.question.score != int(text):
		root.enable_save("yeea6")
		current_block_info.question.score = int(text)
func on_penalty_change(he) -> void:
	if switching:
		return
	var text = current_container.get_node('Validation/Input/Penalty').text
	if text.length() and current_block_info.question.penalty != int(text):
		root.enable_save("yeea6")
		current_block_info.question.penalty = int(text)

func on_multiple_choice_enabled(he) -> void:
	if switching:
		return
	root.enable_save("yeea6")
	current_block_info.normal_question.multiple_choice = current_container.get_node('Normal/Misc/MultipleChoiceButton').pressed

func on_new_answer_click() -> void:
	new_answer('',false)
	current_block_info.normal_question.answers.append({
		'content' : '',
		'correct' : false
	})
	root.enable_save('new answer created')

func on_answer_change(answer) -> void:
	var answer_index = answer.get_index() - 1
	current_block_info.normal_question.answers[answer_index].content = answer.get_node('Answer').text
	root.enable_save('answer content changed')

func on_validity_change(answer) -> void:
	var answer_index = answer.get_index() - 1
	current_block_info.normal_question.answers[answer_index].correct = not current_block_info.normal_question.answers[answer_index].correct
	answer.get_node("Validity").icon = preload('res://sprites/check.svg') if current_block_info.normal_question.answers[answer_index].correct else preload('res://sprites/uncheck.svg')
	root.enable_save('answer validity changed')

func delete_answer(answer) -> void:
	var answer_index = answer.get_index() - 1
	current_block_info.normal_question.answers.remove(answer_index)
	root.enable_save('answer deleted')
	
	answer.queue_free()

func _ready() -> void:
	add_child(tween)
	
	root.get_node('LoadImage').connect('file_selected',self,'image_selected')

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
			current_container.get_node('Normal/Content/ImageContent').texture = texture
			
			current_block_info.normal_question.image_content = {
				'width' : image.get_width(),
				'height' : image.get_height(),
				'mipmaps' : image.has_mipmaps(),
				'format' : image.get_format(),
				'data' : image.get_data(),
			}
			root.enable_save('image content changed')

func on_question_type_change(type_name: String) -> void:
	match type_name:
		'Normal':
			current_block_info.question.type = 0
		'Matching':
			current_block_info.question.type = 1
		'Blank':
			current_block_info.question.type = 2
	current_container.get_node('Normal').visible = type_name == 'Normal'
	current_container.get_node('Matching').visible = type_name == 'Matching'
	current_container.get_node('Blank').visible = type_name == 'Blank'

func set_block(new_block: Polygon2D) -> void:
	switching = true
	current_block = new_block
	if new_block == null:
		return
	if current_container and weakref(current_container).get_ref():
		current_container.queue_free()
	current_block_info = root.GameMap.blocks[current_block.get_index() - 2]
	
	match current_block_info.type:
		'intro':
			current_container = intro_container.get_parent().duplicate().get_node('VBox')
			
			current_container.get_node("TitleBox").text = current_block_info.intro.title
			current_container.get_node("SubtitleBox").text = current_block_info.intro.subtitle
			current_container.get_node("TitleBox").connect('text_changed',self,'on_title_text_change')
			current_container.get_node("SubtitleBox").connect('text_changed',self,'on_subtitle_text_change')
		'question':
			current_container = question_container.get_parent().duplicate().get_node('VBox')
			
			for option in current_container.get_node('QuestionType/Options').get_children():
				option.connect('pressed',self,'on_question_type_change',[option.name])
			
			current_container.get_node('Limit/Input/Submission').connect('text_changed',self,'on_submission_limit_change')
			current_container.get_node('Limit/Input/Resubmission').connect('text_changed',self,'on_resubmission_limit_change')
			current_container.get_node('Limit/Input/Time').connect('text_changed',self,'on_time_limit_change')
			
			current_container.get_node('Validation/Input/Score').connect('text_changed',self,'on_score_change')
			current_container.get_node('Validation/Input/Penalty').connect('text_changed',self,'on_penalty_change')
			
			current_container.get_node('Normal/Content/ContentType').text = Main.translate(current_block_info.normal_question.content_type)
			current_container.get_node('Normal/Content/ContentType').pressed = current_block_info.normal_question.content_type == 'image'
			
			current_container.get_node('Normal/Content/TextContent').visible = current_block_info.normal_question.content_type == 'text'
			current_container.get_node('Normal/Content/ImageContent').visible = current_block_info.normal_question.content_type == 'image'
			
			current_container.get_node('Normal/Content/TextContent').text = current_block_info.normal_question.text_content
			if current_block_info.normal_question.image_content:
				var image = Image.new()
				image.create_from_data(
					current_block_info.normal_question.image_content.width,
					current_block_info.normal_question.image_content.height,
					current_block_info.normal_question.image_content.mipmaps,
					current_block_info.normal_question.image_content.format,
					current_block_info.normal_question.image_content.data
				)
				
				var texture: ImageTexture = ImageTexture.new()
				texture.create_from_image(image)
				current_container.get_node('Normal/Content/ImageContent').texture = texture
			
			current_container.get_node('Normal/Misc/MultipleChoiceButton').pressed = current_block_info.normal_question.multiple_choice
			current_container.get_node('Normal/Misc/MultipleChoiceUI').visible = current_block_info.normal_question.multiple_choice
			
			for answer_info in current_block_info.normal_question.answers:
				new_answer(answer_info.content,answer_info.correct)
			
			current_container.get_node('Normal/Content/ContentType').connect('toggled',self,'on_content_type_change')
			current_container.get_node('Normal/Content/TextContent').connect('text_changed',self,'on_text_content_change')
			current_container.get_node('Normal/Content/ImageContent/Load').connect('pressed',self,'select_image')
			
			current_container.get_node('Normal/Misc/MultipleChoiceButton').connect('toggled',self,'on_multiple_choice_enabled')
			current_container.get_node('Normal/Misc/MultipleChoiceUI/NewAnswer').connect('pressed',self,'on_new_answer_click')
	
	current_container.get_parent().show()
	add_child(current_container.get_parent())
	switching = false

func _process(delta) -> void:
	if current_block == null or weakref(current_block).get_ref() == null:
		pointer.rect_position.x = lerp(
			pointer.rect_position.x,
			-10 + blocks.global_position.x,
			min(15 * delta,1)
		)
		return
	pointer.rect_position.x = lerp(pointer.rect_position.x,-10 + 210 * (current_block.get_index() - 1) + blocks.global_position.x,min(15 * delta,1))
	if Input.is_action_pressed("ctrl") and Input.is_action_pressed("focus"):
		blocks.global_position.x = lerp(
			blocks.global_position.x,
			960 - 210 * (current_block.get_index() - 1),
			min(15 * delta,1)
		)
	
	match current_block_info.type:
		'question':
			current_container.get_node('Validation').visible = current_block_info.question.type != 0 or current_block_info.normal_question.multiple_choice
			
			current_container.get_node('QuestionType/Pointer').rect_position.x = lerp(
				current_container.get_node('QuestionType/Pointer').rect_position.x,
				270 + 560 * current_block_info.question.type,
				20 * delta
			)
			
			current_container.get_node('Limit/Input/Submission').placeholder_text = Main.translate("SUBMISSIONS: ") + String(current_block_info.question.limit.submission)
			current_container.get_node('Limit/Input/Resubmission').placeholder_text = Main.translate("RESUBMISSIONS: ") + String(current_block_info.question.limit.resubmission)
			current_container.get_node('Limit/Input/Time').placeholder_text = Main.translate("TIME (s): ") + String(current_block_info.question.limit.time)
			
			current_container.get_node('Validation/Input/Score').placeholder_text = Main.translate("SCORE: ") + String(current_block_info.question.score)
			current_container.get_node('Validation/Input/Penalty').placeholder_text = Main.translate("PENALTY: ") + String(current_block_info.question.penalty)
