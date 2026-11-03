extends Prop

signal switch_toggled(toggled)
signal switch_activated
signal switch_timer_start
signal switch_timer_timeout


const ICON = preload("res://assets/Prop/SwitchPlateIcon.png")
enum SwitchType {TOGGLE, IMPULSE, TIMER}

@export var connected_entity_id : String
var toggled = false
@export var switch_type := SwitchType.TOGGLE
@export var toggle_on_player := true
@export var toggle_on_enemies := false
@export var toggle_on_npcs := false
@export var timer_duration := 1.0

var triggering_entities := []
var connected_entities := []
var switch_siblings := [] #NOTE this only works for toggle switches right now


func setup(): #Reminder: no function called can use await before finishing entities step
	w.emit_signal("finished_spawn_entities_step") #NOTE we say this is finished immediately so we can be the LAST loaded props, this is why we then need to await four times
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	for e in get_tree().get_nodes_in_group("Entities"):
		if e.is_in_group("EditorEntities"):
			return
		if "id" in e:
			if e.id.nocasecmp_to(connected_entity_id) == 0:
				connected_entities.append(e)
	for c in connected_entities:
		match switch_type:
			SwitchType.TOGGLE:
				connect("switch_toggled", Callable(c, "on_switch_toggled"))
			SwitchType.IMPULSE:
				connect("switch_activated", Callable(c, "on_switch_activated"))
			SwitchType.TIMER:
				connect("switch_timer_start", Callable(c, "on_switch_timer_start"))
				connect("switch_timer_timeout", Callable(c, "on_switch_timer_timeout"))

	await get_tree().process_frame #to set connected entity
	switch_siblings = get_switch_siblings()


func get_switch_siblings() -> Array:
	var out = []
	for s in get_tree().get_nodes_in_group("Switches"):
		if s != self && s.connected_entity_id == connected_entity_id && connected_entity_id != null:
			if s.is_in_group("SwitchLevers") ||  s.is_in_group("SwitchCrystals"):
				printerr("ERROR: CANNOT USE MIXED PLATE + LEVER OR CRYSTAL AS SWITCH SIBLINGS")
			if switch_type == SwitchType.TOGGLE:
				out.append(s)
			else:
				printerr("ERROR, switch ", self, " and switch ", s, " have same connected_entity_id: ", connected_entity_id)
				breakpoint
	return out


func activate(stepping_on = true):
	ms.mission_progress_check(id)
	var pushed_down = !triggering_entities.is_empty()

	match switch_type:
		SwitchType.TOGGLE:
			#sibling code
			for s in switch_siblings:
				s.toggled = toggled
				if s.is_in_group("SwitchPlates"):
					if pushed_down: s.get_node("AnimationPlayer").play("Down")
					else: s.get_node("AnimationPlayer").play("Up")
			#self code
			if pushed_down: $AnimationPlayer.play("Down")
			else: $AnimationPlayer.play("Up")
			toggled = pushed_down
			emit_signal("switch_toggled", toggled)
		SwitchType.IMPULSE:
			if stepping_on:
				$AnimationPlayer.play("Impulse")
				emit_signal("switch_activated")
		SwitchType.TIMER:
			if pushed_down && $Timer.is_stopped():
				toggled = true
				$AnimationPlayer.play("Down")
				emit_signal("switch_timer_start")
				$Timer.start(timer_duration)
				await $AnimationPlayer.animation_finished
				$AnimationPlayer.play("Timer")

func _do_click():
	am.play("switch_lever_down", null, null, 0.8, 0)
	if f.pc():
		f.pc().get_node("PlayerCamera").shake(2, 0.4, 0.2)
func _do_release():
	am.play("switch_lever_up", null, null, 0.4, 0)
	oup.vibrate_impulse(0.2, 0.2)
func _do_tick():
	am.play("switch_timer", self, null, 1.0, 0)
	oup.vibrate_impulse_light(0.2, 0.1)

func is_interactable(_p: Player):
	return false # Should be stepped on instead of inspected!

### SIGNALS ###

func _on_PlayerDetector_body_entered(body: Node2D):
	active_players.append(body.get_parent())

func _on_PlayerDetector_body_exited(body: Node2D):
	active_players.erase(body.get_parent())


func _on_Timer_timeout():
	toggled = false
	$AnimationPlayer.play("Up")
	emit_signal("switch_timer_timeout")
	if triggering_entities.size() != 0:
		activate()

func _on_EntityDetector_body_entered(body: Node2D):
	if (body.get_collision_layer_value(1) && toggle_on_player) \
	|| (body.get_collision_layer_value(2) && toggle_on_enemies) \
	|| (body.get_collision_layer_value(8) && toggle_on_npcs):
		var entities_before = triggering_entities.size()
		triggering_entities.append(body.get_parent())
		if entities_before == 0:
			activate()

func _on_EntityDetector_body_exited(body: Node2D):
	if (body.get_collision_layer_value(1) && toggle_on_player) \
	|| (body.get_collision_layer_value(2) && toggle_on_enemies) \
	|| (body.get_collision_layer_value(8) && toggle_on_npcs):
		triggering_entities.erase(body.get_parent())
		activate(false)
