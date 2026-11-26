
extends Area2D

@export var levelSiguiente: PackedScene

const UMBRAL_RETRASO_SEGUNDOS: float = 10.0


func _ready() -> void:
	# Evitar conexiones duplicadas.
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("jugador"):
		return

	set_deferred("monitoring", false)

	var main = Settings.getMain()

	if main == null:
		push_error("IR A NIVEL: no se encontró Main")
		return

	var ruta_nivel_terminado: String = main.obtener_ruta_nivel_actual()

	if ruta_nivel_terminado.is_empty():
		push_error("IR A NIVEL: no se pudo obtener la ruta del nivel terminado")
		return

	var numero_nivel: int = int(obtener_dato_nivel("numero_nivel"))

	if numero_nivel <= 0:
		push_error("IR A NIVEL: numero_nivel no está configurado correctamente")
		return

	# Registrar la finalización.
	medir_retraso("marcar_nivel_completado", func():
		Settings.marcar_nivel_completado(numero_nivel)
	)

	# Si no hay siguiente nivel, termina la beta.
	if levelSiguiente == null:
		Settings.checkpoint = 0
		Settings.nivelActual = ""

		Save.partidaFinalizada = true

		medir_retraso("guardar_partida_finalizada", func():
			Save.guardar_partida()
		)

		medir_retraso("mostrar_creditos", func():
			main.mostrar_creditos()
		)

		return

	# Cargar el siguiente nivel.
	Settings.nivelActual = levelSiguiente.resource_path
	Settings.checkpoint = 0

	medir_retraso("guardar_partida", func():
		Save.guardar_partida()
	)

	medir_retraso("cargar_siguiente_nivel", func():
		load_level(levelSiguiente)
	)


# =========================================================
# DETECCIÓN DE RETRASOS
# =========================================================

func medir_retraso(nombre_operacion: String, operacion: Callable) -> void:
	var inicio: int = Time.get_ticks_msec()

	operacion.call()

	var duracion: float = (Time.get_ticks_msec() - inicio) / 1000.0

	if duracion > UMBRAL_RETRASO_SEGUNDOS:
		print(
			"[RETRASO] ",
			nombre_operacion,
			" tardó ",
			duracion,
			" segundos."
		)


# =========================================================
# OBTENER DATOS DEL NIVEL
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
	Settings.checkpoint = 0

	if nivel == null:
		push_error("LOAD_LEVEL DE IR A NIVEL: levelSiguiente está vacío")
		return

	var main = Settings.getMain()

	if main == null:
		push_error("LOAD_LEVEL DE IR A NIVEL: no se encontró Main")
		return

	medir_retraso("Main.load_level", func():
		main.load_level(nivel)
	)
