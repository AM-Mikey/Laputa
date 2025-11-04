extends Prop

@export var held_item: String

func _ready():
	var _err = am.connect("interrupt_finished", Callable(self, "on_interrupt_finished"))
	if not held_item:
		expend_prop()

func activate():
	expend_prop()
	am.play("chest")
	am.play_interrupt("get_item")
	active_pc.can_input = false
	active_pc.inventory.append(held_item)
	active_pc.update_inventory()
	print("added item '", held_item, "' to inventory")

func expend_prop():
	spent = true
	$AnimationPlayer.play("Used")

func on_interrupt_finished():
	active_pc.can_input = true
