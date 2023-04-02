extends Node2D

signal completed
signal game_over

var rng = RandomNumberGenerator.new()

var mouse_index = null
var touch_index = null

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_F:
			spawn_fireballs()
		if event.scancode == KEY_B:
			spawn_beams()

	if event is InputEventMouseButton:
		if event.is_pressed():
			mouse_index = event.get_button_index()
			$YSort/Player.set_destination_direction(get_global_mouse_position())
		if not event.is_pressed():
			if event.get_button_index() == mouse_index:
				mouse_index = null
			$YSort/Player.set_destination_direction(null)
	if event is InputEventMouseMotion:
		if mouse_index != null:
			$YSort/Player.set_destination_direction(get_global_mouse_position())

	if event is InputEventScreenTouch:
		if event.is_pressed():
			touch_index = event.get_index()
			$YSort/Player.set_destination_direction(get_canvas_transform().xform_inv(event.get_position()))
		if not event.pressed:
			if event.get_index() == touch_index:
				touch_index = null
				$YSort/Player.destination = null
				$YSort/Player.set_destination_direction(null)
	if event is InputEventScreenDrag:
		if touch_index != null:
			$YSort/Player.set_destination_direction(get_canvas_transform().xform_inv(event.get_position()))

func _ready():
	rng.randomize()

	$CanvasLayer/MarginContainer/HBoxContainer/FireballSpell/FireballChargeBar.value = $YSort/Player.fireball_power
	$CanvasLayer/MarginContainer/HBoxContainer/BeamSpell/BeamChargeBar.value = $YSort/Player.beam_power
		
	$YSort/Player/Camera2D.limit_bottom = $YSort/Dungeon.map_h * 16
	$YSort/Player/Camera2D.limit_right = $YSort/Dungeon.map_w * 16
	
	# place the Player
	while true:
		var x = rng.randi_range(1, $YSort/Dungeon.map_w - 1)
		var y = rng.randi_range(1, $YSort/Dungeon.map_h - 1)
		if $YSort/Dungeon.is_ground(x, y):
			$YSort/Player.position = Vector2(x * 16 + 8, y * 16 + 8)
			break

	# place the Key
	var key = load("res://Scenes/Key.tscn").instance()
	add_child(key)

	while true:
		var x = rng.randi_range(1, $YSort/Dungeon.map_w - 1)
		var y = rng.randi_range(1, $YSort/Dungeon.map_h - 1)
		if $YSort/Dungeon.is_ground(x, y):
			key.position = Vector2(x * 16 + 8, y * 16 + 8)
			break

	# place the Warp
	while true:
		var x = rng.randi_range(1, $YSort/Dungeon.map_w - 1)
		var y = rng.randi_range(1, $YSort/Dungeon.map_h - 1)
		if $YSort/Dungeon.is_ground(x, y):
			$Warp.position = Vector2(x * 16 + 8, y * 16 + 8)
			break

	# place a FireballScroll
	var fireball_scroll = load("res://Scenes/FireballScroll.tscn").instance()
	add_child(fireball_scroll)

	while true:
		var x = rng.randi_range(1, $YSort/Dungeon.map_w - 1)
		var y = rng.randi_range(1, $YSort/Dungeon.map_h - 1)
		if $YSort/Dungeon.is_ground(x, y):
			fireball_scroll.position = Vector2(x * 16 + 8, y * 16 + 8)
			break

	# place a BeamScroll
	var beam_scroll = load("res://Scenes/BeamScroll.tscn").instance()
	add_child(beam_scroll)

	while true:
		var x = rng.randi_range(1, $YSort/Dungeon.map_w - 1)
		var y = rng.randi_range(1, $YSort/Dungeon.map_h - 1)
		if $YSort/Dungeon.is_ground(x, y):
			beam_scroll.position = Vector2(x * 16 + 8, y * 16 + 8)
			break

func _on_Warp_entered():
	emit_signal("completed")

func _process(_delta):
	var ghosts = get_tree().get_nodes_in_group("Ghost")
	for ghost in ghosts:
		ghost.destination = $YSort/Player.position

func _on_GhostSpawnTimer_timeout():
	var ghost = load("res://Scenes/Ghost.tscn").instance()
	add_child(ghost)

	var random_angle = rng.randf_range(0.0, 2 * PI)
	var random_distance = rng.randi_range(100, 200)
	var spawn_position = $YSort/Player.position + Vector2(cos(random_angle), sin(random_angle)) * random_distance
	ghost.position = spawn_position
	ghost.destination = $YSort/Player.position

func destroy():
	# I should check if this deletes all children
	get_tree().queue_delete(self)

func _on_Player_was_hit():
	emit_signal("game_over")

func _on_FireballButton_pressed():
	spawn_fireballs()

func spawn_fireballs():
	$YSort/Player.play_fireball_sfx()
	var direction = $YSort/Player.direction
	spawn_fireball(direction)

	if $YSort/Player.fireball_power > 33:
		spawn_fireball(direction.rotated(PI / 16.0))
		spawn_fireball(direction.rotated(-PI / 16.0))
	if $YSort/Player.fireball_power > 66:
		spawn_fireball(direction.rotated(PI / 8.0))
		spawn_fireball(direction.rotated(-PI / 8.0))

	$YSort/Player.fireball_power = clamp($YSort/Player.fireball_power - 5, 0, 100)
	$CanvasLayer/MarginContainer/HBoxContainer/FireballSpell/FireballChargeBar.value = $YSort/Player.fireball_power
	
func spawn_fireball(direction):
	var fireball = load("res://Scenes/Fireball.tscn").instance()
	# note: adding fireball as a child of just $YSort does not work, and it seems mysterious
	# https://github.com/godotengine/godot/issues/39872
	# https://www.godotforums.org/d/23501-y-sort-and-instanced-child-nodes
	# https://godotengine.org/qa/144986/intanced-children-of-ysort-node-do-not-sort-correctly
	# https://godotengine.org/qa/81429/child-node-specific-node-inside-current-scene-via-gdscript
	$YSort/Dungeon.add_child(fireball)
	fireball.global_position = $YSort/Player.global_position + direction * fireball.speed * 4.0 * 0.016
	fireball.direction = direction

func spawn_beams():
	$YSort/Player.play_beam_sfx()
	if $YSort/Player.beam_power <= 0:
		return
		
	var beam_pattern = load("res://Scenes/BeamPattern.tscn").instance()
	add_child(beam_pattern)
	beam_pattern.global_position = $YSort/Player.global_position

	$YSort/Player.beam_power = clamp($YSort/Player.beam_power - 5, 0, 100)
	$CanvasLayer/MarginContainer/HBoxContainer/BeamSpell/BeamChargeBar.value = $YSort/Player.beam_power

func _on_Player_collected_fireball_scroll():
	$CanvasLayer/MarginContainer/HBoxContainer/FireballSpell/FireballChargeBar.value = $YSort/Player.fireball_power

func _on_BeamButton_pressed():
	spawn_beams()

func _on_Player_collected_beam_scroll():
	$CanvasLayer/MarginContainer/HBoxContainer/BeamSpell/BeamChargeBar.value = $YSort/Player.beam_power
