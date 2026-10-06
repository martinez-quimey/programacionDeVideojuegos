extends DialogueAbstract


func create_dialogue() -> void:
	if Settings.language == "es":
		add_line(
			"Eva",
			"No puedo pasar por aquí..."
		)
		add_line(
			"Eva",
			"¡Oh, Amaterasu, Inari o algún dios de las rocas que puso esto aquí...!"
		)
		add_line(
			"Eva",
			"¿Por qué me odias?!"
		)

	elif Settings.language == "en":
		add_line(
			"Eva",
			"I can't get through here..."
		)
		add_line(
			"Eva",
			"Oh, Amaterasu, Inari, or whatever god of rocks put this here..."
		)
		add_line(
			"Eva",
			"Why do you hate me?!"
		)
