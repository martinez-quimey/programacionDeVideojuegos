
# EstadoPlayer.gd
extends Node
class_name EstadoPlayer




# ==========================================
# PLAYER
# ==========================================

# EstadoPlayer NO es el Player.
#
# El Player real es el padre de estos nodos.

@onready var player: CharacterBody2D = get_parent()

@onready var collision_shape_player: CollisionShape2D = $"..//CollisionShape2D"
@onready var collision_tornado: CollisionShape2D = $"../CollisionShapeTornado"
# ==========================================
# ESTADO
# ==========================================

@onready var estado_manual: EstadoPlayer = $"../estadoManual"
@onready var estado_automatico: EstadoPlayer = $"../estadoAutomatico"


# ==========================================
# MOVIMIENTO FORZADO
# ==========================================

var esta_forzado := false
var direccion_forzada := Vector2.ZERO
var velocidad_forzada := 0.0


# ==========================================
# RETROCESO
# ==========================================

@export var PESO: float = 0.25

const DURACION_RETROCESO: float = 0.5

var retroceso_activo: bool = false
var tiempo_retroceso: float = 0.0
var estado_anterior_retroceso: EstadoPlayer = null


# ==========================================
# TORNADO
# ==========================================

const ENERGIA_TORNADO: int = 6

@export var VELOCIDAD_TORNADO: float = 700.0
@export var DURACION_TORNADO: float = 2.0

var tornado_activo: bool = false
var tiempo_tornado: float = 0.0

var enemigos_golpeados_tornado: Dictionary = {}

@onready var hitbox_tornado: Area2D = $"../HitboxTornado"


# ==========================================
# PROYECTILES
# ==========================================

@export var projectile_scene: PackedScene

var projectile_container: Node


# ==========================================
# REFERENCIAS
# ==========================================

@onready var Invulnerabilidad: Timer = $"../Invulnerabilidad"
@onready var fire_position: Marker2D = $"../FirePosition"
@onready var collision_shape: CollisionShape2D = $"../CollisionShape2D"
@onready var hitbox_turbo: Area2D = $"../HitboxTurbo"


# ==========================================
# SEÑALES
# ==========================================

signal hit
signal died


# ==========================================
# GRAVEDAD
# ==========================================

@export var GRAVITY: float = 600.0
@export var GRAVITY_CAIDA: float = 1600
@export var JUMP_FORCE: float = -600.0
@export var JUMP_FIRE_FORCE: float = -880.0


# ==========================================
# VELOCIDAD
# ==========================================

@export var MAX_SPEED: float = 600.0
@export var ACCELERATION: float = 1500.0
@export var FRICTION: float = 1000.0


# ==========================================
# PENDIENTES
# ==========================================

const ANGULO_MAXIMO_PENDIENTE: float = 50.0
const DISTANCIA_SNAP_SUELO: float = 12.0

# Velocidad inicial del deslizamiento.
@export var VELOCIDAD_DESLIZAMIENTO_PENDIENTE: float = 190.0

# Aceleración mientras se desliza.
@export var ACELERACION_DESLIZAMIENTO_PENDIENTE: float = 450.0

# Rotación visual máxima para evitar inclinaciones absurdas.
@export var ROTACION_MAXIMA_PENDIENTE: float = 65.0

# Estado de deslizamiento.
var deslizandose_pendiente: bool = false
var velocidad_deslizamiento: float = 0.0
var normal_pendiente: Vector2 = Vector2.ZERO

var tiempo_sin_contacto_pendiente: float = 0.0
const TOLERANCIA_CONTACTO_PENDIENTE: float = 0.1

var tiempo_detectando_pendiente: float = 0.0
const TIEMPO_CONFIRMACION_PENDIENTE: float = 0.08

# ==========================================
# PARED
# ==========================================

const WALL_JUMP_FORCE = 650.0
const WALL_SLIDE_SPEED = 150.0
const WALL_LAYER = 3


# ==========================================
# MADRIGUERA
# ==========================================

const MADRIGUERA_LAYER = 2

var esta_en_madriguera: bool = false


# ==========================================
# TURBO FUEGO
# ==========================================

const ENERGIA_TURBO = 3

@export var FUERZA_TURBO: float = 3500
@export var DURACION_TURBO: float = 0.15
@export var DAÑO_TURBO_FUEGO: int = 3
@export var retrocesoPorTurboFuego: int = 600
@export var INVULNERABILIDAD_POST_TURBO: float = 0.4

# ==========================================
# LAYER MORTAL
# ==========================================
#
# ESTA LAYER ES EXCLUSIVAMENTE PARA
# TILES QUE MATAN AL PLAYER.
#
# LOS ATAQUES NO USAN ESTA LAYER.

const Letal_layer = 4

var turbo_activo: bool = false
var tiempo_invulnerabilidad_turbo: float = 0.0


# ==========================================
# ENEMIGOS GOLPEADOS POR TURBO
# ==========================================

var enemigos_golpeados_turbo: Dictionary = {}


# ==========================================
# OTROS
# ==========================================

@export var speed = 400.0

var screen_size: Vector2
var activo: bool = false

var seSalto: bool = false
var saltoFuego: bool = false

var direccion: float = 0.0


# ==========================================
# DIRECCIÓN VISUAL
# ==========================================

var mirando_izquierda: bool = false


# ==========================================
# ESTADO DE PARED
# ==========================================

var agarrado_pared: bool = false
var pared_normal: Vector2 = Vector2.ZERO
var puede_agarrarse_pared: bool = true

@export var FUERZA_HORIZONTAL_SALTO_PARED: float = 900.0

# ==========================================
# CONFIGURAR HITBOX DE ATAQUE
# ==========================================
#
# Los ataques NO buscan enemigos en una layer
# específica.
#
# Las hitbox detectan cuerpos de todas las layers
# excepto la layer 4.
#
# Después de detectar un cuerpo, el código decide
# qué hacer mediante grupos:
#
# "enemigos"
# "rocas_destructibles"
#
# La layer 4 queda reservada exclusivamente
# para los tiles mortales.



