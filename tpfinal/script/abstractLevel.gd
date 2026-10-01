extends Node2D


signal player_died
signal game_paused


# ==========================================
# CONFIGURACIÓN DEL NIVEL
# ==========================================

@export var nombre_nivel: String = ""


# ==========================================
# NODOS
# ==========================================

@onready var player = $Player
@onready var estado_manual: EstadoPlayer = $Player/estadoManual
@onready var estado_automatico: EstadoPlayer = $Player/estadoAutomatico

@onready var projectile_container = $Projectiles
@onready var start_position = $StartPosition


# ==========================================
# POSICIÓN SEGURA INICIAL
# ==========================================

const POSICION_SEGURA_PLAYER := Vector2(0.0, 0.0)


# ==========================================
# INICIO
# ==========================================

func _ready() -> void:

	for hijo in get_children():
		if hijo is Node2D:
			hijo.set_process(false)
			hijo.set_physics_process(false)


	var tiempo_inicio = Time.get_ticks_msec()

	print("")
	print("========================================")
	print("LEVEL: empieza _ready")
	print("========================================")


	# ==========================================
	# CONECTAR SEÑALES
	# ==========================================

	var tiempo_bloque = Time.get_ticks_msec()

	print("LEVEL: antes de conectar señales")

	estado_manual.died.connect(_on_player_died)
	estado_automatico.died.connect(_on_player_died)

	print(
		"LEVEL: señales conectadas | bloque = ",
		Time.get_ticks_msec() - tiempo_bloque,
		" ms | total = ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)


	# ==========================================
	# ASEGURAR CHECKPOINT
	# ==========================================

	tiempo_bloque = Time.get_ticks_msec()

	print("LEVEL: antes de comprobar checkpoint")

	if not "checkpoint" in Settings:
		Settings.checkpoint = 0

	print(
		"LEVEL: checkpoint = ",
		Settings.checkpoint,
		" | bloque = ",
		Time.get_ticks_msec() - tiempo_bloque,
		" ms | total = ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)


	# ==========================================
	# COMPROBAR CACHÉ
	# ==========================================

	tiempo_bloque = Time.get_ticks_msec()

	print("LEVEL: antes de comprobar caché")

	var tiene_cache = Settings.checkpoints_por_nivel.has(
		nombre_nivel
	)

	print(
		"LEVEL: tiene_cache = ",
		tiene_cache,
		" | nombre_nivel = [",
		nombre_nivel,
		"] | claves actuales = ",
		Settings.checkpoints_por_nivel.keys(),
		" | bloque = ",
		Time.get_ticks_msec() - tiempo_bloque,
		" ms | total = ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)


	# ==========================================
	# INICIALIZAR PLAYER
	# ==========================================

	tiempo_bloque = Time.get_ticks_msec()

	print(
		"LEVEL: posición inicial segura = ",
		POSICION_SEGURA_PLAYER
	)

	print(
		"LEVEL: antes de estado_manual.start()"
	)

	estado_manual.start(
		POSICION_SEGURA_PLAYER,
		projectile_container
	)

	print(
		"LEVEL: después de estado_manual.start()",
		" | bloque = ",
		Time.get_ticks_msec() - tiempo_bloque,
		" ms | total = ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	print(
		"LEVEL: posición inicial del Player = ",
		player.position
	)


	# ==========================================
	# CREAR CACHÉ SI NO EXISTE
	# ==========================================

	tiempo_bloque = Time.get_ticks_msec()

	if not tiene_cache:

		print(
			"LEVEL: antes de call_deferred(crear_cache_checkpoints)"
		)

		call_deferred("crear_cache_checkpoints")

		print(
			"LEVEL: call_deferred realizado",
			" | bloque = ",
			Time.get_ticks_msec() - tiempo_bloque,
			" ms | total = ",
			Time.get_ticks_msec() - tiempo_inicio,
			" ms"
		)

	else:

		print(
			"LEVEL: la caché ya existe",
			" | bloque = ",
			Time.get_ticks_msec() - tiempo_bloque,
			" ms | total = ",
			Time.get_ticks_msec() - tiempo_inicio,
			" ms"
		)


	# ==========================================
	# PAUSA
	# ==========================================

	tiempo_bloque = Time.get_ticks_msec()

	print(
		"LEVEL: antes de Settings.sePuedePausar"
	)

	Settings.sePuedePausar = true

	print(
		"LEVEL: _ready TERMINADO",
		" | bloque = ",
		Time.get_ticks_msec() - tiempo_bloque,
		" ms | TOTAL _READY = ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	print("========================================")
	print("LEVEL: fin _ready")
	print("========================================")


# ==========================================
# CREAR CACHÉ DE CHECKPOINTS
# ==========================================

func crear_cache_checkpoints() -> void:

	var tiempo_inicio = Time.get_ticks_msec()

	print("")
	print("========================================")
	print("CACHE: empieza crear_cache_checkpoints")
	print("========================================")


	var tiempo_bloque = Time.get_ticks_msec()

	var posiciones: Dictionary = {}

	print(
		"CACHE: Dictionary creado | ",
		Time.get_ticks_msec() - tiempo_bloque,
		" ms"
	)


	# ==========================================
	# OBTENER CHECKPOINTS
	# ==========================================

	tiempo_bloque = Time.get_ticks_msec()

	print(
		"CACHE: antes de get_children()"
	)

	var checkpoints = $checkpoints.get_children()

	print(
		"CACHE: get_children terminado",
		" | cantidad = ",
		checkpoints.size(),
		" | bloque = ",
		Time.get_ticks_msec() - tiempo_bloque,
		" ms | total = ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)


	# ==========================================
	# RECORRER CHECKPOINTS
	# ==========================================

	tiempo_bloque = Time.get_ticks_msec()

	print(
		"CACHE: empieza recorrer checkpoints"
	)

	for checkpoint in checkpoints:

		print(
			"CACHE: guardando checkpoint ",
			checkpoint.numero_checkpoint
		)

		var marker = checkpoint.get_node_or_null(
			"Marker2D"
		)

		if marker != null:

			posiciones[
				checkpoint.numero_checkpoint
			] = marker.position

		else:

			print(
				"ERROR: el checkpoint ",
				checkpoint.numero_checkpoint,
				" no tiene Marker2D"
			)

	print(
		"CACHE: terminó recorrer checkpoints",
		" | cantidad = ",
		checkpoints.size(),
		" | bloque = ",
		Time.get_ticks_msec() - tiempo_bloque,
		" ms | total = ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)


	# ==========================================
	# GUARDAR CACHÉ
	# ==========================================

	tiempo_bloque = Time.get_ticks_msec()

	print(
		"CACHE: antes de guardar en Settings"
	)

	Settings.checkpoints_por_nivel[
		nombre_nivel
	] = posiciones

	print(
		"CACHE: caché guardada",
		" | bloque = ",
		Time.get_ticks_msec() - tiempo_bloque,
		" ms | total = ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)


	# ==========================================
	# FIN
	# ==========================================

	print(
		"CACHE: FIN",
		" | TOTAL = ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	print("========================================")
	print("CACHE: fin crear_cache_checkpoints")
	print("========================================")


# ==========================================
# OBTENER POSICIÓN DEL CHECKPOINT
# ==========================================

func posicionDeCheckpoint(numero: int) -> Vector2:

	var tiempo_inicio = Time.get_ticks_msec()

	print(
		"CHECKPOINT: buscando posición de checkpoint ",
		numero
	)


	# ==========================================
	# COMPROBAR CACHÉ
	# ==========================================

	var tiempo_bloque = Time.get_ticks_msec()

	if not Settings.checkpoints_por_nivel.has(
		nombre_nivel
	):

		print(
			"CHECKPOINT: no existe caché",
			" | bloque = ",
			Time.get_ticks_msec() - tiempo_bloque,
			" ms"
		)

		return start_position.position


	print(
		"CHECKPOINT: caché encontrada",
		" | bloque = ",
		Time.get_ticks_msec() - tiempo_bloque,
		" ms"
	)


	# ==========================================
	# OBTENER POSICIONES
	# ==========================================

	tiempo_bloque = Time.get_ticks_msec()

	var checkpoints = (
		Settings.checkpoints_por_nivel[
			nombre_nivel
		]
	)

	print(
		"CHECKPOINT: posiciones obtenidas",
		" | bloque = ",
		Time.get_ticks_msec() - tiempo_bloque,
		" ms"
	)


	# ==========================================
	# BUSCAR CHECKPOINT
	# ==========================================

	tiempo_bloque = Time.get_ticks_msec()

	if checkpoints.has(numero):

		print(
			"CHECKPOINT: posición encontrada = ",
			checkpoints[numero],
			" | bloque = ",
			Time.get_ticks_msec() - tiempo_bloque,
			" ms | TOTAL = ",
			Time.get_ticks_msec() - tiempo_inicio,
			" ms"
		)

		return checkpoints[numero]


	# ==========================================
	# FALLBACK
	# ==========================================

	print(
		"CHECKPOINT: número no encontrado",
		" | TOTAL = ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	return start_position.position


# ==========================================
# MUERTE
# ==========================================

func _on_player_died() -> void:

	print(
		"LEVEL: player_died"
	)

	player_died.emit()


# ==========================================
# PAUSA
# ==========================================

func _on_game_paused() -> void:

	pass
