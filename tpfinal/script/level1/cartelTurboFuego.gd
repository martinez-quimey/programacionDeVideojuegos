
extends DialogueAbstract

func create_dialogue() -> void:
	if Settings.language == "es":
		add_line(
			"Cartel",
            "Con el botón C (o el gatillo izquierdo del mando) puedes realizar un turbo de fuego para atacar. Consume mucha energía."
		)

	elif Settings.language == "en":
		add_line(
			"Sign",
            "Press C (or the left trigger on the controller) to perform a fire turbo attack. It consumes a lot of energy."
		)
