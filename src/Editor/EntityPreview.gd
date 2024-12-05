extends Node2D

var entity_path: String
var entity_type: String


func _ready():
	var entity = load(entity_path).instantiate()
	
	if entity_type == "trigger":
		z_index = 100
		$ColorRect.visible = true
		$ColorRect.color = entity.color
		if entity.has_node("CollisionShape2D"):
			var col = entity.get_node("CollisionShape2D")
			$ColorRect.position = col.position - col.shape.size
			$ColorRect.size = col.shape.size * 2
		
		
	else:
		var sprite = entity.get_node("Sprite2D")
		add_child(sprite.duplicate())
	
	entity.queue_free()
