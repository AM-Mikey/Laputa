extends Control

var text: String
@onready var world = get_tree().get_root().get_node("World")

func _ready():
	$Label.text = text
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)



### SIGNALS ###

func _on_Timer_timeout():
	$AnimationPlayer.play("Fadeout")

func _on_AnimationPlayer_animation_finished(_anim_name):
	queue_free()

func _resolution_scale_changed(resolution_scale):
	size = get_tree().get_root().size / resolution_scale
