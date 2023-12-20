extends Node

var localization = {
	'TITLE': 'TIÊU ĐỀ',
	'SUBTITLE': 'PHỤ ĐỀ',
	
	'QUESTION TYPE' : 'LOẠI CÂU HỎI',
	'NORMAL' : 'THƯỜNG',
	'MATCHING' : 'NỐI',
	'FILL IN THE BLANKS' : 'ĐIỀN VÀO CHỖ TRỐNG',
	
	'LIMIT' : 'GIỚI HẠN',
	'SUBMISSIONS: ' : 'BÀI NỘP: ',
	'RESUBMISSIONS: ' : 'NỘP LẠI: ',
	'TIME (s): ' : 'THỜI GIAN (giây): ',
	
	'VALIDATION' : 'CHẤM ĐIỂM',
	'MANUAL' : 'THỦ CÔNG',
	'SCORE: ' : 'ĐIỂM CỘNG: ',
	'PENALTY: ' : 'ĐIỂM TRỪ: ',
	
	'CONTENT' : 'NỘI DUNG',
	'text' : 'chữ',
	'image' : 'hình ảnh',
	
	'MISC' : 'KHÁC',
	
	'MULTIPLE CHOICE' : 'TRẮC NGHIỆM',
	
	'HOSTING...' : 'ĐANG TỔ CHỨC...',
	'FAILED TO HOST GAME' : 'TỔ CHỨC THẤT BẠI',
	'HOSTED ON PORT ' : 'ĐÃ TỔ CHỨC TRÊN CỔNG ',
	
	'CLOSE SUBMISSION' : 'ĐÓNG CÂU HỎI',
	
	'[EMPTY SUBMISSION]' : '[TRỐNG]',
	'APPLY SCORE' : 'ÁP DỤNG',
}

func translate(input_string: String) -> String:
	if ProjectSettings.get('lang') == 'eng' or not localization.has(input_string):
		return input_string
	return localization[input_string]

func get_all_children(node) -> Array:
	var nodes : Array = []

	for N in node.get_children():
		nodes.append(N)
		if N.get_child_count() > 0:
			nodes.append_array(get_all_children(N))

	return nodes
