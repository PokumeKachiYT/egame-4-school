extends Resource
class_name block

class hehe:
	var type: String

static func new():
	return {
		'type' : 'intro',
		'normal_question' : {
			'content_type' : 'text',
			'text_content' : '',
			'image_content' : null,
			'multiple_choice' : false,
			'answers' : [],
		},
		'question' : {
			'type' : 0,
			# 0 - normal
			# 1 - matching
			# 2 - blank filling
			'limit' : {
				'submission' : 0,
				'resubmission' : 0,
				'time' : 0,
			},
			'auto_validation' : true,
			'score' : 5,
			'penalty' : 5,
		},
		'intro' : {
			'title' : '',
			'subtitle' : '',
		}
	}
