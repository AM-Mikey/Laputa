extends Button

func _ready():
	var _err = connect("pressed", self.owner, "_on_" + name.to_lower())

func _on_pressed():
	am.play("ui_accept")

func _on_focus_entered():
	am.play("ui_move")
