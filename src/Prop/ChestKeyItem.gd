extends Prop

export var held_item: String

func _ready():
	add_to_group("LimitedProps")
	
func activate():
	expend_prop()
	am.play("chest")
	active_pc.inventory.append(held_item)
	active_pc.update_inventory()
	print("added item '", held_item, "' to inventory")

func expend_prop():
	spent = true
	$AnimationPlayer.play("Used")
