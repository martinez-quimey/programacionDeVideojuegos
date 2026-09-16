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

func retroceso(direccion_empuje: Vector2,fuerza: float) -> void:

	estado_actual.retroceso(direccion_empuje,fuerza)


func entrar_madriguera() -> void:

	estado_actual.entrar_madriguera()


func salir_madriguera ():

	estado_actual.salir_madriguera()


func movimiento_forzado(direccion, velocidad):

	estado_actual.movimiento_forzado(direccion,velocidad)


func detener_movimiento_forzado():

	estado_actual.detener_movimiento_forzado()
