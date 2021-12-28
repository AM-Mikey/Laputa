extends Prop

export var held_item: String

func _ready():
	add_to_group("LimitedProps")
	var _err = am.connect("interrupt_finished", self, "on_interrupt_finished")
	
func activate():
	expend_prop()
	am.play("chest")
	am.play_interrupt("get_item")
	active_pc.disable()
	active_pc.inventory.append(held_item)
	active_pc.update_inventory()
	print("added item '", held_item, "' to inventory")

func expend_prop():
	spent = true
	$AnimationPlayer.play("Used")

func on_interrupt_finished():
	active_pc.enable()
