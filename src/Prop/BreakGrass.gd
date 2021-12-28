extends Prop

func on_break(method):
	if method == "fire":
		$AnimationPlayer.play("Burn")
	else:
		$AnimationPlayer.play("Cut")
