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
@onready var ataques: Node2D = $"../AtaquesPlayer"

# ==========================================
# ATAQUES (COMPATIBILIDAD CON PLAYER)
# ==========================================
# Los valores reales viven en AtaquesPlayer.
# Estas propiedades permiten que el código externo que
# ya consultaba estado_actual.turbo_activo, etc. siga funcionando.

var turbo_activo: bool:
	get:
		return ataques.turbo_activo
	set(value):
		ataques.turbo_activo = value

var tornado_activo: bool:
	get:
		return ataques.tornado_activo
	set(value):
		ataques.tornado_activo = value

var saltoFuego: bool:
	get:
		return ataques.saltoFuego
	set(value):
		ataques.saltoFuego = value

var tiempo_invulnerabilidad_turbo: float:
	get:
		return ataques.tiempo_invulnerabilidad_turbo
	set(value):
		ataques.tiempo_invulnerabilidad_turbo = value

@onready var collision_shape_player: CollisionShape2D = $"..//CollisionShape2D"
@onready var collision_shape_player_invertida: CollisionShape2D = $"../CollisionShape2DInvertida"

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
# REFERENCIAS
# ==========================================
var reproductor_sonido: AudioStreamPlayer2D

# Único sonido definido actualmente: el que reproduce Eva al recibir daño.
const sonidoAy: AudioStream = preload(
	"res://sonidos/eva/dañoEva.ogg"
	
)
@onready var Invulnerabilidad: Timer = $"../Invulnerabilidad"
@onready var collision_shape: CollisionShape2D = $"../CollisionShape2D"

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

# ==========================================
# VELOCIDAD
# ==========================================

@export var MAX_SPEED: float = 600.0
@export var ACCELERATION: float = 1500.0
@export var FRICTION: float = 1000.0

# ==========================================
# PENDIENTES
# ==========================================
var ignorar_pendiente_mientras_asciende: bool = false
var altura_inicio_salto: float = 0.0

@export var SUAVIZADO_NORMAL_PENDIENTE: float = 8.0

# Diferencia mínima para considerar que la pendiente realmente cambió.
@export var UMBRAL_CAMBIO_NORMAL: float = 0.08

var normal_pendiente_suavizada: Vector2 = Vector2.ZERO
const ANGULO_MINIMO_ROTACION_PENDIENTE: float = 4.0
@export var ACELERACION_CONTROL_PENDIENTE: float = 180.0
const ANGULO_MAXIMO_PENDIENTE: float = 50.0
const DISTANCIA_SNAP_SUELO: float = 20.0

# Velocidad inicial del deslizamiento.
@export var VELOCIDAD_DESLIZAMIENTO_PENDIENTE: float = 190.0

# Aceleración mientras se desliza.
@export var ACELERACION_DESLIZAMIENTO_PENDIENTE: float = 450.0

# Rotación visual máxima para evitar inclinaciones absurdas.
@export var ROTACION_MAXIMA_PENDIENTE: float = 65.0

# Estado de deslizamiento.
var en_pendiente: bool = false
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
# LAYER MORTAL
# ==========================================
#
# ESTA LAYER ES EXCLUSIVAMENTE PARA
# TILES QUE MATAN AL PLAYER.
#
# LOS ATAQUES NO USAN ESTA LAYER.

const Letal_layer = 4
const Lava_layer = 5

# ==========================================
# OTROS
# ==========================================

@export var speed = 400.0

var screen_size: Vector2
var activo: bool = false

var seSalto: bool = false

var direccion: float = 0.0

# ==========================================
# DIRECCIÓN VISUAL
# ==========================================

var mirando_izquierda: bool = false

# ==========================================
# ESTADO DE PARED
# ==========================================
var tiempo_contacto_suelo_pared: float = 0.0
var tiempo_sin_contacto_pared: float = 0.0

const TIEMPO_CONFIRMACION_SUELO_PARED: float = 0.06
const TOLERANCIA_PERDIDA_PARED: float = 0.15
var agarrado_pared: bool = false
var pared_normal: Vector2 = Vector2.ZERO
var puede_agarrarse_pared: bool = true

@export var FUERZA_HORIZONTAL_SALTO_PARED: float = 900.0

func _ready() -> void:
	screen_size = player.get_viewport_rect().size

	# Crear el reproductor desde el código para no depender de un nodo
	# llamado "sonidos" en la escena.
	reproductor_sonido = AudioStreamPlayer2D.new()
	reproductor_sonido.name = "ReproductorSonidoEstado"
	player.add_child(reproductor_sonido)

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

	collision_shape_player.disabled = false
	collision_shape_player_invertida.disabled = true

	en_pendiente = false
	deslizandose_pendiente = false
	normal_pendiente = Vector2.ZERO
	player.rotation = 0.0

	actualizar_hitbox_direccion()
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

