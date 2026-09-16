
# EstadoPlayer.gd
extends Node
class_name EstadoPlayer


# ==========================================
# PLAYER
# ==========================================

# EstadoPlayer NO es el Player.
# Es la clase padre de EstadoManual y
# EstadoAutomatico.
#
# El Player real es el padre de estos nodos.

@onready var player: CharacterBody2D = get_parent()


# ==========================================
# ESTADO
# ==========================================

# IMPORTANTE:
# El estado_actual pertenece al PLAYER.
#
# NO declaramos:
# var estado_actual: EstadoPlayer
#
# porque eso crearía una copia del estado
# dentro de cada EstadoPlayer.


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
# PROYECTILES
# ==========================================

@export var projectile_scene: PackedScene

var projectile_container: Node


# ==========================================
# REFERENCIAS
# ==========================================

@onready var Invulnerabilidad: Timer = $"../Invulnerabilidad"

@onready var fire_position: Marker2D = $"../FirePosition"

@onready var animated_sprite: AnimatedSprite2D = $"../AnimatedSprite2D"

@onready var collision_shape: CollisionShape2D = $"../CollisionShape2D"

@onready var barraVida = $"../../CanvasLayer2/barraDeVida"

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

@export var retrocesoPorTurboFuego: int = 200

@export var INVULNERABILIDAD_POST_TURBO: float = 0.4

const ENEMIGO_LAYER = 4

var turbo_activo: bool = false

var tiempo_invulnerabilidad_turbo: float = 0.0

var colision_enemigos_original: bool


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


# ==========================================
# VIDA
# ==========================================

var vida: int = 5


# ==========================================
# READY
# ==========================================

func _ready() -> void:

	screen_size = player.get_viewport_rect().size


	# ==========================================
	# VIDA
	# ==========================================

	barraVida.max_value = vida

	barraVida.value = vida


	# ==========================================
	# HITBOX TURBO
	# ==========================================

	hitbox_turbo.monitoring = false

	hitbox_turbo.set_collision_mask_value(
		ENEMIGO_LAYER,
		true
	)


	colision_enemigos_original = (
		player.get_collision_mask_value(
			ENEMIGO_LAYER
		)
	)


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

	print("==========================================")
	print("PLAYER READY")
	print("PESO: ", PESO)

	print(
		"HitboxTurbo collision_layer: ",
		hitbox_turbo.collision_layer
	)

	print(
		"HitboxTurbo collision_mask: ",
		hitbox_turbo.collision_mask
	)

	print(
		"HitboxTurbo detecta ENEMIGO_LAYER: ",
		hitbox_turbo.get_collision_mask_value(
			ENEMIGO_LAYER
		)
	)

	print(
		"HitboxTurbo monitoring: ",
		hitbox_turbo.monitoring
	)

	print("==========================================")


# ==========================================
# CAMBIO DE ESTADO
# ==========================================

func cambiar_estado(
	nuevo_estado: EstadoPlayer
) -> void:

	if retroceso_activo:

		print(
			"CAMBIO DE ESTADO BLOQUEADO POR RETROCESO"
		)

		return


	activo = false

	nuevo_estado.activo = true

	# ==========================================
	# IMPORTANTE
	# ==========================================
	# El estado actual pertenece al PLAYER.
	#
	# Antes estaba:
	#
	# estado_actual = nuevo_estado
	#
	# Eso modificaba la variable del EstadoPlayer.
	#
	# Ahora:
	#
	# player.estado_actual = nuevo_estado
	#
	# Esto modifica el estado real del Player.

	player.estado_actual = nuevo_estado


# ==========================================
# CAMBIAR A MANUAL
# ==========================================

func cambiar_a_manual() -> void:

	if player.estado_actual.retroceso_activo:

		print(
			"CAMBIO A MANUAL BLOQUEADO POR RETROCESO"
		)

		return


	estado_manual.activo = true

	estado_automatico.activo = false

	# El estado actual REAL está en Player.
	player.estado_actual = estado_manual


# ==========================================
# CAMBIAR A AUTOMÁTICO
# ==========================================

func cambiar_a_automatico() -> void:

	if player.estado_actual.retroceso_activo:

		print(
			"CAMBIO A AUTOMÁTICO BLOQUEADO POR RETROCESO"
		)

		return


	estado_manual.activo = false

	estado_automatico.activo = true

	# El estado actual REAL está en Player.
	player.estado_actual = estado_automatico


# ==========================================
# DIRECCIÓN
# ==========================================

