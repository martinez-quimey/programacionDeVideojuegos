extends DialogueAbstract

@export var imagenDeEvaSorprendida: Texture2D = preload("res://sprites/eva/expresiones/sorprendida.png")
@export var imagenDeEvaFeliz: Texture2D = preload("res://sprites/eva/expresiones/feliz.png")

func create_dialogue() -> void:
	if Settings.language == "es":
		add_line(
			"Eva",
			"¡Uaaaaaaahhhh!",
			imagenDeEvaSorprendida
		)


	elif Settings.language == "en":

		add_line(
			"Eva",
			"Uaaaaaaahhhh!",
			imagenDeEvaSorprendida
		)
