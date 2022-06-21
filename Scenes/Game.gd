extends Node

var level
var score = 0

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_SPACE:
			if get_tree().paused:
				get_tree().paused = false
				level.destroy()
				score = 0
				$CanvasLayer/MarginContainer/HBoxContainer/Level.text = "LEVEL: " + str(score)
				init_level()

func _ready():
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
