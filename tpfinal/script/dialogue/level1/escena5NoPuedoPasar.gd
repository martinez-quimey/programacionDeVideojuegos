extends DialogueAbstract

@export var imagenDeEvaMolesta: Texture2D = preload("res://sprites/eva/expresiones/ligeramenteMolesta.png")
@export var imagenDeEvaSorprendida: Texture2D = preload("res://sprites/eva/expresiones/sorprendida.png")
func create_dialogue() -> void:
	if Settings.language == "es":
		add_line(
			"Eva",
			"No puedo pasar por aquí...",
			imagenDeEvaMolesta
		)
		add_line(
			"Eva",
			"¡Oh, Amaterasu, Inari o algún dios de las rocas que puso esto aquí...!",
			imagenDeEvaMolesta
		)
		add_line(
			"Eva",
			"¿Por qué me odias?!",
			imagenDeEvaSorprendida
		)

	elif Settings.language == "en":
		add_line(
			"Eva",
			"I can't get through here...",
			imagenDeEvaMolesta
		)
		add_line(
			"Eva",
			"Oh, Amaterasu, Inari, or whatever god of rocks put this here...",
			imagenDeEvaMolesta
		)
		add_line(
			"Eva",
			"Why do you hate me?!",
			imagenDeEvaSorprendida
		)
