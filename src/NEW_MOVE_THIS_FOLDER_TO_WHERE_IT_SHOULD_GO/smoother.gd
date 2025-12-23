extends Node2D

@export var follower: Node2D

func _process(delta: float) -> void:
	follower.global_position = exp_decay(follower.global_position,self.global_position, 5, delta)

func exp_decay(a, b, decay, delta):
	return b+(a-b)*exp(-decay*delta)
