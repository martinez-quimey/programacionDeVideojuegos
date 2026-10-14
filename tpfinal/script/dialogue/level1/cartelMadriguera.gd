
extends DialogueAbstract

func create_dialogue() -> void:
	if Settings.language == "es":
		add_line(
			"Cartel",
            "Con abajo se puede entrar en madrigueras"
		)

	elif Settings.language == "en":
		add_line(
			"Sign",
            "Press down to enter burrows"
		)
