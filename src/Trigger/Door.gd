extends Trigger

const TRANSITION = preload("res://src/Effect/Transition/TransitionIris.tscn")
const LOCKED = preload("res://src/Effect/Locked.tscn")

signal level_change(level, door_index)

@export var same_level := false
@export_file("*.tscn") var level: String
@export var door_index: int = 0
@export var same_level_next_index: int = 0
@export var locked = false
@export var key_id = ""
@export var eat_key = true

var inspect_time = 0.5

func _ready():
	var _err = connect("level_change", Callable(w, "change_level_via_trigger"))
	trigger_type = "door"
	w.emit_signal("finished_spawn_entities_step")

func player_interact(p: Player):
	if !p.is_on_floor(): return # Is this check REALLY needed? -nero
	if !locked || spent:
		enter_door(p)
	else:
		var has_key := false
		var key_index: int
		for i in p.item_array:
			if i.type == "key" && i.id == key_id:
				has_key = true
				key_index = p.item_array.find(i)
				continue
		if has_key:
			if eat_key == true:
				p.item_array.remove_at(key_index)
			spent = true
			locked = false
			enter_door(p)
		else:
			var locked_effect = LOCKED.instantiate()
			locked_effect.global_position = $CollisionShape2D.global_position
			w.farthest_front.add_child(locked_effect)
			#inspect
			var previous_look_dir = p.look_dir
			p.mm.change_state("inspect")
			p.inspect_target = $CollisionShape2D
			await get_tree().create_timer(inspect_time, false, true).timeout
			p.mm.change_state("run")
			p.look_dir = previous_look_dir

func enter_door(p: Player):
	inp.can_act = false
	p.inspect_target = self
	p.mm.change_state("inspect")
	p.move_to(global_position + Vector2($CollisionShape2D.shape.size.x * 0.5, $CollisionShape2D.shape.size.y))
	am.play("door")
	var transition = TRANSITION.instantiate()
	if w.bl.has_node("TransitionIris"):
		w.bl.get_node("TransitionIris").free()
	w.bl.add_child(transition)
	await transition.get_node("AnimationPlayer").animation_finished
	p.mm.change_state("run")

	if same_level:
		emit_signal("level_change", w.current_level.scene_file_path, same_level_next_index)
	else:
		#var level_path = str("res://src/Level/" + level + ".tscn")
		#if !FileAccess.file_exists(l):
			#printerr("ERROR: No Level With Name: ", level)
			#return
		emit_signal("level_change", level, door_index)

func expend_trigger():
	spent = true
