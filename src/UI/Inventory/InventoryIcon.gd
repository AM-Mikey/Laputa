extends MarginContainer

var type: String

func _ready():
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)
	$AnimationPlayer.play(type)

func _on_AnimationPlayer_animation_finished(_anim_name):
	pass
	#queue_free()

func _resolution_scale_changed(resolution_scale):
	set_deferred("size", get_tree().get_root().size / resolution_scale)
