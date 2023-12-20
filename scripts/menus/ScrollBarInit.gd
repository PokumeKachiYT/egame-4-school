extends ScrollContainer

func _ready():
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(1,1,1)
	stylebox.corner_radius_top_right = 250
	stylebox.corner_radius_top_left = 250
	stylebox.corner_radius_bottom_right = 250
	stylebox.corner_radius_bottom_left = 250
	
	var stylebox2 = stylebox.duplicate()
	stylebox2.bg_color = Color(0,1,1)
	
	var stylebox3 = stylebox2.duplicate()
	stylebox3.bg_color = Color(.4,.8,.8)
	
	get_v_scrollbar().add_stylebox_override('grabber',stylebox)
	get_v_scrollbar().add_stylebox_override('grabber_highlight',stylebox2)
	get_v_scrollbar().add_stylebox_override('grabber_pressed',stylebox3)