func establecer_direccion(
	nueva_direccion: float
) -> void:

	if retroceso_activo:

		print(
			"DIRECCIÓN BLOQUEADA POR RETROCESO"
		)

		return


	direccion = nueva_direccion


	if direccion != 0:

		mirando_izquierda = direccion < 0


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

	print("")
	print("==========================================")
	print("!!! RETROCESO RECIBIDO !!!")
	print("==========================================")

	print(
		"Dirección recibida: ",
		direccion_empuje
	)

	print(
		"Fuerza recibida: ",
		fuerza
	)

	print(
		"Peso actual: ",
		PESO
	)

	print(
		"retroceso_activo antes: ",
		retroceso_activo
	)

	print(
		"Velocity antes: ",
		player.velocity
	)


	if retroceso_activo:

		print(
			"RETROCESO IGNORADO: YA ESTABA EN RETROCESO"
		)

		return


	if PESO <= 0:

		print("ERROR: PESO <= 0")

		return


	if direccion_empuje.length() == 0:

		print(
			"ERROR: DIRECCIÓN DE RETROCESO VACÍA"
		)

		return


	retroceso_activo = true

	tiempo_retroceso = DURACION_RETROCESO

	estado_anterior_retroceso = player.estado_actual


	print(
		"Estado anterior: ",
		estado_anterior_retroceso
	)


	direccion = 0.0

	esta_forzado = false

	direccion_forzada = Vector2.ZERO

	velocidad_forzada = 0.0


	var direccion_normalizada := (
		direccion_empuje.normalized()
	)

	var velocidad_retroceso := (
		fuerza / PESO
	)


	print("------------------------------------------")

	print(
		"Dirección normalizada: ",
		direccion_normalizada
	)

	print(
		"Fuerza: ",
		fuerza
	)

	print(
		"Peso: ",
		PESO
	)

	print(
		"Velocidad calculada: ",
		velocidad_retroceso
	)

	print("------------------------------------------")


	player.velocity.x = (
		direccion_normalizada.x
		* velocidad_retroceso
	)

	player.velocity.y = (
		direccion_normalizada.y
		* velocidad_retroceso
	)


	print(
		"Velocity DESPUÉS de aplicar retroceso: "
	)

	print(player.velocity)

	print(
		"retroceso_activo: ",
		retroceso_activo
	)

	print("==========================================")
	print("RETROCESO ACTIVADO")
	print("==========================================")
	print("")


# ==========================================
# PROCESAR RETROCESO
# ==========================================

func procesar_retroceso(delta: float) -> void:

	if not retroceso_activo:

		return


	print(
		"RETROCESO PROCESANDO | tiempo=",
		tiempo_retroceso,
		" | velocity=",
		player.velocity,
		" | posicion=",
		player.global_position
	)


	tiempo_retroceso -= delta


	if not player.is_on_floor():

		player.velocity.y += GRAVITY * delta


	player.move_and_slide()


	print(
		"RETROCESO DESPUÉS move_and_slide | ",
		"velocity=",
		player.velocity,
		" | posicion=",
		player.global_position
	)


	if tiempo_retroceso <= 0.0:

		terminar_retroceso()


# ==========================================
# TERMINAR RETROCESO
# ==========================================

func terminar_retroceso() -> void:

	print("")
	print("==========================================")
	print("!!! TERMINÓ RETROCESO !!!")
	print("==========================================")

	print(
		"Velocity antes de terminar: ",
		player.velocity
	)

	print(
		"Posición final: ",
		player.global_position
	)


	retroceso_activo = false

	tiempo_retroceso = 0.0

	player.velocity.x = 0.0

	estado_anterior_retroceso = null


	print(
		"Velocity después de terminar: ",
		player.velocity
	)

	print("CONTROL DE MOVIMIENTO RESTAURADO")

	print("==========================================")
	print("CONTROL DEVUELTO")
	print("==========================================")


# ==========================================
# MADRIGUERA
# ==========================================

func entrar_madriguera() -> void:

	print("el personaje intenta entrar")

	player.esta_en_madriguera = true

	print(
		"antes de cambiar mask: ",
		player.get_collision_mask()
	)

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
# PROCESO FÍSICO
# ==========================================