# ==========================================
# ATAQUES
# ==========================================

# Se conservan estos métodos para no tener que cambiar
# las llamadas que Player ya hace a estado_actual.

func activar_tornado() -> void:
	ataques.activar_tornado()

func procesar_tornado(delta: float) -> void:
	ataques.procesar_tornado(delta)

func comprobar_golpes_tornado() -> void:
	ataques.comprobar_golpes_tornado()

func desactivar_tornado() -> void:
	ataques.desactivar_tornado()

func salto_fuego() -> void:
	ataques.salto_fuego()

func activar_turbo() -> void:
	ataques.activar_turbo()

func comprobar_golpes_turbo() -> void:
	ataques.comprobar_golpes_turbo()

func desactivar_turbo() -> void:
	ataques.desactivar_turbo()

func comprobar_colision_turbo_diferida() -> void:
	ataques.comprobar_colision_turbo_diferida()

func _on_hitbox_turbo_body_entered(body: Node2D) -> void:
	ataques._on_hitbox_turbo_body_entered(body)

func fire() -> void:
	ataques.fire()

func _on_projectile_delete_requested(projectile) -> void:
	ataques._on_projectile_delete_requested(projectile)

# ==========================================
# PENDIENTES DEMASIADO INCLINADAS
# ==========================================

func esta_en_pendiente_demasiado_inclinada() -> bool:
	if deslizandose_pendiente:
		return true

	if not player.is_on_floor():
		return false

	return rad_to_deg(player.get_floor_angle()) > ANGULO_MAXIMO_PENDIENTE
	# ==========================================
# ROTACIÓN POR PENDIENTE
# ==========================================

func obtener_normal_contacto_pendiente_inclinada() -> Vector2:

	for i in range(player.get_slide_collision_count()):

		var colision := player.get_slide_collision(i)
		var normal_colision := colision.get_normal().normalized()

		# Ignorar paredes y techos.
		if normal_colision.y >= 0.0:
			continue

		var angulo := rad_to_deg(
			acos(clamp(
				normal_colision.dot(Vector2.UP),
				-1.0,
				1.0
			))
		)

		# Solo aceptar pendientes realmente inclinadas.
		if angulo > ANGULO_MAXIMO_PENDIENTE and angulo < 89.0:
			return normal_colision

	return Vector2.ZERO


func obtener_normal_pendiente_por_raycast() -> Vector2:

	var hitbox_actual: CollisionShape2D = collision_shape_player

	if hitbox_actual.disabled:
		hitbox_actual = collision_shape_player_invertida

	if hitbox_actual.disabled or hitbox_actual.shape == null:
		return Vector2.ZERO

	var rect := hitbox_actual.shape.get_rect()

	var espacio := player.get_world_2d().direct_space_state

	var mejor_normal_pendiente := Vector2.ZERO
	var distancia_pendiente := INF

	var distancia_apoyo := INF

	# Examinar cinco puntos de la parte inferior de la hitbox.
	for porcentaje in [0.1, 0.3, 0.5, 0.7, 0.9]:

		var punto_local := Vector2(
			lerpf(rect.position.x, rect.end.x, porcentaje),
			rect.end.y - 2.0
		)

		var origen := hitbox_actual.global_transform * punto_local

		var destino := (
			origen
			+ Vector2.DOWN * (DISTANCIA_SNAP_SUELO + 22.0)
		)

		var consulta := PhysicsRayQueryParameters2D.create(
			origen,
			destino,
			player.collision_mask
		)

		consulta.exclude = [player.get_rid()]
		consulta.collide_with_areas = false

		var resultado := espacio.intersect_ray(consulta)

		if resultado.is_empty():
			continue

		var normal_rayo: Vector2 = resultado["normal"].normalized()

		if normal_rayo.y >= 0.0:
			continue

		var angulo := rad_to_deg(
			acos(clamp(
				normal_rayo.dot(Vector2.UP),
				-1.0,
				1.0
			))
		)

		if angulo >= 89.0:
			continue

		var distancia := origen.distance_to(
			resultado["position"]
		)

		# Registrar el apoyo más cercano, incluso si es plano.
		distancia_apoyo = minf(
			distancia_apoyo,
			distancia
		)

		# Solo considerar superficies inclinadas.
		if angulo < ANGULO_MINIMO_ROTACION_PENDIENTE:
			continue

		# Elegir la pendiente más cercana, no la más inclinada.
		if distancia < distancia_pendiente:

			distancia_pendiente = distancia
			mejor_normal_pendiente = normal_rayo

	# ==========================================
	# VALIDAR LA PENDIENTE
	# ==========================================

	if mejor_normal_pendiente == Vector2.ZERO:
		return Vector2.ZERO

	# No aceptar una pendiente que esté demasiado
	# lejos del apoyo real del personaje.
	if distancia_pendiente > distancia_apoyo + 6.0:
		return Vector2.ZERO

	return mejor_normal_pendiente