##esta var y este const deben borrarse
var ultimo_physics_diagnostic: int = 0

const UMBRAL_PHYSICS_LENTO: int = 100

func configurar_hitbox_ataque(
	hitbox: Area2D
) -> void:

	# ==========================================
	# LIMPIAR TODA LA MÁSCARA
	# ==========================================

	for layer in range(1, 33):

		hitbox.set_collision_mask_value(
			layer,
			false
		)


	# ==========================================
	# ACTIVAR TODAS LAS LAYERS EXCEPTO LA 4
	# ==========================================

	for layer in range(1, 33):

		if layer == Letal_layer:

			continue

		hitbox.set_collision_mask_value(
			layer,
			true
		)


# ==========================================
# READY
# ==========================================

func _ready() -> void:
	ultimo_physics_diagnostic = Time.get_ticks_msec()
	screen_size = player.get_viewport_rect().size


	# ==========================================
	# HITBOX TURBO
	# ==========================================

	hitbox_turbo.monitoring = false

	configurar_hitbox_ataque(
		hitbox_turbo
	)


	# ==========================================
	# HITBOX TORNADO
	# ==========================================

	hitbox_tornado.monitoring = false

	configurar_hitbox_ataque(
		hitbox_tornado
	)
	collision_tornado.set_deferred(
	"disabled",
	true
	)


	# ==========================================
	# PLAYER
	# ==========================================

	player.set_collision_mask_value(
		MADRIGUERA_LAYER,
		true
	)


	# ==========================================
	# CONFIGURACIÓN NATIVA DE PENDIENTES
	# ==========================================

	player.floor_max_angle = deg_to_rad(
		ANGULO_MAXIMO_PENDIENTE
	)

	player.floor_snap_length = DISTANCIA_SNAP_SUELO

	player.floor_constant_speed = false

	player.floor_stop_on_slope = true


	# ==========================================
	# DEBUG DEL HITBOX
	# ==========================================


# ==========================================
# CAMBIO DE ESTADO
# ==========================================

func cambiar_estado(
	nuevo_estado: EstadoPlayer
) -> void:

	if retroceso_activo:

		

		return


	activo = false

	nuevo_estado.activo = true

	player.estado_actual = nuevo_estado


# ==========================================
# CAMBIAR A MANUAL
# ==========================================

func cambiar_a_manual() -> void:

	if player.estado_actual.retroceso_activo:

		

		return


	estado_manual.activo = true
	estado_automatico.activo = false

	player.estado_actual = estado_manual


# ==========================================
# CAMBIAR A AUTOMÁTICO
# ==========================================

func cambiar_a_automatico() -> void:

	if player.estado_actual.retroceso_activo:


		return


	estado_manual.activo = false
	estado_automatico.activo = true

	player.estado_actual = estado_automatico


# ==========================================
# PENDIENTES DEMASIADO INCLINADAS
# ==========================================

func esta_en_pendiente_demasiado_inclinada() -> bool:

	if not player.is_on_floor():
		return false

	var angulo := rad_to_deg(
		player.get_floor_angle()
	)

	return angulo > ANGULO_MAXIMO_PENDIENTE# ==========================================
# ROTACIÓN POR PENDIENTE
# ==========================================
func actualizar_rotacion_pendiente(delta: float) -> void:

	# No detectar pendientes mientras se salta hacia arriba
	# o el personaje está agarrado a una pared.
	if agarrado_pared or (
		not player.is_on_floor()
		and player.velocity.y < 0.0
	):
		tiempo_detectando_pendiente = 0.0

		if not agarrado_pared:
			deslizandose_pendiente = false
			normal_pendiente = Vector2.ZERO
			velocidad_deslizamiento = 0.0
			tiempo_sin_contacto_pendiente = 0.0

		player.rotation = 0.0
		return

	var pendiente_detectada := false
	var normal_detectada := Vector2.ZERO

	for i in range(player.get_slide_collision_count()):

		var colision := player.get_slide_collision(i)
		var normal := colision.get_normal().normalized()

		# Ignorar paredes y superficies inferiores.
		if normal.y >= -0.1:
			continue

		var angulo := rad_to_deg(
			acos(clampf(-normal.y, -1.0, 1.0))
		)

		# Detectar únicamente superficies más inclinadas
		# que el límite normal, pero no paredes verticales.
		if angulo > ANGULO_MAXIMO_PENDIENTE and angulo < 89.0:

			normal_detectada = normal
			pendiente_detectada = true
			break

	if pendiente_detectada:

		tiempo_sin_contacto_pendiente = 0.0

		# Confirmar el contacto antes de activar la pendiente.
		if not deslizandose_pendiente:

			tiempo_detectando_pendiente += delta

			if tiempo_detectando_pendiente < TIEMPO_CONFIRMACION_PENDIENTE:
				return

		# Activar o actualizar la pendiente.
		normal_pendiente = normal_detectada
		deslizandose_pendiente = true
		tiempo_detectando_pendiente = 0.0

		# Conservar la fórmula de rotación original.
		var nueva_rotacion := clampf(
			atan2(normal_pendiente.x, -normal_pendiente.y),
			deg_to_rad(-ROTACION_MAXIMA_PENDIENTE),
			deg_to_rad(ROTACION_MAXIMA_PENDIENTE)
		)

		rotar_manteniendo_apoyo(
			nueva_rotacion,
			normal_pendiente
		)

		return

	# No se confirmó una pendiente.
	tiempo_detectando_pendiente = 0.0

	# Tolerar pequeñas interrupciones en las colisiones.
	if deslizandose_pendiente:

		tiempo_sin_contacto_pendiente += delta

		if tiempo_sin_contacto_pendiente < TOLERANCIA_CONTACTO_PENDIENTE:
			return

	# Se perdió el contacto con la pendiente.
	deslizandose_pendiente = false
	normal_pendiente = Vector2.ZERO
	velocidad_deslizamiento = 0.0
	tiempo_sin_contacto_pendiente = 0.0
	player.rotation = 0.0
