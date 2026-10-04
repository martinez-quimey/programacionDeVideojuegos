# jabali
extends "res://entities/abstract/abstract_enemy.gd"


@export var SPEEDCAMINANDO: float = 200.0
@export var SPEEDCORRIENDO: float = 400.0
@export var CAMINATA: float = 400.0

# =========================================================
# DETECCIÓN DEL BORDE
# =========================================================

# Distancia horizontal desde el centro del jabalí
# hasta donde se comprobará si hay suelo.
@export var DISTANCIA_BORDE: float = 20.0

# Distancia vertical desde el centro del jabalí
# hasta aproximadamente la altura de sus pies.
@export var DISTANCIA_PIES: float = 100.0


@onready var orientacion_jabali: Node2D = $OrientacionEnemy
@onready var area_ataque: Area2D = $OrientacionEnemy/CollisionAtaque


# ==========================================
# ESTADO DE MOVIMIENTO
# ==========================================

var pausado_caminata: bool = false

var direccion: float = 1.0
var distancia_caminada: float = 0.0

var jugador_detectado: Node2D = null

var atacando: bool = false
var muerto: bool = false

var jugador_dentro_ataque: bool = false


func _ready():
	var tiempo_inicio = Time.get_ticks_msec()
	super._ready()

	area_ataque.body_entered.connect(_on_area_ataque_body_entered)
	area_ataque.body_exited.connect(_on_area_ataque_body_exited)

	# Empieza mirando hacia la derecha.
	actualizar_direccion_sprite()
	

	print(
		"READY jabali: ",
		name,
		" | ",
		Time.get_ticks_msec() - tiempo_inicio,
		" ms"
	)


func _physics_process(delta: float) -> void:
	var inicio = Time.get_ticks_msec()

	if muerto:

		velocity = Vector2.ZERO
		move_and_slide()

		return


	# =====================================================
	# GRAVEDAD
	# =====================================================

	if not is_on_floor():

		velocity.y += GRAVITY * delta

	else:

		velocity.y = 0


	# =====================================================
	# COMPROBAR ATAQUE
	# =====================================================

	comprobar_ataque()


	# =====================================================
	# MOVIMIENTO
	# =====================================================

	if pausado_caminata:

		# No modificar velocity.x.
		#
		# Esto permite que un retroceso continúe
		# mientras el movimiento automático del jabalí
		# está pausado.

		pass

	elif atacando:

		velocity.x = 0

	elif jugador_detectado != null and is_instance_valid(jugador_detectado):

		# Persigue al jugador.
		perseguir_jugador()

	else:

		# Patrulla.
		patrullar(delta)


	move_and_slide()


	# =====================================================
	# DETECTAR PARED
	# =====================================================

	if not pausado_caminata and not atacando:

		for i in get_slide_collision_count():

			var collision = get_slide_collision(i)
			var normal = collision.get_normal()

			# Comprobar que sea una pared y no el piso/techo.
			if abs(normal.x) > abs(normal.y):

				# =================================================
				# ESTÁ PERSIGUIENDO AL JUGADOR
				# =================================================

				if jugador_detectado != null and is_instance_valid(jugador_detectado):

					# Si está persiguiendo y choca con una pared,
					# NO cambia de dirección.
					#
					# Se queda quieto.
					#
					# La dirección se volverá a calcular en
					# perseguir_jugador() cuando el jugador
					# cambie de lado.

					velocity.x = 0
					animationPlay("idle")

					break


				# =================================================
				# ESTÁ PATRULLANDO
				# =================================================

				# Está caminando hacia la derecha
				# y chocó contra una pared.
				if direccion > 0 and normal.x < 0:

					cambiar_direccion()

					# Aplicar inmediatamente la nueva dirección.
					velocity.x = direccion * SPEEDCAMINANDO

					break


				# Está caminando hacia la izquierda
				# y chocó contra una pared.
				if direccion < 0 and normal.x > 0:

					cambiar_direccion()

					# Aplicar inmediatamente la nueva dirección.
					velocity.x = direccion * SPEEDCAMINANDO

					break


	# =====================================================
	# DAÑO POR CONTACTO FÍSICO
	# =====================================================

	comprobar_colision_con_jugador()

	var duracion = Time.get_ticks_msec() - inicio

	if duracion >= 50:

		print(
			"⚠️ PROCESS LENTO jabali | ",
			get_path(),
			" | ",
			duracion,
			" ms"
		)


