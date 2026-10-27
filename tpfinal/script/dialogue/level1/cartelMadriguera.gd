extends DialogueAbstract

func create_dialogue() -> void:
	var boton_teclado: String = "la flecha abajo"
	var boton_teclado_en: String = "Down Arrow"

	if Settings.modo_controles == Settings.ModoControles.MODO_B:
		boton_teclado = "S"
		boton_teclado_en = "S"

	if Settings.language == "es":
		add_line(
			"Cartel",
			"Con " + boton_teclado + " se puede entrar en madrigueras."
		)

	elif Settings.language == "en":
		add_line(
			"Sign",
			"Press " + boton_teclado_en + " to enter burrows."
		)
