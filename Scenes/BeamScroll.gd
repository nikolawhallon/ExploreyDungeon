extends Area2D

func destroy():
	get_tree().queue_delete(self)

func _on_BeamScroll_body_entered(body):
	if body.is_in_group("Player"):
		body.collected_beam_scroll()
		destroy()
