#Player
extends CharacterBody2D
@export var projectile_scene: PackedScene


@onready var fire_position: Marker2D = $FirePosition
@onready var projectile_container: Node = $"../Projectiles"


const GRAVITY = 980.0
const JUMP_FORCE = -500.0
const JUMPFire_FORCE = -600.0
const SPEED = 200.0

signal hit

@export var speed: float = 400.0
var screen_size: Vector2
var seSalto: bool
var saltoFuego: bool


func _ready() -> void:
	screen_size = get_viewport_rect().size
	hide()
func _physics_process(delta: float) -> void:
	# Gravedad
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Movimiento horizontal
	velocity.x = Input.get_axis("izquierda", "derecha") * SPEED

	# Salto
	if Input.is_action_just_pressed("salto") and is_on_floor():
		velocity.y = JUMP_FORCE
		
		
	# doble Salto
	if Input.is_action_just_pressed("salto") and !is_on_floor() and !seSalto:
		velocity.y = JUMP_FORCE
		seSalto = true
	#salto con disparo
	if Input.is_action_just_pressed("saltoFuego") and !saltoFuego:
		velocity.y = JUMPFire_FORCE
		saltoFuego = true
		fire()
	if is_on_floor():
		saltoFuego = false
		seSalto = false


	# Animación
	if velocity.x != 0:
		$AnimatedSprite2D.animation = "caminar"
		$AnimatedSprite2D.flip_h = velocity.x < 0
		$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.animation = "quieta"
		$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.play()

	# Mover al jugador
	move_and_slide()




func _on_body_entered(body: Node2D) -> void:
	hide()
	hit.emit()
	$CollisionShape2D.set_deferred("disabled", true)
	self.projectile_container = projectile_container 

func fire():
	var projectile: Proyectile = projectile_scene.instantiate()
	projectile_container.add_child(projectile)
	projectile.set_starting_values(fire_position.global_position, Vector2.DOWN)
	projectile.delete_requested.connect(_on_projectile_delete_requested)


func _on_projectile_delete_requested(projectile):
	projectile_container.remove_child(projectile)
	projectile.queue_free()
	
func start(pos: Vector2) -> void:
	position = pos
	show()
	$CollisionShape2D.set_deferred("disabled", false)