# =========================================================
# DETECTAR SUELO DELANTE
# =========================================================
func hay_suelo_delante() -> bool:

	var espacio = get_world_2d().direct_space_state

	# Punto horizontal delante del jabalí.
	var origen = global_position + Vector2(
		direccion * DISTANCIA_BORDE,
		0
	)

	# Buscamos bastante hacia abajo.
	var destino = origen + Vector2(
		0,
		300
	)

	var parametros = PhysicsRayQueryParameters2D.create(
		origen,
		destino
	)

	parametros.exclude = [self]

	# El suelo está en la capa 1.
	parametros.collision_mask = 1

	var resultado = espacio.intersect_ray(parametros)




	return not resultado.is_empty()

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

			# Contacto físico normal = 1 de daño.
			cuerpo.herir(1)

			# El contacto físico calcula desde qué lado
			# viene el jugador.
			aplicar_empuje_contacto(cuerpo)

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
		# horizontal, usamos la dirección del jabalí.

		if direccion < 0:

			direccion_empuje = Vector2.LEFT

		else:

			direccion_empuje = Vector2.RIGHT


	# =====================================================
	# APLICAR EMPUJE
	# =====================================================

	cuerpo.retroceso(direccion_empuje, 400)


# =========================================================
# PATRULLA
# =========================================================

func patrullar(delta: float) -> void:

	if pausado_caminata:
		return


	# =====================================================
	# COMPROBAR BORDE
	# =====================================================

	if not hay_suelo_delante():

		# Se detiene antes de llegar al vacío.
		velocity.x = 0

		# Cambia de dirección inmediatamente.
		cambiar_direccion()

		# Sigue mirando hacia la nueva dirección.
		velocity.x = direccion * SPEEDCAMINANDO

		animationPlay("caminar")

		return


	# =====================================================
	# MOVIMIENTO NORMAL
	# =====================================================

	animationPlay("caminar")

	velocity.x = direccion * SPEEDCAMINANDO

	distancia_caminada += abs(velocity.x) * delta


	if distancia_caminada >= CAMINATA:

		# La patrulla es la que detiene su propio movimiento.
		#
		# Esto NO está dentro de frenarCaminatas()
		# porque frenarCaminatas() también es utilizada
		# por el retroceso.

		velocity.x = 0

		cambiar_direccion()

		frenarCaminatas()

		return


# =========================================================
# FRENAR CAMINATAS
# =========================================================

func frenarCaminatas():

	if pausado_caminata:
		return


	# Solo bloquea el movimiento automático.
	#
	# NO modificar velocity.x.
	#
	# Así, si esta función fue llamada durante un
	# retroceso, el retroceso continúa.

	pausado_caminata = true

	animationPlay("idle")


	await get_tree().create_timer(1.0).timeout


	if muerto:
		return


	pausado_caminata = false


# =========================================================
# CAMBIAR DIRECCIÓN
# =========================================================

func cambiar_direccion() -> void:

	direccion *= -1

	distancia_caminada = 0.0

	actualizar_direccion_sprite()


# =========================================================
# DIRECCIÓN DEL SPRITE
# =========================================================

func actualizar_direccion_sprite() -> void:

	if direccion > 0:

		# Mira hacia la derecha.
		orientacion_jabali.scale.x = 1

	else:

		# Mira hacia la izquierda.
		orientacion_jabali.scale.x = -1


# =========================================================
# DETECCIÓN DEL JUGADOR
# =========================================================

func actuarContraPlayer():

	if muerto:
		return


	var cuerpos = detection_area.get_overlapping_bodies()


	for cuerpo in cuerpos:

		if cuerpo.is_in_group("jugador"):

			jugador_detectado = cuerpo

			return


