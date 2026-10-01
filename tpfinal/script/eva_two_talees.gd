
# Player.gd
extends CharacterBody2D


# ==========================================
# ESTADOS
# ==========================================

@onready var estado_manual: EstadoPlayer = $estadoManual
@onready var estado_automatico: EstadoPlayer = $estadoAutomatico

var esta_en_madriguera: bool = false

var estado_actual: EstadoPlayer

var poseeDobleSalto: bool = false


# ==========================================
# VIDA
# ==========================================

var vida_maxima: int
var vida: int

@onready var barraVida = $"../CanvasLayer2/barraDeVida"


# ==========================================
# ANIMACIONES
# ==========================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var animated_sprite_pared: AnimatedSprite2D = $AnimatedSprite2D2

@onready var collision_shape_player: CollisionShape2D = $CollisionShape2D

@onready var collision_pared: CollisionShape2D = $CollisionPared

var mirando_izquierda: bool = false

var ultima_animacion: String = "quieta"


# ==========================================
# ENERGÍA DE FUEGO
# ==========================================

var energia_maxima: int
var energia_fuego: int

@onready var tiempo_recarga_fuego: Timer = $TiempoRecargaFuego

@onready var barra = $"../CanvasLayer/barraDeFuego"


# ==========================================
# READY
# ==========================================

func _ready() -> void:

	# ==========================================
	# CONFIGURAR COLISIÓN NORMAL
	# ==========================================

	collision_shape_player.disabled = false

	collision_shape_player.scale = Vector2(1.0, 1.0)


	# ==========================================
	# CONFIGURAR COLISIÓN DE PARED
	# ==========================================

	collision_pared.disabled = true

	collision_pared.scale = Vector2(1.0, 1.0)


	# ==========================================
	# CONFIGURAR ESTADOS
	# ==========================================

	estado_manual.activo = true
	estado_automatico.activo = false

	estado_actual = estado_manual


	# ==========================================
	# CONFIGURAR VIDA DESDE SETTINGS
	# ==========================================

	vida_maxima = Settings.getVidaActual()
	vida = Settings.getVidaActual()

	barraVida.min_value = 0
	barraVida.max_value = vida_maxima
	barraVida.value = vida


	# ==========================================
	# CONFIGURAR ENERGÍA
	# ==========================================

	energia_maxima = Settings.getEnergiaActual()
	energia_fuego = Settings.getEnergiaActual()

	barra.min_value = 0
	barra.max_value = energia_maxima
	barra.value = energia_fuego

	tiempo_recarga_fuego.one_shot = true

	if not tiempo_recarga_fuego.timeout.is_connected(
		_on_tiempo_recarga_fuego_timeout
	):

		tiempo_recarga_fuego.timeout.connect(
			_on_tiempo_recarga_fuego_timeout
		)


	# ==========================================
	# ANIMACIÓN NORMAL
	# ==========================================

	animated_sprite.animation = "quieta"

	animated_sprite.flip_h = false
	animated_sprite.flip_v = false

	animated_sprite.play()


	# ==========================================
	# ANIMACIÓN DE PARED
	# ==========================================

	animated_sprite_pared.animation = "pared"

	animated_sprite_pared.flip_h = false
	animated_sprite_pared.flip_v = false

	animated_sprite_pared.visible = false

	animated_sprite_pared.play()


	# ==========================================
	# TRANSFORMACIÓN INICIAL
	# ==========================================

	rotation = 0.0

	scale = Vector2(1.0, 1.0)

	collision_shape_player.scale = Vector2(1.0, 1.0)

	collision_pared.scale = Vector2(1.0, 1.0)

	ultima_animacion = "quieta"


# ==========================================
# ANIMACIONES
# ==========================================

func guardar_animacion_actual() -> void:

	if animated_sprite.animation != "":

		ultima_animacion = animated_sprite.animation


func reproducir_animacion(
	nombre: String
) -> void:

	if animated_sprite.animation != nombre:

		animated_sprite.animation = nombre

		animated_sprite.play()

		ultima_animacion = nombre


func animacion_tornado() -> void:

	animated_sprite.play("tornado")


