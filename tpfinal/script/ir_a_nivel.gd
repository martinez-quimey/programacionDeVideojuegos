# IrANivel.gd
extends Area2D


@export var levelSiguiente: PackedScene


func _ready() -> void:

	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:

	if not body.is_in_group("jugador"):
		return

	print("ENTRÓ AL IR A NIVEL")


	# ==========================================
	# NIVEL QUE ACABAMOS DE TERMINAR
	# ==========================================

	var nivel_terminado := get_tree().current_scene.scene_file_path

	completar_nivel(nivel_terminado)


	# ==========================================
	# COMPROBAR SIGUIENTE NIVEL
	# ==========================================

	if levelSiguiente == null:

		print("No hay nivel siguiente.")

		return


	# ==========================================
	# GUARDAR EL SIGUIENTE NIVEL COMO ACTUAL
	# ==========================================

	Settings.nivelActual = levelSiguiente.resource_path


	# Guardamos antes de cambiar de escena.
	Save.guardar_partida()


	# ==========================================
	# CARGAR SIGUIENTE NIVEL
	# ==========================================

	load_level(levelSiguiente)


# =========================================================
# COMPLETAR NIVEL
# =========================================================

func completar_nivel(nombreNivel: String) -> void:

	# Si ya estaba completado, no lo vuelve a agregar.
	if Settings.nivelesCompletados.has(nombreNivel):

		print("NIVEL YA COMPLETADO: ", nombreNivel)

		return


	Settings.nivelesCompletados.append(nombreNivel)

	print("NIVEL COMPLETADO: ", nombreNivel)


# =========================================================
# CARGAR NIVEL
# =========================================================

func load_level(nivel: PackedScene) -> void:

	if nivel == null:

		print("ERROR: levelSiguiente está vacío")

		return


	Settings.getMain().load_level(nivel)
