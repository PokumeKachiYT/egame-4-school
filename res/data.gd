extends Resource
class_name DataLoader

export var blocks:Array = [block.new()]

func save_data(path:String) -> void:
	ResourceSaver.save(path,self)

func save_exists(path:String) -> bool:
	return ResourceLoader.exists(path)

func load_data(path:String) -> Resource:
	return load(path)
