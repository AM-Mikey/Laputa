extends Prop

@export var style: int = 0

func setup():
	$Sprite2D.frame_coords.y = style

func activate():
	if $AnimationPlayer.is_playing():
		$AnimationPlayer.stop()
	else:
		$AnimationPlayer.play("Spin")

### SIGNALS ###

func _on_PlayerDetector_body_entered(body: Node2D) -> void:
	active_players.append(body.get_parent())


func _on_PlayerDetector_body_exited(body: Node2D) -> void:
	active_players.erase(body.get_parent())
