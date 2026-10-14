extends DialogueAbstract
@export var imagenDeEvaIdle: Texture2D = preload("res://sprites/eva/expresiones/idle.png")
@export var imagenDeEvaDecidida: Texture2D = preload("res://sprites/eva/expresiones/decidida.png")
func create_dialogue() -> void:
	if Settings.language == "es":
		add_line(
			"Eva",
			"¡¿Hay paraguas yo kai cayendo del cielo?!",
			imagenDeEvaIdle
		)
		add_line(
			"Eva",
			"Habra que tener cuidado",
			imagenDeEvaDecidida
		)

	elif Settings.language == "en":
		add_line(
			"Eva",
			"Are yo-kai umbrellas falling from the sky?!",
			imagenDeEvaIdle
		)
		add_line(
			"Eva",
			"We'll have to be careful.",
			imagenDeEvaDecidida
		)
