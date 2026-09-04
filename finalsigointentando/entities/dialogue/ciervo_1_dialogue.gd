extends Dialogue

@export var imagenDEEva: Texture2D


func create_dialogue() -> void:
	if Settings.language == "es":
		add_line(
			"Ciervo",
			"Hola, Eva"
		)

		add_line(
			"Eva",
			"Hola",
			imagenDEEva
		)

		add_line(
			"Ciervo",
			"Me aburres, fea"
		)

	elif Settings.language == "en":
		add_line(
			"Deer",
			"Hello, Eva"
		)

		add_line(
			"Eva",
			"Hello",
			imagenDEEva
		)

		add_line(
			"Deer",
			"You bore me, ugly"
		)
