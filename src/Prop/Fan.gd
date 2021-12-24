extends Prop

export var style: int = 0

func _ready():
	$Sprite.frame_coords.y = style


func _on_body_entered(body):
	active_pc

func _on_body_exited(_body):
	active_pc = null
	

func _input(event):
	if event.is_action_pressed("inspect") and active_pc != null:
		if not active_pc.disabled:
			toggle_fan()


func toggle_fan():
	$ClickSound.play()
	if $AnimationPlayer.is_playing():
		$AnimationPlayer.stop()
	else:
		$AnimationPlayer.play("Spin")
