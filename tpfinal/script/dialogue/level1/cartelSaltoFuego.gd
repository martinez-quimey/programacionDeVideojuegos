
extends DialogueAbstract

func create_dialogue() -> void:
	if Settings.language == "es":
		add_line(
			"Cartel",
            "Con el botón Z (o el gatillo derecho del mando) puedes realizar un segundo salto en el aire mediante un disparo de fuego"
		)

	elif Settings.language == "en":
		add_line(
			"Sign",
            "Press Z (or the right trigger on the controller) to perform a second jump in midair by shooting fire"
		)
