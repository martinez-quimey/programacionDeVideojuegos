
extends DialogueAbstract


func create_dialogue() -> void:
	if Settings.language == "es":
		add_line(
			"Eva",
			"Con C puedo hacer un ataque muy genial y quemar a ese jabalí molesto",
		)

	elif Settings.language == "en":
		add_line(
			"Eva",
			"With C I can perform a really cool attack and burn that annoying boar",
		)
