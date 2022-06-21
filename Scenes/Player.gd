extends KinematicBody2D

signal was_hit

export var speed = 100
var velocity = Vector2(0, 0)
var direction = Vector2(1, 0)
var collected_key = false

func _physics_process(_delta):
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

	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		if get_global_mouse_position().distance_to(global_position) > 2:
			velocity = speed * (get_global_mouse_position() - global_position).normalized()

	if velocity != Vector2.ZERO:
		direction = velocity.normalized()

	var _returned_velocity = move_and_slide(velocity, Vector2(0, 0), false, 4, 0, false)

func was_hit():
	emit_signal("was_hit")
	visible = false
