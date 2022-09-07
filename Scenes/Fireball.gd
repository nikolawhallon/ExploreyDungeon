extends Area2D

export var speed = 120
var direction = Vector2(1, 0)

func _physics_process(delta):
	var velocity = direction.normalized() * speed
	
	rotation = velocity.angle()
	position += velocity * delta

func destroy():
	get_tree().queue_delete(self)

func _on_Fireball_area_entered(area):
	if area.is_in_group("Ghost"):
		area.destroy()
		destroy()

func _on_Fireball_body_entered(body):
	# if the fireball hits any object (especially collidable tiles)
	# EXCEPT the Player, destroy the fireball
	if !body.is_in_group("Player"):
		destroy()
