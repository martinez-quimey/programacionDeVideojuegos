#irANivel
extends Area2D

@export var levelSiguiente: PackedScene


func _on_body_entered(body):
	
	if body.is_in_group("jugador"):
		print ("entro al body entered")
		load_level (levelSiguiente)

func load_level(levelSiguiente) -> void:
	
	Settings.getMain().load_level(levelSiguiente)
