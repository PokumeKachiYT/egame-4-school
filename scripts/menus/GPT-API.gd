tool

extends Node2D

const API_KEY = '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'
const API_LINK = 'https://api.openai.com/v1/chat/completions'
const headers = PoolStringArray(['Authorization: Bearer ' + API_KEY,'Content-Type: application/json'])

var body = {
	'model' : 'gpt-3.5-turbo-1106',
	'messages' : [],
	'temperature' : 0
}
var http_request: HTTPRequest = HTTPRequest.new()

func append_message(role: String,content: String) -> void:
	body.messages.append({'role' : role,'content' : content})

func request_completed(result,response_code,headers,body) -> void:
	var response = parse_json(body.get_string_from_utf8())
	
	for choice in response.choices:
		print("ChatGPT response: " + choice.message.content)

func _ready():
	add_child(http_request)
	http_request.connect('request_completed',self,'request_completed')
	
	append_message('system',"I'm a singer")
	append_message('user','Tell me the lyrics of a song')
	
	var error = http_request.request(API_LINK,headers,true,HTTPClient.METHOD_POST,to_json(body))
