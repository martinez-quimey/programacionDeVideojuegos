
# tsuchigumo.gd
extends "res://entities/abstract/abstract_enemy.gd"


# =========================================================
# CONFIGURACIÓN DEL MODO
# =========================================================

enum Modo {
	TECHO,
	SUELO
}

@export var modo_inicial: Modo = Modo.TECHO


# =========================================================
# MOVIMIENTO
# =========================================================

@export var SPEEDCAMINANDO: float = 100.0
@export var CAMINATA: float = 200.0

@export var DISTANCIA_BORDE: float = 20.0
@export var DISTANCIA_PIES: float = 100.0

@export var DISTANCIA_BORDE_TECHO: float = 20.0
@export var DISTANCIA_TECHO: float = 100.0

@export var VELOCIDAD_CAIDA_HORIZONTAL: float = 100.0
@export var GRAVEDAD_TECHO: float = 980.0

# Salto más largo y alto.
@export var DISTANCIA_SALTO: float = 100.0
@export var ALTURA_SALTO: float = 110.0
@export var DURACION_SALTO: float = 0.0


# =========================================================
# NODOS
# =========================================================

@onready var orientacion_enemy: Node2D = $OrientacionEnemy
@onready var area_ataque: Area2D = $OrientacionEnemy/CollisionAtaque
@onready var explosion_nube: Node2D = $ExplosionNube


# =========================================================
# ESTADOS
# =========================================================

enum Estado {
	PATRULLANDO,
	CAIDA,
	SALTANDO
}

var modo_actual: Modo
var estado_actual: Estado = Estado.PATRULLANDO

var direccion: float = 1.0
var distancia_caminada: float = 0.0

var jugador_detectado: Node2D = null

var pausado_caminata: bool = false
var muerto: bool = false
var atacando: bool = false

var salto_iniciado: bool = false
var objetivo_salto_x: float = 0.0


# =========================================================
# INICIO
# =========================================================

func _ready() -> void:

	super._ready()

	modo_actual = modo_inicial

	area_ataque.body_entered.connect(
		_on_area_ataque_body_entered
	)

	# La explosión se activa solamente al morir.
	explosion_nube.hide()

	aplicar_orientacion_modo()
	actualizar_direccion_sprite()


# =========================================================
# PROCESO FÍSICO
# =========================================================

func _physics_process(delta: float) -> void:

	if muerto:
		return


	# =====================================================
	# CAÍDA DESDE EL TECHO
	# =====================================================

	if estado_actual == Estado.CAIDA:

		velocity.y += GRAVITY * delta

		move_and_slide()

		if comprobar_peligros():
			return

		if is_on_floor():
			cambiar_a_modo_suelo()

		comprobar_colision_con_jugador()

		return


	# =====================================================
	# SALTO DEL MODO SUELO
	# =====================================================

	if estado_actual == Estado.SALTANDO:

		velocity.y += GRAVITY * delta

		move_and_slide()

		if comprobar_peligros():
			return

		comprobar_colision_con_jugador()

		if is_on_floor() and salto_iniciado:

			salto_iniciado = false
			estado_actual = Estado.PATRULLANDO
			velocity.x = 0.0

			animationPlay("idle")

		return


	# =====================================================
	# MOVIMIENTO SOBRE EL TECHO
	# =====================================================

	if modo_actual == Modo.TECHO:

		# La gravedad invertida lo lleva hacia el techo
		# si pierde contacto con él.
		if is_on_ceiling():
			velocity.y = 0.0
		else:
			velocity.y = -GRAVEDAD_TECHO * delta

		if detectar_jugador():
			iniciar_caida()
			return

		patrullar_techo(delta)

		move_and_slide()

		if comprobar_peligros():
			return

		return


	# =====================================================
	# MOVIMIENTO SOBRE EL SUELO
	# =====================================================

	if modo_actual == Modo.SUELO:

		if not is_on_floor():
			velocity.y += GRAVITY * delta
		else:
			velocity.y = 0.0

		if detectar_jugador_en_ataque():
			iniciar_salto()
			return

		patrullar_suelo(delta)

		move_and_slide()

		if comprobar_peligros():
			return

		comprobar_colision_con_jugador()


# =========================================================
# AGUA Y LAVA
# =========================================================

func comprobar_peligros() -> bool:

	if comprobar_tile_agua():
		return true

	if comprobar_tile_lava():
		return true

	return false


# =========================================================
# ORIENTACIÓN SEGÚN EL MODO
# =========================================================

func aplicar_orientacion_modo() -> void:

	if modo_actual == Modo.TECHO:
		orientacion_enemy.rotation_degrees = 180.0
	else:
		orientacion_enemy.rotation_degrees = 0.0


# =========================================================
# DETECCIÓN DEL TECHO
# =========================================================

