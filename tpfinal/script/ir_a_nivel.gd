
extends Area2D

@export var levelSiguiente: PackedScene


func _ready() -> void:
	print("")
	print("========================================")
	print("IR A NIVEL: empieza _ready()")
	print("Nodo: ", get_path())
	print("Escena del nodo: ", scene_file_path)
	print("Nivel siguiente asignado: ", levelSiguiente != null)

	if levelSiguiente != null:
		print("Ruta del nivel siguiente: ", levelSiguiente.resource_path)

	body_entered.connect(_on_body_entered)

	print("IR A NIVEL: señal body_entered conectada")
	print("IR A NIVEL: _ready() terminado")
	print("========================================")


func _on_body_entered(body: Node) -> void:
	print("")
	print("========================================")
	print("IR A NIVEL: body_entered")
	print("Cuerpo detectado: ", body.name)
	print("Tipo del cuerpo: ", body.get_class())
	print("Pertenece al grupo jugador: ", body.is_in_group("jugador"))

	if not body.is_in_group("jugador"):
		print("IR A NIVEL: se ignora el cuerpo porque no es jugador")
		return

	print("ENTRÓ AL IR A NIVEL")

	set_deferred("monitoring", false)
	print("IR A NIVEL: monitoring desactivado de forma diferida")

	var main = Settings.getMain()

	if main == null:
		push_error("IR A NIVEL: no se encontró Main")
		return

	var ruta_nivel_terminado: String = main.obtener_ruta_nivel_actual()

	print("Ruta del nivel terminado: ", ruta_nivel_terminado)

	if ruta_nivel_terminado.is_empty():
		push_error("IR A NIVEL: no se pudo obtener la ruta del nivel terminado")
		return

	# Obtener el número/ID del nivel actual.
	var numero_nivel: int = int(obtener_dato_nivel("numero_nivel"))

	print("Número/ID del nivel terminado: ", numero_nivel)

	if numero_nivel <= 0:
		push_error("IR A NIVEL: numero_nivel no está configurado correctamente")
		return

	# Registrar la finalización en Settings.
	Settings.marcar_nivel_completado(numero_nivel)

	print("Niveles completados: ", Settings.obtener_ids_niveles_completados())

	# Si no hay siguiente nivel, termina la beta.
	if levelSiguiente == null:
		print("FIN DE LA BETA: no hay siguiente nivel")

		Settings.checkpoint = 0
		Settings.nivelActual = ""

		Save.partidaFinalizada = true
		Save.guardar_partida()

		print("IR A NIVEL: volviendo al menú")
		main._on_main_menu()
		return

	# Cargar el siguiente nivel.
	print("IR A NIVEL: hay un siguiente nivel")
	print("Ruta siguiente: ", levelSiguiente.resource_path)

	Settings.nivelActual = levelSiguiente.resource_path
	Settings.checkpoint = 0

	Save.guardar_partida()
	load_level(levelSiguiente)


# =========================================================
# COMPLETAR NIVEL
# =========================================================


func obtener_dato_nivel(propiedad: String) -> String:
	var nodo: Node = self

	while nodo != null:
		for dato in nodo.get_property_list():
			if dato.name == propiedad:
				return str(nodo.get(propiedad))

		nodo = nodo.get_parent()

	return ""


# =========================================================
# CARGAR NIVEL
# =========================================================

func load_level(nivel: PackedScene) -> void:
	print("LOAD_LEVEL DE IR A NIVEL: comienza")

	Settings.checkpoint = 0
	print("Checkpoint reiniciado a 0")

	if nivel == null:
		push_error("LOAD_LEVEL DE IR A NIVEL: levelSiguiente está vacío")
		return

	var main = Settings.getMain()
	print("LOAD_LEVEL DE IR A NIVEL: Main = ", main)

	if main == null:
		push_error("LOAD_LEVEL DE IR A NIVEL: no se encontró Main")
		return

	print("LOAD_LEVEL DE IR A NIVEL: llamando a Main.load_level()")
	main.load_level(nivel)
	print("LOAD_LEVEL DE IR A NIVEL: llamada realizada")