func rotar_manteniendo_apoyo(
	nueva_rotacion: float,
	normal: Vector2
) -> void:

	if collision_shape_player.shape == null:
		player.rotation = nueva_rotacion
		return

	# Obtener los límites locales de la hitbox.
	var rect := collision_shape_player.shape.get_rect()

	# Elegir el extremo inferior que mira hacia la pendiente.
	# Si la normal apunta a la izquierda, apoyarse con el pie derecho.
	# Si apunta a la derecha, apoyarse con el pie izquierdo.
	var punto_local: Vector2

	if normal.x < 0.0:
		punto_local = Vector2(rect.end.x, rect.end.y)
	else:
		punto_local = Vector2(rect.position.x, rect.end.y)

	# Guardar la posición global del punto de apoyo.
	var apoyo_global := (
		collision_shape_player.global_transform
		* punto_local
	)

	# Rotar el personaje.
	player.rotation = nueva_rotacion

	# Calcular dónde quedó el mismo punto tras la rotación.
	var apoyo_nuevo := (
		collision_shape_player.global_transform
		* punto_local
	)

	# Desplazar el personaje para devolver el apoyo a su lugar.
	player.global_position += apoyo_global - apoyo_nuevo


func restaurar_rotacion() -> void:
	if not deslizandose_pendiente:
		player.rotation = 0.0

	deslizandose_pendiente = false
	normal_pendiente = Vector2.ZERO
	velocidad_deslizamiento = 0.0

# ==========================================
# DIRECCIÓN
# ==========================================
func establecer_direccion(
	nueva_direccion: float
) -> void:

	if retroceso_activo:
		return

	if esta_forzado:
		return

	direccion = nueva_direccion

	if direccion != 0:

		mirando_izquierda = direccion < 0

		# No modificar la escala ni los sprites
		# mientras el personaje está agarrado a la pared.
		if not agarrado_pared:
			player.establecer_direccion_visual(
				direccion
			)


# ==========================================
# MOVIMIENTO FORZADO
# ==========================================

func movimiento_forzado(
	direccion_forzada_nueva: Vector2,
	velocidad: float
) -> void:

	esta_forzado = true

	direccion_forzada = (
		direccion_forzada_nueva.normalized()
	)

	velocidad_forzada = velocidad


func detener_movimiento_forzado() -> void:

	esta_forzado = false

	direccion_forzada = Vector2.ZERO

	velocidad_forzada = 0.0

# ==========================================
# RETROCESO
# ==========================================

func retroceso(
	direccion_empuje: Vector2,
	fuerza: float
) -> void:

	print("\n========== INICIO RETROCESO ==========")
	print("[RETROCESO] Dirección recibida: ", direccion_empuje)
	print("[RETROCESO] Fuerza recibida: ", fuerza)
	print("[RETROCESO] PESO: ", PESO)
	print("[RETROCESO] turbo_activo: ", turbo_activo)
	print("[RETROCESO] tiempo_invulnerabilidad_turbo: ", tiempo_invulnerabilidad_turbo)
	print("[RETROCESO] Invulnerabilidad detenida: ", Invulnerabilidad.is_stopped())
	print("[RETROCESO] retroceso_activo: ", retroceso_activo)

	# ==========================================
	# COMPROBAR BLOQUEOS
	# ==========================================

	if turbo_activo or tiempo_invulnerabilidad_turbo > 0.0 or not Invulnerabilidad.is_stopped():

		print("[RETROCESO CANCELADO] Turbo o invulnerabilidad activos.")
		print("========================================\n")
		return


	if retroceso_activo:

		print("[RETROCESO CANCELADO] Ya hay un retroceso activo.")
		print("========================================\n")
		return


	if PESO <= 0:

		print("[RETROCESO CANCELADO] PESO es menor o igual a cero.")
		print("========================================\n")
		return


	if direccion_empuje.length() == 0:

		print("[RETROCESO CANCELADO] La dirección es cero.")
		print("========================================\n")
		return


	# ==========================================
	# ACTIVAR RETROCESO
	# ==========================================

	retroceso_activo = true
	tiempo_retroceso = DURACION_RETROCESO

	estado_anterior_retroceso = player.estado_actual

	print("[RETROCESO] Estado anterior: ", estado_anterior_retroceso)
	print("[RETROCESO] Duración: ", DURACION_RETROCESO)

	direccion = 0.0

	esta_forzado = false
	direccion_forzada = Vector2.ZERO
	velocidad_forzada = 0.0

	# ==========================================
	# CALCULAR VELOCIDAD
	# ==========================================

	var direccion_normalizada := direccion_empuje.normalized()
	var velocidad_retroceso: float = fuerza / PESO

	print("[RETROCESO] Dirección normalizada: ", direccion_normalizada)
	print("[RETROCESO] Velocidad calculada: ", velocidad_retroceso)

	# ==========================================
	# APLICAR VELOCIDAD
	# ==========================================

	var velocidad_anterior: Vector2 = player.velocity

	player.velocity.x = direccion_normalizada.x * velocidad_retroceso
	player.velocity.y = direccion_normalizada.y * velocidad_retroceso

	print("[RETROCESO] Velocidad anterior: ", velocidad_anterior)
	print("[RETROCESO] Velocidad X aplicada: ", player.velocity.x)
	print("[RETROCESO] Velocidad Y aplicada: ", player.velocity.y)
	print("[RETROCESO] Velocidad final aplicada: ", player.velocity)
	print("[RETROCESO] Retroceso activado correctamente.")
	print("=========== FIN INICIO RETROCESO ===========\n")


# ==========================================
# PROCESAR RETROCESO
# ==========================================

