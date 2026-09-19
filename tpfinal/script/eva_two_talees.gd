# Player.gd
extends CharacterBody2D


# ==========================================
# ESTADOS
# ==========================================

@onready var estado_manual: EstadoPlayer = $estadoManual
@onready var estado_automatico: EstadoPlayer = $estadoAutomatico

var esta_en_madriguera: bool = false

var estado_actual: EstadoPlayer


# ==========================================
# VIDA
# ==========================================

# La vida máxima comienza siendo la que
# tenga configurada Settings.
var vida_maxima: int

# La vida actual también comienza desde Settings.
var vida: int


@onready var barraVida = $"../CanvasLayer2/barraDeVida"


# ==========================================
# ANIMACIONES
# ==========================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var mirando_izquierda: bool = false

var ultima_animacion: String = "quieta"


# ==========================================
# ENERGÍA DE FUEGO
# ==========================================

# Capacidad máxima de energía.
#
# Esta aumenta cuando se consiguen mejoras.
var energia_maxima: int

# Energía disponible actualmente.
#
# Esta es la que aparece en la barra y disminuye
# cuando se usa salto fuego o turbo.
var energia_fuego: int


@onready var tiempo_recarga_fuego: Timer = $TiempoRecargaFuego

@onready var barra = $"../CanvasLayer/barraDeFuego"


# ==========================================
# READY
# ==========================================

func _ready() -> void:

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
	# CONFIGURAR ENERGÍA DESDE SETTINGS
	# ==========================================

	# energia_maxima representa la capacidad máxima
	# que tiene actualmente el jugador.
	energia_maxima = Settings.getEnergiaActual()

	# energia_fuego representa la energía disponible
	# actualmente.
	energia_fuego = Settings.getEnergiaActual()


	barra.min_value = 0
	barra.max_value = energia_maxima
	barra.value = energia_fuego


	# El Timer debe recuperar una sola energía
	# cada vez que termina.
	tiempo_recarga_fuego.one_shot = true


	# Nos aseguramos de que el Timer esté conectado
	# solamente una vez al Player.
	if not tiempo_recarga_fuego.timeout.is_connected(
		_on_tiempo_recarga_fuego_timeout
	):

		tiempo_recarga_fuego.timeout.connect(
			_on_tiempo_recarga_fuego_timeout
		)


	# ==========================================
	# ANIMACIÓN INICIAL
	# ==========================================

	animated_sprite.animation = "quieta"
	animated_sprite.flip_h = false
	animated_sprite.flip_v = false

	animated_sprite.play()

	ultima_animacion = "quieta"


	# ==========================================
	# DEBUG
	# ==========================================


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

		animated_sprite.flip_h = false
		animated_sprite.flip_v = false

		reproducir_animacion("quieta")

		return


	# ==========================================
	# AIRE
	# ==========================================

	if not is_on_floor():

		animated_sprite.flip_v = false
		animated_sprite.flip_h = mirando_izquierda

		reproducir_animacion("salto")

		return


	# ==========================================
	# SUELO
	# ==========================================

	animated_sprite.flip_v = false
	animated_sprite.flip_h = mirando_izquierda


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

		animated_sprite.flip_h = mirando_izquierda


func aplicar_direccion_visual() -> void:

	animated_sprite.flip_h = mirando_izquierda


# ==========================================
# ANIMACIÓN DE SALTO
# ==========================================

func animacion_salto() -> void:

	rotation = 0.0

	animated_sprite.flip_v = false
	animated_sprite.flip_h = mirando_izquierda

	reproducir_animacion("salto")


# ==========================================
# ANIMACIÓN DE TURBO
# ==========================================

func animacion_turbo() -> void:

	rotation = 0.0

	animated_sprite.flip_v = false
	animated_sprite.flip_h = mirando_izquierda

	reproducir_animacion("turboFuego")


# ==========================================
# ANIMACIÓN DE PARED
# ==========================================

func animacion_pared(
	normal_pared: Vector2
) -> void:

	if normal_pared.x < 0:

		rotation = deg_to_rad(-90.0)

		animated_sprite.flip_v = false

	else:

		rotation = deg_to_rad(-90.0)

		animated_sprite.flip_v = true


	animated_sprite.flip_h = false

	reproducir_animacion("quieta")


# ==========================================
# RESTABLECER VISUAL DEL SUELO
# ==========================================

func restablecer_visual_suelo() -> void:

	rotation = 0.0

	animated_sprite.flip_v = false

	animated_sprite.flip_h = mirando_izquierda


# ==========================================
# COMPATIBILIDAD CON ESTADOPLAYER
# ==========================================

func restablecer_animacion_vertical() -> void:

	rotation = 0.0

	animated_sprite.flip_v = false


# ==========================================
# RESTAURAR ANIMACIÓN
# ==========================================

func restaurar_animacion() -> void:

	animated_sprite.animation = ultima_animacion

	animated_sprite.play()

	animated_sprite.flip_h = mirando_izquierda


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


func aumentarVida(cantidad: int) -> void:

	if cantidad <= 0:

		return


	# Aumentamos el máximo.
	vida_maxima += cantidad

	# También aumentamos la vida actual.
	vida += cantidad


	# Actualizamos Settings.
	Settings.vidaActual = vida_maxima


	# Actualizamos la barra.
	barraVida.max_value = vida_maxima
	barraVida.value = vida



func actualizar_barra_vida() -> void:

	barraVida.max_value = vida_maxima
	barraVida.value = vida


# ==========================================
# ENERGÍA
# ==========================================

# Devuelve la energía que el jugador tiene
# actualmente disponible.
#
# NO devuelve la capacidad máxima.
#
# Ejemplo:
# energia_maxima = 7
# energia_fuego = 4
# obtener_energia_fuego() devuelve 4.
func obtener_energia_fuego() -> int:

	return energia_fuego


# Devuelve la capacidad máxima actual de energía.
#
# Ejemplo:
# energia_maxima = 7
# energia_fuego = 4
# getEnergiaMaxima() devuelve 7.
func getEnergiaMaxima() -> int:

	return energia_maxima


# Mantengo este método porque ya existía
# y puede ser usado por otras partes del juego.
#
# Devuelve también la energía disponible actualmente.
func getEnergiaActual() -> int:

	return energia_fuego


func gastar_energia_fuego(cantidad: int) -> bool:

	if energia_fuego < cantidad:

		return false


	energia_fuego -= cantidad

	actualizar_barra_energia()

	iniciar_recarga_energia()

	return true


func aumentarEnergia(cantidad: int) -> void:

	if cantidad <= 0:

		return


	# Aumentamos el máximo.
	energia_maxima += cantidad

	# También aumentamos la energía actual.
	energia_fuego += cantidad


	# Actualizamos Settings.
	Settings.energiaActual = energia_maxima


	# Actualizamos la barra.
	barra.max_value = energia_maxima
	barra.value = energia_fuego


func actualizar_barra_energia() -> void:

	barra.max_value = energia_maxima
	barra.value = energia_fuego


func iniciar_recarga_energia() -> void:

	if energia_fuego >= energia_maxima:

		tiempo_recarga_fuego.stop()

		return


	# Si ya estaba contando, NO reiniciamos el Timer.
	#
	# Esto conserva el comportamiento del código viejo:
	# el primer gasto inicia la cuenta y los siguientes
	# gastos no reinician el tiempo.

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
