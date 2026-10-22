extends DialogueAbstract

@export var imagenDeEvaDecidida: Texture2D = preload("res://sprites/eva/expresiones/decidida.png")
var audio: AudioStream = preload("res://sonidos/diálogos_de_eva/nv1/dialogo07SaltoComplicado.ogg")
func create_dialogue() -> void:
	if Settings.language == "es":
		add_line(
			"Eva",
			"Jmmmm parece complicado, aunque con un salto alto y luego un turbo podría lograrlo",
			imagenDeEvaDecidida,
			audio
		)

	elif Settings.language == "en":
		add_line(
			"Eva",
			"Hmmmm, it looks complicated, but I might be able to make it if I jump high and then use a turbo boost.",
			imagenDeEvaDecidida,
			audio
		)
