extends DialogueAbstract

@export var imagenDeEvaSorprendida: Texture2D = preload("res://sprites/eva/expresiones/sorprendida.png")
@export var imagenDeEvaFeliz: Texture2D = preload("res://sprites/eva/expresiones/feliz.png")

func create_dialogue() -> void:
	if Settings.language == "es":
		add_line(
			"Eva",
			"es una legendaria baya espiritual.",
			imagenDeEvaSorprendida
		)
		add_line(
			"Eva",
			"segun las leyendas aumenta el poder espiritual de quien la consuma.",
			imagenDeEvaFeliz
		)

	elif Settings.language == "en":

		add_line(
			"Eva",
			"It is a legendary spiritual berry.",
			imagenDeEvaSorprendida
		)
		add_line(
			"Eva",
			"According to legend, it increases the spiritual power of whoever consumes it.",
			imagenDeEvaFeliz
		)
