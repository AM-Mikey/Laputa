extends State


func _on_Timer_timeout() -> void:
	main.fire(main.look_dir)
