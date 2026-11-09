
extends Node2D
class_name AtaquesPlayer

# ==========================================
# PLAYER Y REFERENCIAS
# ==========================================

@onready var player: CharacterBody2D = get_parent()

@onready var particulasTornado: GPUParticles2D = $"../Particulas"

@onready var collision_shape_player: CollisionShape2D = $"../CollisionShape2D"
@onready var collision_shape_player_invertida: CollisionShape2D = $"../CollisionShape2DInvertida"
@onready var collision_tornado: CollisionShape2D = $"../CollisionShapeTornado"

@onready var hitbox_tornado: Area2D = $"../HitboxTornado"
@onready var hitbox_turbo: Area2D = $"../HitboxTurbo"

@onready var Invulnerabilidad: Timer = $"../Invulnerabilidad"

@onready var fire_position: Marker2D = $"../FirePosition"


# ==========================================
# ESTADO ACTUAL
# ==========================================

# No se guarda una referencia fija al estado.
# Siempre se obtiene el estado que Player tiene actualmente.
#
# Esto permite trabajar tanto con estadoManual
# como con estadoAutomatico.

func obtener_estado_actual() -> EstadoPlayer:
	return player.estado_actual


# ==========================================
# CONFIGURACIÓN DE HITBOX DE ATAQUE
# ==========================================

# Layer exclusiva para tiles mortales.
const Letal_layer = 4


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

	particulasTornado.emitting = false

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
# TURBO FUEGO
# ==========================================

const ENERGIA_TURBO: int = 3

@export var FUERZA_TURBO: float = 3500.0
@export var DURACION_TURBO: float = 0.15
@export var DAÑO_TURBO_FUEGO: int = 3
@export var retrocesoPorTurboFuego: int = 600
@export var INVULNERABILIDAD_POST_TURBO: float = 0.4

var turbo_activo: bool = false

var tiempo_invulnerabilidad_turbo: float = 0.0

var enemigos_golpeados_turbo: Dictionary = {}


# ==========================================
# ACTIVAR TURBO
# ==========================================

func activar_turbo() -> void:

	var estado := obtener_estado_actual()

	if estado.esta_forzado:
		return

	if estado.retroceso_activo:

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

	if estado.agarrado_pared:
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

	# ==========================================
	# LIBERAR PARED
	# ==========================================

	estado.agarrado_pared = false
	estado.pared_normal = Vector2.ZERO

	if not estado.deslizandose_pendiente:
		player.rotation = 0.0

	Invulnerabilidad.stop()

	# ==========================================
	# HITBOX TURBO
	# ==========================================

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

	# ==========================================
	# ANIMACIÓN
	# ==========================================

	player.animacion_turbo()

	# ==========================================
	# DIRECCIÓN
	# ==========================================

	if estado.mirando_izquierda:

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

			var estado := obtener_estado_actual()

			if estado.mirando_izquierda:
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
	# INVULNERABILIDAD POST TURBO
	# ==========================================

	tiempo_invulnerabilidad_turbo = (
		INVULNERABILIDAD_POST_TURBO
	)

	# ==========================================
	# RESTAURAR VELOCIDAD
	# ==========================================

	var estado := obtener_estado_actual()

	player.velocity.x = (
		sign(player.velocity.x)
		* estado.MAX_SPEED
	)

	player.animated_sprite.visible = true


# ==========================================
# PROCESAR INVULNERABILIDAD POST TURBO
# ==========================================

func procesar_invulnerabilidad_turbo(
	delta: float
) -> void:

	if tiempo_invulnerabilidad_turbo <= 0.0:
		return

	tiempo_invulnerabilidad_turbo -= delta

	if tiempo_invulnerabilidad_turbo < 0.0:

		tiempo_invulnerabilidad_turbo = 0.0


# ==========================================
# COLISIÓN DIFERIDA DEL TURBO
# ==========================================

