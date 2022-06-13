extends Area2D

signal entered

func _on_Warp_body_entered(body):
	if body.is_in_group("Player"):
		if body.collected_key:
			emit_signal("entered")
