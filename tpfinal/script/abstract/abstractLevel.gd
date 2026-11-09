
extends Node2D

signal player_died
signal game_paused

@export var name_level: String = ""
@export var nombre_nivel: String = ""
@export var numero_nivel: int = 0

@onready var player = $Player
@onready var estado_manual: EstadoPlayer = $Player/estadoManual
@onready var estado_automatico: EstadoPlayer = $Player/estadoAutomatico
@onready var projectile_container = $Projectiles
@onready var start_position = $StartPosition

const POSICION_SEGURA_PLAYER := Vector2(0.0, 0.0)
const CHECKPOINTS_POR_LOTE := 5

var cache_en_proceso: bool = false
var cache_checkpoints_lista: bool = false

# =====================================================
# CARGA DIFERIDA DE SPAWNERS
# =====================================================

var spawners_diferidos: Node = null
var spawners_cargados: bool = false
var spawners_cargando: bool = false


func _enter_tree() -> void:

	# Separar Spawners antes de que sus hijos entren al árbol
	# y ejecuten sus funciones _ready().
	spawners_diferidos = get_node_or_null("Spawners")

	if spawners_diferidos != null:
		remove_child(spawners_diferidos)

		print("SPAWNERS: separados antes de iniciar el nivel")
	else:
		print("SPAWNERS: no se encontró el nodo Spawners")


# =====================================================
# HERRAMIENTA DE MEDICIÓN
# =====================================================

func medir_ms(inicio_usec: int) -> float:
	return float(Time.get_ticks_usec() - inicio_usec) / 1000.0


# =====================================================
# READY
# =====================================================

func _ready() -> void:

	var inicio_ready := Time.get_ticks_usec()

	print("")
	print("##################################################")
	print("######## PERF: INICIO _READY #####################")
	print("##################################################")
	print("PERF: nivel = [", nombre_nivel, "]")
	print("PERF: checkpoint inicial = ", Settings.checkpoint)

	# =====================================================
	# DESACTIVAR PROCESS DE HIJOS
	# =====================================================

	var t := Time.get_ticks_usec()

	for hijo in get_children():
		if hijo is Node2D:
			hijo.set_process(false)
			hijo.set_physics_process(false)

	print(
		"PERF: desactivar process de hijos = ",
		medir_ms(t),
		" ms"
	)

	# =====================================================
	# CONECTAR SEÑALES
	# =====================================================

	t = Time.get_ticks_usec()

	estado_manual.died.connect(_on_player_died)
	estado_automatico.died.connect(_on_player_died)

	print("PERF: conectar señales = ", medir_ms(t), " ms")

	# =====================================================
	# COMPROBAR CHECKPOINT
	# =====================================================

	t = Time.get_ticks_usec()

	if not "checkpoint" in Settings:
		Settings.checkpoint = 0

	var checkpoint_guardado: int = int(Settings.checkpoint)

	print("PERF: comprobar checkpoint = ", medir_ms(t), " ms")
	print("PERF: ID de checkpoint guardado = ", checkpoint_guardado)

	# =====================================================
	# COMPROBAR CACHÉ
	# =====================================================

	t = Time.get_ticks_usec()

	var tiene_cache: bool = Settings.checkpoints_por_nivel.has(
		nombre_nivel
	)

	var cache_contiene_checkpoint: bool = false

	if tiene_cache:
		var cache_actual: Dictionary = Settings.checkpoints_por_nivel[
			nombre_nivel
		]

		cache_contiene_checkpoint = cache_actual.has(
			checkpoint_guardado
		)

	print("PERF: comprobar caché = ", medir_ms(t), " ms")
	print("PERF: tiene caché = ", tiene_cache)
	print(
		"PERF: contiene el checkpoint guardado = ",
		cache_contiene_checkpoint
	)

	# =====================================================
	# PREPARAR CACHÉ SI ES NECESARIO
	# =====================================================

	if checkpoint_guardado != 0:

		if not tiene_cache or not cache_contiene_checkpoint:

			print(
				"PERF: falta la posición del checkpoint; creando caché..."
			)

			t = Time.get_ticks_usec()

			await crear_cache_checkpoints()

			print(
				"PERF: espera/creación de caché en _ready = ",
				medir_ms(t),
				" ms"
			)

			t = Time.get_ticks_usec()

			tiene_cache = Settings.checkpoints_por_nivel.has(
				nombre_nivel
			)

			cache_contiene_checkpoint = false

			if tiene_cache:
				var cache_preparada: Dictionary = Settings.checkpoints_por_nivel[
					nombre_nivel
				]

				cache_contiene_checkpoint = cache_preparada.has(
					checkpoint_guardado
				)

			print(
				"PERF: comprobar resultado de caché = ",
				medir_ms(t),
				" ms"
			)

			if not cache_contiene_checkpoint:
				push_warning(
					"LEVEL: no se encontró el checkpoint guardado con ID "
					+ str(checkpoint_guardado)
					+ ". Se utilizará StartPosition."
				)

	else:
		if not tiene_cache:
			print("PERF: checkpoint 0; caché en segundo plano")
			call_deferred("crear_cache_checkpoints")

	# =====================================================
	# INICIAR ESTADO MANUAL
	# =====================================================

	print("PERF: empezando estado_manual.start()")

	t = Time.get_ticks_usec()

	estado_manual.start(
		POSICION_SEGURA_PLAYER,
		projectile_container
	)

	print("PERF: estado_manual.start() = ", medir_ms(t), " ms")
	print("PERF: Player.position después de start = ", player.position)
	print("PERF: estado_manual.activo = ", estado_manual.activo)

	# =====================================================
	# PAUSA
	# =====================================================

	t = Time.get_ticks_usec()

	Settings.sePuedePausar = true

	print("PERF: configurar pausa = ", medir_ms(t), " ms")

	# =====================================================
	# RECALCULAR BAYAS DESPUÉS DEL INICIO
	# =====================================================

	print("BAYAS: programando recálculo diferido")
	call_deferred("recalcular_bayas_diferido")

	print("PERF: TOTAL _ready = ", medir_ms(inicio_ready), " ms")

	print("##################################################")
	print("######## PERF: FIN _READY ########################")
	print("##################################################")
	print("")


