extends Area2D

var speed = 6
var temp_position = Vector2.ZERO
var tail_segments = 0
var orientation = "right"
var fade_out = false
var fade_time = 0.5

func destroy():
	get_tree().queue_delete(self)

func set_beam_start(start_position):
	global_position = start_position
	temp_position = position

func set_orientation(o):
	orientation = o

func set_lifetime(seconds):
	if seconds < 0.05:
		fade_out = true
	else:
		$Timer.start(seconds)

func set_fade_time(seconds):
	fade_time = seconds

func _process(delta):
	if fade_out:
		modulate.a -= delta / fade_time
		if modulate.a < 0.05:
			destroy()

	if orientation == "right":
		position.x += speed
	if orientation == "left":
		position.x -= speed
	if orientation == "up":
		position.y -= speed
	if orientation == "down":
		position.y += speed
	var distance = position.distance_to(temp_position)

	# this logic is saying, every time the beam moves 4 pixels,
	# spawn 1 new beam tail segment
	# TODO: also spawn animated beam segments
	var factor_a = 4
	var factor_b = 1
	if distance > factor_a:
		for _i in range(factor_b):
			tail_segments += 1
			var tail = Sprite.new()
			tail.texture = load("res://Assets/Beam/beam_tail.png")
			add_child(tail)

			if orientation == "right":
				tail.scale.x = 1
				tail.position -= tail_segments * Vector2(factor_a, 0)
			if orientation == "left":
				tail.scale.x = -1
				tail.position += tail_segments * Vector2(factor_a, 0)
			if orientation == "up":
				tail.rotation_degrees = -90
				tail.position += tail_segments * Vector2(0, factor_a)
			if orientation == "down":
				tail.rotation_degrees = 90
				tail.position -= tail_segments * Vector2(0, factor_a)

		temp_position = position

func _on_Timer_timeout():
	fade_out = true

func _on_Beam_area_entered(area):
	if area.is_in_group("Ghost"):
		area.destroy()
