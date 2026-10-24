extends "res://entities/abstract/abstract_enemy.gd"

enum Modo { TECHO, SUELO }

@export var modo_inicial: Modo = Modo.TECHO

@export var SPEEDCAMINANDO: float = 100.0
@export var CAMINATA: float = 200.0
@export var DISTANCIA_BORDE: float = 20.0
@export var DISTANCIA_PIES: float = 100.0
@export var DISTANCIA_BORDE_TECHO: float = 20.0
@export var DISTANCIA_TECHO: float = 300.0
@export var VELOCIDAD_CAIDA_HORIZONTAL: float = 100.0
@export var GRAVEDAD_TECHO: float = 980.0
@export var VELOCIDAD_MAXIMA_ACERCAMIENTO_TECHO: float = 350.0
@export var VELOCIDAD_PRESION_TECHO: float = 80.0
@export var DISTANCIA_SNAP_TECHO: float = 24.0
@export var DISTANCIA_SNAP_SUELO: float = 12.0
@export_flags_2d_physics var MASCARA_SUPERFICIES: int = 1

@export var TIEMPO_DETECCION_ATASCADA: float = 0.35
@export var DISTANCIA_MINIMA_MOVIMIENTO: float = 0.5

var posicion_anterior_patrulla: Vector2 = Vector2.ZERO
var tiempo_sin_avanzar: float = 0.0
var patrulla_bloqueada: bool = false

# NUEVO:
# Cuando la araña está apoyada, pero no detecta suelo delante,
# deja de comprobar el suelo y patrulla comprobando solamente paredes.
# Este modo se desactiva cuando la araña deja de estar apoyada.
var ignorar_deteccion_suelo: bool = false

@export var DISTANCIA_SALTO: float = 2400.0
@export var VELOCIDAD_SALTO_HORIZONTAL: float = 2400.0
@export var ESPERA_ENTRE_SALTOS: float = 1.0
@export var ALTURA_SALTO: float = 45.0
@export var FUERZA_SALTO: float = 260.0
@export var DURACION_SALTO: float = 0.0

@export var FUERZA_EMPUJE_ATAQUE: float = 2800.0
@export var FUERZA_EMPUJE_CAIDA: float = 350.0
@export var ESPERA_EMPUJE_CONTACTO: float = 0.12
@export var DURACION_IGNORAR_JUGADOR: float = 1.0
@export var ESPERA_DANIO_CONTACTO: float = 0.5

var jugador_ignorado_temporalmente: PhysicsBody2D = null
var identificador_ignorar_jugador: int = 0

var tiempo_hasta_danio_contacto: float = 0.0
var tiempo_hasta_empuje_contacto: float = 0.0

const SONIDO_PREPARACION_ARAÑA: AudioStream = preload(
	"res://sonidos/enemigos/araña/sonidoAtaqueAraña.ogg"
)

const SONIDO_SALTO_ARAÑA: AudioStream = preload(
	"res://sonidos/enemigos/araña/arañaAtacando.ogg"
)

@onready var hitbox_principal: CollisionShape2D = $CollisionShape2D
@onready var hitbox_inversa: CollisionShape2D = $CollisionInversa
@onready var orientacion_enemy: Node2D = $OrientacionEnemy
@onready var area_ataque: Area2D = $OrientacionEnemy/CollisionAtaque
@onready var explosion_nube: Node2D = $ExplosionNube
@onready var reproductor_sonido: AudioStreamPlayer = $AudioStreamPlayer

enum Estado {
	PATRULLANDO,
	CAIDA,
	PREPARANDO_ATAQUE,
	SALTANDO
}

var modo_actual: Modo
var estado_actual: Estado = Estado.PATRULLANDO

var distancia_caminada: float = 0.0
var jugador_detectado: Node2D = null

var pausado_caminata: bool = false
var muerto: bool = false
var atacando: bool = false

var preparando_ataque: bool = false
var ataque_cancelado: bool = false

var salto_iniciado: bool = false
var objetivo_salto_x: float = 0.0

var puede_saltar: bool = true
var numero_ataque: int = 0


# =========================================================
# DAÑO DE CONTACTO
# =========================================================

func actualizar_danio_contacto() -> void:
	if muerto:
		DANIO_CONTACTO = 0
	elif estado_actual == Estado.SALTANDO:
		DANIO_CONTACTO = 2
	else:
		DANIO_CONTACTO = 1


func obtener_fuerza_empuje_actual() -> float:
	if estado_actual == Estado.CAIDA:
		return FUERZA_EMPUJE_CAIDA

	if estado_actual == Estado.SALTANDO:
		return FUERZA_EMPUJE_ATAQUE

	return FUERZA_EMPUJE_CONTACTO


# =========================================================
# JUGADOR
# =========================================================

func jugador_vivo(cuerpo: Object) -> bool:
	if not is_instance_valid(cuerpo):
		return false

	if cuerpo is Node and cuerpo.is_queued_for_deletion():
		return false

	if not cuerpo is Node2D:
		return false

	if not cuerpo.is_in_group("jugador"):
		return false

	for propiedad in cuerpo.get_property_list():
		if propiedad.name == "vida":
			return int(cuerpo.get("vida")) > 0

	return false


