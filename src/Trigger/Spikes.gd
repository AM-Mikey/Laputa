extends Area2D


func _on_Spikes_body_entered(body):
	body.is_in_spikes = true
	body.hit(2, Vector2.ZERO)


func _on_Spikes_body_exited(body):
	body.is_in_spikes = false