func procesar_retroceso(delta: float) -> void:

	if not retroceso_activo:
		return

	print("\n---------- PROCESAR RETROCESO ----------")
	print("[PROCESAR] Delta: ", delta)
	print("[PROCESAR] Tiempo restante antes: ", tiempo_retroceso)
	print("[PROCESAR] Velocidad al entrar: ", player.velocity)
	print("[PROCESAR] Está en el suelo: ", player.is_on_floor())

	tiempo_retroceso -= delta

	# ==========================================
	# GRAVEDAD
	# ==========================================

	if not player.is_on_floor():

		player.velocity.y += GRAVITY * delta

		print("[PROCESAR] Aplicando gravedad: ", GRAVITY * delta)
		print("[PROCESAR] Velocidad Y tras gravedad: ", player.velocity.y)

		print(
			"[PROCESAR] Ángulo del suelo: ",
			rad_to_deg(player.get_floor_angle())
		)

	# ==========================================
	# MOVIMIENTO
	# ==========================================

	var velocidad_antes_move: Vector2 = player.velocity

	player.move_and_slide()

	print("[PROCESAR] Velocidad antes de move_and_slide: ", velocidad_antes_move)
	print("[PROCESAR] Velocidad después de move_and_slide: ", player.velocity)
	print("[PROCESAR] Posición actual: ", player.global_position)
	print("[PROCESAR] Está en el suelo después del movimiento: ", player.is_on_floor())

	# ==========================================
	# MUERTE POR TILE MORTAL
	# ==========================================

	if comprobar_tile_mortal():

		print("[PROCESAR] Retroceso interrumpido por tile mortal.")
		return

	# ==========================================
	# TERMINAR RETROCESO
	# ==========================================

	if tiempo_retroceso <= 0.0:

		print("[PROCESAR] Tiempo agotado. Terminando retroceso.")
		terminar_retroceso()

	else:

		print("[PROCESAR] Tiempo restante: ", tiempo_retroceso)

	print("-------- FIN PROCESAR RETROCESO --------\n")


# ==========================================
# TERMINAR RETROCESO
# ==========================================

func terminar_retroceso() -> void:

	print("\n========== TERMINAR RETROCESO ==========")
	print("[FIN] Velocidad antes de terminar: ", player.velocity)
	print("[FIN] Estado anterior: ", estado_anterior_retroceso)
	print("[FIN] Tiempo restante: ", tiempo_retroceso)

	retroceso_activo = false
	tiempo_retroceso = 0.0

	player.velocity.x = 0.0

	estado_anterior_retroceso = null

	print("[FIN] Velocidad después de terminar: ", player.velocity)
	print("[FIN] retroceso_activo: ", retroceso_activo)
	print("========================================\n")


# ==========================================
# ACTIVAR TORNADO
# ==========================================

func activar_tornado() -> void:

	if retroceso_activo:

		return


	if turbo_activo:

		return


	if tornado_activo:

		return


	# ==========================================
	# SOLO SE PUEDE ACTIVAR EN EL SUELO
	# ==========================================

	if not player.is_on_floor():

		return


	# ==========================================
	# COMPROBAR ENERGÍA
	# ==========================================

	if player.obtener_energia_fuego() < ENERGIA_TORNADO:

		return


	if not player.gastar_energia_fuego(
		ENERGIA_TORNADO
	):

		return


	# ==========================================
	# ACTIVAR TORNADO
	# ==========================================

	tornado_activo = true
	tiempo_tornado = DURACION_TORNADO
	# Desactivar colisión principal del Player
	collision_tornado.set_deferred(
		"disabled",
		false
	)
	collision_shape_player.set_deferred(
		"disabled",
		true
	)
	

	enemigos_golpeados_tornado.clear()


	# ==========================================
	# BLOQUEAR PARED
	# ==========================================

	agarrado_pared = false
	pared_normal = Vector2.ZERO
	puede_agarrarse_pared = false


	# ==========================================
	# LIMPIAR MOVIMIENTO ANTERIOR
	# ==========================================

	esta_forzado = false
	direccion_forzada = Vector2.ZERO
	velocidad_forzada = 0.0


	# ==========================================
	# ROTACIÓN NORMAL
	# ==========================================

	if not deslizandose_pendiente:
		player.rotation = 0.0



	# ==========================================
	# HITBOX TORNADO
	# ==========================================

	hitbox_tornado.monitoring = true

	
	# ==========================================
	# ANIMACIÓN
	# ==========================================

	player.animacion_tornado()


	# ==========================================
	# VELOCIDAD INICIAL
	# ==========================================

	if mirando_izquierda:

		player.velocity.x = -VELOCIDAD_TORNADO

	else:

		player.velocity.x = VELOCIDAD_TORNADO


	player.velocity.y = 0.0





# ==========================================
# PROCESAR TORNADO
# ==========================================

func procesar_tornado(delta: float) -> void:

	if not tornado_activo:

		return


	tiempo_tornado -= delta


	# ==========================================
	# VELOCIDAD CONSTANTE
	# ==========================================

	if mirando_izquierda:

		player.velocity.x = -VELOCIDAD_TORNADO

	else:

		player.velocity.x = VELOCIDAD_TORNADO


	# ==========================================
	# GRAVEDAD
	# ==========================================

	if not player.is_on_floor():

		player.velocity.y += GRAVITY * delta


	# ==========================================
	# MOVIMIENTO
	# ==========================================

	player.move_and_slide()


	# ==========================================
	# GOLPES
	# ==========================================

	comprobar_golpes_tornado()


	# ==========================================
	# MUERTE POR TILE MORTAL
	# ==========================================

	if comprobar_tile_mortal():

		return


	# ==========================================
	# TERMINAR
	# ==========================================

	if tiempo_tornado <= 0.0:

		desactivar_tornado()


# ==========================================
# COMPROBAR GOLPES DEL TORNADO
# ==========================================
# ==========================================
# COMPROBAR GOLPES DEL TORNADO
# ==========================================