func actualizar_rotacion_pendiente(delta: float) -> void:

	# ==========================================
	# IGNORAR PENDIENTE DURANTE EL ASCENSO
	# ==========================================

	if ignorar_pendiente_mientras_asciende:

		var sigue_en_ascenso := (
			player.velocity.y < 0.0
			or player.global_position.y < altura_inicio_salto - 8.0
		)

		if sigue_en_ascenso:

			en_pendiente = false
			deslizandose_pendiente = false

			normal_pendiente = Vector2.ZERO
			normal_pendiente_suavizada = Vector2.ZERO

			player.rotation = 0.0
			player.animated_sprite.rotation = 0.0

			return

		ignorar_pendiente_mientras_asciende = false

	# ==========================================
	# DETECTAR CONTACTO REAL CON PENDIENTE
	# MUY INCLINADA
	# ==========================================

	var normal_contacto_inclinada := Vector2.ZERO

	for i in range(player.get_slide_collision_count()):

		var colision := player.get_slide_collision(i)
		var normal_colision := colision.get_normal().normalized()

		if normal_colision.y >= 0.0:
			continue

		var angulo_colision := rad_to_deg(
			acos(clamp(
				normal_colision.dot(Vector2.UP),
				-1.0,
				1.0
			))
		)

		if (
			angulo_colision > ANGULO_MAXIMO_PENDIENTE
			and angulo_colision < 89.0
		):

			normal_contacto_inclinada = normal_colision
			break

	# ==========================================
	# DETECTAR LA NORMAL PARA LA ROTACIÓN
	# ==========================================

	var normal: Vector2 = Vector2.ZERO
	var hay_pendiente := false

	# Prioridad 1: contacto físico con pendiente muy inclinada.
	if normal_contacto_inclinada != Vector2.ZERO:

		normal = normal_contacto_inclinada
		hay_pendiente = true

	else:

		# Prioridad 2: detectar pendientes mediante rayos.
		normal = obtener_normal_pendiente_por_raycast()

		if normal != Vector2.ZERO:

			hay_pendiente = true

		# Prioridad 3: suelo detectado por Godot.
		elif player.is_on_floor():

			normal = player.get_floor_normal()
			hay_pendiente = true

		# Prioridad 4: otras colisiones físicas.
		else:

			var mayor_inclinacion := -1.0

			for i in range(player.get_slide_collision_count()):

				var colision := player.get_slide_collision(i)
				var normal_colision := colision.get_normal()

				if normal_colision.y >= 0.0:
					continue

				var angulo := rad_to_deg(
					acos(clamp(
						normal_colision.dot(Vector2.UP),
						-1.0,
						1.0
					))
				)

				if angulo >= 89.0:
					continue

				var inclinacion := absf(normal_colision.x)

				if inclinacion > mayor_inclinacion:

					mayor_inclinacion = inclinacion
					normal = normal_colision
					hay_pendiente = true

	# ==========================================
	# SIN SUPERFICIE DETECTADA
	# ==========================================

	if not hay_pendiente:

		if en_pendiente or deslizandose_pendiente:

			tiempo_sin_contacto_pendiente += delta

			# Tolerar pequeñas interrupciones de detección.
			if tiempo_sin_contacto_pendiente < TOLERANCIA_CONTACTO_PENDIENTE:
				return

			restaurar_rotacion()

		return

	tiempo_sin_contacto_pendiente = 0.0

	normal = normal.normalized()

	# ==========================================
	# SUAVIZAR LA NORMAL
	# ==========================================

	if normal_pendiente_suavizada == Vector2.ZERO:

		normal_pendiente_suavizada = normal

	else:

		var factor := clampf(
			SUAVIZADO_NORMAL_PENDIENTE * delta,
			0.0,
			1.0
		)

		normal_pendiente_suavizada = (
			normal_pendiente_suavizada.lerp(
				normal,
				factor
			).normalized()
		)

	# ==========================================
	# CALCULAR ÁNGULO
	# ==========================================

	var angulo_suelo := rad_to_deg(
		acos(clamp(
			normal_pendiente_suavizada.dot(Vector2.UP),
			-1.0,
			1.0
		))
	)

	# Ignorar superficies prácticamente planas.
	if angulo_suelo < ANGULO_MINIMO_ROTACION_PENDIENTE:

		restaurar_rotacion()
		return

	# Ignorar paredes.
	if angulo_suelo >= 89.0:

		en_pendiente = false
		return

	# ==========================================
	# ACTUALIZAR ESTADO
	# ==========================================

	normal_pendiente = normal_pendiente_suavizada
	en_pendiente = true

	# IMPORTANTE:
	# Solo una colisión física directa con una pendiente
	# superior a 50 grados activa el deslizamiento.
	deslizandose_pendiente = (
		normal_contacto_inclinada != Vector2.ZERO
	)

	# ==========================================
	# CALCULAR ROTACIÓN
	# ==========================================

	var nueva_rotacion := atan2(
		normal_pendiente.x,
		-normal_pendiente.y
	)

	nueva_rotacion = clamp(
		nueva_rotacion,
		deg_to_rad(-ROTACION_MAXIMA_PENDIENTE),
		deg_to_rad(ROTACION_MAXIMA_PENDIENTE)
	)

	# ==========================================
	# APLICAR ROTACIÓN MANTENIENDO EL APOYO
	# ==========================================

	var rotacion_aplicada := rotar_manteniendo_apoyo(
		nueva_rotacion,
		normal_pendiente
	)

	if not rotacion_aplicada:
		return