func _physics_process(delta: float) -> void:

	# ==========================================
	# RETROCESO
	# ==========================================

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

		player.velocity = (
			direccion_forzada
			* velocidad_forzada
		)

		player.move_and_slide()

		return


	# ==========================================
	# INVULNERABILIDAD POST TURBO
	# ==========================================

	if tiempo_invulnerabilidad_turbo > 0.0:

		tiempo_invulnerabilidad_turbo -= delta

		if tiempo_invulnerabilidad_turbo < 0.0:

			tiempo_invulnerabilidad_turbo = 0.0


	# ==========================================
	# MOVIMIENTO HORIZONTAL
	# ==========================================

	if not turbo_activo:

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


	# ==========================================
	# GRAVEDAD
	# ==========================================

	if not player.is_on_floor():

		if agarrado_pared:

			player.velocity.y = min(
				player.velocity.y + GRAVITY * delta,
				WALL_SLIDE_SPEED
			)

		elif not turbo_activo:

			player.velocity.y += GRAVITY * delta


	# ==========================================
	# MOVIMIENTO FÍSICO
	# ==========================================

	player.move_and_slide()


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

	if player.is_on_floor() and not turbo_activo:

		seSalto = false

		saltoFuego = false

		agarrado_pared = false

		pared_normal = Vector2.ZERO

		puede_agarrarse_pared = true

		player.rotation = 0.0

		animated_sprite.flip_v = false


	# ==========================================
	# ANIMACIÓN
	# ==========================================

	if not turbo_activo:

		actualizar_animacion(direccion)


# ==========================================
# SALTO
# ==========================================

func saltar() -> void:

	if retroceso_activo:

		print("SALTO BLOQUEADO POR RETROCESO")

		return


	if turbo_activo:

		return


	if agarrado_pared:

		var direccion_salto := pared_normal.x

		player.velocity.x = (
			direccion_salto
			* WALL_JUMP_FORCE
		)

		player.velocity.y = JUMP_FORCE

		seSalto = false

		saltoFuego = false

		agarrado_pared = false

		pared_normal = Vector2.ZERO

		puede_agarrarse_pared = false

		player.rotation = 0.0

		animated_sprite.flip_v = false

		return


	if player.is_on_floor():

		player.velocity.y = JUMP_FORCE

		seSalto = false

		return


	if not seSalto:

		player.velocity.y = JUMP_FORCE

		seSalto = true

		player.rotation = 0.0

		animated_sprite.flip_v = false

		animated_sprite.flip_h = mirando_izquierda

		animated_sprite.animation = "salto"

		animated_sprite.play()


# ==========================================
# SALTO FUEGO
# ==========================================

func salto_fuego() -> void:

	if retroceso_activo:

		print(
			"SALTO FUEGO BLOQUEADO POR RETROCESO"
		)

		return


	if turbo_activo:

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

		player.rotation = 0.0

		animated_sprite.flip_v = false


# ==========================================
# TURBO FUEGO
# ==========================================

func activar_turbo() -> void:

	if retroceso_activo:

		print(
			"TURBO BLOQUEADO POR RETROCESO"
		)

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


	# ==========================================
	# REINICIAR LISTA DE ENEMIGOS
	# ==========================================

	enemigos_golpeados_turbo.clear()


	agarrado_pared = false

	pared_normal = Vector2.ZERO

	player.rotation = 0.0

	animated_sprite.flip_v = false

	Invulnerabilidad.stop()


	# ==========================================
	# GUARDAR MÁSCARA ORIGINAL
	# ==========================================

	colision_enemigos_original = (
		player.get_collision_mask_value(
			ENEMIGO_LAYER
		)
	)


	# ==========================================
	# HITBOX TURBO
	# ==========================================

	print("==========================================")
	print("CONFIGURACIÓN HITBOX TURBO")
	print("==========================================")

	print(
		"Collision layer ANTES: ",
		hitbox_turbo.collision_layer
	)

	print(
		"Collision mask ANTES: ",
		hitbox_turbo.collision_mask
	)

	print(
		"Detecta layer enemigo ANTES: ",
		hitbox_turbo.get_collision_mask_value(
			ENEMIGO_LAYER
		)
	)

	print(
		"Monitoring ANTES: ",
		hitbox_turbo.monitoring
	)


	hitbox_turbo.set_collision_mask_value(
		ENEMIGO_LAYER,
		true
	)

	hitbox_turbo.monitoring = true


	print(
		"Collision mask DESPUÉS: ",
		hitbox_turbo.collision_mask
	)

	print(
		"Detecta layer enemigo DESPUÉS: ",
		hitbox_turbo.get_collision_mask_value(
			ENEMIGO_LAYER
		)
	)

	print(
		"Hitbox monitoring DESPUÉS: ",
		hitbox_turbo.monitoring
	)

	print("==========================================")


	# ==========================================
	# ANIMACIÓN
	# ==========================================

	animated_sprite.animation = "turboFuego"

	animated_sprite.play()


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

	print("")
	print("==========================================")
	print("DESACTIVANDO TURBO")
	print("==========================================")


	turbo_activo = false

	hitbox_turbo.monitoring = false


	player.set_collision_mask_value(
		ENEMIGO_LAYER,
		colision_enemigos_original
	)


	tiempo_invulnerabilidad_turbo = (
		INVULNERABILIDAD_POST_TURBO
	)


	player.velocity.x = (
		sign(player.velocity.x)
		* MAX_SPEED
	)


	animated_sprite.visible = true


	print(
		"Hitbox monitoring: ",
		hitbox_turbo.monitoring
	)

	print(
		"Enemigos golpeados durante turbo: ",
		enemigos_golpeados_turbo.size()
	)

	print("==========================================")
	print("TURBO TERMINADO")
	print("==========================================")


