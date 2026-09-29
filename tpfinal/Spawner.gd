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


@export_category("Colisiones")

# Radio utilizado para comprobar si el punto de spawn
# está ocupado por otro objeto.
@export var radio_comprobacion_spawn: float = 1.0


@export_category("Distancia entre instancias")

# Distancia mínima entre objetos creados por este spawner.
@export var distancia_minima_entre_instancias: float = 32.0


# =========================================================
# VARIABLES INTERNAS
# =========================================================

var cantidad_creada: int = 0

var temporizador: float = 0.0

# Guardamos las instancias creadas por este spawner.
var objetos_creados: Array[Node2D] = []


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

	# =====================================================
	# PANTALLA
	# =====================================================

	# Si se permite crear estando dentro de la pantalla,
	# no necesitamos comprobar la cámara.
	if not creacion_visible_en_pantalla:

		var camara = get_viewport().get_camera_2d()


		if camara == null:

			return false


		var distancia = global_position.distance_to(
			camara.global_position
		)


		# Si está demasiado cerca de la cámara,
		# no puede crear.
		if distancia < distancia_de_creacion:

			return false


	# =====================================================
	# OBJETO EN EL PUNTO DE SPAWN
	# =====================================================

	if hay_objeto_en_spawn():

		return false


	# =====================================================
	# OTRA INSTANCIA DEMASIADO CERCA
	# =====================================================

	if hay_instancia_cerca():

		return false


	return true


# =========================================================
# COMPROBAR OBJETO EN EL SPAWN
# =========================================================

func hay_objeto_en_spawn() -> bool:

	var espacio_fisico := get_world_2d().direct_space_state


	var forma := CircleShape2D.new()

	forma.radius = radio_comprobacion_spawn


	var parametros := PhysicsShapeQueryParameters2D.new()

	parametros.shape = forma

	parametros.transform = Transform2D(
		0.0,
		global_position
	)

	# Detectamos cuerpos y áreas.
	parametros.collide_with_bodies = true
	parametros.collide_with_areas = true


	var resultados = espacio_fisico.intersect_shape(
		parametros,
		1
	)


	return resultados.size() > 0


# =========================================================
# COMPROBAR INSTANCIAS CERCANAS
# =========================================================

func hay_instancia_cerca() -> bool:

	# Primero eliminamos referencias a objetos
	# que ya fueron eliminados.
	for i in range(objetos_creados.size() - 1, -1, -1):

		var objeto = objetos_creados[i]


		if not is_instance_valid(objeto):

			objetos_creados.remove_at(i)


	# Comprobamos las instancias restantes.
	for objeto in objetos_creados:

		var distancia = global_position.distance_to(
			objeto.global_position
		)


		if distancia < distancia_minima_entre_instancias:

			return true


	return false


# =========================================================
# CREAR OBJETO
# =========================================================

func crear_objeto() -> void:

	var objeto = escena_a_crear.instantiate()


	get_tree().current_scene.add_child(objeto)


	objeto.global_position = global_position


	# Guardamos la instancia para poder comprobar
	# posteriormente si hay otra demasiado cerca.
	if objeto is Node2D:

		objetos_creados.append(objeto)


	cantidad_creada += 1


	print(
		"Spawner creó objeto. Total: ",
		cantidad_creada
	)
