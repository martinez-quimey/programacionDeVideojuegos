# EstadoManual.gd
extends EstadoPlayer


func _ready() -> void:

	super._ready()


func _physics_process(delta: float) -> void:

	if not activo:
		return


	# ==========================================
	# DIRECCIÓN
	# ==========================================

	var nueva_direccion := Input.get_axis(
		"izquierda",
		"derecha"
	)

	establecer_direccion(nueva_direccion)


	# ==========================================
	# TURBO FUEGO
	# ==========================================

	if Input.is_action_just_pressed("turboFuego"):

		activar_turbo()


	# ==========================================
	# SALTO
	# ==========================================

	if Input.is_action_just_pressed("salto"):

		saltar()


	# ==========================================
	# SALTO FUEGO
	# ==========================================

	if Input.is_action_just_pressed("saltoFuego"):

		salto_fuego()


	# ==========================================
	# FÍSICA DEL PLAYER
	# ==========================================

	super._physics_process(delta)