# ==========================================
# GOLPE DEL TURBO POR SEÑAL
# ==========================================

func _on_hitbox_turbo_body_entered(
	body: Node2D
) -> void:

	print("")
	print("==========================================")
	print("!!! HITBOX TURBO DETECTÓ UN BODY !!!")
	print("==========================================")

	print(
		"Body: ",
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
		"Turbo activo: ",
		turbo_activo
	)


	if not turbo_activo:

		print(
			"Ignorado porque el turbo no está activo"
		)

		return


	if not body.is_in_group("enemigos"):

		print(
			"Ignorado porque NO pertenece al grupo enemigos"
		)

		return


	var id := body.get_instance_id()


	if enemigos_golpeados_turbo.has(id):

		print(
			"Ignorado porque ya recibió daño"
		)

		return


	enemigos_golpeados_turbo[id] = true


	# ==========================================
	# DAÑO
	# ==========================================

	print("!!! APLICANDO DAÑO DEL TURBO !!!")

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
			"ERROR: el enemigo no tiene método herir()"
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


# ==========================================
# PARED
# ==========================================

func detectar_pared() -> void:

	if not puede_agarrarse_pared:

		agarrado_pared = false

		pared_normal = Vector2.ZERO

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


	for i in player.get_slide_collision_count():

		var collision := player.get_slide_collision(i)

		var collider := collision.get_collider()


		if abs(collision.get_normal().x) < 0.8:

			continue


		if not collider is CollisionObject2D:

			continue


		if collider.collision_layer & (
			1 << (WALL_LAYER - 1)
		):

			agarrado_pared = true

			pared_normal = collision.get_normal()

			player.velocity.x = 0.0

			seSalto = false

			saltoFuego = false

			puede_agarrarse_pared = false


			if pared_normal.x < 0:

				player.rotation = deg_to_rad(-90.0)

			else:

				player.rotation = deg_to_rad(-90.0)

				animated_sprite.flip_v = true

			return


	agarrado_pared = false

	pared_normal = Vector2.ZERO

	player.rotation = 0.0


# ==========================================
# ANIMACIONES
# ==========================================

func actualizar_animacion(
	direccion_animacion: float
) -> void:

	if agarrado_pared:

		animated_sprite.animation = "quieta"

		animated_sprite.flip_h = false

		animated_sprite.play()

		return


	if not player.is_on_floor():

		animated_sprite.animation = "salto"

		animated_sprite.flip_h = mirando_izquierda

		animated_sprite.flip_v = false

		animated_sprite.play()

		return


	animated_sprite.flip_v = false

	animated_sprite.flip_h = mirando_izquierda


	if direccion_animacion != 0:

		animated_sprite.animation = "correr"

	else:

		animated_sprite.animation = "quieta"


	animated_sprite.play()


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

		print(
			"DAÑO BLOQUEADO: TURBO ACTIVO"
		)

		return


	if tiempo_invulnerabilidad_turbo > 0.0:

		print(
			"DAÑO BLOQUEADO: INVULNERABILIDAD POST TURBO"
		)

		return


	if Invulnerabilidad.is_stopped():

		vida -= num

		barraVida.value = vida

		Invulnerabilidad.start()

		animacionHerida()

		if vida <= 0:

			morir()


func animacionHerida():

	while not Invulnerabilidad.is_stopped():

		animated_sprite.visible = false

		await get_tree().create_timer(
			0.1
		).timeout

		animated_sprite.visible = true

		await get_tree().create_timer(
			0.1
		).timeout

	animated_sprite.visible = true


func morir():

	died.emit()

	set_physics_process(false)

	set_process(false)

	player.hide()
