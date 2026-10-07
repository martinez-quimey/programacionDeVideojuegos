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

	var inicio = Time.get_ticks_msec()


	if escena_a_crear == null:

		return


	# Si no es infinito y ya alcanzó el límite,
	# dejamos de crear.
	if not infinito and cantidad_creada >= cantidad_maxima:

		return


	# =====================================================
	# TEMPORIZADOR
	# =====================================================

	temporizador -= delta


	if temporizador > 0.0:

		return


	# Reiniciamos el temporizador independientemente
	# de si se pudo crear o no.
	temporizador = tiempo_entre_creaciones


	# =====================================================
	# COMPROBAR SI PUEDE CREAR
	# =====================================================

	if not puede_crear():

		return


	# =====================================================
	# CREAR
	# =====================================================

	crear_objeto()


	var duracion = Time.get_ticks_msec() - inicio


	if duracion >= 50:

		print(
			"⚠️ PROCESS LENTO | ",
			get_path(),
			" | ",
			duracion,
			" ms"
		)


# =========================================================
# COMPROBAR SI PUEDE CREAR
# =========================================================

func puede_crear() -> bool:

	# =====================================================
	# PANTALLA
	# =====================================================

	if not creacion_visible_en_pantalla:

		var camara := get_viewport().get_camera_2d()


		if camara == null:

			return false


		var viewport_size := get_viewport_rect().size

		var zoom := camara.zoom


		# Mitad del tamaño visible de la cámara.
		var mitad_ancho := (
			viewport_size.x
			/ (2.0 * zoom.x)
		)

		var mitad_alto := (
			viewport_size.y
			/ (2.0 * zoom.y)
		)


		var centro := camara.global_position


		# =================================================
		# RECTÁNGULO VISIBLE
		# =================================================

		var izquierda := (
			centro.x
			- mitad_ancho
			- distancia_de_creacion
		)

		var derecha := (
			centro.x
			+ mitad_ancho
			+ distancia_de_creacion
		)

		var arriba := (
			centro.y
			- mitad_alto
			- distancia_de_creacion
		)

		var abajo := (
			centro.y
			+ mitad_alto
			+ distancia_de_creacion
		)


		# =================================================
		# COMPROBAR SI EL SPAWNER ESTÁ EN LA ZONA
		# VISIBLE + MARGEN
		# =================================================

		var dentro_de_zona_visible := (

			global_position.x >= izquierda
			and global_position.x <= derecha

			and

			global_position.y >= arriba
			and global_position.y <= abajo
		)


		if dentro_de_zona_visible:

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

	var espacio_fisico := (
		get_world_2d().direct_space_state
	)


	var forma := CircleShape2D.new()

	forma.radius = radio_comprobacion_spawn


	var parametros := (
		PhysicsShapeQueryParameters2D.new()
	)


	parametros.shape = forma

	parametros.transform = Transform2D(
		0.0,
		global_position
	)


	# Detectamos cuerpos y áreas.
	parametros.collide_with_bodies = true
	parametros.collide_with_areas = true


	var resultados := (
		espacio_fisico.intersect_shape(
			parametros,
			1
		)
	)


	return resultados.size() > 0


# =========================================================
# COMPROBAR INSTANCIAS CERCANAS
# =========================================================

func hay_instancia_cerca() -> bool:

	# Eliminamos referencias a objetos que ya no existen.
	for i in range(
		objetos_creados.size() - 1,
		-1,
		-1
	):

		if not is_instance_valid(
			objetos_creados[i]
		):

			objetos_creados.remove_at(i)


	# Comprobamos las instancias restantes.
	for objeto in objetos_creados:

		var distancia := (
			global_position.distance_to(
				objeto.global_position
			)
		)


		if distancia < distancia_minima_entre_instancias:

			return true


	return false


# =========================================================
# CREAR OBJETO
# =========================================================

func crear_objeto() -> void:

	# =====================================================
	# CREAR INSTANCIA
	# =====================================================

	var objeto := (
		escena_a_crear.instantiate()
	)


	# =====================================================
	# CONFIGURAR POSICIÓN ANTES DE AGREGAR
	# =====================================================

	if objeto is Node2D:

		objeto.global_position = global_position


	# =====================================================
	# AGREGAR AL ÁRBOL
	# =====================================================

	get_tree().current_scene.add_child(
		objeto
	)


	# =====================================================
	# GUARDAR REFERENCIA
	# =====================================================

	if objeto is Node2D:

		objetos_creados.append(
			objeto
		)


	# =====================================================
	# CONTADOR
	# =====================================================

	cantidad_creada += 1
