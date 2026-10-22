
extends DialogueAbstract

@export var imagenDeEvaAsustada: Texture2D = preload("res://sprites/eva/expresiones/sorprendida.png")
var audio: AudioStream = preload( "res://sonidos/diálogos_de_eva/nv1/dialogo2agua.ogg" )
func create_dialogue() -> void:
	if Settings.language == "es":
		add_line(
			"Eva",
			"¿Eso es agua?! ¡Si la toco muero seguro!",
			imagenDeEvaAsustada,
			audio
		)

	elif Settings.language == "en":
		add_line(
			"Eva",
			"Is that water?! If I touch it, I'm definitely going to die!",
			imagenDeEvaAsustada,
			audio
		)
