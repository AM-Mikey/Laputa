extends Trigger

@export var wall_up: bool = true
@export var wall_left: bool = true
@export var wall_down: bool = true
@export var wall_right: bool = true

const WALL_THICKNESS = 8.0

func _ready() -> void:
	trigger_type = "invis_wall"
	var trigger_size = $CollisionShape2D.shape.size
	var trigger_position = $CollisionShape2D.global_position - trigger_size / 2.0
	var trigger_rect: Rect2 = Rect2(trigger_position, trigger_size)
	var trigger_rect_center = trigger_rect.get_center()

	$Up/CollisionShape2D.disabled = !wall_up
	$Up/CollisionShape2D.shape.size = Vector2(trigger_rect.size.x + WALL_THICKNESS * 2.0, WALL_THICKNESS)
	$Up.global_position = Vector2(trigger_rect_center.x, trigger_rect.position.y - WALL_THICKNESS / 2.0)

	$Down/CollisionShape2D.disabled = !wall_down
	$Down/CollisionShape2D.shape.size = Vector2(trigger_rect.size.x + WALL_THICKNESS * 2.0, WALL_THICKNESS)
	$Down.global_position = Vector2(trigger_rect_center.x, trigger_rect.end.y + WALL_THICKNESS / 2.0)

	$Left/CollisionShape2D.disabled = !wall_left
	$Left/CollisionShape2D.shape.size = Vector2(WALL_THICKNESS, trigger_rect.size.y + WALL_THICKNESS * 2.0)
	$Left.global_position = Vector2(trigger_rect.position.x - WALL_THICKNESS / 2.0, trigger_rect_center.y)

	$Right/CollisionShape2D.disabled = !wall_right
	$Right/CollisionShape2D.shape.size = Vector2(WALL_THICKNESS, trigger_rect.size.y + WALL_THICKNESS * 2.0)
	$Right.global_position = Vector2(trigger_rect.end.x + WALL_THICKNESS / 2.0, trigger_rect_center.y)

	w.emit_signal("finished_spawn_entities_step")
