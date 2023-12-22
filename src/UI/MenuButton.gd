extends Button

func _ready():
	var _err = connect("pressed", Callable(self.owner, "_on_" + name.to_lower()))
#	var _err2 = connect("focus_entered", self, "_on_focus_entered", [])

func _on_pressed():
	am.play("ui_accept")

func _on_focus_entered():
	am.play("ui_move")

#func _notification(notif):
#	if notif == NOTIFICATION_FOCUS_ENTER:
#		am.call_deferred("play", "ui_move")
