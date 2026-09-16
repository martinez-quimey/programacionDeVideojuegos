# EstadoAutomatico.gd
extends EstadoPlayer


var izquierda_presionada: bool = false
var derecha_presionada: bool = false

var salto_una_vez: bool = false
var salto_fuego_una_vez: bool = false
var madriguera_una_vez: bool = false
var turbo_fuego_una_vez: bool = false


func _ready() -> void:
	super._ready()


func _physics_process(delta: float) -> void:
	if not activo:
		return

	# Dirección mantenida
	var nueva_direccion := 0.0

	if izquierda_presionada:
		nueva_direccion -= 1.0

	if derecha_presionada:
		nueva_direccion += 1.0

	establecer_direccion(nueva_direccion)


	# Acciones de una sola vez
	if salto_una_vez:
		saltar()
		salto_una_vez = false

	if salto_fuego_una_vez:
		salto_fuego()
		salto_fuego_una_vez = false

	if madriguera_una_vez:
		if estaEnMadriguera():
			salir_madriguera()
		else:
			entrar_madriguera()

		madriguera_una_vez = false

	if turbo_fuego_una_vez:
		activar_turbo()
		turbo_fuego_una_vez = false


	# Ejecuta toda la física y mecánicas del EstadoPlayer
	super._physics_process(delta)


# =========================================================
# IZQUIERDA
# =========================================================

func presionar_izquierda() -> void:
	izquierda_presionada = true


func soltar_izquierda() -> void:
	izquierda_presionada = false


# =========================================================
# DERECHA
# =========================================================

func presionar_derecha() -> void:
	derecha_presionada = true


func soltar_derecha() -> void:
	derecha_presionada = false


# =========================================================
# SALTO
# =========================================================

func presionar_una_vez_salto() -> void:
	salto_una_vez = true


# =========================================================
# SALTO FUEGO
# =========================================================

func presionar_una_vez_salto_fuego() -> void:
	salto_fuego_una_vez = true


# =========================================================
# MADRIGUERA
# =========================================================

func presionar_una_vez_madriguera() -> void:
	madriguera_una_vez = true


# =========================================================
# TURBO FUEGO
# =========================================================

func presionar_una_vez_turbo_fuego() -> void:
	turbo_fuego_una_vez = true