# =====================================================
# RECALCULAR BAYAS DESPUÉS DE INICIAR EL NIVEL
# =====================================================

func recalcular_bayas_diferido() -> void:

	print("")
	print("========================================")
	print("BAYAS: INICIO DEL RECÁLCULO DIFERIDO")
	print("========================================")

	# Esperar un fotograma sin bloquear el flujo de carga.
	await get_tree().process_frame

	if not is_inside_tree():
		print("BAYAS: el nivel salió del árbol; se cancela el recálculo")
		return

	var nodo_bayas: Node = get_node_or_null("bayas")

	if nodo_bayas == null:
		print("BAYAS: ERROR, no existe el nodo hijo llamado 'bayas'")
		return

	var hijos: Array[Node] = nodo_bayas.get_children()

	print("BAYAS: cantidad de hijos encontrados = ", hijos.size())
	print("BAYAS: lista de vida guardada = ", Settings.objetosVidaObtenidos)
	print("BAYAS: lista de energía guardada = ", Settings.objetosEnergiaObtenidos)

	var inicio_recalculo := Time.get_ticks_usec()
	var cantidad_recalculada: int = 0
	var cantidad_sin_metodo: int = 0

	for hijo in hijos:

		if not is_instance_valid(hijo):
			continue

		if hijo.has_method("recalcular_estado"):

			print("BAYAS: recalculando hijo ", hijo.name)

			hijo.recalcular_estado()
			cantidad_recalculada += 1

		else:

			print(
				"BAYAS: AVISO, el hijo ",
				hijo.name,
				" no tiene el método recalcular_estado()"
			)

			cantidad_sin_metodo += 1

	print("BAYAS: hijos recalculados = ", cantidad_recalculada)
	print("BAYAS: hijos sin método = ", cantidad_sin_metodo)
	print("BAYAS: tiempo de recálculo = ", medir_ms(inicio_recalculo), " ms")

	print("BAYAS: FIN DEL RECÁLCULO")
	print("========================================")
	print("")


# =====================================================
# INCORPORAR SPAWNERS DESPUÉS DE COLOCAR AL JUGADOR
# =====================================================