func comprobar_golpes_tornado() -> void:

	if not tornado_activo:

		return


	var cuerpos := (
		hitbox_tornado.get_overlapping_bodies()
	)




	for body in cuerpos:

		if body == null:

			continue





		# ==========================================
		# COMPROBAR SI ES ROCA
		# ==========================================

		if body.is_in_group("rocas_destructibles"):




			if body.has_method("romper_por_tornado"):


				body.romper_por_tornado()


			continue


		# ==========================================
		# COMPROBAR SI ES ENEMIGO
		# ==========================================

		if body.is_in_group("enemigos"):



			var id := body.get_instance_id()


			if enemigos_golpeados_tornado.has(id):

				continue


			enemigos_golpeados_tornado[id] = true


			# ==========================================
			# DAÑO
			# ==========================================

			if body.has_method("herir"):

				body.herir(
					DAÑO_TURBO_FUEGO
				)


			# ==========================================
			# RETROCESO
			# ==========================================

			if body.has_method("retroceso"):

				var direccion_empuje := Vector2.RIGHT


				if mirando_izquierda:

					direccion_empuje = Vector2.LEFT


				body.retroceso(
					direccion_empuje,
					retrocesoPorTurboFuego
				)


			continue


		# ==========================================
		# OTRO CUERPO
		# ==========================================

		
# ==========================================
# DESACTIVAR TORNADO
# ==========================================

func desactivar_tornado() -> void:

	if not tornado_activo:

		return


	tornado_activo = false
	tiempo_tornado = 0.0


	# ==========================================
	# DESACTIVAR HITBOX
	# ==========================================

	hitbox_tornado.monitoring = false
	# Volver a activar colisión principal del Player
	collision_shape_player.set_deferred(
		"disabled",
		false
	)
	
	collision_tornado.set_deferred(
		"disabled",
		false
	)


	# ==========================================
	# RESTAURAR PARED
	# ==========================================

	puede_agarrarse_pared = true
	agarrado_pared = false
	pared_normal = Vector2.ZERO


	# ==========================================
	# REDUCIR VELOCIDAD
	# ==========================================

	player.velocity.x = (
		sign(player.velocity.x)
		* MAX_SPEED
	)


	# ==========================================
	# RESTAURAR ANIMACIÓN
	# ==========================================

	player.restablecer_visual_suelo()


	enemigos_golpeados_tornado.clear()



# ==========================================
# MADRIGUERA
# ==========================================

func entrar_madriguera() -> void:



	player.esta_en_madriguera = true

	player.set_collision_mask_value(
		MADRIGUERA_LAYER,
		false
	)


func salir_madriguera() -> void:

	player.esta_en_madriguera = false

	player.set_collision_mask_value(
		MADRIGUERA_LAYER,
		true
	)


func estaEnMadriguera():

	return player.esta_en_madriguera


# ==========================================
# COMPROBAR LAYER DE UNA COLISIÓN
# ==========================================

func colision_tiene_layer(
	collision: KinematicCollision2D,
	layer: int
) -> bool:

	var rid := collision.get_collider_rid()


	if not rid.is_valid():

		return false


	var collision_layer := (
		PhysicsServer2D.body_get_collision_layer(rid)
	)


	return (
		collision_layer
		&
		(1 << (layer - 1))
	) != 0


# ==========================================
# COMPROBAR TILE MORTAL
# ==========================================

func comprobar_tile_mortal() -> bool:

	for i in range(player.get_slide_collision_count()):

		var collision := (
			player.get_slide_collision(i)
		)

		var objeto := collision.get_collider()


		# ==========================================
		# TILE MORTAL
		# ==========================================

		if objeto is TileMapLayer:

			if colision_tiene_layer(
				collision,
				Letal_layer
			):


				morir()

				return true


	return false


# ==========================================
# PROCESO FÍSICO
# ==========================================
func _physics_process(delta: float) -> void:

	var inicio = Time.get_ticks_msec()

	# ==========================================
	# RETROCESO
	# ==========================================

	var ahora = Time.get_ticks_msec()

	var tiempo_desde_ultimo = (
		ahora - ultimo_physics_diagnostic
	)

	ultimo_physics_diagnostic = ahora

	if tiempo_desde_ultimo >= UMBRAL_PHYSICS_LENTO:

		print(
			"⚠️ INTERVALO PHYSICS LENTO (este print fue hecho desde estado player) | ",
			get_path(),
			" | ",
			tiempo_desde_ultimo,
			" ms desde el último physics"
		)

	if retroceso_activo:

		procesar_retroceso(delta)

		return


	# ==========================================
	# ESTADO ACTIVO
	# ==========================================

	if not activo:

		return


	# ==========================================
	# TURBO
	# ==========================================

	if turbo_activo:

		comprobar_golpes_turbo()


	# ==========================================
	# MOVIMIENTO FORZADO
	# ==========================================

	if esta_forzado:

		# ==========================================
		# MANTENER LA ROTACIÓN EN CERO
		# SIN MODIFICAR LAS ESCALAS
		# ==========================================

		player.rotation = 0.0
		player.animated_sprite.rotation = 0.0
		player.animated_sprite_pared.rotation = 0.0

		player.velocity = (
			direccion_forzada
			* velocidad_forzada
		)

		player.move_and_slide()

		# ==========================================
		# RESTABLECER LAS ROTACIONES
		# ==========================================

		player.rotation = 0.0
		player.animated_sprite.rotation = 0.0
		player.animated_sprite_pared.rotation = 0.0

		print(
			"ROTACIÓN PLAYER: ", rad_to_deg(player.rotation),
			" | SPRITE: ", rad_to_deg(player.animated_sprite.rotation),
			" | SPRITE PARED: ", rad_to_deg(player.animated_sprite_pared.rotation)
		)

		# ==========================================
		# COMPROBAR SI EL MOVIMIENTO FORZADO
		# CHOCÓ CONTRA ALGO
		# ==========================================

		for i in range(player.get_slide_collision_count()):

			var collision := (
				player.get_slide_collision(i)
			)

			var collider := collision.get_collider()

			if collider == null:
				continue

			var normal := collision.get_normal()

			print("========================================")
			print("MOVIMIENTO FORZADO: COLISIÓN")
			print("OBJETO = ", collider.name)
			print("RUTA = ", collider.get_path())
			print("NORMAL = ", normal)
			print("DIRECCIÓN FORZADA = ", direccion_forzada)
			print("VELOCIDAD FORZADA = ", velocidad_forzada)
			print("========================================")

			# ==========================================
			# SI EL OBJETO ESTÁ FRENANDO EL MOVIMIENTO
			# ==========================================

			if direccion_forzada.dot(-normal) > 0.5:

				print(
					"MOVIMIENTO FORZADO: EL OBJETO ESTÁ FRENANDO AL PLAYER"
				)

				player.velocity = Vector2.ZERO

				esta_forzado = false
				direccion_forzada = Vector2.ZERO
				velocidad_forzada = 0.0

				return


		# ==========================================
		# MUERTE AL TOCAR TILE MORTAL
		# ==========================================

		if comprobar_tile_mortal():

			return


		# ==========================================
		# NO EJECUTAR EL MOVIMIENTO NORMAL
		# ==========================================

		return


	# ==========================================
	# TORNADO
	# ==========================================

	if tornado_activo:

		procesar_tornado(delta)

		return


	# ==========================================
	# INVULNERABILIDAD POST TURBO
	# ==========================================

	if tiempo_invulnerabilidad_turbo > 0.0:

		tiempo_invulnerabilidad_turbo -= delta

		if tiempo_invulnerabilidad_turbo < 0.0:

			tiempo_invulnerabilidad_turbo = 0.0


