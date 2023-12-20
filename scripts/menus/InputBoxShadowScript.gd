extends TextEdit

func _process(delta):
	text = get_parent().text
	set_v_scroll(get_parent().scroll_vertical)