func es_jugador_valido(cuerpo: Object) -> bool:
	return jugador_vivo(cuerpo)


func actualizar_objetivo() -> void:
	if jugador_detectado == null:
		return

	if jugador_vivo(jugador_detectado):
		return

	jugador_detectado = null

	if (
		estado_actual == Estado.PREPARANDO_ATAQUE
		or estado_actual == Estado.SALTANDO
	):
		cancelar_ataque()

	if estado_actual == Estado.CAIDA:
		estado_actual = Estado.PATRULLANDO
		atacando = false
		preparando_ataque = false
		salto_iniciado = false
		velocity = Vector2.ZERO

		patrulla_bloqueada = false
		ignorar_deteccion_suelo = false
		reiniciar_detector_atasco()

		actualizar_danio_contacto()
		aplicar_orientacion_modo()
		animationPlay("idle")


# =========================================================
# INICIO
# =========================================================
func _ready() -> void:
	super._ready()

	add_to_group("enemigos")

	modo_actual = modo_inicial
	estado_actual = Estado.PATRULLANDO

	# Asegurar que la dirección inicial sea válida.
	if is_zero_approx(direccion):
		direccion = 1.0

	# Limpiar estados que podrían impedir el movimiento.
	muerto = false
	pausado_caminata = false
	patrulla_bloqueada = false
	ignorar_deteccion_suelo = false
	atacando = false
	preparando_ataque = false
	salto_iniciado = false

	actualizar_danio_contacto()
	configurar_superficie_fisica()

	if is_instance_valid(area_ataque):
		if not area_ataque.body_entered.is_connected(
			_on_area_ataque_body_entered
		):
			area_ataque.body_entered.connect(
				_on_area_ataque_body_entered
			)

		if not area_ataque.body_exited.is_connected(
			_on_area_ataque_body_exited
		):
			area_ataque.body_exited.connect(
				_on_area_ataque_body_exited
			)

	if is_instance_valid(explosion_nube):
		explosion_nube.hide()

	aplicar_orientacion_modo()
	actualizar_direccion_sprite()

	if modo_actual == Modo.SUELO:
		# La araña empieza patrullando por su cuenta.
		# Si está en el aire, la gravedad la hará aterrizar
		# mientras conserva la velocidad horizontal.
		velocity.x = direccion * SPEEDCAMINANDO
		velocity.y = 0.0

		reiniciar_detector_atasco()
		animationPlay("caminar")
	else:
		# El modo techo conserva su comportamiento original.
		velocity.x = 0.0
		animationPlay("idle")

# =========================================================
# FÍSICA
# =========================================================

func configurar_superficie_fisica() -> void:
	collision_mask = collision_mask | MASCARA_SUPERFICIES

	floor_max_angle = deg_to_rad(89.0)
	floor_stop_on_slope = true

	if modo_actual == Modo.TECHO:
		up_direction = Vector2.DOWN
		floor_snap_length = DISTANCIA_SNAP_TECHO
	else:
		up_direction = Vector2.UP
		floor_snap_length = DISTANCIA_SNAP_SUELO


func actualizar_hitbox_modo() -> void:
	var usar_hitbox_techo: bool = (
		modo_actual == Modo.TECHO
		and estado_actual != Estado.CAIDA
	)

	if is_instance_valid(hitbox_principal):
		hitbox_principal.set_deferred(
			"disabled",
			usar_hitbox_techo
		)

	if is_instance_valid(hitbox_inversa):
		hitbox_inversa.set_deferred(
			"disabled",
			not usar_hitbox_techo
		)


# =========================================================
# SALTO
# =========================================================

func obtener_fuerza_salto_aplicada() -> float:
	var gravedad_salto: float = maxf(absf(GRAVITY), 0.001)
	var altura: float = maxf(ALTURA_SALTO, 0.0)

	return sqrt(2.0 * gravedad_salto * altura)


func obtener_velocidad_salto_aplicada() -> float:
	return absf(VELOCIDAD_SALTO_HORIZONTAL)


func obtener_distancia_salto_aplicada() -> float:
	return absf(DISTANCIA_SALTO)


# =========================================================
# PROCESO FÍSICO
# =========================================================

