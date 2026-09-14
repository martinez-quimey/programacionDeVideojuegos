extends CharacterBody2D
class_name Player

# Señales que sirven para comunicar el estado del Player
# a los elementos conectados. Se puede utilizar tanto para
# comunicar estados a la State Machine (sin incluir código
# de la state machine directamente) como para comunicarse,
# por ejemplo, con el entorno del nivel.

## Señal que indica que el personaje fue golpeado
signal hit(amount: int)
## Señal que indica que el personaje fue curado
signal healed(amount: int)
## Señal que indica cambio de estado en la salud del personaje
signal hp_changed(current_hp: int, max_hp: int)
## Señal emitida al morir
signal died()

@onready var weapon: Node = $"%Weapon"
@onready var body_animations: AnimationPlayer = $BodyAnimations
@onready var body_pivot: Node2D = $BodyPivot
@onready var floor_raycasts: Array = $FloorRaycasts.get_children()

@export var acceleration: float = 3750.0 # Lo multiplicamos por delta, asi que es 60.0 / (1.0 / 60.0)
@export var h_speed_limit: float = 300.0
@export var jump_speed: int = 500
@export var friction_weight: float = 6.25 # Lo multiplicamos por delta, asi que es 0.1 / (1.0 / 60.0)
@export var gravity: float = 625.0 # Lo multiplicamos por delta, asi que es 10.0 / (1.0 / 60.0)
@export var push_force: float = 80.0

var projectile_container: Node
var h_movement_direction: int = 0

## Flag de ayuda para saber identificar el estado de actividad
var dead: bool = false


func _ready() -> void:
	initialize()


func initialize(_projectile_container: Node = get_parent()) -> void:
	self.projectile_container = _projectile_container
	weapon.projectile_container = projectile_container


# El único elemento que queda abstraer de esta función
# es el manejo del salto. Esta parte del código no va a
# seguir formando parte del código del player, y, en su lugar
# lo migraremos al código del estado Jump correspondiente
func _process_input() -> void:
	# Jump Action
	var jump: bool = Input.is_action_just_pressed(&"jump")
	if jump && is_on_floor_raycasted():
		velocity.y -= jump_speed


# Dado que es un comportamiento común a varios states diferentes,
# una solución para evitar código repetido es extraer el comportamiento
# de manejo del disparo del arma a una función para ser llamada
# desde cada state.
func _handle_weapon_actions() -> void:
	weapon.process_input()
	if Input.is_action_just_pressed(&"fire_weapon"):
		if projectile_container == null:
			projectile_container = get_parent()
		if weapon.projectile_container == null:
			weapon.projectile_container = projectile_container
		weapon.fire()


# Hacemos lo mismo que con las acciones del arma, encapsulamos el
# comportamiento del handling del input horizontal. En este caso
# dividimos la aceleración y la desaceleración por separado porque
# ahora delegamos esa decisión a cada state.
func _handle_move_input(delta: float) -> void:
	h_movement_direction = int(
		Input.is_action_pressed(&"move_right")) - int(Input.is_action_pressed(&"move_left")
	)
	if h_movement_direction != 0:
		velocity.x = clamp(
			velocity.x + (h_movement_direction * acceleration * delta),
			-h_speed_limit,
			h_speed_limit
		)
		# Giramos el sprite dependiendo de a dónde nos movemos
		# 1 para derecha, -1 para izquierda, pero nunca 0
		body_pivot.scale.x = 1 - 2 * float(h_movement_direction < 0)


# Se extrae el comportamiento del manejo de la aplicación de fricción
# a una función para ser llamada apropiadamente desde cada state
func _handle_deacceleration(delta: float) -> void:
	velocity.x = lerp(velocity.x, 0.0, friction_weight * delta) if abs(velocity.x) > 1 else 0


# Se extrae el comportamiento de la aplicación de gravedad y movimiento
# a una función para ser llamada apropiadamente desde cada state
func _apply_movement(delta: float) -> void:
	# Gravity
	# Multiplicamos por delta para que sea independiente del framerate
	velocity.y += gravity * delta
	
	# Basado en https://youtu.be/SJuScDavstM
	for i in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		if collision.get_collider() is RigidBody2D:
			var collision_normal: Vector2 = collision.get_normal()
			var velocity_alignment: float = float(
				collision_normal.dot(-velocity.normalized()) > 0.0
			)
			collision.get_collider().apply_central_impulse(
				-collision_normal.slerp(-velocity.normalized(), 0.5) * push_force * velocity_alignment
			)
	
	move_and_slide()


## Función is_on_floor() custom que agrega chequeo de raycasts
## para expandir la ventana de chequeo de piso
func is_on_floor_raycasted() -> bool:
	var is_colliding: bool = is_on_floor()
	for raycast in floor_raycasts:
		## Al tener deshabilitados los raycasts por default
		## ya que queremos que solamente se procesen en esta
		## función, debemos forzar una actualización
		raycast.force_raycast_update()
		is_colliding = is_colliding || raycast.is_colliding()
	return is_colliding


# Esta función ya no llama directamente a remove, sino que deriva
# el handleo a la state machine emitiendo una señal. Esto es para
# los casos de estados en los cuales no se manejan hits
func notify_hit(amount: int = 1) -> void:
	hit.emit(amount)


# Y acá se maneja el hit final. Como aun no tenemos una "cantidad" de HP,
# sino una flag, el hit nos mata instantaneamente y tiramos una notificación.
# Esta signal tranquilamente podría llamarse "dead", pero como esa la utilizamos
# para otras cosas, y como sabemos que incorporaremos una barra de salud después
# es apropiado manejarlo de esta manera.
func _handle_hit(_amount: int = 1) -> void:
	dead = true
	hp_changed.emit(0, 1)


# El llamado a remove final
func _remove() -> void:
	set_physics_process(false)
	collision_layer = 0


# Wrapper sobre el llamado a animación para tener un solo punto de entrada controlable
# (en el caso de que necesitemos expandir la lógica o debuggear, por ejemplo)
func _play_animation(animation: StringName) -> void:
	if body_animations.has_animation(animation):
		body_animations.play(animation)
