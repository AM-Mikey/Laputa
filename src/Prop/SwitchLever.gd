extends Prop

signal switch_toggled(toggled)
signal switch_activated
signal switch_timer_start
signal switch_timer_timeout


const ICON = preload("res://assets/Prop/SwitchLeverIcon.png")
enum SwitchType {TOGGLE, IMPULSE, TIMER}

@export var connected_entity_id : String
var toggled = false
@export var switch_type := SwitchType.TOGGLE
@export var timer_duration := 1.0

var connected_entity : Node


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
			if e.id == connected_entity_id:
				connected_entity = e
				set_switch_toggled_from_connected_entity()
	match switch_type:
		SwitchType.TOGGLE:
			connect("switch_toggled", Callable(connected_entity, "on_switch_toggled"))
		SwitchType.IMPULSE:
			connect("switch_activated", Callable(connected_entity, "on_switch_activated"))
		SwitchType.TIMER:
			connect("switch_timer_start", Callable(connected_entity, "on_switch_timer_start"))
			connect("switch_timer_timeout", Callable(connected_entity, "on_switch_timer_timeout"))



func set_switch_toggled_from_connected_entity(): #only do this kinda level setup for toggle switches
	toggled = connected_entity.toggled
	match switch_type:
		SwitchType.TOGGLE:
			if toggled:
				$AnimationPlayer.play("PresetDown")
			else:
				$AnimationPlayer.play("PresetUp")

func activate():
	ms.mission_progress_check(id)
	match switch_type:
		SwitchType.TOGGLE:
			toggled = !toggled
			if toggled:
				$AnimationPlayer.play("Down")
			else:
				$AnimationPlayer.play("Up")
			emit_signal("switch_toggled", toggled)
		SwitchType.IMPULSE:
			$AnimationPlayer.play("Pull")
			emit_signal("switch_activated")
		SwitchType.TIMER:
			if !toggled:
				toggled = true
				$AnimationPlayer.play("Down")
				emit_signal("switch_timer_start")
				$Timer.start(timer_duration)
				await $AnimationPlayer.animation_finished
				$AnimationPlayer.play("Timer")

func _do_click():
	am.play("switch_lever_down", null, null, 0.8, 0)
func _do_release():
	am.play("switch_lever_up", null, null, 0.4, 0)

func _do_tick():
	am.play("switch_timer", self, null, 1.0, 0)

### SIGNALS ###

func _on_PlayerDetector_body_entered(body: Node2D):
	active_players.append(body.get_parent())

func _on_PlayerDetector_body_exited(body: Node2D):
	active_players.erase(body.get_parent())


func _on_Timer_timeout():
	toggled = false
	$AnimationPlayer.play("Up")
	emit_signal("switch_timer_timeout")