func _physics_process(delta: float) -> void:
	if muerto:
		return

	actualizar_objetivo()

	if muerto:
		return

	# El padre aplica el retroceso y llama a frenarCaminatas().
	# Durante esa pausa, la araña conserva velocity.x y no permite
	# que la patrulla o el ataque sobrescriban el movimiento.
	if pausado_caminata:
		if modo_actual == Modo.TECHO and estado_actual != Estado.CAIDA:
			velocity.y -= GRAVEDAD_TECHO * delta
			velocity.y = maxf(
				velocity.y,
				-absf(VELOCIDAD_MAXIMA_ACERCAMIENTO_TECHO)
			)
		else:
			velocity.y += GRAVITY * delta

		move_and_slide()

		if comprobar_peligros():
			return

		comprobar_colision_con_jugador()
		return

	tiempo_hasta_danio_contacto = maxf(
		tiempo_hasta_danio_contacto - delta,
		0.0
	)

	tiempo_hasta_empuje_contacto = maxf(
		tiempo_hasta_empuje_contacto - delta,
		0.0
	)

	actualizar_danio_contacto()

	if estado_actual == Estado.CAIDA:
		up_direction = Vector2.UP
		floor_snap_length = DISTANCIA_SNAP_SUELO

		velocity.y += GRAVITY * delta

		move_and_slide()

		if comprobar_peligros():
			return

		comprobar_colision_con_jugador()

		if is_on_floor():
			cambiar_a_modo_suelo()

		return

	if estado_actual == Estado.PREPARANDO_ATAQUE:
		velocity = Vector2.ZERO
		move_and_slide()

		if comprobar_peligros():
			return

		comprobar_colision_con_jugador()
		return

	if estado_actual == Estado.SALTANDO:
		up_direction = Vector2.UP
		floor_snap_length = DISTANCIA_SNAP_SUELO

		velocity.y += GRAVITY * delta

		var distancia_restante: float = (
			objetivo_salto_x - global_position.x
		)

		var velocidad_salto: float = obtener_velocidad_salto_aplicada()
		var paso_horizontal: float = velocidad_salto * delta

		if absf(distancia_restante) <= paso_horizontal:
			velocity.x = distancia_restante / maxf(delta, 0.0001)
		else:
			velocity.x = signf(distancia_restante) * velocidad_salto

		move_and_slide()

		if comprobar_peligros():
			return

		comprobar_colision_con_jugador()

		if muerto:
			return

		if is_on_floor() and salto_iniciado:
			salto_iniciado = false
			estado_actual = Estado.PATRULLANDO
			atacando = false
			preparando_ataque = false
			ataque_cancelado = false

			actualizar_danio_contacto()

			# Recuperar la patrulla después del ataque.
			patrulla_bloqueada = false
			ignorar_deteccion_suelo = false

			if is_zero_approx(direccion):
				direccion = 1.0

			velocity.x = direccion * SPEEDCAMINANDO
			velocity.y = 0.0

			reiniciar_detector_atasco()
			actualizar_direccion_sprite()
			animationPlay("caminar")

			iniciar_espera_entre_saltos()
		return

	if modo_actual == Modo.TECHO:
		var adherida_al_techo: bool = is_on_floor()

		if adherida_al_techo and detectar_jugador():
			iniciar_caida()
			return

		velocity.y = maxf(
			velocity.y - GRAVEDAD_TECHO * delta,
			-absf(VELOCIDAD_MAXIMA_ACERCAMIENTO_TECHO)
		)

		if adherida_al_techo:
			patrullar_techo(delta)
		else:
			velocity.x = 0.0
			animationPlay("idle")
			tiempo_sin_avanzar = 0.0
			posicion_anterior_patrulla = global_position

		move_and_slide()

		if comprobar_peligros():
			return

		comprobar_colision_con_jugador()

		if muerto:
			return

		if (
			estado_actual == Estado.PATRULLANDO
			and adherida_al_techo
			and is_on_floor()
		):
			comprobar_atasco_patrulla(delta)

		return

	if modo_actual == Modo.SUELO:
		up_direction = Vector2.UP
		floor_snap_length = DISTANCIA_SNAP_SUELO

		if not is_on_floor():
			# La araña dejó de estar apoyada.
			# Se reactiva la detección de suelo.
			ignorar_deteccion_suelo = false
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

		if muerto:
			return

		if estado_actual == Estado.PATRULLANDO and is_on_floor():
			comprobar_atasco_patrulla(delta)
		else:
			tiempo_sin_avanzar = 0.0
			posicion_anterior_patrulla = global_position


# =========================================================
# DETECTOR DE ATASCO
# =========================================================

func comprobar_atasco_patrulla(delta: float) -> void:
	if patrulla_bloqueada:
		velocity.x = 0.0
		animationPlay("idle")
		tiempo_sin_avanzar = 0.0
		posicion_anterior_patrulla = global_position
		return

	var desplazamiento_x: float = absf(
		global_position.x - posicion_anterior_patrulla.x
	)

	if absf(velocity.x) < 1.0:
		tiempo_sin_avanzar = 0.0
		posicion_anterior_patrulla = global_position
		return

	if desplazamiento_x < DISTANCIA_MINIMA_MOVIMIENTO:
		tiempo_sin_avanzar += delta
	else:
		tiempo_sin_avanzar = 0.0

	posicion_anterior_patrulla = global_position

	if tiempo_sin_avanzar < TIEMPO_DETECCION_ATASCADA:
		return

	tiempo_sin_avanzar = 0.0
	cambiar_direccion()

	if modo_actual == Modo.TECHO:
		if (
			not hay_techo_en_direccion(direccion)
			or hay_pared_delante()
		):
			detener_patrulla()
			return
	else:
		if ignorar_deteccion_suelo:
			if hay_pared_delante():
				cambiar_direccion()

				if hay_pared_delante():
					detener_patrulla()
					return
		else:
			if (
				not hay_suelo_en_direccion(direccion)
				or hay_pared_delante()
			):
				if is_on_floor() and not hay_pared_delante():
					ignorar_deteccion_suelo = true
				else:
					detener_patrulla()
					return

	patrulla_bloqueada = false
	velocity.x = direccion * SPEEDCAMINANDO
	posicion_anterior_patrulla = global_position
	actualizar_direccion_sprite()
	animationPlay("caminar")


