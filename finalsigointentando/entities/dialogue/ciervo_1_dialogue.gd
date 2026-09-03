extends Dialogue


@export var imagenDEEva: Texture2D


func create_dialogue() -> void:
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
