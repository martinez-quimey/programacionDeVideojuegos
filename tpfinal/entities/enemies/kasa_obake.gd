extends "res://entities/abstract/abstract_enemy.gd"



# ==========================================
# VELOCIDADES
# ==========================================

@export var VELOCIDAD_CAIDA_LENTA: float = 80.0
@export var VELOCIDAD_CAIDA_RAPIDA: float = 700.0


# ==========================================
# ESTADO DEL PARAGUAS
# ==========================================

var cayendo_rapido: bool = false


# ==========================================
# INICIO
# ==========================================

func _ready():

	super._ready()

	animationPlay("abierto")


# ==========================================
# FÍSICA
# ==========================================

func _physics_process(delta):

	# Si ya está muerto, no hacemos nada.
	if vida <= 0:
		return


	# ==========================================
	# DETECTAR AL JUGADOR
	# ==========================================

	if player_in_range and not cayendo_rapido:

		var jugador = obtener_jugador()

		if jugador != null:

			# El jugador debe estar debajo del paraguas.
			if jugador.global_position.y > global_position.y:

				cayendo_rapido = true

				animationPlay("cerrado")


	# ==========================================
	# CAÍDA
	# ==========================================

	if cayendo_rapido:

		velocity.y = VELOCIDAD_CAIDA_RAPIDA

	else:

		velocity.y = VELOCIDAD_CAIDA_LENTA


	# ==========================================
	# MOVIMIENTO
	# ==========================================

	move_and_slide()


	# ==========================================
	# CONTACTO CON EL JUGADOR
	# ==========================================

	comprobar_colision_con_jugador()


	# ==========================================
	# CONTACTO CON EL SUELO
	# ==========================================

	if is_on_floor():

		morir()


# ==========================================
# OBTENER JUGADOR
# ==========================================

func obtener_jugador():

	for cuerpo in detection_area.get_overlapping_bodies():

		if cuerpo.is_in_group("jugador"):

			return cuerpo

	return null


# =========================================================
# DAÑO POR CONTACTO FÍSICO
# =========================================================

func comprobar_colision_con_jugador():

	for i in get_slide_collision_count():

		var collision = get_slide_collision(i)

		var cuerpo = collision.get_collider()


		if cuerpo == null:
			continue


		if cuerpo.is_in_group("jugador"):

			cuerpo.herir(2)

			# El contacto físico calcula desde qué lado
			# viene el jugador.

			aplicar_empuje_contacto(cuerpo)

			# El paraguas muere después de golpear al jugador.

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


	# =====================================================
	# JUGADOR A LA IZQUIERDA
	# =====================================================

	if diferencia_x < -0.1:

		direccion_empuje = Vector2.LEFT


	# =====================================================
	# JUGADOR A LA DERECHA
	# =====================================================

	elif diferencia_x > 0.1:

		direccion_empuje = Vector2.RIGHT


	# =====================================================
	# JUGADOR PRÁCTICAMENTE ENCIMA
	# =====================================================

	else:

		# Si están prácticamente en la misma posición
		# horizontal, usamos la dirección del paraguas.

		if velocity.x < 0:

			direccion_empuje = Vector2.LEFT

		else:

			direccion_empuje = Vector2.RIGHT


	# =====================================================
	# APLICAR EMPUJE
	# =====================================================

	cuerpo.retroceso(direccion_empuje, 400)


# ==========================================
# ANIMACIONES
# ==========================================

func animationPlay(nombre: String):

	animated_sprite.play(nombre)
