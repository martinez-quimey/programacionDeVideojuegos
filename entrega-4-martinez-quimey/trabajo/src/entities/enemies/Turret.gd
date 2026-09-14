extends CharacterBody2D
class_name EnemyTurret

@onready var fire_position: Node2D = $FirePosition
@onready var fire_timer: Timer = $FireTimer
@onready var raycast: RayCast2D = $RayCast2D
@onready var body_anim: AnimatedSprite2D = $Body

@export var projectile_scene: PackedScene
@export var pathfinding: PathfindAstar
var target: Node2D
var projectile_container: Node

var path: PackedVector2Array = []
var speed: float = 100.0

## Flag de ayuda para saber identificar el estado de actividad
var dead: bool = false


func _ready() -> void:
	if pathfinding == null:
		pathfinding = get_parent().get_node("AstarTileMap")
	
	fire_timer.timeout.connect(fire)
	set_physics_process(false)
	
	## Seteamos la primera animación que debe ejecutarse
	_play_animation(&"idle")


func initialize(turret_pos: Vector2, _projectile_container: Node, _pathfinding: PathfindAstar) -> void:
	global_position = turret_pos
	self.projectile_container = _projectile_container
	pathfinding = _pathfinding
	$TimerIdle.start()


func fire() -> void:
	if target != null:
		var proj_instance: Node = projectile_scene.instantiate()
		if projectile_container == null:
			projectile_container = get_parent()
		projectile_container.add_child(proj_instance)
		proj_instance.initialize(
			fire_position.global_position,
			fire_position.global_position.direction_to(target.global_position)
		)
		fire_timer.start()
		_play_animation(&"attack")


func _physics_process(_delta: float) -> void:
	raycast.set_target_position(raycast.to_local(target.global_position))
	if raycast.is_colliding() && raycast.get_collider() == target:
		if fire_timer.is_stopped():
			fire_timer.start()
	elif !fire_timer.is_stopped():
		fire_timer.stop()

	
	## Damos vuelta el cuerpo para que mire al objetivo en el eje x
	## y usamos la dirección a la que se casteó el raycast
	## Otra manera sería hacer (target.global_position - global_position).x < 0
	body_anim.flip_h = raycast.target_position.x < 0
	
	if !path.is_empty():
		var next_point: Vector2 = path[0]
		
		if global_position.distance_to(next_point) < 5.0:
			path.remove_at(0)
		else:
			velocity = global_position.direction_to(next_point) * speed
			move_and_slide()


## Esta función ya no llama directamente a remove, sino que inhabilita las
## colisiones con el mundo, pausa todo lo demás y ejecuta una animación de muerte
## dependiendo de si el enemigo esta o no alerta
func notify_hit() -> void:
	print("I'm turret and imma die")
	dead = true
	target = null
	set_physics_process(false)
	fire_timer.stop()
	collision_layer = 0
	if target != null:
		_play_animation(&"die_alert")
	else:
		_play_animation(&"die")


func _remove() -> void:
	get_parent().remove_child(self)
	queue_free()


func _on_detection_area_body_entered(body: Node2D) -> void:
	if target == null && !dead:
		target = body
		path = pathfinding.get_simple_path(
			global_position,
			target.global_position
		)
		set_physics_process(true)
		
		## No se ejecuta directamente el "idle_alert", sino que se ejecuta una
		## animación de transición
		_play_animation(&"alert")


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == target && !dead:
		target = null
		path.clear()
		set_physics_process(false)
		fire_timer.stop()
		
		## No se ejecuta directamente el "idle", sino que se ejecuta una
		## animación de transición
		_play_animation(&"go_normal")


## Acá manejamos el callback de "animation finished" y procesamos qué
## lógica ejecutar a continuación, estilo grafo.
func _on_animation_finished() -> void:
	match body_anim.animation:
		&"alert":
			_play_animation(&"idle_alert")
		&"go_normal":
			_play_animation(&"idle")
		&"fire", &"attack":
			_play_animation(&"alert")
		&"die", &"die_alert":
			call_deferred(&"_remove")


## Wrapper sobre el llamado a animación para tener un solo punto de entrada controlable
## (en el caso de que necesitemos expandir la lógica o debuggear, por ejemplo)
func _play_animation(animation: StringName) -> void:
	if body_anim.sprite_frames.has_animation(animation):
		body_anim.play(animation)
