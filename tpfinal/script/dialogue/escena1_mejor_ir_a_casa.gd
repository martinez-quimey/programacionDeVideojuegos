
extends DialogueAbstract

@export var imagenDEEvaIdle: Texture2D

func create_dialogue() -> void:
	if Settings.language == "es":
		add_line(
			"Eva",
			"Explorar es divertido, pero ya quiero ir a casa"
		)


	elif Settings.language == "en":
		add_line(
			"Eva",
			"Exploring is fun, but I already want to go home"
		)