func actualizar_animacion(
	direccion_animacion: float
) -> void:

	if direccion_animacion != 0:

		mirando_izquierda = direccion_animacion < 0


	# ==========================================
	# PARED
	# ==========================================

	if estado_actual.agarrado_pared:

		animated_sprite.visible = false
		animated_sprite_pared.visible = true

		return


	# ==========================================
	# AIRE
	# ==========================================

	if not is_on_floor():

		animated_sprite.visible = true
		animated_sprite_pared.visible = false

		animated_sprite.flip_v = false

		aplicar_direccion_visual()

		reproducir_animacion("salto")

		return


	# ==========================================
	# SUELO
	# ==========================================

	animated_sprite.visible = true
	animated_sprite_pared.visible = false

	animated_sprite.flip_v = false

	aplicar_direccion_visual()


	if direccion_animacion != 0:

		reproducir_animacion("correr")

	else:

		reproducir_animacion("quieta")


# ==========================================
# DIRECCIÓN VISUAL
# ==========================================

func establecer_direccion_visual(
	nueva_direccion: float
) -> void:

	if nueva_direccion != 0:

		mirando_izquierda = nueva_direccion < 0

		aplicar_direccion_visual()


func aplicar_direccion_visual() -> void:

	# ==========================================
	# ORIENTACIÓN NORMAL
	# ==========================================

	rotation = 0.0


	# ==========================================
	# MOSTRAR SPRITE NORMAL
	# ==========================================

	animated_sprite.visible = true
	animated_sprite_pared.visible = false


	# ==========================================
	# ESPEJAR TODO EL PLAYER
	# ==========================================

	if mirando_izquierda:

		scale = Vector2(-1.0, 1.0)

	else:

		scale = Vector2(1.0, 1.0)


	# ==========================================
	# COLLISION SHAPE NORMAL
	# ==========================================

	collision_shape_player.scale = Vector2(1.0, 1.0)


# ==========================================
# ANIMACIÓN DE SALTO
# ==========================================

func animacion_salto() -> void:

	rotation = 0.0

	animated_sprite.flip_v = false

	aplicar_direccion_visual()

	reproducir_animacion("salto")


# ==========================================
# ANIMACIÓN DE TURBO
# ==========================================

func animacion_turbo() -> void:

	rotation = 0.0

	animated_sprite.flip_v = false

	aplicar_direccion_visual()

	reproducir_animacion("turboFuego")


# ==========================================
# ANIMACIÓN DE PARED
# ==========================================

func animacion_pared(
	normal_pared: Vector2
) -> void:

	# ==========================================
	# OCULTAR ANIMACIÓN NORMAL
	# ==========================================

	animated_sprite.visible = false
	animated_sprite_pared.visible = true


	# ==========================================
	# ANIMACIÓN PARED
	# ==========================================

	animated_sprite_pared.animation = "pared"


	# ==========================================
	# PARED DERECHA
	# ==========================================

	if normal_pared.x < 0:

		animated_sprite_pared.flip_h = true
		animated_sprite_pared.flip_v = true

		animated_sprite_pared.rotation = deg_to_rad(180.0)
		
		scale.x = 1.0
		scale.y = 1.0


	# ==========================================
	# PARED IZQUIERDA
	# ==========================================

	else:

		animated_sprite_pared.flip_h = false
		animated_sprite_pared.flip_v = false

		animated_sprite_pared.rotation = deg_to_rad(0.0)
	
		scale.x = -1.0
		scale.y = 1.0


	animated_sprite_pared.play()


	# ==========================================
	# CAMBIAR COLLISIÓN
	# ==========================================

	collision_shape_player.disabled = true
	collision_pared.disabled = false


	# ==========================================
	# ROTACIÓN DEL PLAYER
	# ==========================================

	rotation = 0.0


# ==========================================
# RESTABLECER VISUAL DEL SUELO
# ==========================================

func restablecer_visual_suelo() -> void:

	rotation = 0.0

	scale = Vector2(1.0, 1.0)

	collision_shape_player.scale = Vector2(1.0, 1.0)

	collision_shape_player.disabled = false

	collision_pared.disabled = true

	animated_sprite.visible = true

	animated_sprite_pared.visible = false

	animated_sprite.flip_v = false

	animated_sprite_pared.flip_v = false

	aplicar_direccion_visual()


# ==========================================
# COMPATIBILIDAD CON ESTADOPLAYER
# ==========================================

func restablecer_animacion_vertical() -> void:

	rotation = 0.0

	scale = Vector2(1.0, 1.0)

	collision_shape_player.scale = Vector2(1.0, 1.0)

	collision_shape_player.disabled = false

	collision_pared.disabled = true

	animated_sprite.visible = true

	animated_sprite_pared.visible = false

	animated_sprite.flip_v = false

	animated_sprite_pared.flip_v = false


