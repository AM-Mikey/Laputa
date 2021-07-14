extends Control

var animation: String

onready var world = get_tree().get_root().get_node("World")

func _ready():
		get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
		_on_viewport_size_changed()
		$AnimationPlayer.play(animation)
	
	
	
	
	
func _on_viewport_size_changed():
	
	#we need to scale both x and y to the largest distance from an edge,
	#if we spawn the transition on recruit directly, we can calculate this
	
	#$MarginContainer.rect_size = Vector2(100, 100)
	
	
	print("ggps: ", get_global_position())
	var x_distance = rect_position.x - get_tree().get_root().size.x / world.resolution_scale / 2
	var y_distance = rect_position.y - get_tree().get_root().size.y / world.resolution_scale / 2
#	var x_distance = get_global_position().x - get_tree().get_root().size.x / world.resolution_scale / 2
#	var y_distance = get_global_position().y - get_tree().get_root().size.y / world.resolution_scale / 2

	var distance_from_edge = max(abs(x_distance), abs(y_distance)) 
	print("distance from edge: ", distance_from_edge)
	$MarginContainer.rect_size = Vector2(distance_from_edge, distance_from_edge) *  world.resolution_scale #2 *
	print("rect size: ", $MarginContainer.rect_size)
	
#	if get_tree().get_root().size.x >+ get_tree().get_root().size.y:
#		$MarginContainer.rect_size.x = get_tree().get_root().size.x / world.resolution_scale
#		$MarginContainer.rect_size.y = get_tree().get_root().size.x / world.resolution_scale
#	elif get_tree().get_root().size.x < get_tree().get_root().size.y:
#		$MarginContainer.rect_size.x = get_tree().get_root().size.y / world.resolution_scale
#		$MarginContainer.rect_size.y = get_tree().get_root().size.y / world.resolution_scale


func _on_AnimationPlayer_animation_finished(anim_name):
	#pass
	queue_free()
