extends DialogueAbstract

@export var imagenDeEvaMolesta: Texture2D = preload("res://sprites/eva/expresiones/ligeramenteMolesta.png")
@export var imagenDeEvaSorprendida: Texture2D = preload("res://sprites/eva/expresiones/sorprendida.png")
var audio1: AudioStream = preload("res://sonidos/diálogos_de_eva/nv1/diálogo4noPuedoPasarporaqui.ogg")
var audio2: AudioStream = preload("res://sonidos/diálogos_de_eva/nv1/dialogo5Amaterasu.ogg")
var audio3: AudioStream = preload("res://sonidos/diálogos_de_eva/nv1/dialogo6PorQueMeOdias.ogg")
func create_dialogue() -> void:
	if Settings.language == "es":
		add_line(
			"Eva",
			"No puedo pasar por aquí...",
			imagenDeEvaMolesta,
			audio1
		)
		add_line(
			"Eva",
			"¡Oh, Amaterasu, Inari o algún dios de las rocas que puso esto aquí...!",
			imagenDeEvaMolesta,
			audio2
		)
		add_line(
			"Eva",
			"¿Por qué me odias?!",
			imagenDeEvaSorprendida,
			audio3
		)

	elif Settings.language == "en":
		add_line(
			"Eva",
			"I can't get through here...",
			imagenDeEvaMolesta,
			audio1
		)
		add_line(
			"Eva",
			"Oh, Amaterasu, Inari, or whatever god of rocks put this here...",
			imagenDeEvaMolesta,
			audio2
		)
		add_line(
			"Eva",
			"Why do you hate me?!",
			imagenDeEvaSorprendida,
			audio3
		)
