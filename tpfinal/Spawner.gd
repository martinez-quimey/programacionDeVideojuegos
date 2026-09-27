extends Node2D


# =========================================================
# CONFIGURACIÓN
# =========================================================

@export_category("Objeto a crear")

@export var escena_a_crear: PackedScene


@export_category("Cantidad")

@export var infinito: bool = true

@export var cantidad_maxima: int = 5


@export_category("Tiempo")

@export var tiempo_entre_creaciones: float = 2.0


@export_category("Pantalla")

@export var creacion_visible_en_pantalla: bool = false

@export var distancia_de_creacion: float = 500.0


# =========================================================
# VARIABLES INTERNAS
# =========================================================

var cantidad_creada: int = 0

var temporizador: float = 0.0


# =========================================================
# INICIO
# =========================================================

func _ready() -> void:

	if escena_a_crear == null:

		push_warning(
			"SpawnerGenerico: no se asignó una escena para crear."
		)

		return


	temporizador = tiempo_entre_creaciones


# =========================================================
# PROCESO
# =========================================================

func _process(delta: float) -> void:

	if escena_a_crear == null:
		return


	# Si no es infinito y ya alcanzó el límite,
	# dejamos de crear.
	if not infinito and cantidad_creada >= cantidad_maxima:
		return


	temporizador -= delta


	if temporizador > 0.0:
		return


	temporizador = tiempo_entre_creaciones


	if puede_crear():

		crear_objeto()


# =========================================================
# COMPROBAR SI PUEDE CREAR
# =========================================================

func puede_crear() -> bool:

	# Si se permite crear estando dentro de la pantalla,
	# no necesitamos comprobar la cámara.
	if creacion_visible_en_pantalla:

		return true


	# Si NO se permite crear dentro de la pantalla,
	# comprobamos la distancia respecto a la cámara.
	var camara = get_viewport().get_camera_2d()


	if camara == null:

		return false


	var distancia = global_position.distance_to(
		camara.global_position
	)


	# Si está suficientemente lejos de la cámara,
	# puede crear.
	return distancia >= distancia_de_creacion


# =========================================================
# CREAR OBJETO
# =========================================================

func crear_objeto() -> void:

	var objeto = escena_a_crear.instantiate()


	get_tree().current_scene.add_child(objeto)


	objeto.global_position = global_position


	cantidad_creada += 1


	print(
		"Spawner creó objeto. Total: ",
		cantidad_creada
	)