func rotar_manteniendo_apoyo(
	nueva_rotacion: float,
	normal: Vector2
) -> bool:

	# ==========================================
	# SELECCIONAR HITBOX ACTUAL
	# ==========================================

	var hitbox_actual: CollisionShape2D

	if mirando_izquierda:
		hitbox_actual = collision_shape_player_invertida
	else:
		hitbox_actual = collision_shape_player

	if hitbox_actual.shape == null:
		return false

	# ==========================================
	# CALCULAR POSICIÓN FUTURA
	# ==========================================

	var rect := hitbox_actual.shape.get_rect()

	var punto_local: Vector2

	if normal.x < 0.0:
		punto_local = Vector2(rect.end.x, rect.end.y)
	else:
		punto_local = Vector2(rect.position.x, rect.end.y)

	# Guardar la posición global del punto de apoyo.
	var apoyo_global := (
		hitbox_actual.global_transform * punto_local
	)

	# Crear la transformación futura del jugador.
	var transform_jugador := Transform2D(
		nueva_rotacion,
		player.global_position
	)

	# Obtener la transformación de la hitbox
	# relativa al jugador.
	var transform_relativa := (
		player.global_transform.affine_inverse()
		* hitbox_actual.global_transform
	)

	# Calcular dónde quedaría la hitbox al rotar.
	var transform_hitbox := (
		transform_jugador * transform_relativa
	)

	var apoyo_nuevo := transform_hitbox * punto_local

	# Corregir la posición para mantener el apoyo.
	var nueva_posicion := (
		player.global_position
		+ apoyo_global
		- apoyo_nuevo
	)

	transform_jugador.origin = nueva_posicion

	# ==========================================
	# COMPROBAR TODAS LAS HITBOX ACTIVAS
	# ==========================================

	var espacio := player.get_world_2d().direct_space_state

	var hitboxes: Array[CollisionShape2D] = [
		collision_shape_player,
		collision_shape_player_invertida,
	]

	for hitbox in hitboxes:

		if hitbox.disabled:
			continue

		if hitbox.shape == null:
			continue

		# Obtener su transformación relativa al jugador.
		var relativa := (
			player.global_transform.affine_inverse()
			* hitbox.global_transform
		)

		# Simular la posición de esta hitbox después del giro.
		var transform_futura := transform_jugador * relativa

		var consulta := PhysicsShapeQueryParameters2D.new()

		consulta.shape = hitbox.shape
		consulta.transform = transform_futura
		consulta.collision_mask = player.collision_mask
		consulta.collide_with_bodies = true
		consulta.collide_with_areas = false
		consulta.exclude = [player.get_rid()]
		consulta.margin = 0.01

		# Si encuentra algo, la rotación está bloqueada.
		var colisiones := espacio.intersect_shape(
			consulta,
			1
		)

		if not colisiones.is_empty():

			return false

	# ==========================================
	# ROTACIÓN SEGURA
	# ==========================================

	player.global_position = nueva_posicion
	player.global_rotation = nueva_rotacion

	return true
