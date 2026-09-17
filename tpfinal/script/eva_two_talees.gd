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
# ANIMACIONES
# ==========================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var mirando_izquierda: bool = false

var ultima_animacion: String = "quieta"


# ==========================================
# ENERGÍA DE FUEGO
# ==========================================

const ENERGIA_MAXIMA = 5

var energia_fuego: int = 5

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
	# CONFIGURAR ENERGÍA
	# ==========================================

	barra.min_value = 0

	barra.max_value = ENERGIA_MAXIMA

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


	print("==========================================")
	print("PLAYER - ENERGÍA CONFIGURADA")
	print("==========================================")

	print(
		"Energía inicial: ",
		energia_fuego
	)

	print(
		"Energía máxima: ",
		ENERGIA_MAXIMA
	)

	print(
		"Timer wait_time: ",
		tiempo_recarga_fuego.wait_time
	)

	print(
		"Timer one_shot: ",
		tiempo_recarga_fuego.one_shot
	)

	print(
		"Timer conectado: ",
		tiempo_recarga_fuego.timeout.is_connected(
			_on_tiempo_recarga_fuego_timeout
		)
	)

	print("==========================================")


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


func actualizar_animacion(
	direccion_animacion: float
) -> void:

	# ==========================================
	# ACTUALIZAR DIRECCIÓN VISUAL
	# ==========================================
	#
	# Esto es importante.
	#
	# Antes EstadoPlayer cambiaba directamente
	# su propia variable mirando_izquierda.
	#
	# Ahora Player es quien controla la animación,
	# así que también debe actualizar su dirección
	# visual a partir de la dirección REAL del
	# movimiento.
	#
	# Si direccion_animacion es negativa:
	# mira a la izquierda.
	#
	# Si es positiva:
	# mira a la derecha.

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
#
# EstadoPlayer puede llamar a esta función
# si todavía tiene esa llamada.
#
# No cambia la lógica. Simplemente hace lo mismo
# que restablecer_visual_suelo().

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
# ENERGÍA
# ==========================================

func obtener_energia_fuego() -> int:

	return energia_fuego


func gastar_energia_fuego(cantidad: int) -> bool:

	if energia_fuego < cantidad:

		return false


	energia_fuego -= cantidad

	actualizar_barra_energia()

	print(
		"ENERGÍA GASTADA: ",
		cantidad,
		" | Energía actual: ",
		energia_fuego,
		"/",
		ENERGIA_MAXIMA
	)


	iniciar_recarga_energia()

	return true


func actualizar_barra_energia() -> void:

	barra.value = energia_fuego


func iniciar_recarga_energia() -> void:

	if energia_fuego >= ENERGIA_MAXIMA:

		tiempo_recarga_fuego.stop()

		print(
			"RECARGA: energía ya está al máximo"
		)

		return


	# Si ya estaba contando, NO reiniciamos el Timer.
	#
	# Esto conserva el comportamiento del código viejo:
	# el primer gasto inicia la cuenta y los siguientes
	# gastos no reinician el tiempo.

	if tiempo_recarga_fuego.is_stopped():

		print(
			"RECARGA: iniciando Timer | ",
			"Energía actual = ",
			energia_fuego
		)

		tiempo_recarga_fuego.start()

		print(
			"RECARGA: Timer iniciado | ",
			"tiempo restante = ",
			tiempo_recarga_fuego.time_left
		)


func recargar_energia_fuego() -> void:

	print("")
	print("==========================================")
	print("!!! RECARGANDO ENERGÍA !!!")
	print("==========================================")

	print(
		"Energía antes: ",
		energia_fuego
	)


	if energia_fuego < ENERGIA_MAXIMA:

		energia_fuego += 1

		actualizar_barra_energia()


		print(
			"Energía después: ",
			energia_fuego
		)


	if energia_fuego < ENERGIA_MAXIMA:

		print(
			"Hay energía por recuperar."
		)

		print(
			"Reiniciando Timer."
		)

		tiempo_recarga_fuego.start()


	else:

		print(
			"ENERGÍA COMPLETAMENTE RECARGADA"
		)

		tiempo_recarga_fuego.stop()


	print("==========================================")


func _on_tiempo_recarga_fuego_timeout() -> void:

	print("")
	print("==========================================")
	print("!!! TIMEOUT DE RECARGA RECIBIDO !!!")
	print("==========================================")

	print(
		"Energía antes de recargar: ",
		energia_fuego
	)

	recargar_energia_fuego()

	print("==========================================")


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
