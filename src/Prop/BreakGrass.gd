extends Prop

func _ready():
	editor_hidden = true

func on_break(method):
	if method == "fire":
		$AnimationPlayer.play("Burn")
	else:
		$AnimationPlayer.play("Cut")