func rotar_sprite_manteniendo_apoyo(
	nueva_rotacion: float,
	normal: Vector2
) -> void:

	var sprite: AnimatedSprite2D = player.animated_sprite

	# Obtener la textura del fotograma actual.
	var textura: Texture2D = sprite.sprite_frames.get_frame_texture(
		sprite.animation,
		sprite.frame
	)

	if textura == null:
		return

	# Obtener el tamaño de la textura.
	var tamano: Vector2 = textura.get_size()

	# Calcular el origen del rectángulo según el centrado.
	var origen: Vector2

	if sprite.centered:
		origen = sprite.offset - tamano / 2.0
	else:
		origen = sprite.offset

	# Crear el rectángulo del sprite.
	var rect: Rect2 = Rect2(origen, tamano)

	# Elegir la esquina inferior que toca la pendiente.
	var punto_local: Vector2

	if normal.x < 0.0:
		punto_local = Vector2(rect.end.x, rect.end.y)
	else:
		punto_local = Vector2(rect.position.x, rect.end.y)

	# Guardar la posición global del punto de apoyo.
	var apoyo_global: Vector2 = (
		sprite.global_transform * punto_local
	)

	# Rotar únicamente el sprite.
	sprite.rotation = nueva_rotacion

	# Calcular dónde quedó el punto después de rotarlo.
	var apoyo_nuevo: Vector2 = (
		sprite.global_transform * punto_local
	)

	# Corregir la posición para conservar el apoyo.
	sprite.global_position += apoyo_global - apoyo_nuevo
func restaurar_rotacion() -> void:

	player.rotation = 0.0
	player.animated_sprite.rotation = 0.0

	en_pendiente = false
	deslizandose_pendiente = false

	normal_pendiente = Vector2.ZERO
	normal_pendiente_suavizada = Vector2.ZERO

	velocidad_deslizamiento = 0.0
	tiempo_sin_contacto_pendiente = 0.0
	tiempo_detectando_pendiente = 0.0
# ==========================================
# DIRECCIÓN
# ==========================================

func actualizar_hitbox_direccion() -> void:

	# No cambiar las hitboxes durante el tornado.
	if ataques.tornado_activo:
		return

	# El sistema de pared controla sus propias colisiones.
	if agarrado_pared or player.transfiriendo_hitbox_pared:
		return

	# Player.gd es el único responsable de cambiar las hitboxes.
	player.mirando_izquierda = mirando_izquierda
	player.actualizar_colision_direccion()


func establecer_direccion(
	nueva_direccion: float
) -> void:

	if retroceso_activo:
		return

	if esta_forzado:
		return

	# ==========================================
	# PENDIENTES MUY INCLINADAS
	# ==========================================

	if deslizandose_pendiente and normal_pendiente != Vector2.ZERO:

		# Guardar siempre la dirección pulsada.
		# El movimiento horizontal sigue controlado
		# por procesar_pendiente_inclinada().
		direccion = nueva_direccion

		if nueva_direccion != 0.0:

			mirando_izquierda = nueva_direccion < 0.0

			actualizar_hitbox_direccion()

			if not agarrado_pared:

				player.establecer_direccion_visual(
					nueva_direccion
				)

		return

	# ==========================================
	# MOVIMIENTO NORMAL
	# ==========================================

	direccion = nueva_direccion

	if direccion != 0.0:

		mirando_izquierda = direccion < 0.0

		actualizar_hitbox_direccion()

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
	print("[RETROCESO] ataques.turbo_activo: ", ataques.turbo_activo)
	print("[RETROCESO] ataques.tiempo_invulnerabilidad_turbo: ", ataques.tiempo_invulnerabilidad_turbo)
	print("[RETROCESO] Invulnerabilidad detenida: ", Invulnerabilidad.is_stopped())
	print("[RETROCESO] retroceso_activo: ", retroceso_activo)

	# ==========================================
	# COMPROBAR BLOQUEOS
	# ==========================================

	if ataques.turbo_activo or ataques.tiempo_invulnerabilidad_turbo > 0.0 or not Invulnerabilidad.is_stopped():

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
	if comprobar_tile_lava():
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
	
func entrar_madriguera() -> void:

	esta_en_madriguera = true
	player.esta_en_madriguera = true

	# Eliminar todo el momentum del jugador al entrar.
	player.velocity = Vector2.ZERO

	player.set_collision_mask_value(
		MADRIGUERA_LAYER,
		false
	)
