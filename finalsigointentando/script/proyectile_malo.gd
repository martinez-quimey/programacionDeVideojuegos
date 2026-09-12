#proyectil enemigo
extends AbstractProyectile


func _ready():
	super._ready()
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body is StaticBody2D and not body.is_in_group("enemigos"):

		explotar()
	elif body.is_in_group("jugador"):
		body.herir(1)
		explotar()
