extends Node

var level
var score = 0

var started = false
var temp_dungeon = null

func _unhandled_input(event):
	OS.window_fullscreen = true

func _input(event):
	if not started or get_tree().paused:
		if event is InputEventKey and event.pressed:
			if event.scancode == KEY_SPACE:
				restart()
		if event is InputEventMouseButton:
			if event.is_pressed():
				restart()
		if event is InputEventScreenTouch:
			if event.is_pressed():
				restart()

func _process(_delta):
	if not started or get_tree().paused:
		if Input.is_action_just_pressed("start"):
			restart()

func _ready():
	temp_dungeon = load("res://Scenes/Dungeon.tscn").instance()
	add_child(temp_dungeon)

func restart():
	if temp_dungeon != null:
		get_tree().queue_delete(temp_dungeon)
		temp_dungeon = null
	if not started:
		started = true
		$CanvasLayer/StartLabel.visible = false
	if get_tree().paused:
		get_tree().paused = false
		$CanvasLayer/RetryLabel.visible = false
	if level != null:
		level.destroy()
	score = 0
	$CanvasLayer/MarginContainer/HBoxContainer/Level.text = "LEVEL: " + str(score)
	init_level()

func init_level():
	level = load("res://Scenes/Level.tscn").instance()
	call_deferred("add_child", level)
	level.connect("completed", self, "_on_Level_completed")
	level.connect("game_over", self, "_on_Level_game_over")

func _on_Level_completed():
	level.destroy()
	score += 1
	$CanvasLayer/MarginContainer/HBoxContainer/Level.text = "LEVEL: " + str(score)
	init_level()

func _on_Level_game_over():
	# currently I pause the whole level, but it might be cool
	# to have finer control, so that things like lit torch
	# animations can continue to occur
	get_tree().paused = true
	$CanvasLayer/RetryLabel.visible = true
