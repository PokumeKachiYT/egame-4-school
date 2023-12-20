extends Button

onready var root = get_parent().get_parent()

func on_click() -> void:
	root.get_node('ControlScreen/Controls').get_node('question').hide()
	root.get_node('ControlScreen/Controls').get_node('intro').hide()
	if root.state == 'proceedable':
		root.state = 'none'
		if root.current_block_index > -1:
			if root.current_block_info.type == 'question' or root.current_block_info.type == 'intro':
				for client in root.clients:
					root.send_data(client,{'info_type':'end'})
				yield(get_tree().create_timer(.5),"timeout")
		
		root.current_block_index += 1
		
		if root.current_block_index == root.GameMap.blocks.size():
			root.state = 'ending'
		else:
			root.current_block_info = root.GameMap.blocks[root.current_block_index]
			root.state = 'transition'

func _ready() -> void:
	connect('button_up',self,'on_click')

func _process(delta):
	rect_position.x = lerp(rect_position.x,860 if root.state == 'proceedable' else 960,10 * delta)