func hay_techo_delante() -> bool:

	var espacio = get_world_2d().direct_space_state

	var origen = global_position + Vector2(
		direccion * DISTANCIA_BORDE_TECHO,
		0.0
	)

	var destino = origen + Vector2(
		0.0,
		-DISTANCIA_TECHO
	)

	var parametros = PhysicsRayQueryParameters2D.create(
		origen,
		destino
	)

	parametros.exclude = [self]
	parametros.collision_mask = 1

	var resultado = espacio.intersect_ray(parametros)

	return not resultado.is_empty()


# =========================================================
# DETECCIÓN DEL SUELO
# =========================================================

func hay_suelo_delante() -> bool:

	var espacio = get_world_2d().direct_space_state

	var origen = global_position + Vector2(
		direccion * DISTANCIA_BORDE,
		0.0
	)

	var destino = origen + Vector2(
		0.0,
		DISTANCIA_PIES
	)

	var parametros = PhysicsRayQueryParameters2D.create(
		origen,
		destino
	)

	parametros.exclude = [self]
	parametros.collision_mask = 1

	var resultado = espacio.intersect_ray(parametros)

	return not resultado.is_empty()


# =========================================================
# PATRULLA SOBRE EL TECHO
# =========================================================

func patrullar_techo(delta: float) -> void:

	if pausado_caminata:
		return

	if not hay_techo_delante():

		velocity.x = 0.0

		cambiar_direccion()

		velocity.x = direccion * SPEEDCAMINANDO

		animationPlay("caminar")

		return

	animationPlay("caminar")

	velocity.x = direccion * SPEEDCAMINANDO

	distancia_caminada += abs(velocity.x) * delta

	if distancia_caminada >= CAMINATA:

		velocity.x = 0.0

		cambiar_direccion()

		frenar_caminata()


# =========================================================
# PATRULLA SOBRE EL SUELO
# =========================================================

func patrullar_suelo(delta: float) -> void:

	if pausado_caminata:
		return

	if not hay_suelo_delante():

		velocity.x = 0.0

		cambiar_direccion()

		velocity.x = direccion * SPEEDCAMINANDO

		animationPlay("caminar")

		return

	animationPlay("caminar")

	velocity.x = direccion * SPEEDCAMINANDO

	distancia_caminada += abs(velocity.x) * delta

	if distancia_caminada >= CAMINATA:

		velocity.x = 0.0

		cambiar_direccion()

		frenar_caminata()


# =========================================================
# CAMBIAR DIRECCIÓN
# =========================================================

func cambiar_direccion() -> void:

	direccion *= -1.0

	distancia_caminada = 0.0

	actualizar_direccion_sprite()


func actualizar_direccion_sprite() -> void:

	if direccion > 0.0:
		orientacion_enemy.scale.x = 1.0
	else:
		orientacion_enemy.scale.x = -1.0


# =========================================================
# PAUSA DE PATRULLA
# =========================================================

func frenar_caminata() -> void:

	if pausado_caminata:
		return

	pausado_caminata = true

	animationPlay("idle")

	await get_tree().create_timer(1.0).timeout

	if muerto:
		return

	pausado_caminata = false


# =========================================================
# DETECCIÓN DEL JUGADOR
# =========================================================

func detectar_jugador() -> bool:

	var cuerpos = detection_area.get_overlapping_bodies()

	for cuerpo in cuerpos:

		if cuerpo.is_in_group("jugador"):

			jugador_detectado = cuerpo

			return true

	jugador_detectado = null

	return false


# =========================================================
# CAÍDA HACIA EL JUGADOR
# =========================================================

func iniciar_caida() -> void:

	if modo_actual != Modo.TECHO:
		return

	if estado_actual != Estado.PATRULLANDO:
		return

	if jugador_detectado == null:
		return

	if not is_instance_valid(jugador_detectado):
		jugador_detectado = null
		return

	estado_actual = Estado.CAIDA

	pausado_caminata = false

	velocity.x = sign(
		jugador_detectado.global_position.x - global_position.x
	) * VELOCIDAD_CAIDA_HORIZONTAL

	velocity.y = 0.0

	animationPlay("caer")


# =========================================================
# TRANSICIÓN AL MODO SUELO
# =========================================================

func cambiar_a_modo_suelo() -> void:

	modo_actual = Modo.SUELO

	estado_actual = Estado.PATRULLANDO

	velocity = Vector2.ZERO

	distancia_caminada = 0.0

	aplicar_orientacion_modo()
	actualizar_direccion_sprite()

	animationPlay("idle")


# =========================================================
# DETECCIÓN DEL JUGADOR EN COLLISION ATAQUE
# =========================================================

func detectar_jugador_en_ataque() -> bool:

	if atacando:
		return false

	var cuerpos = area_ataque.get_overlapping_bodies()

	for cuerpo in cuerpos:

		if cuerpo.is_in_group("jugador"):

			jugador_detectado = cuerpo

			return true

	return false


