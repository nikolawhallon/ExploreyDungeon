extends Node2D

var iterations = 0
var max_iterations = 3

func _ready():
	$BeamRight.set_orientation("right")
	$BeamRight.set_lifetime(0.25)

	$BeamLeft.set_orientation("left")
	$BeamLeft.set_lifetime(0.25)

	$BeamUp.set_orientation("up")
	$BeamUp.set_lifetime(0.25)

	$BeamDown.set_orientation("down")
	$BeamDown.set_lifetime(0.25)
	
func _on_Timer_timeout():
	var beam_right_up = load("res://Scenes/Beam.tscn").instance()
	add_child(beam_right_up)
	beam_right_up.set_beam_start($BeamRight.global_position + Vector2(0, -4))
	beam_right_up.set_orientation("up")
	beam_right_up.set_lifetime(0.1)
	beam_right_up.set_fade_time(0.1)

	var beam_right_down = load("res://Scenes/Beam.tscn").instance()
	add_child(beam_right_down)
	beam_right_down.set_beam_start($BeamRight.global_position + Vector2(0, 4))
	beam_right_down.set_orientation("down")
	beam_right_down.set_lifetime(0.1)
	beam_right_down.set_fade_time(0.1)

	var beam_left_up = load("res://Scenes/Beam.tscn").instance()
	add_child(beam_left_up)
	beam_left_up.set_beam_start($BeamLeft.global_position + Vector2(0, -4))
	beam_left_up.set_orientation("up")
	beam_left_up.set_lifetime(0.1)
	beam_left_up.set_fade_time(0.1)

	var beam_left_down = load("res://Scenes/Beam.tscn").instance()
	add_child(beam_left_down)
	beam_left_down.set_beam_start($BeamLeft.global_position + Vector2(0, 4))
	beam_left_down.set_orientation("down")
	beam_left_down.set_lifetime(0.1)
	beam_left_down.set_fade_time(0.1)

	iterations += 1
	if iterations == max_iterations:
		$Timer.stop()
