
extends CharacterBody2D

var direccion: float = 1.0

@onready var Invulnerabilidad: Timer = $Invulnerabilidad
@onready var detection_area: Area2D = $OrientacionEnemy/DetectionArea
@onready var animated_sprite: AnimatedSprite2D = $OrientacionEnemy/AnimatedSprite2D

# FÍSICA
@export var GRAVITY: float = 600.0
@export var PESO: float = 1.0
@export var vida: int = 1
@export var DANIO_CONTACTO: int = 1
@export var FUERZA_EMPUJE_CONTACTO: float = 400.0
@export var FUERZA_EMPUJE_CONTACTO_DESDE_ARRIBA: float = 500.0

# INMUNIDADES AMBIENTALES
@export var esInmuneALaLava: bool = false
@export var esInmuneAlAgua: bool = false

# OPTIMIZACIÓN
@export var distancia_maxima_actividad: float = 1000.0
var enemigo_activo: bool = true

# ESTADO
const isBoss = false
var player_in_range: bool = false


func _ready() -> void:
	if is_instance_valid(detection_area):
		if not detection_area.body_entered.is_connected(_on_body_entered):
			detection_area.body_entered.connect(_on_body_entered)

		if not detection_area.body_exited.is_connected(_on_body_exited):
			detection_area.body_exited.connect(_on_body_exited)


# OPTIMIZACIÓN
func comprobar_distancia_al_player() -> void:
	var player := get_tree().get_first_node_in_group("jugador")

	if not is_instance_valid(player):
		return

	var distancia: float = global_position.distance_to(player.global_position)
	var debe_estar_activo: bool = distancia <= distancia_maxima_actividad

	if enemigo_activo == debe_estar_activo:
		return

	enemigo_activo = debe_estar_activo
	set_physics_process(enemigo_activo)


# GRAVEDAD
func aplicar_gravedad(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0


# AGUA
func comprobar_tile_agua() -> bool:
	if esInmuneAlAgua:
		return false

	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var collider = collision.get_collider()

		if collider is TileMapLayer and collision_tiene_layer(collision, 4):
			morir()
			return true

	return false


# LAVA
func comprobar_tile_lava() -> bool:
	if esInmuneALaLava:
		return false

	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var collider = collision.get_collider()

		if collider is TileMapLayer and collision_tiene_layer(collision, 5):
			morir()
			return true

	return false


# CAPA DE COLISIÓN
func collision_tiene_layer(
	collision: KinematicCollision2D,
	layer: int
) -> bool:
	var collider = collision.get_collider()

	if not collider is CollisionObject2D:
		return false

	return (collider.collision_layer & (1 << (layer - 1))) != 0


# RETROCESO
func retroceso(direccion_retroceso: Vector2, fuerza: int) -> void:
	if is_queued_for_deletion():
		return

	if PESO <= 0.0 or fuerza <= 0:
		return

	if direccion_retroceso.is_zero_approx():
		return

	var direccion_normalizada: Vector2 = direccion_retroceso.normalized()
	var fuerza_efectiva: float = float(fuerza) / PESO

	# Aplicar el impulso horizontal.
	velocity.x = direccion_normalizada.x * fuerza_efectiva

	# Aplicar el impulso vertical si la dirección lo incluye.
	if not is_zero_approx(direccion_normalizada.y):
		velocity.y = direccion_normalizada.y * fuerza_efectiva

	# Avisar al enemigo para que su movimiento automático
	# no sobrescriba velocity.x inmediatamente.
	#
	# Si el enemigo sobrescribe frenarCaminatas(), se ejecutará
	# esa versión. Así se conserva la compatibilidad con la araña.
	frenarCaminatas()


func frenarCaminatas() -> void:
	pass


# DETECCIÓN DEL JUGADOR
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("jugador"):
		player_in_range = true
		actuarContraPlayer()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("jugador"):
		player_in_range = false
		dejarDeActuarContraPlayer()


func actuarContraPlayer() -> void:
	pass


func dejarDeActuarContraPlayer() -> void:
	pass


# MUERTE PREDETERMINADA
# Los enemigos con animación de muerte deben sobrescribir esta función.
func morir() -> void:
	queue_free()


# RECIBIR DAÑO
func herir(num: int) -> void:
	if num <= 0 or is_queued_for_deletion():
		return

	if not is_instance_valid(Invulnerabilidad):
		return

	if not Invulnerabilidad.is_stopped():
		return

	print("Enemigo herido")
	print("Vida anterior: ", vida)

	vida -= num

	print("Vida nueva: ", vida)

	if vida <= 0:
		morir()
		return

	if isBoss:
		pass

	Invulnerabilidad.start()
	animacionHerida()


# ANIMACIONES
func animationPlay(_nombre: String) -> void:
	pass


# COLISIÓN CON EL JUGADOR
func comprobar_colision_con_jugador() -> void:
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var cuerpo = collision.get_collider()

		if not is_instance_valid(cuerpo):
			continue

		if not cuerpo.is_in_group("jugador"):
			continue

		aplicar_empuje_contacto(cuerpo)

		if cuerpo.has_method("herir") and DANIO_CONTACTO > 0:
			cuerpo.herir(DANIO_CONTACTO)

		return


# EMPUJE POR CONTACTO
func aplicar_empuje_contacto(cuerpo: Node2D) -> void:
	if not is_instance_valid(cuerpo):
		return

	if not cuerpo.has_method("retroceso"):
		return

	var diferencia_x: float = cuerpo.global_position.x - global_position.x
	var diferencia_y: float = cuerpo.global_position.y - global_position.y

	var direccion_empuje: Vector2
	var fuerza_empuje: float

	if diferencia_y < -20.0:
		var direccion_horizontal: float = signf(diferencia_x)

		if is_zero_approx(direccion_horizontal):
			direccion_horizontal = direccion

		direccion_empuje = Vector2(
			direccion_horizontal * 0.35,
			-1.0
		).normalized()

		fuerza_empuje = FUERZA_EMPUJE_CONTACTO_DESDE_ARRIBA
	else:
		if diferencia_x < -0.1:
			direccion_empuje = Vector2.LEFT
		elif diferencia_x > 0.1:
			direccion_empuje = Vector2.RIGHT
		elif direccion < 0.0:
			direccion_empuje = Vector2.LEFT
		else:
			direccion_empuje = Vector2.RIGHT

		fuerza_empuje = FUERZA_EMPUJE_CONTACTO

	cuerpo.retroceso(
		direccion_empuje,
		int(round(fuerza_empuje))
	)


# ANIMACIÓN DE HERIDA PREDETERMINADA
func animacionHerida() -> void:
	if not is_instance_valid(Invulnerabilidad):
		return

	while is_instance_valid(self) and not Invulnerabilidad.is_stopped():
		if not is_instance_valid(animated_sprite):
			return

		animated_sprite.visible = false
		await get_tree().create_timer(0.1).timeout

		if not is_instance_valid(self):
			return

		if not is_instance_valid(animated_sprite):
			return

		animated_sprite.visible = true
		await get_tree().create_timer(0.1).timeout

	if is_instance_valid(animated_sprite):
		animated_sprite.visible = true
