
extends DialogueAbstract

@export var imagenDeEvaDecidida: Texture2D = preload("res://sprites/eva/expresiones/decidida.png")
func create_dialogue() -> void:
	if Settings.language == "es":
		add_line(
			"Eva",
			"Un jabalí salvaje, son una molestia",
			imagenDeEvaDecidida
		)

	elif Settings.language == "en":
		add_line(
			"Eva",
			"A wild boar, they're a nuisance",
			imagenDeEvaDecidida
		)
