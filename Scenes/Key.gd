extends Area2D

var sfx_collected = preload("res://Assets/Sfx/key.wav")

func _ready():
	$AudioStreamPlayer2D.set_volume_db(-12.0)

func destroy():
	get_tree().queue_delete(self)

func _on_Key_body_entered(body):
	if body.is_in_group("Player"):
		body.collected_key = true
		visible = false
		set_collision_layer_bit(0, false)
		set_collision_mask_bit(0, false)
		$AudioStreamPlayer2D.stream = sfx_collected
		$AudioStreamPlayer2D.play()

func _on_AudioStreamPlayer2D_finished():
	destroy()