# ==========================================
# MOVIMIENTO Y GRAVEDAD
# ===================================
	if agarrado_pared:
		# Mantener el contacto con la pared sin bloquear la caída.
		# La normal apunta desde la pared hacia el personaje.
		player.velocity.x = -pared_normal.x * 20.0

	elif deslizandose_pendiente and normal_pendiente != Vector2.ZERO:
		procesar_pendiente_inclinada(delta)

	elif not turbo_activo:
		if direccion != 0:
			player.velocity.x = move_toward(
				player.velocity.x,
				direccion * MAX_SPEED,
				ACCELERATION * delta
			)
		else:
			player.velocity.x = move_toward(
				player.velocity.x,
				0.0,
				FRICTION * delta
			)
	if not player.is_on_floor():
		if agarrado_pared:
			player.velocity.y = min(
				player.velocity.y + GRAVITY * delta,
				WALL_SLIDE_SPEED
			)
		elif not turbo_activo:
			if player.velocity.y > 0:
				player.velocity.y += GRAVITY_CAIDA * delta
			else:
				player.velocity.y += GRAVITY * delta


# ==========================================
# MOVIMIENTO FÍSICO
# ==========================================

	player.move_and_slide()

	actualizar_rotacion_pendiente(delta)

	if comprobar_tile_mortal():
		return



	# ==========================================
	# MUERTE AL TOCAR TILE MORTAL
	# ==========================================

	if comprobar_tile_mortal():

		return


	# ==========================================
	# PARED
	# ==========================================

	if not player.is_on_wall():

		puede_agarrarse_pared = true

	if not turbo_activo:
		detectar_pared()

	# ==========================================
	# ESTADO DE SUELO
	# ==========================================

	if player.is_on_floor() and not turbo_activo and not deslizandose_pendiente:
		seSalto = false
		saltoFuego = false

		agarrado_pared = false
		pared_normal = Vector2.ZERO

		puede_agarrarse_pared = true

		player.restablecer_visual_suelo()

	# ANIMACIÓN
	if not turbo_activo:
		if deslizandose_pendiente:
			player.animated_sprite.visible = true
			player.animated_sprite_pared.visible = false
			player.animated_sprite.flip_v = false

			if player.animated_sprite.animation != "quieta":
				player.animated_sprite.play("quieta")
		else:
			player.actualizar_animacion(direccion)
		

# ==========================================
# MOVIMIENTO SOBRE PENDIENTE INCLINADA
# ==========================================

func procesar_pendiente_inclinada(delta: float) -> void:
	if normal_pendiente == Vector2.ZERO:
		return

	# Dirección paralela a la pendiente, orientada cuesta abajo.
	var tangente := Vector2(
		normal_pendiente.y,
		-normal_pendiente.x
	).normalized()

	if tangente.y < 0.0:
		tangente = -tangente

	# La gravedad acelera el descenso.
	var aceleracion := Vector2.DOWN.dot(tangente) * GRAVITY_CAIDA

	velocidad_deslizamiento += aceleracion * delta

	# Velocidad mínima de deslizamiento.
	velocidad_deslizamiento = maxf(
		velocidad_deslizamiento,
		320.0
	)

	# Límite para que no alcance la velocidad de caída normal.
	velocidad_deslizamiento = minf(
		velocidad_deslizamiento,
		850.0
	)

	# Intentar caminar contra la pendiente frena el descenso.
	if direccion != 0.0:
		var movimiento_deseado := Vector2(direccion, 0.0)
		var componente_caminar := movimiento_deseado.dot(tangente)

		velocidad_deslizamiento -= (
			componente_caminar * ACCELERATION * delta
		)

		velocidad_deslizamiento = clampf(
			velocidad_deslizamiento,
			0.0,
			850.0
		)

	player.velocity = tangente * velocidad_deslizamiento

# ==========================================
# SALTO
# ==========================================
# ==========================================
# SALTO
# ==========================================# ==========================================
# SALTO
# ==========================================
func saltar() -> void:

	if retroceso_activo:
		return

	if esta_forzado:
		return

	if tornado_activo:
		return

	if turbo_activo:
		return

	if agarrado_pared:

		var direccion_salto := pared_normal.x

		player.velocity.x = (
			direccion_salto * FUERZA_HORIZONTAL_SALTO_PARED
		)

		player.velocity.y = JUMP_FORCE

		agarrado_pared = false
		pared_normal = Vector2.ZERO
		puede_agarrarse_pared = false

		seSalto = false
		saltoFuego = false

		restaurar_rotacion()
		player.restablecer_visual_suelo()

		return

	if player.is_on_floor() or deslizandose_pendiente:

		# Cancelar el deslizamiento.
		deslizandose_pendiente = false
		normal_pendiente = Vector2.ZERO
		velocidad_deslizamiento = 0.0
		tiempo_sin_contacto_pendiente = 0.0
		tiempo_detectando_pendiente = 0.0

		player.rotation = 0.0

		# Aplicar el salto original.
		player.velocity.y = JUMP_FORCE

		# Esperar antes de comprobar si soltó el botón.
		await get_tree().create_timer(0.12).timeout

		# Usar el nombre correcto de la acción: "salto".
		if not Input.is_action_pressed("salto"):
			if player.velocity.y < 0.0:
				player.velocity.y *= 0.80

		seSalto = false
		saltoFuego = false

		return

	if not seSalto:

		if player.poseeDobleSalto:

			player.velocity.y = JUMP_FORCE

			seSalto = true

			player.animacion_salto()

