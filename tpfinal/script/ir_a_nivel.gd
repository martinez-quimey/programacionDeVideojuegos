
# IrANivel.gd
extends Area2D


@export var levelSiguiente: PackedScene


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("jugador"):
		return

	print("ENTRÓ AL IR A NIVEL")

	# Evitar completar el nivel varias veces.
	set_deferred("monitoring", false)

	# Nivel que acabamos de terminar.
	var nivel_terminado := get_tree().current_scene.scene_file_path
	completar_nivel(nivel_terminado)

	# Si no hay siguiente nivel, termina la beta y vuelve al menú.
	if levelSiguiente == null:
		print("FIN DE LA BETA: NIVEL COMPLETADO")

		Save.partidaFinalizada = true
		Settings.nivelActual = ""
		Save.guardar_partida()

		var main = Settings.getMain()

		if main != null:
			main._on_main_menu()
		else:
			push_error("No se encontró Main para volver al menú.")

		return

	# Hay otro nivel: guardar su ruta como nivel actual.
	Settings.nivelActual = levelSiguiente.resource_path
	Save.guardar_partida()

	load_level(levelSiguiente)

# =========================================================
# COMPLETAR NIVEL
# =========================================================

func completar_nivel(nombreNivel: String) -> void:

	if Settings.nivelesCompletados.has(nombreNivel):
		print("NIVEL YA COMPLETADO: ", nombreNivel)
		return

	Settings.nivelesCompletados.append(nombreNivel)

	print("NIVEL COMPLETADO: ", nombreNivel)


# =========================================================
# CARGAR NIVEL
# =========================================================

func load_level(nivel: PackedScene) -> void:

	Settings.checkpoint = 0

	if nivel == null:
		print("ERROR: levelSiguiente está vacío")
		return

	Settings.getMain().load_level(nivel)
