# Player.gd
extends CharacterBody2D

@export var projectile_scene: PackedScene
@onready var Invulnerabilidad: Timer = $Invulnerabilidad


@export var GRAVITY: float = 600.0

@export var JUMP_FORCE: float = -600.0
@export var JUMP_FIRE_FORCE: float = -880.0


# ==========================================
# VELOCIDAD
# ==========================================

@export var MAX_SPEED: float = 600.0
@export var SPEEDCAMINANDO: float = 100.0
@export var ACCELERATION: float = 1500.0
@export var FRICTION: float = 1000.0


# ==========================================
# PARED
# ==========================================

const WALL_JUMP_FORCE = 650.0
const WALL_SLIDE_SPEED = 150.0

const WALL_LAYER = 3

# ==========================================
# TURBO FUEGO
# ==========================================

const ENERGIA_TURBO = 3
@export var FUERZA_TURBO: float = 3500
@export var DURACION_TURBO: float = 0.15


# Los enemigos estarán en Collision Layer 4
const ENEMIGO_LAYER = 4

var turbo_activo: bool = false

# Guarda cómo estaba la máscara antes del turbo.
var colision_enemigos_original: bool


# ==========================================
# REFERENCIAS
# ==========================================

@onready var fire_position: Marker2D = $FirePosition
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@onready var tiempo_recarga_fuego = $TiempoRecargaFuego

@onready var barra = $"../CanvasLayer/barraDeFuego"
@onready var barraVida = $"../CanvasLayer2/barraDeVida"

@onready var hitbox_turbo: Area2D = $HitboxTurbo

signal hit
signal died

@export var speed: float = 400.0

var screen_size: Vector2

var seSalto: bool = false
var saltoFuego: bool = false

var activo: bool = false

var projectile_container: Node


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
# ENERGÍA DE FUEGO
# ==========================================

const ENERGIA_MAXIMA = 5

var energia_fuego: int = 5


func _ready() -> void:

	screen_size = get_viewport_rect().size


	# ==========================================
	# BARRA DE VIDA
	# ==========================================

	barraVida.max_value = vida
	barraVida.value = vida


	# ==========================================
	# BARRA DE FUEGO
	# ==========================================

	barra.min_value = 0
	barra.max_value = ENERGIA_MAXIMA
	barra.value = energia_fuego


	# ==========================================
	# HITBOX TURBO
	# ==========================================

	hitbox_turbo.monitoring = false


	# ==========================================
	# GUARDAR ESTADO DE COLISIÓN
	# ==========================================

	colision_enemigos_original = get_collision_mask_value(ENEMIGO_LAYER)


	hide()


