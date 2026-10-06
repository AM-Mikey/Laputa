extends ProgressBar

@export var boss: Actor = null: set = set_boss

var show_position: = Vector2(0.0, 243.0)
var hide_position: = Vector2(0.0, 280.0)

var in_show_animation: bool = false

signal anim_bar_filled_finished
signal anim_bar_hide_finished

func set_boss(val: Actor):
	max_value = val.hp
	if boss and boss.hp_changed.is_connected(_on_hp_changed):
		boss.hp_changed.disconnect(_on_hp_changed)
	if val and !val.hp_changed.is_connected(_on_hp_changed):
		val.hp_changed.connect(_on_hp_changed)
	boss = val

func _ready() -> void:
	value = 0.0
	vs.scale_changed.connect(_on_viewport_scale_changed)

func show_ui():
	visible = true
	in_show_animation = true
	var tween: Tween = create_tween()
	#tween.tween_property(self, "position:y", show_position.y, 0.3)
	tween.tween_property(self, "value", max_value, 2.0)
	await tween.finished
	in_show_animation = false
	anim_bar_filled_finished.emit()

func hide_ui():
	#var tween: Tween = create_tween()
	#tween.tween_property(self, "position", hide_position, 3.0)
	#await tween.finished
	visible = false
	await get_tree().process_frame
	anim_bar_hide_finished.emit()


func _on_hp_changed() -> void:
	value = boss.hp

func _on_value_changed(value: float) -> void:
	if in_show_animation:
		am.play("npc_voice_normal")

func _on_viewport_scale_changed(rs_scale) -> void:
	print(rs_scale)
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
