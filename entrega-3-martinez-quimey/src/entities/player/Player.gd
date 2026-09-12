extends CharacterBody2D

## El uso de "%path" es un shorthand para acceder a los "Nodos Únicos de Escena"
## El nodo "Weapon" está marcado como un "Nodo Único de Escena", es decir, es el
## único nodo en la escena actual que se llama así, por lo que si se hace una query del
## mismo utilizando este patrón, se puede acceder a él de manera dinámica sin
## importar su ubicación en el árbol, es decir, ya no se tiene que especificar una
## ruta estática al mismo.
## https://docs.godotengine.org/es/stable/tutorials/scripting/scene_unique_nodes.html
@onready var weapon: Node = $"%Weapon"
@onready var body_animations: AnimationPlayer = $BodyAnimations
@onready var body: Sprite2D = $bodyPivot/Body
@onready var body_pivot : Node2D = $bodyPivot
@export var ACCELERATION: float = 3750.0
@export var H_SPEED_LIMIT: float = 600.0
@export var jump_speed: int = 500
@export var FRICTION_WEIGHT: float = 6.25
@export var gravity: float = 625.0
@export var push_force: float = 80.0

var projectile_container: Node
var h_movement_direction: int = 0
var jump: bool = false

## Flag de ayuda para saber identificar el estado de actividad
var dead: bool = false


func _ready() -> void:
	initialize()


func initialize(projectile_container: Node = get_parent()) -> void:
	self.projectile_container = projectile_container
	weapon.projectile_container = projectile_container


func _physics_process(delta: float) -> void:
	_process_input()

	# Apply velocity
	## Si estoy muerto solo aplico fricción para que no se deslice como cubito de hielo
	## Multiplicamos por delta para que sea independiente del framerate
	if !dead && h_movement_direction != 0:
		velocity.x = clamp(
			velocity.x + (h_movement_direction * ACCELERATION * delta),
			-H_SPEED_LIMIT,
			H_SPEED_LIMIT
		)
	else:
		velocity.x = lerp(
			velocity.x,
			0.0,
			FRICTION_WEIGHT * delta
		) if abs(velocity.x) > 1 else 0.0

	# Jump
	# NO multiplicamos por delta ya que se aplica una sola vez
	if jump and is_on_floor():
		velocity.y -= jump_speed

	# Gravity
	# Multiplicamos por delta para que sea independiente del framerate
	velocity.y += gravity * delta

	move_and_slide()

	# Basado en https://youtu.be/SJuScDavstM
	for i in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		if collision.get_collider() is RigidBody2D:
			var collision_normal: Vector2 = collision.get_normal()
			var velocity_alignment: float = float(
				collision_normal.dot(-velocity.normalized()) > 0.0
			)
			collision.get_collider().apply_central_impulse(
				-collision_normal.slerp(-velocity.normalized(), 0.5)
				* push_force
				* velocity_alignment
			)


func _process_input() -> void:
	## Estoy muerto, asi que dejo de procesar inputs
	if dead:
		jump = false
		return

	# Weapon Fire
	if Input.is_action_just_pressed("fire_cannon"):
		if projectile_container == null:
			projectile_container = get_parent()
		if weapon.projectile_container == null:
			weapon.projectile_container = projectile_container
		weapon.fire()

	# Jump Action
	jump = Input.is_action_just_pressed("jump")

	# Horizontal Movement
	h_movement_direction = int(
		Input.is_action_pressed("move_right")
	) - int(
		Input.is_action_pressed("move_left")
	)
	body.flip_h = h_movement_direction <0
	if is_on_floor():
		_play_animation("jump")
	elif h_movement_direction != 0:
		_play_animation("walk")
	else:
		_play_animation("idle")

	weapon.process_input()


func notify_hit() -> void:
	if dead:
		return

	print("I'm player and imma die")
	dead = true
	_remove.call_deferred()


func _remove() -> void:
	set_physics_process(false)
	hide()
	collision_layer = 0


## Wrapper sobre el llamado a animación para tener un solo punto de entrada controlable
## (en el caso de que necesitemos expandir la lógica o debuggear, por ejemplo)
func _play_animation(animation: String) -> void:
	if body_animations.has_animation(animation):
		body_animations.play(animation)
