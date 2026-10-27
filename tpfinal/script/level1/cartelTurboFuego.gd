extends DialogueAbstract

func create_dialogue() -> void:
	var boton_teclado: String = "C"

	if Settings.modo_controles == Settings.ModoControles.MODO_B:
		boton_teclado = "L"

	if Settings.language == "es":
		add_line(
			"Cartel",
			"Con el botón " + boton_teclado + " (o el gatillo izquierdo del mando) puedes realizar un turbo de fuego para atacar. Consume mucha energía."
		)

	elif Settings.language == "en":
		add_line(
			"Sign",
			"Press " + boton_teclado + " (or the left trigger on the controller) to perform a fire turbo attack. It consumes a lot of energy."
		)
