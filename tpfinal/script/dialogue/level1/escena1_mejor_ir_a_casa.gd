
extends DialogueAbstract

@export var imagenDEEvaIdle: Texture2D

func create_dialogue() -> void:
	print (Settings.language)
	if Settings.language == "es":
		print ("entro al if en español")
		add_line(
			"Eva",
			"Explorar es divertido, pero ya quiero ir a casa"
		)


	elif Settings.language == "en":
		print ("entro al if en ingles")
		add_line(
			"Eva",
			"Exploring is fun, but I already want to go home"
		)