func comprobar_colision_turbo_diferida() -> void:

	if not turbo_activo:
		return

	await get_tree().create_timer(
		0.05
	).timeout

	if not turbo_activo:
		return

	# ==========================================
	# CONSULTA DE COLISIÓN
	# ==========================================

	var query := PhysicsShapeQueryParameters2D.new()

	query.shape = collision_shape_player.shape

	query.transform = collision_shape_player.global_transform

	query.collision_mask = player.collision_mask

	query.collide_with_bodies = true

	query.collide_with_areas = false

	# Ignorar al propio jugador.
	query.exclude = [
		player.get_rid()
	]

	# ==========================================
	# CONSULTAR ESPACIO FÍSICO
	# ==========================================

	var espacio := player.get_world_2d().direct_space_state

	var resultados := espacio.intersect_shape(
		query,
		32
	)

	# ==========================================
	# COMPROBAR CUERPOS QUE BLOQUEAN AL PLAYER
	# ==========================================

	for resultado in resultados:

		var collider = resultado.get("collider")

		if collider == null or not is_instance_valid(collider):
			continue

		if collider is PhysicsBody2D:

			if not collider.is_queued_for_deletion():
				return

	# ==========================================
	# RESTAURAR VELOCIDAD DEL TURBO
	# ==========================================

	var estado := obtener_estado_actual()

	if estado.mirando_izquierda:

		player.velocity.x = -FUERZA_TURBO

	else:

		player.velocity.x = FUERZA_TURBO


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

		var estado := obtener_estado_actual()

		var direccion_empuje := Vector2.RIGHT

		if estado.mirando_izquierda:

			direccion_empuje = Vector2.LEFT

		body.retroceso(
			direccion_empuje,
			retrocesoPorTurboFuego
		)


# ==========================================
# TORNADO
# ==========================================

const ENERGIA_TORNADO: int = 6

@export var VELOCIDAD_TORNADO: float = 700.0
@export var DURACION_TORNADO: float = 2.0

var tornado_activo: bool = false

var tiempo_tornado: float = 0.0

var enemigos_golpeados_tornado: Dictionary = {}


# ==========================================
# ACTIVAR TORNADO
# ==========================================

func activar_tornado() -> void:

	var estado := obtener_estado_actual()

	if estado.retroceso_activo:
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

	particulasTornado.emitting = true

	# ==========================================
	# DESACTIVAR COLISIONES NORMALES
	# ==========================================

	collision_shape_player.set_deferred(
		"disabled",
		true
	)

	collision_shape_player_invertida.set_deferred(
		"disabled",
		true
	)

	# ==========================================
	# ACTIVAR COLISIÓN FÍSICA DEL TORNADO
	# ==========================================

	collision_tornado.set_deferred(
		"disabled",
		false
	)

	enemigos_golpeados_tornado.clear()

	# ==========================================
	# BLOQUEAR PARED
	# ==========================================

	estado.agarrado_pared = false

	estado.pared_normal = Vector2.ZERO

	estado.puede_agarrarse_pared = false

	# ==========================================
	# LIMPIAR MOVIMIENTO FORZADO
	# ==========================================

	estado.esta_forzado = false

	estado.direccion_forzada = Vector2.ZERO

	estado.velocidad_forzada = 0.0

	# ==========================================
	# ROTACIÓN NORMAL
	# ==========================================

	if not estado.deslizandose_pendiente:

		player.rotation = 0.0

	# ==========================================
	# HITBOX DE ATAQUE DEL TORNADO
	# ==========================================

	hitbox_tornado.monitoring = true

	# ==========================================
	# ANIMACIÓN
	# ==========================================

	player.animacion_tornado()

	# ==========================================
	# VELOCIDAD INICIAL
	# ==========================================

	if estado.mirando_izquierda:

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

	var estado := obtener_estado_actual()

	tiempo_tornado -= delta

	# ==========================================
	# VELOCIDAD CONSTANTE
	# ==========================================

	if estado.mirando_izquierda:

		player.velocity.x = -VELOCIDAD_TORNADO

	else:

		player.velocity.x = VELOCIDAD_TORNADO

	# ==========================================
	# GRAVEDAD
	# ==========================================

	if not player.is_on_floor():

		player.velocity.y += estado.GRAVITY * delta

	# ==========================================
	# MOVIMIENTO
	# ==========================================

	player.move_and_slide()

	# ==========================================
	# GOLPES
	# ==========================================

	comprobar_golpes_tornado()

	# ==========================================
	# MUERTE POR TILE MORTAL O LAVA
	# ==========================================

	if estado.comprobar_tile_mortal():
		return

	if estado.comprobar_tile_lava():
		return

	# ==========================================
	# TERMINAR
	# ==========================================

	if tiempo_tornado <= 0.0:

		desactivar_tornado()


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

				var estado := obtener_estado_actual()

				var direccion_empuje := Vector2.RIGHT

				if estado.mirando_izquierda:

					direccion_empuje = Vector2.LEFT

				body.retroceso(
					direccion_empuje,
					retrocesoPorTurboFuego
				)

			continue


