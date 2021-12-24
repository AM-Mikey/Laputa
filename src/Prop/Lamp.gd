extends Prop

export var style: int = 0


func _ready():
	$Sprite.frame_coords.y = style


func _on_body_entered(body):
	active_pc = body

func _on_body_exited(_body):
	active_pc = null
	

func _input(event):
	if event.is_action_pressed("inspect") and active_pc != null:
		if not active_pc.disabled:
			toggle_lamp()


func toggle_lamp():
	$SFX.play()
	if $Sprite.frame_coords.x == 0:
		$Sprite.frame_coords.x = 1
		$Light2D.enabled = true
	elif $Sprite.frame_coords.x == 1:
		$Sprite.frame_coords.x = 0
		$Light2D.enabled = false
