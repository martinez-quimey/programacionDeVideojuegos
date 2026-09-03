#proyectil enemigo
extends Proyectile


func _ready():
	super._ready()
	body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	if body.is_in_group("jugador"):
		body.morir()
		emit_signal("delete_requested", self)