# ==========================================
# SALTO FUEGO
# ==========================================

func salto_fuego() -> void:

	if esta_forzado:
		return
	if retroceso_activo:

		

		return


	if turbo_activo:

		return
	
	if agarrado_pared:

		return

	if player.obtener_energia_fuego() >= 2 \
	and saltoFuego == false \
	and not player.is_on_floor():

		if not player.gastar_energia_fuego(2):

			return


		print(
			"SALTO FUEGO | Energía actual: ",
			player.obtener_energia_fuego()
		)


		player.velocity.y = JUMP_FIRE_FORCE

		fire()

		saltoFuego = true


		agarrado_pared = false
		pared_normal = Vector2.ZERO


		
		if not deslizandose_pendiente:
			player.rotation = 0.0

		player.animated_sprite.flip_v = false


# ==========================================
# TURBO FUEGO
# ==========================================

func activar_turbo() -> void:
	if esta_forzado:
		return
	if retroceso_activo:

		print(
			"TURBO BLOQUEADO POR RETROCESO"
		)

		return


	if tornado_activo:

		return


	if player.obtener_energia_fuego() < ENERGIA_TURBO:

		return


	if turbo_activo:

		return


	if agarrado_pared:

		return


	print("")
	print("==========================================")
	print("!!! ACTIVANDO TURBO !!!")
	print("==========================================")


	turbo_activo = true

	tiempo_invulnerabilidad_turbo = 0.0


	if not player.gastar_energia_fuego(
		ENERGIA_TURBO
	):

		turbo_activo = false

		return


	print(
		"TURBO | Energía actual: ",
		player.obtener_energia_fuego()
	)


	enemigos_golpeados_turbo.clear()


	agarrado_pared = false
	pared_normal = Vector2.ZERO

	if not deslizandose_pendiente:
		player.rotation = 0.0


	Invulnerabilidad.stop()


	# ==========================================
	# HITBOX TURBO
	# ==========================================
	#
	# La hitbox NO busca enemigos en layer 4.
	#
	# La configuración ya fue realizada en _ready():
	# detecta todas las layers excepto la 4.
	#
	# El grupo "enemigos" decide si el cuerpo
	# realmente es un enemigo.

	print("==========================================")
	print("CONFIGURACIÓN HITBOX TURBO")
	print("==========================================")


	print(
		"Collision layer: ",
		hitbox_turbo.collision_layer
	)

	print(
		"Collision mask: ",
		hitbox_turbo.collision_mask
	)

	print(
		"Monitoring ANTES: ",
		hitbox_turbo.monitoring
	)


	hitbox_turbo.monitoring = true


	print(
		"Collision mask DESPUÉS: ",
		hitbox_turbo.collision_mask
	)

	print(
		"Layer 4 detectada: ",
		hitbox_turbo.get_collision_mask_value(
			Letal_layer
		)
	)

	print(
		"Hitbox monitoring DESPUÉS: ",
		hitbox_turbo.monitoring
	)

	print("==========================================")


	player.animacion_turbo()


	# ==========================================
	# DIRECCIÓN
	# ==========================================

	if mirando_izquierda:

		player.velocity.x = -FUERZA_TURBO

	else:

		player.velocity.x = FUERZA_TURBO


	print(
		"Velocity del turbo: ",
		player.velocity
	)

	print("==========================================")
	print("TURBO ACTIVADO")
	print("==========================================")


	await get_tree().create_timer(
		DURACION_TURBO
	).timeout


	if turbo_activo:

		desactivar_turbo()


# ==========================================
# COMPROBAR GOLPES DEL TURBO
# ==========================================

func comprobar_golpes_turbo() -> void:

	if not turbo_activo:

		return


	var cuerpos := (
		hitbox_turbo.get_overlapping_bodies()
	)


	if cuerpos.size() == 0:

		return


	print("")
	print("==========================================")
	print(
		"TURBO DETECTÓ CUERPOS: ",
		cuerpos.size()
	)
	print("==========================================")


	for body in cuerpos:

		if body == null:

			continue


		print(
			"Cuerpo detectado: ",
			body
		)

		print(
			"Nombre: ",
			body.name
		)

		print(
			"Es enemigo: ",
			body.is_in_group("enemigos")
		)

		print(
			"Tiene herir(): ",
			body.has_method("herir")
		)

		print(
			"Tiene retroceso(): ",
			body.has_method("retroceso")
		)


		# ==========================================
		# FILTRO DE ENEMIGO
		# ==========================================

		if not body.is_in_group("enemigos"):

			print(
				"IGNORADO: NO ES DEL GRUPO enemigos"
			)

			continue


		var id := body.get_instance_id()


		if enemigos_golpeados_turbo.has(id):

			print(
				"IGNORADO: YA FUE GOLPEADO POR ESTE TURBO"
			)

			continue


		enemigos_golpeados_turbo[id] = true


		# ==========================================
		# DAÑO
		# ==========================================

		print("")
		print("==========================================")
		print("!!! TURBO GOLPEÓ ENEMIGO !!!")
		print("==========================================")


		print(
			"Enemigo: ",
			body
		)

		print(
			"Daño: ",
			DAÑO_TURBO_FUEGO
		)


		if body.has_method("herir"):

			body.herir(
				DAÑO_TURBO_FUEGO
			)

			print(
				"DAÑO APLICADO CORRECTAMENTE"
			)

		else:

			print(
				"ERROR: EL ENEMIGO NO TIENE MÉTODO herir()"
			)


		# ==========================================
		# RETROCESO DEL ENEMIGO
		# ==========================================

		if body.has_method("retroceso"):

			var direccion_empuje := Vector2.RIGHT


			if mirando_izquierda:

				direccion_empuje = Vector2.LEFT


			print(
				"Aplicando retroceso al enemigo"
			)

			print(
				"Dirección: ",
				direccion_empuje
			)

			print(
				"Fuerza: ",
				retrocesoPorTurboFuego
			)


			body.retroceso(
				direccion_empuje,
				retrocesoPorTurboFuego
			)

		else:

			print(
				"El enemigo no tiene método retroceso()"
			)


		print("==========================================")
		print("FIN DEL GOLPE DEL TURBO")
		print("==========================================")
		print("")


