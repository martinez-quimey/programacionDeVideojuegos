extends DialogueAbstract

func create_dialogue() -> void:
	var boton_teclado: String = "X"

	if Settings.modo_controles == Settings.ModoControles.MODO_B:
		boton_teclado = "K"

	if Settings.language == "es":
		add_line(
			"Cartel",
			"Presiona " + boton_teclado + " (Cuadrado en PlayStation, X en Xbox o Y en Nintendo) para realizar un tornado. Consume 6 de energía."
		)

	elif Settings.language == "en":
		add_line(
			"Sign",
			"Press " + boton_teclado + " (Square on PlayStation, X on Xbox or Y on Nintendo) to perform a tornado. Costs 6 energy."
		)