func reiniciar_detector_atasco() -> void:
	tiempo_sin_avanzar = 0.0
	posicion_anterior_patrulla = global_position


func detener_patrulla() -> void:
	velocity.x = 0.0
	patrulla_bloqueada = true
	tiempo_sin_avanzar = 0.0
	posicion_anterior_patrulla = global_position
	animationPlay("idle")


# =========================================================
# RECIBIR DAÑO
# =========================================================

func herir(num: int) -> void:
	if muerto:
		return

	if num <= 0:
		return

	if not is_instance_valid(Invulnerabilidad):
		return

	if not Invulnerabilidad.is_stopped():
		return

	vida -= num

	if vida <= 0:
		morir()
		return

	Invulnerabilidad.start()

	if (
		estado_actual == Estado.PREPARANDO_ATAQUE
		or estado_actual == Estado.SALTANDO
	):
		cancelar_ataque()

	animacionHerida()


# =========================================================
# AGUA Y LAVA
# =========================================================

func comprobar_peligros() -> bool:
	if muerto:
		return true

	if comprobar_tile_agua():
		return true

	if muerto:
		return true

	if comprobar_tile_lava():
		return true

	return muerto


# =========================================================
# ORIENTACIÓN Y HITBOX
# =========================================================

func aplicar_orientacion_modo() -> void:
	if not is_instance_valid(orientacion_enemy):
		return

	if modo_actual == Modo.TECHO and estado_actual != Estado.CAIDA:
		orientacion_enemy.rotation_degrees = 180.0
	else:
		orientacion_enemy.rotation_degrees = 0.0

	actualizar_hitbox_modo()


func actualizar_direccion_sprite() -> void:
	if not is_instance_valid(orientacion_enemy):
		return

	var escala_x: float = 1.0 if direccion > 0.0 else -1.0

	if modo_actual == Modo.TECHO and estado_actual != Estado.CAIDA:
		escala_x *= -1.0

	orientacion_enemy.scale.x = escala_x


# =========================================================
# DETECCIÓN DEL TECHO
# =========================================================

func hay_techo_delante() -> bool:
	return hay_techo_en_direccion(direccion)


func hay_techo_en_direccion(direccion_consulta: float) -> bool:
	var espacio := get_world_2d().direct_space_state

	var origen := global_position + Vector2(
		direccion_consulta * DISTANCIA_BORDE_TECHO,
		0.0
	)

	var destino := origen + Vector2(0.0, -DISTANCIA_TECHO)

	var parametros := PhysicsRayQueryParameters2D.create(
		origen,
		destino
	)

	parametros.exclude = [get_rid()]
	parametros.collision_mask = MASCARA_SUPERFICIES

	var resultado := espacio.intersect_ray(parametros)

	return not resultado.is_empty()


# =========================================================
# DETECCIÓN DEL SUELO
# =========================================================
func hay_suelo_debajo() -> bool:
	var espacio := get_world_2d().direct_space_state

	var origen: Vector2 = global_position
	var destino: Vector2 = origen + Vector2(
		0.0,
		DISTANCIA_PIES
	)

	var parametros := PhysicsRayQueryParameters2D.create(
		origen,
		destino
	)

	parametros.exclude = [get_rid()]
	parametros.collision_mask = MASCARA_SUPERFICIES

	if not espacio.intersect_ray(parametros).is_empty():
		return true

	var forma := RectangleShape2D.new()
	forma.size = Vector2(12.0, 8.0)

	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	consulta.collision_mask = MASCARA_SUPERFICIES
	consulta.collide_with_bodies = true
	consulta.collide_with_areas = false
	consulta.exclude = [get_rid()]

	for i in range(9):
		var fraccion: float = float(i) / 8.0
		var posicion_y: float = lerpf(
			origen.y,
			destino.y,
			fraccion
		)

		consulta.transform = Transform2D(
			0.0,
			Vector2(global_position.x, posicion_y)
		)

		if not espacio.intersect_shape(consulta, 1).is_empty():
			return true

	return false
func hay_suelo_delante() -> bool:
	return hay_suelo_en_direccion(direccion)


