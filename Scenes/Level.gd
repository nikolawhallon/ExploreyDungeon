extends Node2D

signal completed
signal game_over

var rng = RandomNumberGenerator.new()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_F:
			var fireball = load("res://Scenes/Fireball.tscn").instance()
			add_child(fireball)

			fireball.position = $Player.position
			fireball.direction = $Player.direction

func _ready():
	rng.randomize()

	$Player/Camera2D.limit_bottom = $Dungeon.map_h * 16
	$Player/Camera2D.limit_right = $Dungeon.map_w * 16
	
	# place the Player
	while true:
		var x = rng.randi_range(1, $Dungeon.map_w - 1)
		var y = rng.randi_range(1, $Dungeon.map_h - 1)
		if $Dungeon.is_ground(x, y):
			$Player.position = Vector2(x * 16 + 8, y * 16 + 8)
			break

	# place the Key
	var key = load("res://Scenes/Key.tscn").instance()
	add_child(key)

	while true:
		var x = rng.randi_range(1, $Dungeon.map_w - 1)
		var y = rng.randi_range(1, $Dungeon.map_h - 1)
		if $Dungeon.is_ground(x, y):
			key.position = Vector2(x * 16 + 8, y * 16 + 8)
			break

	# place the Warp
	while true:
		var x = rng.randi_range(1, $Dungeon.map_w - 1)
		var y = rng.randi_range(1, $Dungeon.map_h - 1)
		if $Dungeon.is_ground(x, y):
			$Warp.position = Vector2(x * 16 + 8, y * 16 + 8)
			break

func _on_Warp_entered():
	emit_signal("completed")

func _process(_delta):
	var ghosts = get_tree().get_nodes_in_group("Ghost")
	for ghost in ghosts:
		ghost.destination = $Player.position

func _on_GhostSpawnTimer_timeout():
	var ghost = load("res://Scenes/Ghost.tscn").instance()
	add_child(ghost)

	var random_angle = rng.randf_range(0.0, 2 * PI)
	var random_distance = rng.randi_range(100, 200)
	var spawn_position = $Player.position + Vector2(cos(random_angle), sin(random_angle)) * random_distance
	ghost.position = spawn_position
	ghost.destination = $Player.position

func destroy():
	# I should check if this deletes all children
	get_tree().queue_delete(self)

func _on_Player_was_hit():
	emit_signal("game_over")
