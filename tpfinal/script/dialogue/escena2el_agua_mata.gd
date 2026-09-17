
extends DialogueAbstract

@export var imagenDeEvaAsustada: Texture2D

func create_dialogue() -> void:
	if Settings.language == "es":
		add_line(
			"Eva",
			"¿Eso es agua?! ¡Si la toco muero seguro!",
			imagenDeEvaAsustada
		)

	elif Settings.language == "en":
		add_line(
			"Eva",
			"Is that water?! If I touch it, I'm definitely going to die!",
			imagenDeEvaAsustada
		)