func hay_suelo_en_direccion(direccion_consulta: float) -> bool:
	var espacio := get_world_2d().direct_space_state

	var distancia_delante: float = maxf(
		DISTANCIA_BORDE * 0.5,
		4.0
	)

	var origen := global_position + Vector2(
		direccion_consulta * distancia_delante,
		0.0
	)

	var destino := origen + Vector2(
		0.0,
		DISTANCIA_PIES
	)

	var parametros_rayo := PhysicsRayQueryParameters2D.create(
		origen,
		destino
	)

	parametros_rayo.exclude = [get_rid()]
	parametros_rayo.collision_mask = MASCARA_SUPERFICIES

	if not espacio.intersect_ray(parametros_rayo).is_empty():
		return true

	var ancho: float = 12.0
	var alto: float = 8.0
	var forma := RectangleShape2D.new()
	forma.size = Vector2(ancho, alto)

	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	consulta.collision_mask = MASCARA_SUPERFICIES
	consulta.collide_with_bodies = true
	consulta.collide_with_areas = false
	consulta.exclude = [get_rid()]

	var pasos: int = 8

	for i in range(pasos + 1):
		var fraccion: float = float(i) / float(pasos)
		var posicion_y: float = lerpf(
			origen.y,
			destino.y,
			fraccion
		)

		consulta.transform = Transform2D(
			0.0,
			Vector2(origen.x, posicion_y)
		)

		if not espacio.intersect_shape(consulta, 1).is_empty():
			return true

	return false


# =========================================================
# PATRULLA
# =========================================================

func patrullar_techo(_delta: float) -> void:
	if pausado_caminata or patrulla_bloqueada:
		animationPlay("idle")
		return

	var techo_delante: bool = hay_techo_en_direccion(direccion)
	var pared_delante: bool = hay_pared_delante()

	if not techo_delante or pared_delante:
		cambiar_direccion()

		if (
			not hay_techo_en_direccion(direccion)
			or hay_pared_delante()
		):
			detener_patrulla()
			return

	velocity.x = direccion * SPEEDCAMINANDO
	animationPlay("caminar")

func patrullar_suelo(_delta: float) -> void:
	if pausado_caminata or patrulla_bloqueada:
		animationPlay("idle")
		return

	# Si deja de estar apoyada, vuelve a comprobar el suelo.
	if not is_on_floor():
		ignorar_deteccion_suelo = false

	# Solo activa el modo alternativo si falla la detección
	# del suelo DEBAJO mientras Godot todavía la considera apoyada.
	elif not ignorar_deteccion_suelo and not hay_suelo_debajo():
		ignorar_deteccion_suelo = true

		print(
			"[ARAÑA] No detecta suelo debajo, pero is_on_floor() ",
			"sigue siendo true. Ignorará el detector de suelo ",
			"y comprobará únicamente las paredes."
		)

	var pared_delante: bool = hay_pared_delante()

	# MODO ALTERNATIVO:
	# Ignora tanto la detección de suelo debajo como la de delante.
	# Solo las paredes determinan cuándo debe girar.
	if ignorar_deteccion_suelo:
		if pared_delante:
			cambiar_direccion()

			if hay_pared_delante():
				detener_patrulla()
				return

		velocity.x = direccion * SPEEDCAMINANDO
		animationPlay("caminar")
		return

	# MODO NORMAL:
	# La falta de suelo delante significa que debe girar.
	var suelo_delante: bool = hay_suelo_delante()

	if not suelo_delante or pared_delante:
		cambiar_direccion()

		var suelo_nueva_direccion: bool = hay_suelo_delante()
		var pared_nueva_direccion: bool = hay_pared_delante()

		# Si el otro sentido tampoco es transitable, se detiene.
		if not suelo_nueva_direccion or pared_nueva_direccion:
			velocity.x = 0.0
			animationPlay("idle")
			return

	velocity.x = direccion * SPEEDCAMINANDO
	animationPlay("caminar")

func hay_pared_delante() -> bool:
	var distancia_comprobacion: float = maxf(DISTANCIA_BORDE, 4.0)

	return test_move(
		global_transform,
		Vector2(direccion * distancia_comprobacion, 0.0)
	)


func cambiar_direccion() -> void:
	direccion *= -1.0
	distancia_caminada = 0.0
	actualizar_direccion_sprite()


# =========================================================
# PAUSA DE PATRULLA
# =========================================================

func frenarCaminatas() -> void:
	if pausado_caminata or muerto:
		return

	# No modificar velocity.x aquí.
	# El padre ya aplicó el retroceso antes de llamar a esta función.
	pausado_caminata = true
	animationPlay("idle")

	await get_tree().create_timer(1.0).timeout

	if muerto:
		return

	pausado_caminata = false
	reiniciar_detector_atasco()


# =========================================================
# DETECCIÓN DEL JUGADOR
# =========================================================

func detectar_jugador() -> bool:
	if muerto or not is_instance_valid(detection_area):
		return false

	for cuerpo in detection_area.get_overlapping_bodies():
		if jugador_vivo(cuerpo):
			jugador_detectado = cuerpo
			return true

	jugador_detectado = null
	return false


# =========================================================
# CAÍDA DESDE EL TECHO
# =========================================================

