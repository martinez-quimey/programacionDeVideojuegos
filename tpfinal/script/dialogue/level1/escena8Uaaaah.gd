extends DialogueAbstract

@export var imagenDeEvaSorprendida: Texture2D = preload("res://sprites/eva/expresiones/sorprendida.png")
@export var imagenDeEvaFeliz: Texture2D = preload("res://sprites/eva/expresiones/feliz.png")
var audio1: AudioStream = preload("res://sonidos/diálogos_de_eva/nv1/ahhhhh.ogg")
func create_dialogue() -> void:
	if Settings.language == "es":
		add_line(
			"Eva",
			"¡Uaaaaaaahhhh!",
			imagenDeEvaSorprendida,
			audio1
		)


	elif Settings.language == "en":

		add_line(
			"Eva",
			"Uaaaaaaahhhh!",
			imagenDeEvaSorprendida,
			audio1
		)
