
extends DialogueAbstract


func create_dialogue() -> void:
	if Settings.language == "es":
		add_line(
			"Eva",
			"Con el boton z (o el gatillo derecho en mando) puedo hacer un segundo salto mediante un disparo de fuego",
			
		)

	elif Settings.language == "en":
		add_line(
			"Eva",
			"With the Z button (or the right trigger on the controller) I can do a second jump using a fire",

		)