func salir_madriguera() -> void:

	esta_en_madriguera = false
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

func comprobar_tile_lava() -> bool:
	for i in range(player.get_slide_collision_count()):
		var collision = player.get_slide_collision(i)
		var collider = collision.get_collider()

		if collider is TileMapLayer:
			if colision_tiene_layer(collision, Lava_layer):
				var es_inmune: bool = player.get("esInmuneALaLava")

				if not es_inmune:
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

	if ataques.turbo_activo:

		ataques.comprobar_golpes_turbo()

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

		if ataques.turbo_activo and player.get_slide_collision_count() > 0:
			ataques.comprobar_colision_turbo_diferida()

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

		if comprobar_tile_lava():
			return
		# ==========================================
		# NO EJECUTAR EL MOVIMIENTO NORMAL
		# ==========================================

		return

	# ==========================================
	# TORNADO
	# ==========================================

	if ataques.tornado_activo:

		ataques.procesar_tornado(delta)

		return

	# ==========================================
	# INVULNERABILIDAD POST TURBO
	# ==========================================

	ataques.procesar_invulnerabilidad_turbo(delta)

# ==========================================
# MOVIMIENTO Y GRAVEDAD
# ===================================
	if agarrado_pared:
		# Mantener el contacto con la pared sin bloquear la caída.
		# La normal apunta desde la pared hacia el personaje.
		player.velocity.x = -pared_normal.x * 20.0

	elif deslizandose_pendiente and normal_pendiente != Vector2.ZERO:
		procesar_pendiente_inclinada(delta)

	elif not ataques.turbo_activo:
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
		elif not ataques.turbo_activo and not deslizandose_pendiente:
			if player.velocity.y > 0:
				player.velocity.y += GRAVITY_CAIDA * delta
			else:
				player.velocity.y += GRAVITY * delta

# ==========================================
# MOVIMIENTO FÍSICO
# ==========================================

	player.move_and_slide()
	comprobar_transferencia_hitbox_pared()
	actualizar_rotacion_pendiente(delta)

	if comprobar_tile_mortal():
		return

	if comprobar_tile_lava():
		return

	# ==========================================
	# MUERTE AL TOCAR TILE MORTAL
	# ==========================================

	if comprobar_tile_mortal():

		return
	if comprobar_tile_lava():
		return

	# ==========================================
	# PARED
	# ==========================================

	if not player.is_on_wall():

		puede_agarrarse_pared = true

	if not ataques.turbo_activo:
		detectar_pared(delta)

	# ==========================================
	# ESTADO DE SUELO
	# ==========================================

	if player.is_on_floor() and not ataques.turbo_activo and not deslizandose_pendiente and not agarrado_pared:
		seSalto = false
		ataques.saltoFuego = false

		agarrado_pared = false
		pared_normal = Vector2.ZERO

		puede_agarrarse_pared = true

		# No restablecer la rotación visual si Eva sigue sobre
		# una pendiente suave.
		if not en_pendiente:
			player.restablecer_visual_suelo()
	# ANIMACIÓN
	if not ataques.turbo_activo:

		if deslizandose_pendiente:

			player.animated_sprite.visible = true
			player.animated_sprite_pared.visible = false
			player.animated_sprite.flip_v = false

			var animacion_pendiente := "quieta"

			if direccion != 0.0 and normal_pendiente != Vector2.ZERO:

				var tangente_animacion := Vector2(
					normal_pendiente.y,
					-normal_pendiente.x
				).normalized()

				if tangente_animacion.y < 0.0:
					tangente_animacion = -tangente_animacion

				var direccion_cuesta_abajo := signf(
					tangente_animacion.x
				)

				if signf(direccion) != direccion_cuesta_abajo:

					# Eva intenta subir, así que anima caminar,
					# aunque en realidad continúe deslizándose.
					animacion_pendiente = "correr"

			if player.animated_sprite.animation != animacion_pendiente:
				player.animated_sprite.play(animacion_pendiente)

		else:

			player.actualizar_animacion(direccion)




