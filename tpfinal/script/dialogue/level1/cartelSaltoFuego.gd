extends DialogueAbstract

func create_dialogue() -> void:
	var boton_teclado: String = "Z"

	if Settings.modo_controles == Settings.ModoControles.MODO_B:
		boton_teclado = "Y"

	if Settings.language == "es":
		add_line(
			"Cartel",
			"Con el botón " + boton_teclado + " (o el gatillo derecho del mando) puedes realizar un segundo salto en el aire mediante un disparo de fuego."
		)

	elif Settings.language == "en":
		add_line(
			"Sign",
			"Press " + boton_teclado + " (or the right trigger on the controller) to perform a second jump in midair by shooting fire."
		)