func cargar_spawners_diferidos() -> void:

	if spawners_cargados:
		print("SPAWNERS: ya estaban cargados")
		return

	if spawners_cargando:
		print("SPAWNERS: la carga ya está en proceso")
		return

	if spawners_diferidos == null:
		print("SPAWNERS: no hay ningún nodo pendiente")
		return

	spawners_cargando = true

	var inicio := Time.get_ticks_usec()

	print("")
	print("========================================")
	print("SPAWNERS: INICIO DE CARGA DIFERIDA")
	print("========================================")

	# Dejar que el nivel complete un fotograma adicional
	# después de que Main coloque al jugador.
	await get_tree().process_frame

	if not is_inside_tree():
		spawners_cargando = false
		return

	if not is_instance_valid(spawners_diferidos):
		spawners_diferidos = null
		spawners_cargando = false
		return

	if spawners_diferidos.get_parent() != null:
		push_warning(
			"SPAWNERS: el nodo ya tiene un padre; se cancela la incorporación"
		)
		spawners_cargando = false
		return

	var t_add := Time.get_ticks_usec()

	add_child(spawners_diferidos)

	print(
		"SPAWNERS: add_child = ",
		medir_ms(t_add),
		" ms"
	)

	spawners_cargados = true
	spawners_cargando = false

	print(
		"SPAWNERS: carga diferida terminada | TOTAL = ",
		medir_ms(inicio),
		" ms"
	)

	print("========================================")
	print("")


# =====================================================
# CREAR CACHÉ POR LOTES
# =====================================================

func crear_cache_checkpoints() -> void:

	if cache_en_proceso:
		print("PERF CACHE: ya hay una caché en proceso; esperando")

		var inicio_espera := Time.get_ticks_usec()

		while cache_en_proceso:
			await get_tree().process_frame

		print(
			"PERF CACHE: espera de otra caché = ",
			medir_ms(inicio_espera),
			" ms"
		)
		return

	cache_en_proceso = true
	cache_checkpoints_lista = false

	var inicio_cache := Time.get_ticks_usec()
	var inicio_get_children := Time.get_ticks_usec()

	print("")
	print("##################################################")
	print("######## PERF CACHE: INICIO ######################")
	print("##################################################")

	var posiciones: Dictionary = {}
	var checkpoints = $checkpoints.get_children()

	print("PERF CACHE: get_children() = ", medir_ms(inicio_get_children), " ms")
	print("PERF CACHE: cantidad de checkpoints = ", checkpoints.size())
	print("PERF CACHE: nivel = [", nombre_nivel, "]")

	var tiempo_procesamiento_total_usec: int = 0
	var tiempo_espera_total_usec: int = 0
	var checkpoint_mas_lento: String = ""
	var checkpoint_mas_lento_usec: int = 0

	var inicio_lote := Time.get_ticks_usec()
	var procesados_lote: int = 0

	for i in range(checkpoints.size()):

		var inicio_checkpoint := Time.get_ticks_usec()
		var checkpoint = checkpoints[i]

		var marker = checkpoint.get_node_or_null("Marker2D")

		if marker != null:

			var id_checkpoint: int = int(
				checkpoint.numero_checkpoint
			)

			posiciones[id_checkpoint] = marker.global_position

		else:
			push_warning(
				"PERF CACHE: checkpoint "
				+ str(checkpoint.name)
				+ " no tiene Marker2D"
			)

		var duracion_checkpoint := Time.get_ticks_usec() - inicio_checkpoint

		tiempo_procesamiento_total_usec += duracion_checkpoint

		if duracion_checkpoint > checkpoint_mas_lento_usec:
			checkpoint_mas_lento_usec = duracion_checkpoint
			checkpoint_mas_lento = str(checkpoint.name)

		procesados_lote += 1

		if procesados_lote >= CHECKPOINTS_POR_LOTE:

			print(
				"PERF CACHE: lote hasta índice ",
				i,
				" | elementos = ",
				procesados_lote,
				" | tiempo del lote = ",
				medir_ms(inicio_lote),
				" ms"
			)

			var inicio_espera := Time.get_ticks_usec()

			await get_tree().process_frame

			var espera_usec := Time.get_ticks_usec() - inicio_espera
			tiempo_espera_total_usec += espera_usec

			print(
				"PERF CACHE: espera de fotograma = ",
				float(espera_usec) / 1000.0,
				" ms"
			)

			procesados_lote = 0
			inicio_lote = Time.get_ticks_usec()

	if procesados_lote > 0:
		print(
			"PERF CACHE: último lote = ",
			procesados_lote,
			" elementos | tiempo = ",
			medir_ms(inicio_lote),
			" ms"
		)

	# =====================================================
	# PUBLICAR CACHÉ COMPLETA
	# =====================================================

	var inicio_guardado := Time.get_ticks_usec()

	Settings.checkpoints_por_nivel[nombre_nivel] = posiciones

	cache_checkpoints_lista = true
	cache_en_proceso = false

	print("PERF CACHE: guardar diccionario = ", medir_ms(inicio_guardado), " ms")
	print("PERF CACHE: posiciones guardadas = ", posiciones.size())
	print("PERF CACHE: procesamiento acumulado = ", float(tiempo_procesamiento_total_usec) / 1000.0, " ms")
	print("PERF CACHE: espera acumulada de fotogramas = ", float(tiempo_espera_total_usec) / 1000.0, " ms")
	print(
		"PERF CACHE: checkpoint individual más lento = ",
		checkpoint_mas_lento,
		" (",
		float(checkpoint_mas_lento_usec) / 1000.0,
		" ms)"
	)
	print("PERF CACHE: TOTAL = ", medir_ms(inicio_cache), " ms")

	print("##################################################")
	print("######## PERF CACHE: FIN #########################")
	print("##################################################")
	print("")