func procesar_pendiente_inclinada(delta: float) -> void:

	if normal_pendiente == Vector2.ZERO:
		return

	var normal := normal_pendiente.normalized()

	var tangente := Vector2(
		normal.y,
		-normal.x
	).normalized()

	# Orientar la tangente cuesta abajo.
	if tangente.y < 0.0:
		tangente = -tangente

	var direccion_cuesta_abajo := signf(tangente.x)

	# ==========================================
	# CALCULAR INCLINACIÓN
	# ==========================================

	var angulo := acos(clamp(
		normal.dot(Vector2.UP),
		-1.0,
		1.0
	))

	var factor_inclinacion := sin(angulo)

	# No generar movimiento horizontal artificial.
	player.velocity.x = 0.0

	# ==========================================
	# VELOCIDAD DE CAÍDA OBJETIVO
	# ==========================================

	# Al subir, cae lentamente.
	var velocidad_caida_objetivo := lerpf(
		10.0,
		55.0,
		factor_inclinacion
	)

	# Al bajar, cae un poco más rápido.
	if direccion != 0.0:

		if signf(direccion) == direccion_cuesta_abajo:

			velocidad_caida_objetivo += lerpf(
				15.0,
				25.0,
				factor_inclinacion
			)

	# ==========================================
	# APLICAR VELOCIDAD
	# ==========================================

	if direccion != 0.0:

		player.velocity.y = move_toward(
			player.velocity.y,
			velocidad_caida_objetivo,
			7000.0 * delta
		)

	else:

		# Si no se pulsa ninguna dirección,
		# dejar que la gravedad actúe normalmente.
		player.velocity.y += (
			GRAVITY * factor_inclinacion * delta
		)



func saltar() -> void:

	if retroceso_activo:
		return

	if esta_forzado:
		return

	if ataques.tornado_activo:
		return

	if ataques.turbo_activo:
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
		ataques.saltoFuego = false

		restaurar_rotacion()
		player.restablecer_visual_suelo()

		return
	if player.is_on_floor() or en_pendiente or deslizandose_pendiente:

		ignorar_pendiente_mientras_asciende = true
		altura_inicio_salto = player.global_position.y
		# Cancelar el deslizamiento.
		en_pendiente = false
		deslizandose_pendiente = false
		normal_pendiente = Vector2.ZERO
		velocidad_deslizamiento = 0.0
		tiempo_sin_contacto_pendiente = 0.0
		tiempo_detectando_pendiente = 0.0

		player.rotation = 0.0
		player.animated_sprite.rotation = 0.0

		# Aplicar el salto original.
		player.velocity.y = JUMP_FORCE

		# Esperar antes de comprobar si soltó el botón.
		await get_tree().create_timer(0.12).timeout

		# Usar el nombre correcto de la acción: "salto".
		if not Input.is_action_pressed("salto"):
			if player.velocity.y < 0.0:
				player.velocity.y *= 0.80

		seSalto = false
		ataques.saltoFuego = false

		return

	if not seSalto:

		if player.poseeDobleSalto:

			player.velocity.y = JUMP_FORCE

			seSalto = true

			player.animacion_salto()

# ==========================================
# SALTO FUEGO
# ==========================================

