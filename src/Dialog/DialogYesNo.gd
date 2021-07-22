extends Control


onready var db = get_parent()

func _on_Yes_pressed():
	db.seek("/dba")
	db.busy = false
	db.dialog_loop()
	queue_free()

func _on_No_pressed():
	db.seek("/dbb")
	db.busy = false
	if tb.get_line_count() > 3: #was greater than or equal to, made starting on line 3 impossible
	tb.text = ""
	dialog_loop()
	queue_free()
