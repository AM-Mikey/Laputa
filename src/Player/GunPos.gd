@tool
extends Marker2D

func _ready():
	set_notify_transform(true)
	set_notify_local_transform(true)

func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED or NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
		if get_parent() == null:
			return
		if get_parent().get_parent() == null:
			return
		if get_parent().get_parent().has_node("Sprite2D"):
			get_parent().get_parent().get_node("Sprite2D").set_gun_pos()
