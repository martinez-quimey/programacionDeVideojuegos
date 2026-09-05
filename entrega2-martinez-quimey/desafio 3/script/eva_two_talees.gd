#player
#Player
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


@onready var fire_position: Marker2D = $FirePosition

signal hit
signal died

@export var speed: float = 400.0

var screen_size: Vector2
var seSalto: bool
var saltoFuego: bool
var activo: bool = false
var projectile_container: Node


func _ready() -> void:
	screen_size = get_viewport_rect().size
	hide()


func _physics_process(delta: float) -> void:
	if not activo:
		return

	# ==========================================
	# GRAVEDAD
	# ==========================================

	if not is_on_floor():
		velocity.y += GRAVITY * delta


	# ==========================================
	# MOVIMIENTO HORIZONTAL
	# ==========================================

	var direccion = Input.get_axis("izquierda", "derecha")
	var caminando = Input.is_action_pressed("caminar")

	if direccion != 0:

		# CAMINANDO
		if caminando:
			velocity.x = move_toward(
				velocity.x,
				direccion * SPEEDCAMINANDO,
				ACCELERATION * delta
			)

		# CORRIENDO
		else:
			velocity.x = move_toward(
				velocity.x,
				direccion * MAX_SPEED,
				ACCELERATION * delta
			)

	else:
		# FRENADO
		velocity.x = move_toward(
			velocity.x,
			0.0,
			FRICTION * delta
		)


	# ==========================================
	# SALTO
	# ==========================================

	if Input.is_action_just_pressed("salto") and is_on_floor():
		velocity.y = JUMP_FORCE


	# ==========================================
	# DOBLE SALTO
	# ==========================================

	if Input.is_action_just_pressed("salto") and !is_on_floor() and !seSalto:
		velocity.y = JUMP_FORCE
		seSalto = true


	# ==========================================
	# SALTO CON DISPARO
	# ==========================================

	if Input.is_action_just_pressed("saltoFuego") and !saltoFuego:
		velocity.y = JUMP_FIRE_FORCE
		saltoFuego = true
		fire()


	# ==========================================
	# RESETEAR SALTOS AL TOCAR EL SUELO
	# ==========================================

	if is_on_floor():
		saltoFuego = false
		seSalto = false


	# ==========================================
	# ANIMACIONES
	# ==========================================

	if direccion != 0:

		$AnimatedSprite2D.flip_h = direccion < 0
		$AnimatedSprite2D.flip_v = false

		if caminando:
			$AnimatedSprite2D.animation = "caminar"
		else:
			$AnimatedSprite2D.animation = "correr"

		$AnimatedSprite2D.play()

	else:

		$AnimatedSprite2D.animation = "quieta"
		$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.play()


	# ==========================================
	# MOVER AL JUGADOR
	# ==========================================

	move_and_slide()


func _on_body_entered(body: Node2D) -> void:
	hide()
	hit.emit()
	$CollisionShape2D.set_deferred("disabled", true)


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


func _on_projectile_delete_requested(projectile):
	projectile_container.remove_child(projectile)
	projectile.queue_free()


func start(pos: Vector2, projectile_container) -> void:
	position = pos
	activo = true

	show()

	$CollisionShape2D.set_deferred("disabled", false)

	self.projectile_container = projectile_container

	set_physics_process(true)
	set_process(true)


func morir():
	died.emit()

	set_physics_process(false)
	set_process(false)

	hide()
