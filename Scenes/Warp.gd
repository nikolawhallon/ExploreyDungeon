extends Area2D

signal entered

var sfx_entered = preload("res://Assets/Sfx/portal_a.wav")

func _ready():
	$AudioStreamPlayer2D.set_volume_db(-12.0)

func _on_Warp_body_entered(body):
	if body.is_in_group("Player"):
		if body.collected_key:
			set_collision_layer_bit(0, false)
			set_collision_mask_bit(0, false)
			body.visible = false
			body.paused = true
			$AudioStreamPlayer2D.stream = sfx_entered
			$AudioStreamPlayer2D.play()

func _on_AudioStreamPlayer2D_finished():
	emit_signal("entered")
