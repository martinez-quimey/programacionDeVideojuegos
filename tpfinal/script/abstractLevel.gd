extends Node2D

signal player_died
signal game_paused

@export var nombre_nivel: String = ""

@onready var player = $Player
@onready var estado_manual: EstadoPlayer = $Player/estadoManual
@onready var estado_automatico: EstadoPlayer = $Player/estadoAutomatico
@onready var projectile_container = $Projectiles
@onready var start_position = $StartPosition

const POSICION_SEGURA_PLAYER := Vector2(0.0, 0.0)


func _ready() -> void:

	var tiempo_inicio = Time.get_ticks_msec()

	print("")
	print("##################################################")
	print("######## ABSTRACT LEVEL: INICIO _READY ###########")
	print("##################################################")

	print(
		"LEVEL: nombre_nivel = [",
		nombre_nivel,
		"]"
	)

	print(
		"LEVEL: Settings.checkpoint AL ENTRAR A _READY = ",
		Settings.checkpoint
	)

	print(
		"LEVEL: Player.position AL ENTRAR A _READY = ",
		player.position
	)

	print(
		"LEVEL: StartPosition.position = ",
		start_position.position
	)

	print(
		"LEVEL: POSICION_SEGURA_PLAYER = ",
		POSICION_SEGURA_PLAYER
	)

	print(
		"LEVEL: Settings.checkpoints_por_nivel ANTES DE _READY = ",
		Settings.checkpoints_por_nivel
	)

	# =====================================================
	# DESACTIVAR PROCESS DE HIJOS
	# =====================================================

	print("")
	print("LEVEL: desactivando process de hijos")

	for hijo in get_children():

		if hijo is Node2D:

			print(
				"LEVEL: desactivando hijo = ",
				hijo.name
			)

			hijo.set_process(false)
			hijo.set_physics_process(false)

	# =====================================================
	# SEÑALES
	# =====================================================

	var tiempo_bloque = Time.get_ticks_msec()

	print("")
	print("LEVEL: antes de conectar señales")

	estado_manual.died.connect(_on_player_died)
	estado_automatico.died.connect(_on_player_died)

	print(
		"LEVEL: señales conectadas | ",
		Time.get_ticks_msec() - tiempo_bloque,
		" ms"
	)

	# =====================================================
	# CHECKPOINT
	# =====================================================

	tiempo_bloque = Time.get_ticks_msec()

	print("")
	print("LEVEL: antes de comprobar checkpoint")

	if not "checkpoint" in Settings:
		print(
			"LEVEL: Settings NO tenía checkpoint"
		)

		Settings.checkpoint = 0

	print(
		"LEVEL: checkpoint ACTUAL = ",
		Settings.checkpoint
	)

	print(
		"LEVEL: checkpoint después de comprobación = ",
		Settings.checkpoint,
		" | bloque = ",
		Time.get_ticks_msec() - tiempo_bloque,
		" ms"
	)

	# =====================================================
	# CACHÉ
	# =====================================================

	tiempo_bloque = Time.get_ticks_msec()

	print("")
	print("LEVEL: antes de comprobar caché")

	var tiene_cache = Settings.checkpoints_por_nivel.has(
		nombre_nivel
	)

	print(
		"LEVEL: tiene_cache = ",
		tiene_cache
	)

	print(
		"LEVEL: nombre_nivel = [",
		nombre_nivel,
		"]"
	)

	print(
		"LEVEL: claves actuales de checkpoints_por_nivel = ",
		Settings.checkpoints_por_nivel.keys()
	)

	if tiene_cache:

		print(
			"LEVEL: CONTENIDO DE LA CACHÉ PARA ESTE NIVEL = ",
			Settings.checkpoints_por_nivel[nombre_nivel]
		)

	print(
		"LEVEL: comprobación caché terminada | ",
		Time.get_ticks_msec() - tiempo_bloque,
		" ms"
	)

	# =====================================================
	# INICIAR ESTADO MANUAL
	# =====================================================

	print("")
	print(
		"LEVEL: Player.position ANTES DE estado_manual.start() = ",
		player.position
	)

	print(
		"LEVEL: posición que se enviará a estado_manual.start() = ",
		POSICION_SEGURA_PLAYER
	)

	tiempo_bloque = Time.get_ticks_msec()

	print(
		"LEVEL: antes de estado_manual.start()"
	)

	estado_manual.start(
		POSICION_SEGURA_PLAYER,
		projectile_container
	)

	print(
		"LEVEL: después de estado_manual.start()"
	)

	print(
		"LEVEL: Player.position DESPUÉS de estado_manual.start() = ",
		player.position
	)

	print(
		"LEVEL: estado_manual.activo = ",
		estado_manual.activo
	)

	print(
		"LEVEL: bloque start() = ",
		Time.get_ticks_msec() - tiempo_bloque,
		" ms"
	)

	# =====================================================
	# CREAR CACHÉ
	# =====================================================

	tiempo_bloque = Time.get_ticks_msec()

	if not tiene_cache:

		print("")
		print(
			"LEVEL: NO HAY CACHÉ"
		)

		print(
			"LEVEL: antes de call_deferred(crear_cache_checkpoints)"
		)

		call_deferred(
			"crear_cache_checkpoints"
		)

		print(
			"LEVEL: call_deferred realizado"
		)

	else:

		print("")
		print(
			"LEVEL: LA CACHÉ YA EXISTE"
		)

	print(
		"LEVEL: bloque caché = ",
		Time.get_ticks_msec() - tiempo_bloque,
		" ms"
	)

	# =====================================================
	# PAUSA
	# =====================================================

	print("")
	print(
		"LEVEL: antes de Settings.sePuedePausar"
	)

	Settings.sePuedePausar = true

	print(
		"LEVEL: Settings.sePuedePausar = ",
		Settings.sePuedePausar
	)

	print("")
	print(
		"LEVEL: _READY TERMINADO"
	)

	print(
		"LEVEL: Player.position AL TERMINAR _READY = ",
		player.position
	)

	print(
		"LEVEL: Settings.checkpoint AL TERMINAR _READY = ",
		Settings.checkpoint
	)

	print(
		"LEVEL: TOTAL _READY = ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	print("##################################################")
	print("######## ABSTRACT LEVEL: FIN _READY ##############")
	print("##################################################")
	print("")


func crear_cache_checkpoints() -> void:

	var tiempo_inicio = Time.get_ticks_msec()

	print("")
	print("##################################################")
	print("######## CACHE: INICIO CREAR CACHE ################")
	print("##################################################")

	var posiciones: Dictionary = {}

	print(
		"CACHE: Settings.checkpoint al empezar = ",
		Settings.checkpoint
	)

	print(
		"CACHE: nombre_nivel = [",
		nombre_nivel,
		"]"
	)

	print(
		"CACHE: antes de obtener checkpoints"
	)

	var checkpoints = $checkpoints.get_children()

	print(
		"CACHE: cantidad de checkpoints = ",
		checkpoints.size()
	)

	# =====================================================
	# RECORRER CHECKPOINTS
	# =====================================================

	for checkpoint in checkpoints:

		print("")
		print(
			"CACHE: ----------------------------------------"
		)

		print(
			"CACHE: checkpoint encontrado = ",
			checkpoint.name
		)

		print(
			"CACHE: numero_checkpoint = ",
			checkpoint.numero_checkpoint
		)

		print(
			"CACHE: posición del checkpoint = ",
			checkpoint.position
		)

		var marker = checkpoint.get_node_or_null(
			"Marker2D"
		)

		if marker != null:

			print(
				"CACHE: Marker2D encontrado"
			)

			print(
				"CACHE: Marker2D.position = ",
				marker.position
			)

			print(
				"CACHE: GUARDANDO posición para checkpoint ",
				checkpoint.numero_checkpoint,
				" = ",
				marker.position
			)

			posiciones[
				checkpoint.numero_checkpoint
			] = marker.global_position

		else:

			print(
				"CACHE: ERROR: checkpoint ",
				checkpoint.numero_checkpoint,
				" NO tiene Marker2D"
			)

	# =====================================================
	# MOSTRAR RESULTADO
	# =====================================================

	print("")
	print(
		"CACHE: ========================================="
	)

	print(
		"CACHE: DICCIONARIO FINAL DE POSICIONES = ",
		posiciones
	)

	print(
		"CACHE: cantidad de posiciones guardadas = ",
		posiciones.size()
	)

	Settings.checkpoints_por_nivel[
		nombre_nivel
	] = posiciones

	print(
		"CACHE: caché guardada en Settings"
	)

	print(
		"CACHE: Settings.checkpoints_por_nivel = ",
		Settings.checkpoints_por_nivel
	)

	print(
		"CACHE: TOTAL = ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	print("##################################################")
	print("######## CACHE: FIN CREAR CACHE ##################")
	print("##################################################")
	print("")


func posicionDeCheckpoint(numero: int) -> Vector2:

	var tiempo_inicio = Time.get_ticks_msec()

	print("")
	print("##################################################")
	print("###### CHECKPOINT: INICIO BUSQUEDA ################")
	print("##################################################")

	print(
		"CHECKPOINT: número solicitado = ",
		numero
	)

	print(
		"CHECKPOINT: Settings.checkpoint actual = ",
		Settings.checkpoint
	)

	print(
		"CHECKPOINT: nombre_nivel = [",
		nombre_nivel,
		"]"
	)

	print(
		"CHECKPOINT: claves disponibles = ",
		Settings.checkpoints_por_nivel.keys()
	)

	# =====================================================
	# COMPROBAR CACHÉ
	# =====================================================

	if not Settings.checkpoints_por_nivel.has(
		nombre_nivel
	):

		print("")
		print(
			"CHECKPOINT: !!! NO EXISTE CACHÉ PARA ESTE NIVEL !!!"
		)

		print(
			"CHECKPOINT: se devolverá StartPosition"
		)

		print(
			"CHECKPOINT: StartPosition.position = ",
			start_position.position
		)

		print(
			"CHECKPOINT: TOTAL = ",
			Time.get_ticks_msec() - tiempo_inicio,
			" ms"
		)

		print("##################################################")
		print("###### CHECKPOINT: FIN BUSQUEDA ##################")
		print("##################################################")
		print("")

		return start_position.position

	# =====================================================
	# OBTENER CACHÉ
	# =====================================================

	var checkpoints = (
		Settings.checkpoints_por_nivel[
			nombre_nivel
		]
	)

	print("")
	print(
		"CHECKPOINT: caché encontrada"
	)

	print(
		"CHECKPOINT: contenido completo = ",
		checkpoints
	)

	print(
		"CHECKPOINT: cantidad de entradas = ",
		checkpoints.size()
	)

	print(
		"CHECKPOINT: ¿existe número ",
		numero,
		"? ",
		checkpoints.has(numero)
	)

	# =====================================================
	# CHECKPOINT ENCONTRADO
	# =====================================================

	if checkpoints.has(numero):

		var posicion = checkpoints[numero]

		print("")
		print(
			"CHECKPOINT: !!! POSICIÓN ENCONTRADA !!!"
		)

		print(
			"CHECKPOINT: número = ",
			numero
		)

		print(
			"CHECKPOINT: posición almacenada = ",
			posicion
		)

		print(
			"CHECKPOINT: tipo de posición = ",
			typeof(posicion)
		)

		print(
			"CHECKPOINT: Player.position ANTES DE DEVOLVER = ",
			player.position
		)

		print(
			"CHECKPOINT: DEVOLVIENDO = ",
			posicion
		)

		print(
			"CHECKPOINT: TOTAL = ",
			Time.get_ticks_msec() - tiempo_inicio,
			" ms"
		)

		print("##################################################")
		print("###### CHECKPOINT: FIN BUSQUEDA ##################")
		print("##################################################")
		print("")

		return posicion

	# =====================================================
	# CHECKPOINT NO ENCONTRADO
	# =====================================================

	print("")
	print(
		"CHECKPOINT: !!! NÚMERO NO ENCONTRADO !!!"
	)

	print(
		"CHECKPOINT: número buscado = ",
		numero
	)

	print(
		"CHECKPOINT: números existentes = ",
		checkpoints.keys()
	)

	print(
		"CHECKPOINT: se devolverá StartPosition"
	)

	print(
		"CHECKPOINT: StartPosition.position = ",
		start_position.position
	)

	print(
		"CHECKPOINT: TOTAL = ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	print("##################################################")
	print("###### CHECKPOINT: FIN BUSQUEDA ##################")
	print("##################################################")
	print("")

	return start_position.position


func _on_player_died() -> void:

	print("")
	print("############################################")
	print("LEVEL: PLAYER DIED")
	print("############################################")

	print(
		"LEVEL: Settings.checkpoint cuando murió = ",
		Settings.checkpoint
	)

	print(
		"LEVEL: Player.position cuando murió = ",
		player.position
	)

	player_died.emit()


func _on_game_paused() -> void:
	pass
