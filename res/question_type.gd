extends Resource
class_name question_type

var content_type: String = 'text'
var text_content: String = ''
var image_content: String = ''
var limit = {
	'submission' : 0,
	'time' : 0,
}
var multiple_choice: bool = false
var answers: Array = []
