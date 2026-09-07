# Player.gd
extends CharacterBody2D

@export var projectile_scene: PackedScene

const GRAVITY = 980.0
const JUMP_FORCE = -600.0
const JUMP_FIRE_FORCE = -880.0

# ==========================================
# VELOCIDAD
# ==========================================

const MAX_SPEED = 600.0
const SPEEDCAMINANDO = 100.0
const ACCELERATION = 1500.0
const FRICTION = 1000.0

# ==========================================
# PARED
# ==========================================

const WALL_JUMP_FORCE = 650.0
const WALL_SLIDE_SPEED = 150.0

# Paredes especiales = Collision Layer 3
const WALL_LAYER = 3


@onready var fire_position: Marker2D = $FirePosition
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

signal hit
signal died

@export var speed: float = 400.0

var screen_size: Vector2

var seSalto: bool = false


var activo: bool = false

var projectile_container: Node

# ==========================================
# ESTADO DE PARED
# ==========================================

var agarrado_pared: bool = false
var pared_normal: Vector2 = Vector2.ZERO

# Evita volver a agarrarse inmediatamente
# después de hacer un wall jump.
var puede_agarrarse_pared: bool = true
var vida: int = 5

@onready var timer = $TiempoFuego
@onready var barra = $"../CanvasLayer/barraDeFuego" #barra del timer del salto fuego
@onready var barraVida = $"../CanvasLayer2/barraDeVida" 

	
func _ready() -> void:
	screen_size = get_viewport_rect().size

	barraVida.max_value = vida
	barraVida.value = vida

	hide()



func _physics_process(delta: float) -> void:

	if timer.is_stopped():
		barra.value = 0
	else:
		barra.value = (timer.time_left / timer.wait_time) * 100

	if not activo:
		return



	# ==========================================
	# MOVIMIENTO HORIZONTAL
	# ==========================================

	var direccion := Input.get_axis("izquierda", "derecha")
	var caminando := Input.is_action_pressed("caminar")


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

		else:

			velocity.y += GRAVITY * delta


	# ==========================================
	# SALTO
	# ==========================================

	if Input.is_action_just_pressed("salto"):

		# ==========================================
		# WALL JUMP
		# ==========================================

		if agarrado_pared:

			# Guardamos la dirección antes de salir.
			var direccion_salto := pared_normal.x

			# --------------------------------------
			# IMPULSO
			# --------------------------------------

			velocity.x = direccion_salto * WALL_JUMP_FORCE
			velocity.y = JUMP_FORCE

			# --------------------------------------
			# RECUPERAR HABILIDADES
			# --------------------------------------

			seSalto = false


			# --------------------------------------
			# SALIR DE LA PARED
			# --------------------------------------

			agarrado_pared = false
			pared_normal = Vector2.ZERO

			# --------------------------------------
			# BLOQUEAR AGARRE INMEDIATO
			# --------------------------------------

			puede_agarrarse_pared = false

			# --------------------------------------
			# VOLVER A ORIENTACIÓN NORMAL
			# --------------------------------------

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

	if Input.is_action_just_pressed("saltoFuego")  :
		if ($TiempoFuego.is_stopped()) :
			velocity.y = JUMP_FIRE_FORCE

			fire()
			$TiempoFuego.start()


			# Salimos de la pared.
			agarrado_pared = false
			pared_normal = Vector2.ZERO

			# Volver a la orientación normal.
			rotation = 0.0
		else:
			pass


	# ==========================================
	# MOVER
	# ==========================================

	move_and_slide()


	# ==========================================
	# PERMITIR VOLVER A AGARRARSE
	# ==========================================

	# Cuando ya nos alejamos de la pared,
	# volvemos a permitir el wall grab.
	if not is_on_wall():

		puede_agarrarse_pared = true


	# ==========================================
	# DETECTAR PARED
	# ==========================================

	detectar_pared()


	# ==========================================
	# RESETEAR AL TOCAR EL SUELO
	# ==========================================

	if is_on_floor():

		seSalto = false

		agarrado_pared = false
		pared_normal = Vector2.ZERO

		puede_agarrarse_pared = true

		# Personaje vuelve a posición normal.
		rotation = 0.0


	# ==========================================
	# ANIMACIONES
	# ==========================================

	actualizar_animacion(direccion, caminando)


# ==========================================
# DETECTAR PARED ESPECIAL
# ==========================================

func detectar_pared() -> void:

	# ==========================================
	# BLOQUEO DESPUÉS DE WALL JUMP
	# ==========================================

	if not puede_agarrarse_pared:

		agarrado_pared = false
		pared_normal = Vector2.ZERO
		rotation = 0.0

		return


	# ==========================================
	# SUELO
	# ==========================================

	if is_on_floor():

		agarrado_pared = false
		pared_normal = Vector2.ZERO

		return


	# ==========================================
	# NO ESTÁ EN UNA PARED
	# ==========================================

	if not is_on_wall():

		agarrado_pared = false
		pared_normal = Vector2.ZERO

		return


	# ==========================================
	# BUSCAR COLISIÓN CON PARED ESPECIAL
	# ==========================================

	for i in get_slide_collision_count():

		var collision := get_slide_collision(i)

		var collider := collision.get_collider()

		# Solo paredes verticales.
		if abs(collision.get_normal().x) < 0.8:
			continue


		if not collider is CollisionObject2D:
			continue


		# ==========================================
		# COMPROBAR COLLISION LAYER 3
		# ==========================================

		if collider.collision_layer & (1 << (WALL_LAYER - 1)):

			agarrado_pared = true

			pared_normal = collision.get_normal()

			velocity.x = 0.0


			# ======================================
			# ROTAR EL PERSONAJE
			# ======================================

			if pared_normal.x < 0:

				# Pared a la derecha.
				#
				# Los pies quedan hacia la derecha.

				rotation = deg_to_rad(-90.0)

			else:

				# Pared a la izquierda.
				#
				# Los pies quedan hacia la izquierda.

				rotation = deg_to_rad(90.0)


			return


	# ==========================================
	# NO ES UNA PARED ESPECIAL
	# ==========================================

	agarrado_pared = false
	pared_normal = Vector2.ZERO

	rotation = 0.0


# ==========================================
# ANIMACIONES
# ==========================================

func actualizar_animacion(direccion: float, caminando: bool) -> void:

	# ==========================================
	# PARED
	# ==========================================

	if agarrado_pared:

		# La animación sigue siendo quieta.
		animated_sprite.animation = "quieta"

		animated_sprite.flip_h = false
		animated_sprite.flip_v = false

		animated_sprite.play()

		return


	# ==========================================
	# AIRE
	# ==========================================

	if not is_on_floor():

		animated_sprite.animation = "salto"

		animated_sprite.flip_h = direccion < 0
		animated_sprite.flip_v = false

		animated_sprite.play()

		return


	# ==========================================
	# SUELO
	# ==========================================

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

	# Restablecer estado de pared.
	agarrado_pared = false
	pared_normal = Vector2.ZERO
	puede_agarrarse_pared = true

	set_physics_process(true)
	set_process(true)



# ==========================================
# herido
# ==========================================

func herir():
	vida -= 1
	barraVida.value = vida

	if vida <= 0:
		morir()


# ==========================================
# MORIR
# ==========================================

func morir():

	died.emit()

	set_physics_process(false)
	set_process(false)

	hide()
