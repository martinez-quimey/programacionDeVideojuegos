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

	# Conectar las señales del área de detección.
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)




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
	#
	# No modificamos velocity.x.
	# El paraguas cae verticalmente.
	# ==========================================

	move_and_slide()


	# ==========================================
	# CONTACTO FÍSICO
	# ==========================================

	comprobar_contacto_con_jugador()


	# ==========================================
	# CONTACTO CON EL SUELO
	# ==========================================

	if is_on_floor():

		morir()
	var duracion = Time.get_ticks_msec() - inicio

	if duracion >= 50:

		print(
			"⚠️ PROCESS LENTO paraguas | ",
			get_path(),
			" | ",
			duracion,
			" ms"
		)

# ==========================================
# JUGADOR ENTRA EN DETECTION AREA
# ==========================================

func _on_detection_body_entered(body: Node2D) -> void:

	if not body.is_in_group("jugador"):
		return


	# Solo detectamos al jugador si está debajo.

	if body.global_position.y > global_position.y:

		jugador_debajo = body


# ==========================================
# JUGADOR SALE DE DETECTION AREA
# ==========================================

func _on_detection_body_exited(body: Node2D) -> void:

	if body == jugador_debajo:

		jugador_debajo = null


# =========================================================
# DAÑO POR CONTACTO FÍSICO
# =========================================================

func comprobar_contacto_con_jugador():

	for i in get_slide_collision_count():

		var colision = get_slide_collision(i)

		var cuerpo = colision.get_collider()


		if cuerpo == null:
			continue


		if not cuerpo.is_in_group("jugador"):
			continue


		# ==========================================
		# DE QUÉ LADO VIENE EL JUGADOR
		# ==========================================

		var diferencia_y: float = cuerpo.global_position.y - global_position.y


		# ==========================================
		# JUGADOR VIENE DESDE ARRIBA
		# ==========================================

		if diferencia_y < 0:

			continue


		# ==========================================
		# HACER DAÑO
		# ==========================================

		cuerpo.herir(1)


		# ==========================================
		# EMPUJE
		# ==========================================

		aplicar_empuje_contacto(cuerpo)


		# ==========================================
		# MORIR
		# ==========================================

		morir()

		return


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
