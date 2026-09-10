extends Dialogue

@export var imagenDEEvaAlegre: Texture2D
@export var imagenDeEvaFastidiada: Texture2D

func create_dialogue() -> void:
	if Settings.language == "es":
		add_line(
			"Ciervo",
			"Hola, Eva"
		)

		add_line(
			"Eva",
			"¡Hola!",
			imagenDEEvaAlegre
		)

		add_line(
			"Ciervo",
			"Con Z puedes disparar fuego hacia abajo"
		)
		add_line(
			"Ciervo",
			"Manteniendo presionado x puedes caminar"
		)
		add_line(
			"Eva",
			"caminar, que aburridoooooooo",
			imagenDeEvaFastidiada
		)
		add_line(
			"Ciervo",
			"Y con c haces un turbo de fuego"
		)
		add_line(
			"Ciervo",
			"Pero para cualquier ataque de fuego necesitaras energia"
		)

	elif Settings.language == "en":
		add_line(
			"Deer",
			"Hello, Eva"
		)

		add_line(
			"Eva",
			"Hello!",
			imagenDEEvaAlegre
		)

		add_line(
			"Deer",
			"With Z you can shoot fire downwards"
		)
		add_line(
			"Deer",
			"holding down x you can walk"
		)
		add_line(
			"Eva",
			"walking, how boriiiiiing",
			imagenDeEvaFastidiada
		)
		add_line(
			"Deer",
			"and with c you make a fire turbo"
		)
		add_line(
			"Deer",
			"but for any fire attack you'll need energy"
		)