# ==========================================
# DESACTIVAR TORNADO
# ==========================================

func desactivar_tornado() -> void:

	player.detener_rotacion_tornado()

	if not tornado_activo:
		return

	tornado_activo = false

	tiempo_tornado = 0.0

	particulasTornado.emitting = false

	# ==========================================
	# DESACTIVAR HITBOX DE ATAQUE
	# ==========================================

	hitbox_tornado.monitoring = false

	# ==========================================
	# DESACTIVAR CUERPO FÍSICO DEL TORNADO
	# ==========================================

	collision_tornado.set_deferred(
		"disabled",
		true
	)

	# ==========================================
	# RESTAURAR COLISIÓN NORMAL
	# ==========================================

	var estado := obtener_estado_actual()

	estado.actualizar_hitbox_direccion()

	# ==========================================
	# RESTAURAR PARED
	# ==========================================

	estado.puede_agarrarse_pared = true

	estado.agarrado_pared = false

	estado.pared_normal = Vector2.ZERO

	# ==========================================
	# REDUCIR VELOCIDAD
	# ==========================================

	player.velocity.x = (
		sign(player.velocity.x)
		* estado.MAX_SPEED
	)

	# ==========================================
	# RESTAURAR ANIMACIÓN
	# ==========================================

	player.restablecer_visual_suelo()

	enemigos_golpeados_tornado.clear()


# ==========================================
# SALTO FUEGO
# ==========================================

@export var sonido_saltoFuego: AudioStream

@export var JUMP_FIRE_FORCE: float = -880.0

var saltoFuego: bool = false


# ==========================================
# ACTIVAR SALTO FUEGO
# ==========================================

func salto_fuego() -> void:

	var estado := obtener_estado_actual()

	if estado.esta_forzado:
		return

	if estado.retroceso_activo:
		return

	if turbo_activo:
		return

	if estado.agarrado_pared:
		return

	# ==========================================
	# COMPROBAR ENERGÍA Y CONDICIONES
	# ==========================================

	if player.obtener_energia_fuego() >= 2 \
	and saltoFuego == false \
	and not player.is_on_floor():

		if not player.gastar_energia_fuego(2):
			return

		print(
			"SALTO FUEGO | Energía actual: ",
			player.obtener_energia_fuego()
		)

		# ==========================================
		# SONIDO Y MOVIMIENTO
		# ==========================================

		player._reproducir_sonido(
			sonido_saltoFuego
		)

		player.velocity.y = JUMP_FIRE_FORCE

		# ==========================================
		# PROYECTIL
		# ==========================================

		fire()

		saltoFuego = true

		# ==========================================
		# LIBERAR PARED
		# ==========================================

		estado.agarrado_pared = false

		estado.pared_normal = Vector2.ZERO

		# ==========================================
		# RESTAURAR ROTACIÓN Y ANIMACIÓN
		# ==========================================

		if not estado.deslizandose_pendiente:

			player.rotation = 0.0

		player.animated_sprite.flip_v = false


# ==========================================
# PROYECTILES
# ==========================================

@export var projectile_scene: PackedScene

var projectile_container: Node


# ==========================================
# CONFIGURAR CONTENEDOR DE PROYECTILES
# ==========================================

func configurar_contenedor_proyectiles(
	contenedor: Node
) -> void:

	projectile_container = contenedor


# ==========================================
# DISPARAR PROYECTIL
# ==========================================

func fire() -> void:

	if projectile_scene == null:
		return

	if projectile_container == null:
		return

	var projectile: AbstractProyectile = (
		projectile_scene.instantiate()
	)

	projectile_container.add_child(
		projectile
	)

	projectile.set_starting_values(
		fire_position.global_position,
		Vector2.DOWN
	)

	projectile.delete_requested.connect(
		_on_projectile_delete_requested
	)


# ==========================================
# ELIMINAR PROYECTIL
# ==========================================

func _on_projectile_delete_requested(
	projectile
) -> void:

	if projectile_container == null:
		return

	projectile_container.remove_child(
		projectile
	)

	projectile.queue_free()
