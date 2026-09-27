extends CharacterBody2D


@onready var Invulnerabilidad: Timer = $Invulnerabilidad
@onready var detection_area: Area2D = $OrientacionEnemy/DetectionArea
@onready var animated_sprite: AnimatedSprite2D = $OrientacionEnemy/AnimatedSprite2D


# ==========================================
# FÍSICA
# ==========================================

@export var GRAVITY: float = 600.0

# Peso del enemigo.
# Cuanto mayor sea, menor será el retroceso.
@export var PESO: float = 1.0


@export var vida: int = 1

# ==========================================
# ESTADO
# ==========================================

const isBoss = false


var player_in_range: bool = false


func _ready():

	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)


# ==========================================
# GRAVEDAD
# ==========================================

func aplicar_gravedad(delta: float) -> void:

	if not is_on_floor():

		velocity.y += GRAVITY * delta

	else:

		velocity.y = 0


# ==========================================
# RETROCESO
# ==========================================

func retroceso(direccion: Vector2, fuerza: int) -> void:

	print("se activo el retroceso del enemigo")
	print(str(direccion))
	print(str(fuerza))

	if PESO <= 0:
		return

	direccion = direccion.normalized()

	var retroceso = fuerza / PESO

	velocity.x = direccion.x * retroceso

	frenarCaminatas() # para que el movimiento del enemigo no anule el retroceso

func frenarCaminatas():
	pass

# ==========================================
# DETECCIÓN DEL JUGADOR
# ==========================================

func _on_body_entered(body):

	if body.is_in_group("jugador"):

		player_in_range = true

		actuarContraPlayer()


func _on_body_exited(body):

	if body.is_in_group("jugador"):

		player_in_range = false

		dejarDeActuarContraPlayer()


func actuarContraPlayer():

	pass


func dejarDeActuarContraPlayer():

	pass



	


# ==========================================
# MUERTE
# ==========================================

func morir():

	animationPlay("muerte")
	await get_tree().create_timer(1.0).timeout
	queue_free()


# ==========================================
# RECIBIR DAÑO
# ==========================================

func herir(num: int):
	print ("enemigo herido")
	print("vida: " + str(vida))
	if Invulnerabilidad.is_stopped():

		vida -= num
		print("vidaNueva: " + str(vida))
		if isBoss:
			pass

		if vida <= 0:
			print ("morir")
			morir()

			return

		Invulnerabilidad.start()

		animacionHerida()


# ==========================================
# ANIMACIONES
# ==========================================

func animationPlay(string: String):

	pass

func animacionHerida():

	while not Invulnerabilidad.is_stopped():

		animated_sprite.visible = false

		await get_tree().create_timer(0.1).timeout

		animated_sprite.visible = true

		await get_tree().create_timer(0.1).timeout

	animated_sprite.visible = true
