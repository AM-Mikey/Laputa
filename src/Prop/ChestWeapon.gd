extends Prop

export var weapon_name: String
var weapon

func _ready():
	add_to_group("LimitedProps")
	weapon = load("res://src/Weapon/%s" % weapon_name + ".tres")

func activate():
	expend_prop()
	am.play("chest")
	active_pc.weapon_array.push_front(weapon)
	active_pc.get_node("WeaponManager").update_weapon()
	print("added weapon '", weapon_name, "' to inventory")

func expend_prop():
	spent = true
	$AnimationPlayer.play("Used")
