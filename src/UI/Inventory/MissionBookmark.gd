@tool
class_name MissionBookmark
extends Control

signal mission_selected(mission: SideMission)

enum BannerColor { BLUE, RED } # NOTE: The order matters!

const BANNER_HEIGHT := 17.0
const BANNER_WIDTH := 133.0
const SELECTED_OFFSET_SIZE := 24.0

const SELECT_MOVE_DURATION := 0.15

# Mission-complete sequence
const CROSSOUT_DURATION := 0.2
const COMPLETE_MOVE_DURATION := 0.3
const COMPLETE_FADE_DURATION := 0.1
const APPEAR_FADE_DURATION := 0.2

@export var banner_color: BannerColor = BannerColor.RED:
	set(value):
		banner_color = value
		if _panel_style and _atlas:  # only exist once _ready() has run
			_apply_banner_color()

@onready var button: Button = $Button
@onready var margin_container: MarginContainer = $MarginContainer
@onready var label: RichTextLabel = $MarginContainer/Label
@onready var color_rect: ColorRect = $MarginContainer/Label/ColorRect

var mission_data: SideMission
var is_selected := false
var animation_pending := false

var _tween: Tween
var _crossout_tween: Tween
var _atlas: AtlasTexture
var _panel_style: StyleBoxTexture


func _ready() -> void:
	_panel_style = get_theme_stylebox("panel").duplicate() as StyleBoxTexture
	_atlas = (_panel_style.texture as AtlasTexture).duplicate()
	_panel_style.texture = _atlas
	add_theme_stylebox_override("panel", _panel_style)

	color_rect.size.x = 0
	color_rect.visible = false
	_apply_banner_color()


func setup(mission: SideMission, selected := false, pending_animation := false) -> void:
	mission_data = mission
	animation_pending = pending_animation
	is_selected = selected
	label.text = mission.display_name
	custom_minimum_size.x = _get_width()
	update_status(mission)


func select() -> void:
	is_selected = true
	_move_to(_get_width())


func deselect() -> void:
	is_selected = false
	_move_to(_get_width())


func update_status(mission: SideMission) -> void:
	if mission.status == SideMission.Status.COMPLETE:
		banner_color = BannerColor.BLUE
		if animation_pending:
			color_rect.visible = false
			_set_crossout_length(0.0)
		else:
			color_rect.visible = true
			_set_crossout_length(float(label.get_content_width()))
	else:
		banner_color = BannerColor.RED
		color_rect.visible = false


func start_complete_animation() -> void:
	is_selected = false
	button.disabled = true
	await _animate_crossout(CROSSOUT_DURATION)
	await _move_to_and_wait(0.0, COMPLETE_MOVE_DURATION)
	await _fade()


func appear_animation() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, APPEAR_FADE_DURATION)


func _offset(amount: float) -> void:
	_restart_tween()
	_tween.tween_property(self, "position:y", position.y - amount, COMPLETE_FADE_DURATION)
	await _tween.finished


func _apply_banner_color() -> void:
	_set_banner_y(banner_color * BANNER_HEIGHT)
	label.theme_type_variation = "BookmarkText" + BannerColor.keys()[banner_color].capitalize()


func _set_banner_y(y: float) -> void:
	if _panel_style == null or _atlas == null:
		return
	var region := _atlas.region
	region.position.y = y
	_atlas.region = region
	_panel_style.emit_changed()


func _set_crossout_length(length: float) -> void:
	color_rect.position.x = 0
	color_rect.size.x = length


func _animate_crossout(duration: float) -> void:
	if _crossout_tween and _crossout_tween.is_running():
		_crossout_tween.kill()

	color_rect.visible = true
	_set_crossout_length(0.0)

	_crossout_tween = create_tween()
	_crossout_tween.tween_property(color_rect, "size:x", float(label.get_content_width()), duration)
	await _crossout_tween.finished


func _get_width() -> float:
	return BANNER_WIDTH - SELECTED_OFFSET_SIZE if is_selected else BANNER_WIDTH


func _restart_tween() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()


func _move_to(target_x: float, duration := SELECT_MOVE_DURATION) -> void:
	var start_x := custom_minimum_size.x
	_restart_tween()
	# Tween by integer amounts so that the sprite doesn't look weird
	_tween.tween_method(func(t: float) -> void:
		custom_minimum_size.x = floorf(lerpf(start_x, target_x, t)),
		0.0, 1.0, duration).set_ease(Tween.EASE_OUT)


func _move_to_and_wait(target_x: float, duration: float) -> void:
	_move_to(target_x, duration)
	await _tween.finished


func _fade() -> void:
	_restart_tween()
	_tween.tween_property(self, "modulate:a", 0.0, COMPLETE_FADE_DURATION)
	await _tween.finished


func _on_Button_pressed() -> void:
	mission_selected.emit(mission_data)
