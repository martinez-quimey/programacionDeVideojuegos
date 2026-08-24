extends CharacterBody2D

func _physics_process(delta):
	velocity = Vector2.ZERO

	if Input.is_action_pressed("derecha"):
		velocity.x += 100

	if Input.is_action_pressed("izquierda"):
		velocity.x -= 100

	move_and_slide()
