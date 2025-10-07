extends Prop

@export var gun_name: String
var gun

func _ready():
	gun = load("res://src/Gun/%s" % gun_name + ".tres")

func activate():
	expend_prop()
	am.play("chest")
	am.play_interrupt("get_item")
	active_pc.get_node("GunManager/Guns").add_child(gun)
	active_pc.emit_signal("guns_updated", active_pc.guns.get_children())
	print("added gun '", gun_name, "' to inventory")

func expend_prop():
	spent = true
	$AnimationPlayer.play("Used")
