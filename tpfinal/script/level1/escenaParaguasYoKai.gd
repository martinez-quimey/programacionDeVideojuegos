extends DialogueAbstract
@export var imagenDeEvaIdle: Texture2D = preload("res://sprites/eva/expresiones/idle.png")
@export var imagenDeEvaDecidida: Texture2D = preload("res://sprites/eva/expresiones/decidida.png")
var audio1: AudioStream = preload("res://sonidos/diálogos_de_eva/nv1/dialogo09hayParaguasYoKai.ogg")
var audio2: AudioStream = preload("res://sonidos/diálogos_de_eva/nv1/dialogo10tenerCuidado.ogg")
func create_dialogue() -> void:
	if Settings.language == "es":
		add_line(
			"Eva",
			"¡¿Hay paraguas yo kai cayendo del cielo?!",
			imagenDeEvaIdle,
			audio1
		)
		add_line(
			"Eva",
			"Habra que tener cuidado",
			imagenDeEvaDecidida,
			audio2
		)

	elif Settings.language == "en":
		add_line(
			"Eva",
			"Are yo-kai umbrellas falling from the sky?!",
			imagenDeEvaIdle,
			audio1
		)
		add_line(
			"Eva",
			"We'll have to be careful.",
			imagenDeEvaDecidida,
			audio2
		)
