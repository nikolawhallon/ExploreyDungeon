extends KinematicBody2D

signal was_hit
signal collected_fireball_scroll
signal collected_beam_scroll

var sfx_fireball = preload("res://Assets/Sfx/fire.wav")
var sfx_beam = preload("res://Assets/Sfx/beam.wav")
var sfx_step = preload("res://Assets/Sfx/step_player.wav")

export var speed = 70
export var paused = false
var velocity = Vector2(0, 0)
var direction = Vector2(-1, 0)
var collected_key = false

var destination_direction = null

var fireball_power = 100
var beam_power = 100

func _ready():
	$FireballSfx.set_volume_db(-12.0)
	$BeamSfx.set_volume_db(-12.0)
	$StepSfx.set_volume_db(-48.0)

func set_destination_direction(click_touch_global_position):
	if paused:
		return

	if click_touch_global_position != null:
		destination_direction = (click_touch_global_position - global_position)
	else:
		destination_direction = null

func _physics_process(_delta):
	if paused:
		return

	if Input.is_key_pressed(KEY_W):
		velocity.y = -speed
	elif Input.is_key_pressed(KEY_S):
		velocity.y = speed
	else:
		velocity.y = 0

	if Input.is_key_pressed(KEY_A):
		velocity.x = - speed
	elif Input.is_key_pressed(KEY_D):
		velocity.x = speed
	else:
		velocity.x = 0

	if destination_direction != null:
		if destination_direction.length() > 2:
			velocity = speed * destination_direction.normalized()

	if velocity != Vector2.ZERO:
		direction = velocity.normalized()
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

func was_hit():
	if paused:
		return

	emit_signal("was_hit")
	visible = false

func collected_fireball_scroll():
	if paused:
		return

	fireball_power = clamp(fireball_power + 50, 0, 100)
	emit_signal("collected_fireball_scroll")

func collected_beam_scroll():
	if paused:
		return

	beam_power = clamp(beam_power + 50, 0, 100)
	emit_signal("collected_beam_scroll")

func play_fireball_sfx():
	if paused:
		return

	if $FireballSfx.playing:
		$FireballSfx.stop()
	$FireballSfx.stream = sfx_fireball
	$FireballSfx.play()

func play_beam_sfx():
	if paused:
		return

	if $BeamSfx.playing:
		$BeamSfx.stop()
	$BeamSfx.stream = sfx_beam
	$BeamSfx.play()