func iniciar_caida() -> void:
	if muerto:
		return

	if modo_actual != Modo.TECHO:
		return

	if estado_actual != Estado.PATRULLANDO:
		return

	if not jugador_vivo(jugador_detectado):
		jugador_detectado = null
		return

	estado_actual = Estado.CAIDA
	pausado_caminata = false
	atacando = false
	patrulla_bloqueada = false
	ignorar_deteccion_suelo = false
	reiniciar_detector_atasco()

	actualizar_danio_contacto()

	up_direction = Vector2.UP
	floor_snap_length = DISTANCIA_SNAP_SUELO

	aplicar_orientacion_modo()

	var diferencia_x: float = (
		jugador_detectado.global_position.x - global_position.x
	)

	var direccion_caida: float = signf(diferencia_x)

	if is_zero_approx(direccion_caida):
		direccion_caida = direccion

	direccion = direccion_caida

	velocity.x = direccion * VELOCIDAD_CAIDA_HORIZONTAL
	velocity.y = 0.0

	actualizar_direccion_sprite()
	animationPlay("caer")


# =========================================================
# TRANSICIÓN AL SUELO
# =========================================================
func cambiar_a_modo_suelo() -> void:
	if muerto:
		return

	modo_actual = Modo.SUELO
	estado_actual = Estado.PATRULLANDO

	# Detener el movimiento de caída y establecer el modo suelo.
	velocity.y = 0.0
	distancia_caminada = 0.0

	# Limpiar cualquier estado que pueda impedir la patrulla.
	pausado_caminata = false
	atacando = false
	preparando_ataque = false
	salto_iniciado = false
	patrulla_bloqueada = false
	ignorar_deteccion_suelo = false

	# Mantener la dirección actual, salvo que no sea válida.
	if is_zero_approx(direccion):
		direccion = 1.0

	configurar_superficie_fisica()
	aplicar_orientacion_modo()
	actualizar_direccion_sprite()
	actualizar_danio_contacto()

	# Iniciar la patrulla inmediatamente al aterrizar.
	velocity.x = direccion * SPEEDCAMINANDO
	reiniciar_detector_atasco()

	animationPlay("caminar")

# =========================================================
# DETECCIÓN DEL JUGADOR PARA ATAQUE
# =========================================================

func detectar_jugador_en_ataque() -> bool:
	if muerto or pausado_caminata:
		return false

	if estado_actual != Estado.PATRULLANDO:
		return false

	if not puede_saltar or atacando:
		return false

	if not is_instance_valid(area_ataque):
		return false

	for cuerpo in area_ataque.get_overlapping_bodies():
		if jugador_vivo(cuerpo):
			jugador_detectado = cuerpo
			return true

	return false


func _on_area_ataque_body_entered(body: Node2D) -> void:
	if muerto:
		return

	if not jugador_vivo(body):
		return

	jugador_detectado = body


func _on_area_ataque_body_exited(body: Node2D) -> void:
	if muerto or body != jugador_detectado:
		return

	if not jugador_vivo(body):
		jugador_detectado = null

		if (
			estado_actual == Estado.PREPARANDO_ATAQUE
			or estado_actual == Estado.SALTANDO
		):
			cancelar_ataque()

		return

	if (
		is_instance_valid(area_ataque)
		and not area_ataque.get_overlapping_bodies().has(body)
	):
		jugador_detectado = null


# =========================================================
# PREPARACIÓN DEL ATAQUE
# =========================================================

func iniciar_salto() -> void:
	if muerto or pausado_caminata:
		return

	if modo_actual != Modo.SUELO:
		return

	if estado_actual != Estado.PATRULLANDO:
		return

	if not puede_saltar:
		return

	if not jugador_vivo(jugador_detectado):
		jugador_detectado = null
		return

	estado_actual = Estado.PREPARANDO_ATAQUE
	preparando_ataque = true
	ataque_cancelado = false
	atacando = true

	actualizar_danio_contacto()

	numero_ataque += 1
	var identificador_ataque: int = numero_ataque

	velocity = Vector2.ZERO

	var diferencia_x: float = (
		jugador_detectado.global_position.x - global_position.x
	)

	if not is_zero_approx(diferencia_x):
		direccion = signf(diferencia_x)

	actualizar_direccion_sprite()
	animationPlay("idle")

	if is_instance_valid(reproductor_sonido):
		reproductor_sonido.stop()
		reproductor_sonido.stream = SONIDO_PREPARACION_ARAÑA
		reproductor_sonido.play()
	else:
		cancelar_ataque()
		return

	await reproductor_sonido.finished

	if muerto or identificador_ataque != numero_ataque:
		return

	if ataque_cancelado:
		return

	if not jugador_vivo(jugador_detectado):
		jugador_detectado = null
		cancelar_ataque()
		return

	ejecutar_salto(identificador_ataque)


# =========================================================
# EJECUTAR SALTO
# =========================================================