# ==========================================
# DESACTIVAR TURBO
# ==========================================

func desactivar_turbo() -> void:


	turbo_activo = false

	hitbox_turbo.monitoring = false


	# ==========================================
	# IMPORTANTE
	# ==========================================
	#
	# Ya NO se modifica la máscara de colisión
	# del Player.
	#
	# Layer 4 pertenece exclusivamente a los
	# tiles mortales.
	#
	# El ataque nunca utilizó esa layer.

	tiempo_invulnerabilidad_turbo = (
		INVULNERABILIDAD_POST_TURBO
	)


	player.velocity.x = (
		sign(player.velocity.x)
		* MAX_SPEED
	)


	player.animated_sprite.visible = true



# ==========================================
# GOLPE DEL TURBO POR SEÑAL
# ==========================================

func _on_hitbox_turbo_body_entered(
	body: Node2D
) -> void:






	if not turbo_activo:

	

		return


	# ==========================================
	# FILTRO DE ENEMIGO
	# ==========================================

	if not body.is_in_group("enemigos"):

	

		return


	var id := body.get_instance_id()


	if enemigos_golpeados_turbo.has(id):


		return


	enemigos_golpeados_turbo[id] = true


	# ==========================================
	# DAÑO
	# ==========================================





	if body.has_method("herir"):

		body.herir(
			DAÑO_TURBO_FUEGO
		)



	# ==========================================
	# RETROCESO DEL ENEMIGO
	# ==========================================

	if body.has_method("retroceso"):

		var direccion_empuje := Vector2.RIGHT


		if mirando_izquierda:

			direccion_empuje = Vector2.LEFT




		body.retroceso(
			direccion_empuje,
			retrocesoPorTurboFuego
		)

	



# ==========================================
# PARED
# ==========================================
# ==========================================
# PARED
# ==========================================

func detectar_pared() -> void:

	if deslizandose_pendiente:
		agarrado_pared = false
		pared_normal = Vector2.ZERO
		player.animated_sprite.visible = true
		player.animated_sprite_pared.visible = false
		return

	if not puede_agarrarse_pared or tornado_activo:
		agarrado_pared = false
		pared_normal = Vector2.ZERO

		if not deslizandose_pendiente:
			player.rotation = 0.0
		return

	if player.is_on_floor():
		agarrado_pared = false
		pared_normal = Vector2.ZERO
		return

	if not player.is_on_wall():
		agarrado_pared = false
		pared_normal = Vector2.ZERO
		return

	for i in range(player.get_slide_collision_count()):

		var collision := player.get_slide_collision(i)

		if abs(collision.get_normal().x) < 0.8:
			continue

		if not colision_tiene_layer(collision, WALL_LAYER):
			continue

		agarrado_pared = true
		pared_normal = collision.get_normal()
		player.velocity.x = 0.0

		seSalto = false
		saltoFuego = false

		player.animacion_pared(pared_normal)
		return

	agarrado_pared = false
	pared_normal = Vector2.ZERO

	if not deslizandose_pendiente:
		player.rotation = 0.0

# ==========================================
# OTROS
# ==========================================

func _on_body_entered(body: Node2D) -> void:

	player.hide()

	hit.emit()

	collision_shape.set_deferred(
		"disabled",
		true
	)


# ==========================================
# PROYECTILES
# ==========================================

func fire():

	var projectile: AbstractProyectile = (
		projectile_scene.instantiate()
	)

	projectile_container.add_child(projectile)

	projectile.set_starting_values(
		fire_position.global_position,
		Vector2.DOWN
	)

	projectile.delete_requested.connect(
		_on_projectile_delete_requested
	)


func _on_projectile_delete_requested(
	projectile
):

	projectile_container.remove_child(
		projectile
	)

	projectile.queue_free()


# ==========================================
# INICIAR PLAYER
# ==========================================

func start(
	pos: Vector2,
	projectile_container_nuevo
) -> void:

	player.position = pos

	activo = true

	player.show()

	collision_shape.set_deferred(
		"disabled",
		false
	)

	self.projectile_container = (
		projectile_container_nuevo
	)

	if not deslizandose_pendiente:
		player.rotation = 0.0


	agarrado_pared = false
	pared_normal = Vector2.ZERO
	puede_agarrarse_pared = true


	player.set_collision_mask_value(
		MADRIGUERA_LAYER,
		true
	)

	set_physics_process(true)
	set_process(true)


# ==========================================
# DAÑO
# ==========================================

func herir(num: int) -> void:

	if turbo_activo:


		return


	if tiempo_invulnerabilidad_turbo > 0.0:


		return


	if Invulnerabilidad.is_stopped():

		# ==========================================
		# LA VIDA PERTENECE AL PLAYER
		# ==========================================

		player.vida -= num

		player.actualizar_barra_vida()

		Invulnerabilidad.start()

		animacionHerida()


		if player.getVidaActual() <= 0:

			morir()


# ==========================================
# ANIMACIÓN DE HERIDA
# ==========================================

func animacionHerida():

	while not Invulnerabilidad.is_stopped():

		player.animated_sprite.visible = false

		await get_tree().create_timer(
			0.2
		).timeout

		player.animated_sprite.visible = true

		await get_tree().create_timer(
			0.2
		).timeout

	player.animated_sprite.visible = true


# ==========================================
# MORIR
# ==========================================

func morir():

	died.emit()

	set_physics_process(false)
	set_process(false)

	player.velocity = Vector2.ZERO

	player.hide()