func _physics_process(delta: float) -> void:

	if not activo:
		return


	# ==========================================
	# TURBO FUEGO
	# ==========================================

	if Input.is_action_just_pressed("turboFuego"):

		if energia_fuego >= ENERGIA_TURBO \
		and not turbo_activo \
		and not agarrado_pared:

			activar_turbo()


	# ==========================================
	# MOVIMIENTO HORIZONTAL
	# ==========================================

	var direccion := Input.get_axis("izquierda", "derecha")
	var caminando := Input.is_action_pressed("caminar")


	if not turbo_activo:

		if direccion != 0:

			if caminando:

				velocity.x = move_toward(
					velocity.x,
					direccion * SPEEDCAMINANDO,
					ACCELERATION * delta
				)

			else:

				velocity.x = move_toward(
					velocity.x,
					direccion * MAX_SPEED,
					ACCELERATION * delta
				)

		else:

			velocity.x = move_toward(
				velocity.x,
				0.0,
				FRICTION * delta
			)


	# ==========================================
	# GRAVEDAD
	# ==========================================

	if not is_on_floor():

		if agarrado_pared:

			velocity.y = min(
				velocity.y + GRAVITY * delta,
				WALL_SLIDE_SPEED
			)

		elif not turbo_activo:

			velocity.y += GRAVITY * delta


	# ==========================================
	# SALTO
	# ==========================================

	if Input.is_action_just_pressed("salto") and not turbo_activo:

		# ==========================================
		# WALL JUMP
		# ==========================================

		if agarrado_pared:

			var direccion_salto := pared_normal.x

			velocity.x = direccion_salto * WALL_JUMP_FORCE
			velocity.y = JUMP_FORCE

			seSalto = false
			saltoFuego = false

			agarrado_pared = false
			pared_normal = Vector2.ZERO

			puede_agarrarse_pared = false

			rotation = 0.0


		# ==========================================
		# SALTO NORMAL
		# ==========================================

		elif is_on_floor():

			velocity.y = JUMP_FORCE

			seSalto = false


		# ==========================================
		# DOBLE SALTO
		# ==========================================

		elif not seSalto:

			velocity.y = JUMP_FORCE

			seSalto = true


	# ==========================================
	# SALTO CON FUEGO
	# ==========================================

	if Input.is_action_just_pressed("saltoFuego") and not turbo_activo:

		if energia_fuego >= 2 and saltoFuego == false:

			energia_fuego -= 2

			barra.value = energia_fuego

			velocity.y = JUMP_FIRE_FORCE

			fire()

			saltoFuego = true

			if tiempo_recarga_fuego.is_stopped():

				tiempo_recarga_fuego.start()

			agarrado_pared = false
			pared_normal = Vector2.ZERO

			rotation = 0.0


	# ==========================================
	# MOVER
	# ==========================================

	move_and_slide()


	# ==========================================
	# PERMITIR VOLVER A AGARRARSE
	# ==========================================

	if not is_on_wall():

		puede_agarrarse_pared = true


	# ==========================================
	# DETECTAR PARED
	# ==========================================

	if not turbo_activo:

		detectar_pared()


	# ==========================================
	# RESETEAR AL TOCAR EL SUELO
	# ==========================================

	if is_on_floor() and not turbo_activo:

		seSalto = false
		saltoFuego = false

		agarrado_pared = false
		pared_normal = Vector2.ZERO

		puede_agarrarse_pared = true

		rotation = 0.0


	# ==========================================
	# ANIMACIONES
	# ==========================================

	if not turbo_activo:

		actualizar_animacion(direccion, caminando)


# ==========================================
# ACTIVAR TURBO FUEGO
# ==========================================

func activar_turbo() -> void:

	turbo_activo = true


	# ==========================================
	# GASTAR ENERGÍA
	# ==========================================

	energia_fuego -= ENERGIA_TURBO

	barra.value = energia_fuego


	# ==========================================
	# INICIAR RECARGA
	# ==========================================

	if tiempo_recarga_fuego.is_stopped():

		tiempo_recarga_fuego.start()


	# ==========================================
	# SALIR DE LA PARED
	# ==========================================

	agarrado_pared = false
	pared_normal = Vector2.ZERO

	rotation = 0.0


	# ==========================================
	# HACERSE INVULNERABLE
	# ==========================================

	Invulnerabilidad.stop()


	# ==========================================
	# QUITAR COLISIÓN CON ENEMIGOS
	# ==========================================

	colision_enemigos_original = get_collision_mask_value(ENEMIGO_LAYER)

	set_collision_mask_value(ENEMIGO_LAYER, false)


	# ==========================================
	# ACTIVAR HITBOX
	# ==========================================

	hitbox_turbo.monitoring = true


	# ==========================================
	# ANIMACIÓN
	# ==========================================

	animated_sprite.animation = "turboFuego"
	animated_sprite.play()


	# ==========================================
	# PROPULSIÓN
	# ==========================================

	if animated_sprite.flip_h:

		velocity.x = -FUERZA_TURBO

	else:

		velocity.x = FUERZA_TURBO


	# ==========================================
	# DURACIÓN
	# ==========================================

	await get_tree().create_timer(DURACION_TURBO).timeout

	desactivar_turbo()


# ==========================================
# DESACTIVAR TURBO
# ==========================================

func desactivar_turbo() -> void:

	turbo_activo = false


	# ==========================================
	# DESACTIVAR HITBOX
	# ==========================================

	hitbox_turbo.monitoring = false


	# ==========================================
	# RESTAURAR COLISIÓN CON ENEMIGOS
	# ==========================================

	set_collision_mask_value(
		ENEMIGO_LAYER,
		colision_enemigos_original
	)


	# ==========================================
	# VELOCIDAD NORMAL MÁXIMA
	# ==========================================

	velocity.x = sign(velocity.x) * MAX_SPEED


	animated_sprite.visible = true


# ==========================================
# HITBOX DEL TURBO
# ==========================================

func _on_hitbox_turbo_body_entered(body: Node2D) -> void:

	if body.is_in_group("enemigos"):

		if body.has_method("herir"):

			body.herir(3)