func ejecutar_salto(identificador_ataque: int) -> void:
	if identificador_ataque != numero_ataque:
		return

	if muerto or ataque_cancelado or pausado_caminata:
		return

	if modo_actual != Modo.SUELO:
		cancelar_ataque()
		return

	if estado_actual != Estado.PREPARANDO_ATAQUE:
		return

	if not jugador_vivo(jugador_detectado):
		jugador_detectado = null
		cancelar_ataque()
		return

	preparando_ataque = false
	estado_actual = Estado.SALTANDO
	salto_iniciado = true

	actualizar_danio_contacto()

	if is_instance_valid(reproductor_sonido):
		reproductor_sonido.stop()
		reproductor_sonido.stream = SONIDO_SALTO_ARAÑA
		reproductor_sonido.play()

	var diferencia_x: float = (
		jugador_detectado.global_position.x - global_position.x
	)

	var direccion_salto: float = signf(diferencia_x)

	if is_zero_approx(direccion_salto):
		direccion_salto = direccion

	direccion = direccion_salto

	objetivo_salto_x = global_position.x + (
		direccion_salto * obtener_distancia_salto_aplicada()
	)

	velocity.x = (
		direccion_salto * obtener_velocidad_salto_aplicada()
	)

	velocity.y = -obtener_fuerza_salto_aplicada()

	patrulla_bloqueada = false
	ignorar_deteccion_suelo = false
	reiniciar_detector_atasco()

	aplicar_orientacion_modo()
	actualizar_direccion_sprite()
	animationPlay("saltar")


# =========================================================
# CANCELAR ATAQUE
# =========================================================

func cancelar_ataque() -> void:
	numero_ataque += 1
	ataque_cancelado = true
	preparando_ataque = false
	atacando = false
	salto_iniciado = false

	actualizar_danio_contacto()

	if is_instance_valid(reproductor_sonido):
		reproductor_sonido.stop()

	if muerto or pausado_caminata:
		return

	velocity.x = 0.0

	if modo_actual == Modo.SUELO:
		estado_actual = Estado.PATRULLANDO
		velocity.y = 0.0
		actualizar_danio_contacto()
		animationPlay("idle")


# =========================================================
# ESPERA ENTRE SALTOS
# =========================================================

func iniciar_espera_entre_saltos() -> void:
	puede_saltar = false

	await get_tree().create_timer(
		maxf(ESPERA_ENTRE_SALTOS, 0.0)
	).timeout

	if muerto:
		return

	puede_saltar = true


# =========================================================
# DAÑO Y COLISIÓN CON EL JUGADOR
# =========================================================

func comprobar_colision_con_jugador() -> void:
	if muerto:
		return

	actualizar_danio_contacto()

	var jugador: Node2D = null

	for i in range(get_slide_collision_count()):
		var colision := get_slide_collision(i)
		var cuerpo = colision.get_collider()

		if es_jugador_valido(cuerpo):
			jugador = cuerpo
			break

	if not is_instance_valid(jugador):
		jugador = obtener_jugador_en_contacto()

	if not is_instance_valid(jugador):
		return

	if not jugador_vivo(jugador):
		return

	procesar_contacto_jugador(jugador)


func obtener_jugador_en_contacto() -> Node2D:
	var forma_activa: CollisionShape2D

	if (
		modo_actual == Modo.TECHO
		and estado_actual != Estado.CAIDA
	):
		forma_activa = hitbox_inversa
	else:
		forma_activa = hitbox_principal

	if not is_instance_valid(forma_activa):
		return null

	if forma_activa.disabled or forma_activa.shape == null:
		return null

	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma_activa.shape
	consulta.transform = forma_activa.global_transform
	consulta.collision_mask = 0xFFFFFFFF
	consulta.collide_with_bodies = true
	consulta.collide_with_areas = false
	consulta.exclude = [get_rid()]

	var resultados := get_world_2d().direct_space_state.intersect_shape(
		consulta,
		32
	)

	for resultado in resultados:
		var cuerpo = resultado.get("collider")

		if es_jugador_valido(cuerpo):
			return cuerpo

	return null


func procesar_contacto_jugador(cuerpo: Node2D) -> void:
	if not es_jugador_valido(cuerpo):
		return

	if tiempo_hasta_empuje_contacto <= 0.0:
		aplicar_empuje_contacto(cuerpo)

		tiempo_hasta_empuje_contacto = maxf(
			ESPERA_EMPUJE_CONTACTO,
			0.01
		)

	if tiempo_hasta_danio_contacto <= 0.0:
		if cuerpo.has_method("herir"):
			cuerpo.herir(DANIO_CONTACTO)

		tiempo_hasta_danio_contacto = maxf(
			ESPERA_DANIO_CONTACTO,
			0.01
		)

	if cuerpo is PhysicsBody2D:
		ignorar_colision_temporal_jugador(cuerpo)


# =========================================================
# EXCEPCIÓN DE COLISIÓN TEMPORAL
# =========================================================

