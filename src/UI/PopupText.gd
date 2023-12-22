extends Control

var text: String
@onready var world = get_tree().get_root().get_node("World")

func _ready():
	var _err = get_tree().root.connect("size_changed", Callable(self, "on_viewport_size_changed"))
	on_viewport_size_changed()
	
	$Label.text = text


func _on_Timer_timeout():
	$AnimationPlayer.play("Fadeout")

func _on_AnimationPlayer_animation_finished(_anim_name):
	queue_free()


func on_viewport_size_changed():
	size = get_tree().get_root().size / world.resolution_scale
