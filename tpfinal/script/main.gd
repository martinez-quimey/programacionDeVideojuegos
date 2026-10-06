extends Node2D


@onready var game_container: Node2D = $GameContainer
@onready var hud: CanvasLayer = $HUD


# =========================================================
# NIVEL INICIAL
# =========================================================

@export var level1: PackedScene


# =========================================================
# NIVEL ACTUAL
# =========================================================

var game: Node2D = null

var ruta_nivel_actual: String = ""


# =========================================================
# POSICIÓN SEGURA DE APARICIÓN
# =========================================================

const POSICION_SEGURA_PLAYER := Vector2(0.0, 0.0)


# =========================================================
# DIAGNÓSTICO DE PROCESS / PHYSICS
# =========================================================

var ultimo_process_diagnostic: int = 0
var ultimo_physics_diagnostic: int = 0

const UMBRAL_FRAME_LENTO: int = 100


# =========================================================
# IDIOMA
# =========================================================

func _enter_tree() -> void:

	var tiempo_inicio = Time.get_ticks_msec()

	print("")
	print("========================================")
	print("MAIN: empieza _enter_tree")
	print("========================================")

	var idioma_guardado = Save.obtener_idioma_guardado()

	print(
		"MAIN: obtener_idioma_guardado = ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	if idioma_guardado == null:
		Settings.language = "es"
	else:
		Settings.language = idioma_guardado

	print(
		"MAIN: _enter_tree TERMINADO | TOTAL = ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	var tiempo_inicio = Time.get_ticks_msec()

	print("")
	print("========================================")
	print("MAIN: empieza _ready")
	print("========================================")

	Settings.setearMain(self)

	print(
		"MAIN: Settings.setearMain | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	hud.start_game.connect(new_game)
	hud.retry_game.connect(retry_game)
	hud.main_menu.connect(_on_main_menu)
	hud.continue_game.connect(continue_game)

	ultimo_process_diagnostic = Time.get_ticks_msec()
	ultimo_physics_diagnostic = Time.get_ticks_msec()

	print(
		"MAIN: señales conectadas | TOTAL = ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)


# =========================================================
# DIAGNÓSTICO PROCESS
# =========================================================

func _process(_delta: float) -> void:

	var ahora = Time.get_ticks_msec()

	var tiempo_desde_ultimo = (
		ahora - ultimo_process_diagnostic
	)

	ultimo_process_diagnostic = ahora

	if tiempo_desde_ultimo >= UMBRAL_FRAME_LENTO:

		print(
			"⚠️ FRAME MUY LENTO | Main | ",
			tiempo_desde_ultimo,
			" ms desde el último process"
		)


# =========================================================
# DIAGNÓSTICO PHYSICS
# =========================================================

func _physics_process(_delta: float) -> void:

	var ahora = Time.get_ticks_msec()

	var tiempo_desde_ultimo = (
		ahora - ultimo_physics_diagnostic
	)

	ultimo_physics_diagnostic = ahora

	if tiempo_desde_ultimo >= UMBRAL_FRAME_LENTO:

		print(
			"⚠️ PHYSICS MUY LENTO | Main | ",
			tiempo_desde_ultimo,
			" ms desde el último physics"
		)


# =========================================================
# PAUSA
# =========================================================

func _input(event: InputEvent) -> void:

	if not event.is_pressed():
		return

	if event.is_echo():
		return

	if not event.is_action_pressed("pausa"):
		return

	if get_tree().paused:
		return

	if not Settings.sePuedePausar:

		print(
			"PAUSA BLOQUEADA: Settings.sePuedePausar = false"
		)

		return

	print("MAIN: PAUSANDO JUEGO")

	Settings.sePuedePausar = false

	hud.show_pause_menu()

	get_tree().paused = true

	get_viewport().set_input_as_handled()


# =========================================================
# OBTENER RUTA DEL NIVEL ACTUAL
# =========================================================

func obtener_ruta_nivel_actual() -> String:

	if ruta_nivel_actual == "":

		print(
			"ERROR: no hay ninguna ruta de nivel guardada"
		)

		return ""

	return ruta_nivel_actual


# =========================================================
# CONTINUAR PARTIDA
# =========================================================

func continue_game() -> void:

	var tiempo_inicio = Time.get_ticks_msec()

	print("")
	print("====================================")
	print("CONTINUANDO PARTIDA")
	print("====================================")

	print(
		"MAIN CONTINUE: inicio | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	print(
		"Nivel guardado: ",
		Settings.nivelActual
	)

	if Settings.nivelActual == "":

		print(
			"ERROR 1: nivelActual está vacío"
		)

		return

	if not ResourceLoader.exists(
		Settings.nivelActual
	):

		print(
			"ERROR 2: el recurso NO existe"
		)

		print(
			"Ruta buscada: ",
			Settings.nivelActual
		)

		return

	print(
		"MAIN CONTINUE: antes de load() | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	var escena_nivel = load(
		Settings.nivelActual
	)

	print(
		"MAIN CONTINUE: después de load() | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	if escena_nivel == null:

		print(
			"ERROR 3: load() devolvió null"
		)

		return

	if not escena_nivel is PackedScene:

		print(
			"ERROR 4: el recurso NO es una PackedScene"
		)

		return

	print(
		"MAIN CONTINUE: antes de instantiate() | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	var nuevo_game = escena_nivel.instantiate()

	print(
		"MAIN CONTINUE: después de instantiate() | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	if nuevo_game == null:

		print(
			"ERROR 5: instantiate() devolvió null"
		)

		return

	if not nuevo_game is Node2D:

		print(
			"ERROR 6: el nivel no es Node2D"
		)

		nuevo_game.queue_free()

		return

	if game != null:

		print(
			"MAIN CONTINUE: antes de queue_free() nivel anterior | ",
			Time.get_ticks_msec() - tiempo_inicio,
			" ms"
		)

		game.queue_free()
		game = null

		print(
			"MAIN CONTINUE: después de queue_free() | ",
			Time.get_ticks_msec() - tiempo_inicio,
			" ms"
		)

	game = nuevo_game

	ruta_nivel_actual = Settings.nivelActual

	print(
		"MAIN CONTINUE: antes de add_child() | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	var antes_add_child = Time.get_ticks_msec()

	game_container.add_child(game)

	var despues_add_child = Time.get_ticks_msec()

	print(
		"MAIN CONTINUE: después de add_child() | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	print(
		"MAIN CONTINUE: SOLO add_child() = ",
		despues_add_child - antes_add_child,
		" ms"
	)

	Settings.sePuedePausar = true

	print(
		"MAIN CONTINUE: antes de await process_frame | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	var antes_frame = Time.get_ticks_msec()

	await get_tree().process_frame

	var despues_frame = Time.get_ticks_msec()

	print(
		"MAIN CONTINUE: después de await process_frame | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	print(
		"MAIN CONTINUE: SOLO await process_frame = ",
		despues_frame - antes_frame,
		" ms"
	)

	if game.has_signal("player_died"):

		if not game.player_died.is_connected(
			_on_player_died
		):

			game.player_died.connect(
				_on_player_died
			)

	print(
		"MAIN CONTINUE: antes de colocar checkpoint | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	await colocar_player_en_checkpoint()

	print(
		"MAIN CONTINUE: después de colocar checkpoint | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	print(
		"NIVEL CARGADO CORRECTAMENTE"
	)

	print(
		"MAIN CONTINUE: FIN | TOTAL = ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)


# =========================================================
# NUEVA PARTIDA
# =========================================================

func new_game() -> void:

	var tiempo_inicio = Time.get_ticks_msec()

	print("")
	print("====================================")
	print("NUEVA PARTIDA")
	print("====================================")

	if level1 == null:

		print(
			"ERROR: level1 no está asignado en Main"
		)

		return

	Settings.checkpoint = 0
	Settings.sePuedePausar = true

	print(
		"MAIN NEW_GAME: antes de load_level | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	await load_level(level1)

	print(
		"MAIN NEW_GAME: después de load_level | TOTAL = ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)


# =========================================================
# PROJECTILE CONTAINER
# =========================================================

func obtener_projectile_container() -> Node:

	if game == null:
		return null

	var container = game.get_node_or_null(
		"Projectiles"
	)

	if container == null:

		container = game.find_child(
			"Projectiles",
			true,
			false
		)

	return container


# =========================================================
# REINICIAR PLAYER
# =========================================================

func reiniciar_player() -> void:

	var tiempo_inicio = Time.get_ticks_msec()

	print("")
	print("MAIN: empieza reiniciar_player")

	if game == null:
		return

	var nuevo_player = (
		game.get_node_or_null("Player")
	)

	if nuevo_player == null:

		print(
			"ERROR: no se encontró Player"
		)

		return

	var projectile_container = (
		obtener_projectile_container()
	)

	if projectile_container == null:

		print(
			"ERROR: no existe Projectiles"
		)

		return

	var estado_manual: EstadoPlayer = (
		nuevo_player.get_node_or_null(
			"estadoManual"
		)
	)

	var estado_automatico: EstadoPlayer = (
		nuevo_player.get_node_or_null(
			"estadoAutomatico"
		)
	)

	if estado_manual == null:

		print(
			"ERROR: Player no tiene estadoManual"
		)

		return

	if estado_automatico != null:
		estado_automatico.activo = false

	nuevo_player.estado_actual = estado_manual

	nuevo_player.vida = nuevo_player.vida_maxima
	nuevo_player.actualizar_barra_vida()

	nuevo_player.energia_fuego = (
		nuevo_player.energia_maxima
	)

	nuevo_player.actualizar_barra_energia()

	nuevo_player.tiempo_recarga_fuego.stop()

	nuevo_player.show()
	nuevo_player.animated_sprite.visible = true

	nuevo_player.velocity = Vector2.ZERO

	estado_manual.activo = true

	if estado_automatico != null:
		estado_automatico.activo = false

	nuevo_player.estado_actual = estado_manual

	estado_manual.direccion = 0.0
	estado_manual.esta_forzado = false
	estado_manual.direccion_forzada = Vector2.ZERO
	estado_manual.velocidad_forzada = 0.0

	estado_manual.retroceso_activo = false
	estado_manual.tiempo_retroceso = 0.0
	estado_manual.estado_anterior_retroceso = null

	estado_manual.tornado_activo = false
	estado_manual.tiempo_tornado = 0.0
	estado_manual.enemigos_golpeados_tornado.clear()

	estado_manual.turbo_activo = false
	estado_manual.tiempo_invulnerabilidad_turbo = 0.0
	estado_manual.enemigos_golpeados_turbo.clear()

	estado_manual.agarrado_pared = false
	estado_manual.pared_normal = Vector2.ZERO
	estado_manual.puede_agarrarse_pared = true

	estado_manual.seSalto = false
	estado_manual.saltoFuego = false

	nuevo_player.esta_en_madriguera = false

	nuevo_player.set_collision_mask_value(
		2,
		true
	)

	estado_manual.collision_shape_player.set_deferred(
		"disabled",
		false
	)

	estado_manual.collision_tornado.set_deferred(
		"disabled",
		true
	)

	estado_manual.hitbox_tornado.monitoring = false
	estado_manual.hitbox_turbo.monitoring = false

	nuevo_player.get_node(
		"Invulnerabilidad"
	).stop()

	if not estado_manual.died.is_connected(
		_on_player_died
	):

		estado_manual.died.connect(_on_player_died)

	nuevo_player.restablecer_visual_suelo()

	nuevo_player.reproducir_animacion(
		"quieta"
	)

	print(
		"PLAYER REINICIADO SIN CAMBIAR POSICIÓN: ",
		nuevo_player.position
	)

	print(
		"MAIN: reiniciar_player FIN | TOTAL = ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)


# =========================================================
# COLOCAR PLAYER EN CHECKPOINT
# =========================================================

func colocar_player_en_checkpoint() -> void:

	var tiempo_inicio = Time.get_ticks_msec()

	print("")
	print("========================================")
	print("CHECKPOINT: empieza colocar_player")
	print("========================================")

	if game == null:

		print(
			"CHECKPOINT: game == null | ",
			Time.get_ticks_msec() - tiempo_inicio,
			" ms"
		)

		return

	print(
		"CHECKPOINT: antes de buscar Player | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	var player = game.get_node_or_null("Player")

	print(
		"CHECKPOINT: después de buscar Player | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	if player == null:

		print(
			"ERROR: no se encontró Player para colocar checkpoint"
		)

		return

	print(
		"CHECKPOINT: antes de posicionDeCheckpoint() | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	var posicion_checkpoint = (
		game.posicionDeCheckpoint(
			Settings.checkpoint
		)
	)

	print(
		"CHECKPOINT: después de posicionDeCheckpoint() | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	print(
		"CHECKPOINT: posición obtenida = ",
		posicion_checkpoint
	)

	print(
		"CHECKPOINT: posición actual Player LOCAL = ",
		player.position
	)

	print(
		"CHECKPOINT: posición actual Player GLOBAL = ",
		player.global_position
	)

	print(
		"CHECKPOINT: ANTES DE CAMBIAR POSICIÓN | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	# =====================================================
	# CAMBIO IMPORTANTE:
	# La posición obtenida del checkpoint se interpreta
	# como posición GLOBAL.
	# =====================================================

	player.global_position = posicion_checkpoint

	print(
		"CHECKPOINT: DESPUÉS DE CAMBIAR POSICIÓN | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	print(
		"PLAYER: teletransportado al checkpoint GLOBAL = ",
		player.global_position
	)

	print(
		"PLAYER: posición LOCAL después del teletransporte = ",
		player.position
	)

	print(
		"CHECKPOINT: ANTES DE await process_frame | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	var antes_frame = Time.get_ticks_msec()

	await get_tree().process_frame

	var despues_frame = Time.get_ticks_msec()

	print(
		"CHECKPOINT: DESPUÉS DE await process_frame | ",
		despues_frame - tiempo_inicio,
		" ms"
	)

	print(
		"CHECKPOINT: SOLO await process_frame = ",
		despues_frame - antes_frame,
		" ms"
	)

	print(
		"CHECKPOINT: posición Player GLOBAL después de process_frame = ",
		player.global_position
	)

	print(
		"CHECKPOINT: posición Player LOCAL después de process_frame = ",
		player.position
	)

	print(
		"CHECKPOINT: FIN | TOTAL = ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	print("========================================")
	print("CHECKPOINT: fin colocar_player")
	print("========================================")


# =========================================================
# REINTENTAR
# =========================================================

func retry_game() -> void:

	var tiempo_inicio = Time.get_ticks_msec()

	print("")
	print("####################################")
	print("########## REINTENTAR NIVEL ########")
	print("####################################")

	print(
		"RETRY: inicio | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	if game == null:

		print(
			"ERROR: no existe nivel cargado"
		)

		return

	var checkpoint_guardado = Settings.checkpoint

	print(
		"CHECKPOINT ANTES DE REINICIAR: ",
		checkpoint_guardado
	)

	get_tree().paused = false

	Settings.sePuedePausar = true

	var ruta_nivel = game.scene_file_path

	if ruta_nivel == "":
		ruta_nivel = ruta_nivel_actual

	if ruta_nivel == "":

		print(
			"ERROR: no se pudo obtener la ruta del nivel"
		)

		return

	print(
		"Nivel que se va a recargar: ",
		ruta_nivel
	)

	print(
		"RETRY: antes de load() | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	var escena_nivel = load(
		ruta_nivel
	)

	print(
		"RETRY: después de load() | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	if escena_nivel == null:

		print(
			"ERROR: no se pudo cargar nuevamente el nivel"
		)

		return

	if not escena_nivel is PackedScene:

		print(
			"ERROR: la escena del nivel no es PackedScene"
		)

		return

	print(
		"BORRANDO NIVEL COMPLETO"
	)

	game.queue_free()
	game = null

	# =====================================================
	# RESTAURAR CHECKPOINT ANTES DE CREAR EL NIVEL NUEVO
	# =====================================================

	Settings.checkpoint = checkpoint_guardado

	print(
		"RETRY: checkpoint restaurado antes de crear nivel = ",
		Settings.checkpoint
	)

	print(
		"RETRY: antes de await process_frame después de queue_free | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	var antes_frame_borrado = Time.get_ticks_msec()

	await get_tree().process_frame

	var despues_frame_borrado = Time.get_ticks_msec()

	print(
		"RETRY: después de await process_frame borrado | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	print(
		"RETRY: solo frame de borrado = ",
		despues_frame_borrado - antes_frame_borrado,
		" ms"
	)

	print(
		"CREANDO NIVEL NUEVO"
	)

	print(
		"RETRY: antes de instantiate() | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	game = escena_nivel.instantiate()

	print(
		"RETRY: después de instantiate() | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	if game == null:

		print(
			"ERROR: no se pudo instanciar nuevamente el nivel"
		)

		return

	if not game is Node2D:

		print(
			"ERROR: el nivel nuevo no es Node2D"
		)

		game.queue_free()
		game = null

		return

	print(
		"RETRY: antes de add_child() | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	var antes_add_child = Time.get_ticks_msec()

	game_container.add_child(game)

	var despues_add_child = Time.get_ticks_msec()

	print(
		"RETRY: después de add_child() | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	print(
		"RETRY: SOLO add_child() = ",
		despues_add_child - antes_add_child,
		" ms"
	)

	ruta_nivel_actual = ruta_nivel

	Settings.sePuedePausar = true

	print(
		"RETRY: antes de colocar_player_en_checkpoint() | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	await colocar_player_en_checkpoint()

	print(
		"RETRY: después de colocar_player_en_checkpoint() | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	if game.has_signal("player_died"):

		if not game.player_died.is_connected(
			_on_player_died
		):

			game.player_died.connect(
				_on_player_died
			)

	print(
		"CHECKPOINT FINAL: ",
		Settings.checkpoint
	)

	print(
		"POSICIÓN FINAL PLAYER LOCAL: ",
		game.get_node("Player").position
	)

	print(
		"POSICIÓN FINAL PLAYER GLOBAL: ",
		game.get_node("Player").global_position
	)

	print(
		"REINTENTAR FINALIZADO | ",
		Time.get_ticks_msec()
		- tiempo_inicio,
		" ms"
	)

	print("####################################")
	print("######## FIN REINTENTAR NIVEL #######")
	print("####################################")


# =========================================================
# CARGAR NIVEL
# =========================================================

func load_level(
	level_scene: PackedScene
) -> void:

	var tiempo_inicio = Time.get_ticks_msec()

	print("")
	print("====================================")
	print("CARGANDO NIVEL")
	print("====================================")

	if level_scene == null:

		print(
			"ERROR: level_scene es null"
		)

		return

	ruta_nivel_actual = (
		level_scene.resource_path
	)

	if game != null:

		print(
			"LOAD_LEVEL: antes de queue_free() | ",
			Time.get_ticks_msec() - tiempo_inicio,
			" ms"
		)

		game.queue_free()
		game = null

		print(
			"LOAD_LEVEL: antes de await process_frame por nivel anterior | ",
			Time.get_ticks_msec() - tiempo_inicio,
			" ms"
		)

		var antes_frame_borrado = Time.get_ticks_msec()

		await get_tree().process_frame

		var despues_frame_borrado = Time.get_ticks_msec()

		print(
			"LOAD_LEVEL: después de await process_frame por nivel anterior | ",
			Time.get_ticks_msec() - tiempo_inicio,
			" ms"
		)

		print(
			"LOAD_LEVEL: solo frame de borrado = ",
			despues_frame_borrado - antes_frame_borrado,
			" ms"
		)

	print(
		"LOAD_LEVEL: antes de instantiate() | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	game = level_scene.instantiate()

	print(
		"LOAD_LEVEL: después de instantiate() | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	if game == null:

		print(
			"ERROR: no se pudo instanciar nivel"
		)

		return

	print(
		"LOAD_LEVEL: antes de add_child() | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	var antes_add_child = Time.get_ticks_msec()

	game_container.add_child(game)

	var despues_add_child = Time.get_ticks_msec()

	print(
		"LOAD_LEVEL: después de add_child() | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	print(
		"LOAD_LEVEL: SOLO add_child() = ",
		despues_add_child - antes_add_child,
		" ms"
	)

	Settings.sePuedePausar = true

	Settings.checkpoint = 0

	print(
		"LOAD_LEVEL: antes de colocar_player_en_checkpoint() | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	await colocar_player_en_checkpoint()

	print(
		"LOAD_LEVEL: después de colocar_player_en_checkpoint() | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)

	if game.has_signal("player_died"):

		if not game.player_died.is_connected(
			_on_player_died
		):

			game.player_died.connect(
				_on_player_died
			)

	print(
		"LOAD_LEVEL: FIN | ",
		Time.get_ticks_msec()
		- tiempo_inicio,
		" ms"
	)


# =========================================================
# PLAYER MUERE
# =========================================================

func _on_player_died() -> void:

	print(
		"MAIN: PLAYER MURIÓ"
	)

	Settings.sePuedePausar = false

	hud.show_game_over()


# =========================================================
# COMPATIBILIDAD GAME_PAUSED
# =========================================================

func _on_game_paused() -> void:

	print(
		"MAIN: game_paused recibido"
	)

	if get_tree().paused:
		return

	if not Settings.sePuedePausar:
		return

	Settings.sePuedePausar = false

	hud.show_pause_menu()

	get_tree().paused = true


# =========================================================
# VOLVER AL MENÚ
# =========================================================

func _on_main_menu() -> void:

	print(
		"MAIN: VOLVIENDO AL MENÚ"
	)

	get_tree().paused = false

	Settings.sePuedePausar = false

	if game != null:

		game.queue_free()

		game = null

	ruta_nivel_actual = ""

	hud.show_main_menu()
