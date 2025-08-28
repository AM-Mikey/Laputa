extends Prop

func on_break(method):
	am.play("break_block")
	queue_free()