func dejarDeActuarContraPlayer():

	if muerto:
		return


	jugador_detectado = null

	# Cuando el jugador sale del rango,
	# vuelve a patrullar cambiando de dirección.
	cambiar_direccion()


# =========================================================
# PERSEGUIR AL JUGADOR
# =========================================================

func perseguir_jugador():

	if pausado_caminata:
		return


	if jugador_detectado == null:
		return


	if not is_instance_valid(jugador_detectado):

		jugador_detectado = null

		return


	# =====================================================
	# CALCULAR DIRECCIÓN DEL JUGADOR
	# =====================================================

	var diferencia_x = jugador_detectado.global_position.x - global_position.x


	if diferencia_x > 0:

		direccion = 1.0

	elif diferencia_x < 0:

		direccion = -1.0


	# Actualizar el sprite incluso cuando está detenido.
	actualizar_direccion_sprite()


	# =====================================================
	# COMPROBAR BORDE
	# =====================================================

	if not hay_suelo_delante():

		print("PERSIGUIENDO: hay_suelo_delante() = FALSE")

		# Llegó al borde mientras perseguía al jugador.
		#
		# NO cambia de dirección.
		# Se queda quieto mirando hacia el jugador.

		velocity.x = 0

		animationPlay("idle")

		return


	print("PERSIGUIENDO: hay_suelo_delante() = TRUE")


	# =====================================================
	# PERSECUCIÓN NORMAL
	# =====================================================

	animationPlay("correr")

	velocity.x = direccion * SPEEDCORRIENDO


# =========================================================
# ATAQUE
# =========================================================

func comenzar_ataque():

	if atacando:
		return


	if muerto:
		return


	atacando = true

	velocity.x = 0

	animationPlay("atacar")


	# ==========================================
	# DAÑO Y RETROCESO DEL ATAQUE
	# ==========================================

	var cuerpos = area_ataque.get_overlapping_bodies()

	for cuerpo in cuerpos:

		if cuerpo.is_in_group("jugador"):

			# Ataque = 2 de daño.
			cuerpo.herir(2)

			# El ataque SIEMPRE empuja en la dirección
			# en la que está mirando el jabalí.
			#
			# direccion = 1  -> derecha
			# direccion = -1 -> izquierda
			cuerpo.retroceso(Vector2(direccion, 0), 600)

			break


	# ==========================================
	# DURACIÓN DEL ATAQUE
	# ==========================================

	await get_tree().create_timer(2.0).timeout


	if muerto:
		return


	# ==========================================
	# TERMINÓ EL ATAQUE
	# ==========================================

	atacando = false

	# Volver explícitamente a patrullar.
	animationPlay("caminar")

	velocity.x = direccion * SPEEDCAMINANDO


# =========================================================
# COLLISION ATAQUE
# =========================================================

func _on_area_ataque_body_entered(body):

	if not body.is_in_group("jugador"):
		return


	jugador_dentro_ataque = true


func _on_area_ataque_body_exited(body):

	if body.is_in_group("jugador"):

		jugador_dentro_ataque = false


# =========================================================
# COMPROBAR ATAQUE
# =========================================================

func comprobar_ataque():

	if muerto:
		return


	if atacando:
		return


	var cuerpos = area_ataque.get_overlapping_bodies()


	for cuerpo in cuerpos:

		if cuerpo.is_in_group("jugador"):

			comenzar_ataque()

			return


# =========================================================
# ANIMACIONES
# =========================================================

func animationPlay(string: String):

	if muerto and string != "muerte":
		return


	match string:

		"idle":

			animated_sprite.play("idle")


		"caminar":

			animated_sprite.play("caminar")


		"correr":

			animated_sprite.play("correr")


		"atacar":

			animated_sprite.play("atacar")


		"muerte":

			muerto = true

			atacando = false

			velocity = Vector2.ZERO

			animated_sprite.play("morir")

			await animated_sprite.animation_finished

			queue_free()


		"morir":

			muerto = true

			atacando = false

			velocity = Vector2.ZERO

			animated_sprite.play("morir")

			await animated_sprite.animation_finished

			queue_free()


func morir():

	animationPlay("muerte")

	await get_tree().create_timer(1.0).timeout

	queue_free()
