extends Control

var text
onready var world = get_tree().get_root().get_node("World")

func _ready():
	get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
	_on_viewport_size_changed()
	
	$MarginContainer/Label.text = text
	
func _on_viewport_size_changed():
	$MarginContainer.rect_size = get_tree().get_root().size / world.resolution_scale


func _on_Timer_timeout():
	$AnimationPlayer.play("Fadeout")

func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()