# ==========================================
# RECARGAR ENERGÍA DE FUEGO
# ==========================================

func recargar_energia_fuego() -> void:

	if energia_fuego < ENERGIA_MAXIMA:

		energia_fuego += 1

		barra.value = energia_fuego


	if energia_fuego < ENERGIA_MAXIMA:

		tiempo_recarga_fuego.start()


# ==========================================
# DETECTAR PARED ESPECIAL
# ==========================================

func detectar_pared() -> void:

	if not puede_agarrarse_pared:

		agarrado_pared = false
		pared_normal = Vector2.ZERO
		rotation = 0.0

		return


	if is_on_floor():

		agarrado_pared = false
		pared_normal = Vector2.ZERO

		return


	if not is_on_wall():

		agarrado_pared = false
		pared_normal = Vector2.ZERO

		return


	for i in get_slide_collision_count():

		var collision := get_slide_collision(i)

		var collider := collision.get_collider()


		if abs(collision.get_normal().x) < 0.8:

			continue


		if not collider is CollisionObject2D:

			continue


		if collider.collision_layer & (1 << (WALL_LAYER - 1)):

			agarrado_pared = true

			pared_normal = collision.get_normal()

			velocity.x = 0.0


			if pared_normal.x < 0:

				rotation = deg_to_rad(-90.0)

			else:

				rotation = deg_to_rad(-90.0)
				animated_sprite.flip_v = true


			return


	agarrado_pared = false
	pared_normal = Vector2.ZERO

	rotation = 0.0


# ==========================================
# ANIMACIONES
# ==========================================

func actualizar_animacion(direccion: float, caminando: bool) -> void:

	if agarrado_pared:

		animated_sprite.animation = "quieta"

		animated_sprite.flip_h = false

		animated_sprite.play()

		return


	if not is_on_floor():

		animated_sprite.animation = "salto"

		animated_sprite.flip_h = direccion < 0
		animated_sprite.flip_v = false

		animated_sprite.play()

		return


	animated_sprite.flip_v = false


	if direccion != 0:

		animated_sprite.flip_h = direccion < 0

		if caminando:

			animated_sprite.animation = "caminar"

		else:

			animated_sprite.animation = "correr"

	else:

		animated_sprite.animation = "quieta"


	animated_sprite.play()


# ==========================================
# RECIBIR DAÑO
# ==========================================

func _on_body_entered(body: Node2D) -> void:

	hide()

	hit.emit()

	collision_shape.set_deferred("disabled", true)


# ==========================================
# DISPARAR
# ==========================================

func fire():

	var projectile: AbstractProyectile = projectile_scene.instantiate()

	projectile_container.add_child(projectile)

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

func _on_projectile_delete_requested(projectile):

	projectile_container.remove_child(projectile)

	projectile.queue_free()


# ==========================================
# INICIAR JUGADOR
# ==========================================

func start(pos: Vector2, projectile_container) -> void:

	position = pos

	activo = true

	show()

	collision_shape.set_deferred("disabled", false)

	self.projectile_container = projectile_container

	rotation = 0.0

	agarrado_pared = false
	pared_normal = Vector2.ZERO
	puede_agarrarse_pared = true

	set_physics_process(true)
	set_process(true)


# ==========================================
# HERIDO
# ==========================================

func herir(num:int):

	# Durante el turbo no puede recibir daño.
	if turbo_activo:

		return


	if Invulnerabilidad.is_stopped():

		vida -= num

		barraVida.value = vida

		Invulnerabilidad.start()

		animacionHerida()

		if vida <= 0:

			morir()


# ==========================================
# ANIMACIÓN DE HERIDA
# ==========================================

func animacionHerida():

	while not Invulnerabilidad.is_stopped():

		$AnimatedSprite2D.visible = false

		await get_tree().create_timer(0.1).timeout

		$AnimatedSprite2D.visible = true

		await get_tree().create_timer(0.1).timeout


	$AnimatedSprite2D.visible = true


# ==========================================
# MORIR
# ==========================================

func morir():

	died.emit()

	set_physics_process(false)

	set_process(false)

	hide()


# ==========================================
# TIMEOUT DEL TIMER DE RECARGA
# ==========================================

func _on_tiempo_recarga_fuego_timeout() -> void:

	recargar_energia_fuego()
