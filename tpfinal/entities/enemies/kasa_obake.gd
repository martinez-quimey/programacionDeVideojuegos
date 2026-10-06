extends "res://entities/abstract/abstract_enemy.gd"


# ==========================================
# VELOCIDADES
# ==========================================

@export var VELOCIDAD_CAIDA_LENTA: float = 80.0
@export var VELOCIDAD_CAIDA_RAPIDA: float = 700.0


# ==========================================
# ESTADO
# ==========================================

var jugador_debajo: Node2D = null


# ==========================================
# INICIO
# ==========================================

func _ready() -> void:

	super._ready()


	animationPlay("abierto")

	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)

	$DamageArea.body_entered.connect(_on_damage_area_body_entered)


# ==========================================
# FÍSICA
# ==========================================

func _physics_process(delta):

	var inicio = Time.get_ticks_msec()

	if vida <= 0:

		return


	# ==========================================
	# VELOCIDAD DE CAÍDA
	# ==========================================

	if jugador_debajo != null:

		velocity.y = VELOCIDAD_CAIDA_RAPIDA

		animationPlay("cerrado")

	else:

		velocity.y = VELOCIDAD_CAIDA_LENTA

		animationPlay("abierto")


	# ==========================================
	# CAER RECTO
	# ==========================================

	move_and_slide()


	# ==========================================
	# CONTACTO CON EL SUELO
	# ==========================================

	if is_on_floor():

		morir()


	var duracion = Time.get_ticks_msec() - inicio





# ==========================================
# JUGADOR ENTRA EN DETECTION AREA
# ==========================================

func _on_detection_body_entered(body: Node2D) -> void:


	if not body.is_in_group("jugador"):
		return

	jugador_debajo = body


# ==========================================
# JUGADOR SALE DE DETECTION AREA
# ==========================================

func _on_detection_body_exited(body: Node2D) -> void:

	
	if body == jugador_debajo:


		jugador_debajo = null


# ==========================================
# DAMAGE AREA
# ==========================================

func _on_damage_area_body_entered(body: Node2D) -> void:

	# ==========================================
	# IGNORAR EL PROPIO PARAGUAS
	# ==========================================

	if body == self:

		return




	# ==========================================
	# SI CHOCÓ CON EL JUGADOR
	# ==========================================

	if body.is_in_group("jugador"):

	
		body.herir(1)
	
		aplicar_empuje_contacto(body)



	# ==========================================
	# EL PARAGUAS MUERE AL CHOCAR CON CUALQUIER CUERPO EXTERNO
	# ==========================================

	
	morir()


# =========================================================
# EMPUJE POR CONTACTO
# =========================================================

func aplicar_empuje_contacto(cuerpo: Node2D) -> void:

	if cuerpo == null:
		return


	var diferencia_x: float = cuerpo.global_position.x - global_position.x

	var direccion_empuje := Vector2.RIGHT


	# Jugador a la izquierda.
	if diferencia_x < -0.1:

		direccion_empuje = Vector2.LEFT


	# Jugador a la derecha.
	elif diferencia_x > 0.1:

		direccion_empuje = Vector2.RIGHT


	# Misma posición horizontal.
	else:

		direccion_empuje = Vector2.RIGHT


	# Empuje reducido.
	cuerpo.retroceso(direccion_empuje, 200)


# ==========================================
# ANIMACIONES
# ==========================================

func animationPlay(nombre: String):

	animated_sprite.play(nombre)
