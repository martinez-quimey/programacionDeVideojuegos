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

@onready var collision_shape_player: CollisionShape2D = $"../CollisionShape2D"
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
# DIRECCIÓN
# ==========================================

func establecer_direccion(
	nueva_direccion: float
) -> void:

	if retroceso_activo:

	

		return


	direccion = nueva_direccion


	if direccion != 0:

		mirando_izquierda = direccion < 0

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
	

	if turbo_activo or tiempo_invulnerabilidad_turbo > 0.0:

		print(
			"RETROCESO BLOQUEADO: PLAYER INMUNE"
		)

		return




	if retroceso_activo:


		return


	if PESO <= 0:

		

		return


	if direccion_empuje.length() == 0:

	

		return


	retroceso_activo = true
	tiempo_retroceso = DURACION_RETROCESO

	estado_anterior_retroceso = player.estado_actual


	


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


	player.velocity.x = (
		direccion_normalizada.x
		* velocidad_retroceso
	)

	player.velocity.y = (
		direccion_normalizada.y
		* velocidad_retroceso
	)



# ==========================================
# PROCESAR RETROCESO
# ==========================================

func procesar_retroceso(delta: float) -> void:

	if not retroceso_activo:

		return

	tiempo_retroceso -= delta


	if not player.is_on_floor():

		player.velocity.y += GRAVITY * delta
			
		print(
			"Ángulo del suelo: ",
			rad_to_deg(player.get_floor_angle())
		)

	player.move_and_slide()



	# ==========================================
	# MUERTE POR TILE MORTAL DURANTE RETROCESO
	# ==========================================

	if comprobar_tile_mortal():

		return


	if tiempo_retroceso <= 0.0:

		terminar_retroceso()


# ==========================================
# TERMINAR RETROCESO
# ==========================================

func terminar_retroceso() -> void:



	retroceso_activo = false
	tiempo_retroceso = 0.0

	player.velocity.x = 0.0

	estado_anterior_retroceso = null




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


		if comprobar_tile_mortal():

			return


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
		print(
			"EN SUELO | Ángulo: ",
			rad_to_deg(player.get_floor_angle()),
			" | Normal: ",
			player.get_floor_normal()
		)
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

	if player.is_on_floor() and not turbo_activo:

		seSalto = false
		saltoFuego = false

		agarrado_pared = false
		pared_normal = Vector2.ZERO

		puede_agarrarse_pared = true

		player.restablecer_visual_suelo()


	# ==========================================
	# ANIMACIÓN
	# ==========================================

	if not turbo_activo:

		player.actualizar_animacion(direccion)


# ==========================================
# SALTO
# ==========================================

func saltar() -> void:

	if retroceso_activo:



		return


	if tornado_activo:

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

		player.restablecer_visual_suelo()

		return


	if player.is_on_floor():

		player.velocity.y = JUMP_FORCE

		seSalto = false

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

	if retroceso_activo:

		

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

		player.animated_sprite.flip_v = false


# ==========================================
# TURBO FUEGO
# ==========================================

func activar_turbo() -> void:

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

	print("")
	print("==========================================")
	print("DESACTIVANDO TURBO")
	print("==========================================")


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


	# ==========================================
	# FILTRO DE ENEMIGO
	# ==========================================

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



# ==========================================
# PARED
# ==========================================
func detectar_pared() -> void:

	# ==========================================
	# PUEDE AGARRARSE A PARED
	# ==========================================

	
	if not puede_agarrarse_pared:

	

		agarrado_pared = false
		pared_normal = Vector2.ZERO

		player.rotation = 0.0

		return



	# ==========================================
	# TORNADO
	# ==========================================


	if tornado_activo:

	
		agarrado_pared = false
		pared_normal = Vector2.ZERO
		player.rotation = 0.0

		return




	# ==========================================
	# SUELO
	# ==========================================


	if player.is_on_floor():

	
		agarrado_pared = false
		pared_normal = Vector2.ZERO

		return


	# ==========================================
	# PARED
	# ==========================================



	if not player.is_on_wall():

		agarrado_pared = false
		pared_normal = Vector2.ZERO

		return


	# ==========================================
	# INFORMACIÓN GENERAL
	# ==========================================




	# ==========================================
	# BUSCAR LA COLISIÓN DE LA PARED
	# ==========================================

	
	for i in range(player.get_slide_collision_count()):

	

		var collision := (
			player.get_slide_collision(i)
		)

		var collider := collision.get_collider()





		# ==========================================
		# COMPROBAR SI ES REALMENTE UNA PARED
		# ==========================================

		if abs(collision.get_normal().x) < 0.8:


			continue


		# ==========================================
		# COMPROBAR LAYER
		# ==========================================

	


		var tiene_layer_pared := colision_tiene_layer(
			collision,
			WALL_LAYER
		)



		if collider != null:

			if collider is CollisionObject2D:

				print(
					"[9] collision_layer del collider = ",
					collider.collision_layer
				)

				print(
					"[9] collider tiene layer 1: ",
					collider.get_collision_layer_value(1)
				)

		


		if not tiene_layer_pared:


			continue




		# ==========================================
		# ENCONTRÓ PARED VÁLIDA
		# ==========================================




		agarrado_pared = true


		

		pared_normal = (
			collision.get_normal()
		)


	

		player.velocity.x = 0.0


	

		seSalto = false
		saltoFuego = false




		

		player.animacion_pared(
			pared_normal
		)

		return


	# ==========================================
	# NO ENCONTRÓ PARED VÁLIDA
	# ==========================================

	agarrado_pared = false
	pared_normal = Vector2.ZERO

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