func detectar_pared(delta: float) -> void:

	# ==========================================
	# VOLVER AL SUELO SI ESTÁ AGARRADA A UNA PARED
	# ==========================================

	# Dar prioridad al suelo cuando Eva ya está agarrada.
	if agarrado_pared and player.is_on_floor():

		tiempo_contacto_suelo_pared += delta

		# Confirmar que el contacto con el suelo sea estable.
		if tiempo_contacto_suelo_pared >= TIEMPO_CONFIRMACION_SUELO_PARED:

			salir_de_pared()

		return

	# Si dejó de tocar el suelo, reiniciar el contador.
	tiempo_contacto_suelo_pared = 0.0

	# ==========================================
	# TRANSICIONES DE COLISIONES
	# ==========================================

	if player.restaurando_hitbox_pared:
		return

	if player.transfiriendo_hitbox_pared:
		return

	# ==========================================
	# PENDIENTE
	# ==========================================





	if deslizandose_pendiente:

		player.animated_sprite.visible = true
		player.animated_sprite_pared.visible = false
		player.animated_sprite.flip_v = false

		var animacion_pendiente := "quieta"

		if direccion != 0.0 and normal_pendiente != Vector2.ZERO:

			var tangente_animacion := Vector2(
				normal_pendiente.y,
				-normal_pendiente.x
			).normalized()

			if tangente_animacion.y < 0.0:
				tangente_animacion = -tangente_animacion

			var direccion_cuesta_abajo := signf(
				tangente_animacion.x
			)

			if signf(direccion) == direccion_cuesta_abajo:
				# Pulsar hacia abajo: animación de caída.
				animacion_pendiente = "caer"
			else:
				# Pulsar hacia arriba: animación de caminar.
				animacion_pendiente = "correr"

		if player.animated_sprite.animation != animacion_pendiente:
			player.animated_sprite.play(animacion_pendiente)

	else:

		player.actualizar_animacion(direccion)

	# ==========================================
	# BLOQUEOS
	# ==========================================

	if not puede_agarrarse_pared or ataques.tornado_activo:

		if agarrado_pared or not player.collision_pared.disabled:
			salir_de_pared()

		return

	# ==========================================
	# BUSCAR UNA PARED VÁLIDA
	# ==========================================

	var pared_detectada := false
	var normal_detectada := Vector2.ZERO

	for i in range(player.get_slide_collision_count()):

		var collision := player.get_slide_collision(i)
		var normal := collision.get_normal()

		# Ignorar suelo, techo y superficies que no sean paredes.
		if absf(normal.x) < 0.8:
			continue

		# Solo aceptar paredes de la layer 3.
		if not colision_tiene_layer(collision, WALL_LAYER):
			continue

		normal_detectada = normal
		pared_detectada = true

		break

	# ==========================================
	# MANTENER EL AGARRE A LA PARED
	# ==========================================

	if pared_detectada:

		var entrando_en_pared := (
			not agarrado_pared
			or signf(pared_normal.x) != signf(normal_detectada.x)
		)

		pared_normal = normal_detectada

		tiempo_sin_contacto_pared = 0.0
		tiempo_contacto_suelo_pared = 0.0

		# Mantener el estado de pared.
		agarrado_pared = true

		player.velocity.x = 0.0

		seSalto = false
		ataques.saltoFuego = false

		# Cambiar la hitbox y la animación solo al entrar
		# o cuando se pasa a una pared del lado contrario.
		if entrando_en_pared:
			player.animacion_pared(normal_detectada)

		return

	# ==========================================
	# NO SE DETECTÓ UNA PARED VÁLIDA
	# ==========================================

	if agarrado_pared or not player.collision_pared.disabled:

		tiempo_sin_contacto_pared += delta

		# Tolerar interrupciones breves de contacto.
		if tiempo_sin_contacto_pared < TOLERANCIA_PERDIDA_PARED:
			return

		salir_de_pared()
		return

	# ==========================================
	# EVA NO ESTÁ AGARRADA A NINGUNA PARED
	# ==========================================

	tiempo_sin_contacto_pared = 0.0

	if player.is_on_floor():
		return
func salir_de_pared() -> void:

	# Abandonar inmediatamente el estado de pared.
	agarrado_pared = false
	pared_normal = Vector2.ZERO

	# Restaurar la hitbox si la pared está activa
	# o si todavía se estaba realizando la transferencia.
	if (
		not player.collision_pared.disabled
		or player.transfiriendo_hitbox_pared
	):
		player.restaurar_hitbox_pared()

	if not en_pendiente:
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

func start(
	pos: Vector2,
	projectile_container_nuevo
) -> void:
	normal_pendiente_suavizada = Vector2.ZERO
	player.position = pos

	activo = true

	player.show()

	actualizar_hitbox_direccion()

	ataques.configurar_contenedor_proyectiles(projectile_container_nuevo)

	en_pendiente = false
	deslizandose_pendiente = false
	normal_pendiente = Vector2.ZERO
	velocidad_deslizamiento = 0.0

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

	if ataques.turbo_activo:
		return

	if ataques.tiempo_invulnerabilidad_turbo > 0.0:
		return

	if Invulnerabilidad.is_stopped():

		player.vida -= num

		player.actualizar_barra_vida()

		Invulnerabilidad.start()

		# Reproducir el sonido de daño.
		reproducir_sonido(sonidoAy)

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

func comprobar_transferencia_hitbox_pared() -> void:
	if not player.transfiriendo_hitbox_pared:
		return

	if player.restaurando_hitbox_pared:
		return

	if player.get_slide_collision_count() == 0:
		return

	for i in range(player.get_slide_collision_count()):
		var collision := player.get_slide_collision(i)
		var normal := collision.get_normal()

		# Comprobar que sea una pared.
		if absf(normal.x) < 0.8:
			continue

		if not colision_tiene_layer(collision, WALL_LAYER):
			continue

		# La hitbox de pared encontró una pared válida.
		player.transfiriendo_hitbox_pared = false
		agarrado_pared = true
		pared_normal = normal

		seSalto = false
		ataques.saltoFuego = false
		player.velocity.x = 0.0

		player.animacion_pared(normal)

		print("[HITBOX PARED] Agarre completado.")
		return


func reproducir_sonido(sonido: AudioStream) -> void:

	if sonido == null:
		return

	if not is_instance_valid(reproductor_sonido):
		return

	reproductor_sonido.stream = sonido
	reproductor_sonido.play()
