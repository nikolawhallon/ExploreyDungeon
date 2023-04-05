extends Area2D

var sfx_spawned = preload("res://Assets/Sfx/ghost.wav")

export var speed = 10
var destination = Vector2(320, 240)

var rng = RandomNumberGenerator.new()

func _ready():
	$AudioStreamPlayer2D.set_volume_db(-48.0)
	
	rng.randomize()
	
	$AnimatedSprite.speed_scale = rng.randf_range(0.8, 1.2)
	
	$AudioStreamPlayer2D.stream = sfx_spawned
	$AudioStreamPlayer2D.play()

func _physics_process(delta):
	var velocity = (destination - position).normalized() * speed
	position += velocity * delta

	if velocity.x < 0 and scale.x > 0:
		scale.x *= -1
	elif velocity.x > 0 and scale.x < 0:
		scale.x *= -1

func destroy():
	get_tree().queue_delete(self)

func _on_Ghost_body_entered(body):
	if body.is_in_group("Player"):
		body.was_hit()