# =====================================================
# BUSCAR POSICIÓN DE CHECKPOINT
# =====================================================

func posicionDeCheckpoint(numero: int) -> Vector2:

	var inicio_busqueda := Time.get_ticks_usec()

	print("PERF CHECKPOINT: buscar ID = ", numero)

	if numero == 0:
		print("PERF CHECKPOINT: ID 0; usando StartPosition")
		print("PERF CHECKPOINT: búsqueda = ", medir_ms(inicio_busqueda), " ms")
		return start_position.global_position

	if cache_en_proceso:
		print("PERF CHECKPOINT: la caché está en proceso; esperando")

		var inicio_espera := Time.get_ticks_usec()

		while cache_en_proceso:
			await get_tree().process_frame

		print(
			"PERF CHECKPOINT: espera de caché = ",
			medir_ms(inicio_espera),
			" ms"
		)

	if not Settings.checkpoints_por_nivel.has(nombre_nivel):
		push_warning(
			"CHECKPOINT: no existe caché para el nivel "
			+ nombre_nivel
		)
		print(
			"PERF CHECKPOINT: búsqueda total = ",
			medir_ms(inicio_busqueda),
			" ms"
		)
		return start_position.global_position

	var checkpoints: Dictionary = Settings.checkpoints_por_nivel[
		nombre_nivel
	]

	if checkpoints.has(numero):

		var posicion: Vector2 = checkpoints[numero]

		print(
			"PERF CHECKPOINT: encontrado ID ",
			numero,
			" en ",
			medir_ms(inicio_busqueda),
			" ms"
		)
		print("PERF CHECKPOINT: posición = ", posicion)

		return posicion

	push_warning(
		"CHECKPOINT: el ID "
		+ str(numero)
		+ " no existe en la caché del nivel "
		+ nombre_nivel
	)

	print("PERF CHECKPOINT: ID no encontrado; usando StartPosition")
	print(
		"PERF CHECKPOINT: búsqueda total = ",
		medir_ms(inicio_busqueda),
		" ms"
	)

	return start_position.global_position


# =====================================================
# MUERTE DEL JUGADOR
# =====================================================

func _on_player_died() -> void:

	print("")
	print("LEVEL: PLAYER DIED")
	print("LEVEL: checkpoint cuando murió = ", Settings.checkpoint)
	print("LEVEL: Player.position cuando murió = ", player.position)

	player_died.emit()


# =====================================================
# PAUSA
# =====================================================

func _on_game_paused() -> void:
	pass
