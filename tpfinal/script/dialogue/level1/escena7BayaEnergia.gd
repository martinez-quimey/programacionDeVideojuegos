extends DialogueAbstract

@export var imagenDeEvaSorprendida: Texture2D = preload("res://sprites/eva/expresiones/sorprendida.png")
@export var imagenDeEvaFeliz: Texture2D = preload("res://sprites/eva/expresiones/feliz.png")
var audio1: AudioStream = preload("res://sonidos/diálogos_de_eva/nv1/dialogo11BayaEspiritual.ogg")
var audio2: AudioStream = preload("res://sonidos/diálogos_de_eva/nv1/dialogo12segunlasleyendas.ogg")
func create_dialogue() -> void:
	if Settings.language == "es":
		add_line(
			"Eva",
			"es la legendaria baya espiritual.",
			imagenDeEvaSorprendida,
			audio1
		)
		add_line(
			"Eva",
			"segun las leyendas aumenta el poder espiritual de quien las consuma.",
			imagenDeEvaFeliz,
			audio2
		)

	elif Settings.language == "en":

		add_line(
			"Eva",
			"It is a legendary spiritual berry.",
			imagenDeEvaSorprendida,
			audio1
		)
		add_line(
			"Eva",
			"According to legend, it increases the spiritual power of whoever consumes it.",
			imagenDeEvaFeliz,
			audio2
		)
