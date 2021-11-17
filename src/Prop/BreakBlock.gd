extends StaticBody2D

func on_break(method):
	$BreakSound.play()
	yield($BreakSound, "finished")
	queue_free()
