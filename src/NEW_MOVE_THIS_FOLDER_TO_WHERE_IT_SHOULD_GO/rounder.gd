extends Node2D

@onready var child: Node2D = get_child(0)

func _process(_delta: float) -> void:
	var offset := self.global_position.round() - self.global_position
	child.position = offset
	$"../../..".position = offset * vs.resolution_scale - Vector2(10,10)