# ==========================================
# RESTAURAR ANIMACIÓN
# ==========================================

func restaurar_animacion() -> void:

	animated_sprite.visible = true

	animated_sprite_pared.visible = false

	collision_shape_player.disabled = false

	collision_pared.disabled = true

	animated_sprite.animation = ultima_animacion

	animated_sprite.play()

	aplicar_direccion_visual()


# ==========================================
# ANIMACIÓN DE HERIDA
# ==========================================

func animacionHerida() -> void:

	while not $Invulnerabilidad.is_stopped():

		animated_sprite.visible = false

		await get_tree().create_timer(
			0.1
		).timeout

		animated_sprite.visible = true

		await get_tree().create_timer(
			0.1
		).timeout

	animated_sprite.visible = true


# ==========================================
# VIDA
# ==========================================

func getVidaActual() -> int:

	return vida


func getVidaMaxima() -> int:

	return vida_maxima


func aumentar_vida(aumento: int):

	var vidaAumentada = vida + aumento

	if vida_maxima < vidaAumentada:

		vida = vida_maxima

	else:

		vida = vidaAumentada

	actualizar_barra_vida()


func aumentar_energia(aumento: int):

	print("se consumio baya de energia")

	var energiaAumentada = energia_fuego + aumento

	if energia_maxima < energiaAumentada:

		energia_fuego = energia_maxima

	else:

		energia_fuego = energiaAumentada

	actualizar_barra_energia()


func aumentarVidaMax(cantidad: int) -> void:

	if cantidad <= 0:

		return

	vida_maxima += cantidad

	vida += cantidad

	Settings.vidaActual = vida_maxima

	barraVida.max_value = vida_maxima
	barraVida.value = vida


func actualizar_barra_vida() -> void:

	barraVida.max_value = vida_maxima
	barraVida.value = vida


# ==========================================
# ENERGÍA
# ==========================================

func obtener_energia_fuego() -> int:

	return energia_fuego


func getEnergiaMaxima() -> int:

	return energia_maxima


func getEnergiaActual() -> int:

	return energia_fuego


func gastar_energia_fuego(cantidad: int) -> bool:

	if energia_fuego < cantidad:

		return false

	energia_fuego -= cantidad

	actualizar_barra_energia()

	iniciar_recarga_energia()

	return true


func aumentarEnergiaMax(cantidad: int) -> void:

	if cantidad <= 0:

		return

	energia_maxima += cantidad

	energia_fuego += cantidad

	Settings.energiaActual = energia_maxima

	barra.max_value = energia_maxima
	barra.value = energia_fuego


func actualizar_barra_energia() -> void:

	barra.max_value = energia_maxima
	barra.value = energia_fuego


func iniciar_recarga_energia() -> void:

	if energia_fuego >= energia_maxima:

		tiempo_recarga_fuego.stop()

		return

	if tiempo_recarga_fuego.is_stopped():

		tiempo_recarga_fuego.start()


func recargar_energia_fuego() -> void:

	if energia_fuego < energia_maxima:

		energia_fuego += 1

		actualizar_barra_energia()


	if energia_fuego < energia_maxima:

		tiempo_recarga_fuego.start()

	else:

		tiempo_recarga_fuego.stop()


func _on_tiempo_recarga_fuego_timeout() -> void:

	recargar_energia_fuego()


# ==========================================
# DAÑO
# ==========================================

func herir(num: int) -> void:

	estado_actual.herir(num)


# ==========================================
# RETROCESO
# ==========================================

func retroceso(
	direccion_empuje: Vector2,
	fuerza: float
) -> void:

	estado_actual.retroceso(
		direccion_empuje,
		fuerza
	)


# ==========================================
# MADRIGUERA
# ==========================================

func entrar_madriguera() -> void:

	estado_actual.entrar_madriguera()


func salir_madriguera():

	estado_actual.salir_madriguera()


# ==========================================
# MOVIMIENTO FORZADO
# ==========================================

func movimiento_forzado(
	direccion,
	velocidad
):

	estado_actual.movimiento_forzado(
		direccion,
		velocidad
	)


func detener_movimiento_forzado():

	estado_actual.detener_movimiento_forzado()
