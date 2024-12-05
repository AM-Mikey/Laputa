extends ColorRect

@onready var world = get_tree().get_root().get_node("World")

func _ready():
	update()



func update():
	color = get_parent().color
	
	get_parent().z_index = 100
	var col
	if get_parent().has_node("CollisionShape2D"):
		col = get_parent().get_node("CollisionShape2D")
		position = col.position - col.shape.size
		size = col.shape.size * 2
	
	visible = world.debug_visible
