extends KinematicBody2D

var sfx_step = preload("res://Assets/Sfx/step_demon.wav")

var velocity = Vector2.ZERO
var speed = 50.0
var destination

func _ready():
	$StepSfx.set_volume_db(-48.0)

func destroy():
	get_tree().queue_delete(self)

func _physics_process(_delta):
	if destination != null:
		velocity = speed * (destination - position).normalized()

	if velocity != Vector2.ZERO:
		if !$StepSfx.playing:
			$StepSfx.stream = sfx_step
			$StepSfx.play()

	if velocity == Vector2.ZERO:
		$AnimatedSprite.animation = "idle"
	else:
		$AnimatedSprite.animation = "walk"
	
	if velocity.x > 0:
		$AnimatedSprite.scale = Vector2(-1.0, 1.0)
	elif velocity.x < 0:
		$AnimatedSprite.scale = Vector2(1.0, 1.0)

	var _returned_velocity = move_and_slide(velocity, Vector2(0, 0), false, 4, 0, false)
