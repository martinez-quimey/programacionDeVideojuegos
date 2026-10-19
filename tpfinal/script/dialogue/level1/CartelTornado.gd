
extends DialogueAbstract

func create_dialogue() -> void:
	if Settings.language == "es":
		add_line(
			"Cartel",
			"Presiona X (□ en PlayStation, X en Xbox o Y en Nintendo) para realizar un tornado. Consume 6 de energía."
		)

	elif Settings.language == "en":
		add_line(
			"Sign",
			"Press X (□ on PlayStation, X on Xbox or Y on Nintendo) to perform a tornado. Costs 6 energy."
		)
