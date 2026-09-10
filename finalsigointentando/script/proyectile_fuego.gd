#proyectileDeFuego
extends AbstractProyectile

func _ready():
	super._ready()
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("enemigos"):
		body.herir()
		explotar()
	elif body is StaticBody2D:
		explotar()