func ignorar_colision_temporal_jugador(jugador: Node2D) -> void:
	if not is_instance_valid(jugador):
		return

	if not jugador is PhysicsBody2D:
		return

	var cuerpo_fisico := jugador as PhysicsBody2D

	if cuerpo_fisico == jugador_ignorado_temporalmente:
		return

	if is_instance_valid(jugador_ignorado_temporalmente):
		remove_collision_exception_with(
			jugador_ignorado_temporalmente
		)

	jugador_ignorado_temporalmente = cuerpo_fisico

	identificador_ignorar_jugador += 1
	var identificador_actual: int = identificador_ignorar_jugador

	add_collision_exception_with(cuerpo_fisico)

	restaurar_colision_despues_de_espera(
		cuerpo_fisico,
		identificador_actual
	)


func restaurar_colision_despues_de_espera(
	jugador: PhysicsBody2D,
	identificador: int
) -> void:
	await get_tree().create_timer(
		maxf(DURACION_IGNORAR_JUGADOR, 0.01)
	).timeout

	if identificador != identificador_ignorar_jugador:
		return

	if is_instance_valid(jugador):
		remove_collision_exception_with(jugador)

	if jugador_ignorado_temporalmente == jugador:
		jugador_ignorado_temporalmente = null


func restaurar_colision_temporal_jugador() -> void:
	identificador_ignorar_jugador += 1

	if is_instance_valid(jugador_ignorado_temporalmente):
		remove_collision_exception_with(
			jugador_ignorado_temporalmente
		)

	jugador_ignorado_temporalmente = null


# =========================================================
# EMPUJE AL JUGADOR
# =========================================================

func aplicar_empuje_contacto(cuerpo: Node2D) -> void:
	if not es_jugador_valido(cuerpo):
		return

	if not cuerpo.has_method("retroceso"):
		return

	var direccion_empuje: float

	if (
		estado_actual == Estado.CAIDA
		or estado_actual == Estado.SALTANDO
	):
		direccion_empuje = signf(direccion)

		if is_zero_approx(direccion_empuje):
			direccion_empuje = signf(velocity.x)

		if is_zero_approx(direccion_empuje):
			direccion_empuje = 1.0
	else:
		var diferencia_x: float = (
			cuerpo.global_position.x - global_position.x
		)

		if is_zero_approx(diferencia_x):
			direccion_empuje = signf(direccion)
		else:
			direccion_empuje = signf(diferencia_x)

		if is_zero_approx(direccion_empuje):
			direccion_empuje = 1.0

	var fuerza: float = obtener_fuerza_empuje_actual()

	cuerpo.retroceso(
		Vector2(direccion_empuje, 0.0),
		int(round(fuerza))
	)


# =========================================================
# ANIMACIONES
# =========================================================

func animationPlay(nombre: String) -> void:
	if muerto:
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

		"muerte", "morir":
			morir()


# =========================================================
# EXPLOSIÓN
# =========================================================

func soltar_explosion_nube() -> void:
	if not is_instance_valid(explosion_nube):
		return

	var padre := get_parent()

	if padre == null:
		return

	remove_child(explosion_nube)
	padre.add_child(explosion_nube)

	explosion_nube.global_position = global_position
	explosion_nube.show()

	if explosion_nube.has_method("reproducir"):
		explosion_nube.reproducir()


# =========================================================
# MUERTE
# =========================================================

func morir() -> void:
	if muerto:
		return

	muerto = true
	DANIO_CONTACTO = 0

	pausado_caminata = false

	numero_ataque += 1
	ataque_cancelado = true
	preparando_ataque = false
	atacando = false
	salto_iniciado = false
	jugador_detectado = null

	if is_instance_valid(reproductor_sonido):
		reproductor_sonido.stop()

	restaurar_colision_temporal_jugador()

	if is_instance_valid(hitbox_principal):
		hitbox_principal.set_deferred("disabled", true)

	if is_instance_valid(hitbox_inversa):
		hitbox_inversa.set_deferred("disabled", true)

	if is_instance_valid(area_ataque):
		area_ataque.set_deferred("monitoring", false)
		area_ataque.set_deferred("monitorable", false)

	if is_instance_valid(detection_area):
		detection_area.set_deferred("monitoring", false)
		detection_area.set_deferred("monitorable", false)

	velocity = Vector2.ZERO

	soltar_explosion_nube()

	queue_free()


# =========================================================
# ANIMACIÓN DE HERIDA
# =========================================================

func animacionHerida() -> void:
	while not muerto and is_instance_valid(Invulnerabilidad):
		if Invulnerabilidad.is_stopped():
			break

		if is_instance_valid(animated_sprite):
			animated_sprite.modulate = Color(1.0, 0.2, 0.2, 1.0)

		await get_tree().create_timer(0.1).timeout

		if muerto:
			return

		if is_instance_valid(animated_sprite):
			animated_sprite.modulate = Color.WHITE

		await get_tree().create_timer(0.1).timeout

	if muerto:
		return

	if is_instance_valid(animated_sprite):
		animated_sprite.modulate = Color.WHITE


# =========================================================
# DEJAR DE ACTUAR CONTRA PLAYER
# =========================================================

func dejarDeActuarContraPlayer() -> void:
	jugador_detectado = null

	if (
		estado_actual == Estado.PREPARANDO_ATAQUE
		or estado_actual == Estado.SALTANDO
	):
		cancelar_ataque()