# =========================================================
# SALTO BAJO HACIA EL JUGADOR
# =========================================================

func iniciar_salto() -> void:

	if muerto:
		return

	if modo_actual != Modo.SUELO:
		return

	if estado_actual != Estado.PATRULLANDO:
		return

	if jugador_detectado == null:
		return

	if not is_instance_valid(jugador_detectado):
		return

	estado_actual = Estado.SALTANDO

	atacando = true

	salto_iniciado = true

	var diferencia_x = (
		jugador_detectado.global_position.x - global_position.x
	)

	var direccion_salto = sign(diferencia_x)

	if direccion_salto == 0.0:
		direccion_salto = direccion

	objetivo_salto_x = global_position.x + (
		direccion_salto * DISTANCIA_SALTO
	)

	var gravedad_positiva = maxf(GRAVITY, 1.0)

	var tiempo_aire = 2.0 * sqrt(
		2.0 * ALTURA_SALTO / gravedad_positiva
	)

	velocity.x = DISTANCIA_SALTO / maxf(tiempo_aire, 0.01)

	velocity.x *= direccion_salto

	velocity.y = -sqrt(
		2.0 * gravedad_positiva * ALTURA_SALTO
	)

	direccion = direccion_salto

	actualizar_direccion_sprite()

	animationPlay("saltar")

	await get_tree().create_timer(0.15).timeout

	if muerto:
		return

	atacando = false


# =========================================================
# DAÑO Y RETROCESO POR CONTACTO
# =========================================================

func comprobar_colision_con_jugador() -> void:

	for i in get_slide_collision_count():

		var collision = get_slide_collision(i)

		var cuerpo = collision.get_collider()

		if cuerpo == null:
			continue

		if cuerpo.is_in_group("jugador"):

			# Primero aplica el retroceso horizontal.
			aplicar_empuje_contacto(cuerpo)

			# Después aplica el daño.
			cuerpo.herir(1)

			return


# =========================================================
# EMPUJE POR CONTACTO
# =========================================================

func aplicar_empuje_contacto(cuerpo: Node2D) -> void:

	if cuerpo == null:
		return

	var diferencia_x: float = (
		cuerpo.global_position.x - global_position.x
	)

	var direccion_empuje: float

	if diferencia_x < 0.0:
		direccion_empuje = -1.0
	elif diferencia_x > 0.0:
		direccion_empuje = 1.0
	else:
		direccion_empuje = direccion

	# Solo horizontal, sin componente vertical.
	cuerpo.retroceso(Vector2(direccion_empuje, 0.0), 400)


# =========================================================
# ANIMACIONES
# =========================================================

func animationPlay(nombre: String) -> void:

	if muerto and nombre != "muerte":
		return

	match nombre:

		"idle":
			animated_sprite.play("idle")

		"caminar":
			animated_sprite.play("caminar")

		"caer":
			animated_sprite.play("caer")

		"saltar":
			animated_sprite.play("saltar")

		"muerte":
			muerto = true
			velocity = Vector2.ZERO
			animated_sprite.play("morir")
			soltar_explosion_nube()
			await animated_sprite.animation_finished
			queue_free()


# =========================================================
# EXPLOSIÓN AL MORIR
# =========================================================

func soltar_explosion_nube() -> void:

	if not is_instance_valid(explosion_nube):
		return

	var padre = get_parent()

	if padre == null:
		return

	# Separa el efecto del enemigo para que no desaparezca
	# cuando se elimine este nodo.
	remove_child(explosion_nube)
	padre.add_child(explosion_nube)

	explosion_nube.global_position = global_position
	explosion_nube.show()

	if explosion_nube is GPUParticles2D:
		explosion_nube.restart()
		explosion_nube.emitting = true

	elif explosion_nube is CPUParticles2D:
		explosion_nube.restart()
		explosion_nube.emitting = true


# =========================================================
# MUERTE
# =========================================================

func morir() -> void:

	if muerto:
		return

	animationPlay("muerte")


# =========================================================
# PARPADEO ROJO AL RECIBIR DAÑO
# =========================================================

func animacionHerida() -> void:

	while not Invulnerabilidad.is_stopped():

		if muerto:
			return

		animated_sprite.modulate = Color(1.0, 0.2, 0.2, 1.0)

		await get_tree().create_timer(0.1).timeout

		if muerto:
			return

		animated_sprite.modulate = Color.WHITE

		await get_tree().create_timer(0.1).timeout

	animated_sprite.modulate = Color.WHITE


# =========================================================
# DETECCIÓN DE SALIDA DEL JUGADOR
# =========================================================

func dejarDeActuarContraPlayer() -> void:

	jugador_detectado = null


func _on_area_ataque_body_entered(body: Node2D) -> void:
	pass
