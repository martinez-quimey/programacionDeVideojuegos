
extends Node2D

@onready var areaMadriguera: Area2D = $AreaMadriguera
@onready var collisionMadriguera: Area2D = $CollisionMadriguera
@onready var impulsoParaSacar: Node2D = $impulsoParaSacar

var puede_salir: bool = false
var tiempo_espera: float = 0.0


func _ready():

	impulsoParaSacar.process_mode = Node.PROCESS_MODE_DISABLED


func _process(delta):

	entrarMadriguera()
	salirMadriguera()

	if not puede_salir: # hay un tiempo para que al entrar su propio collider de salida no genere que salga y entre a la vez
		tiempo_espera += delta

		if tiempo_espera >= 1.0:
			puede_salir = true


func entrarMadriguera():

	if not Input.is_action_just_pressed("interactMadriguera"):
		return

	var cuerpos = areaMadriguera.get_overlapping_bodies()

	for cuerpo in cuerpos:

		if cuerpo.is_in_group("jugador"):

			if not cuerpo.is_on_floor():
				return

			cuerpo.entrar_madriguera()

			puede_salir = false
			tiempo_espera = 0.0

			break


func salirMadriguera():

	if not puede_salir:

		return

	var cuerpos = collisionMadriguera.get_overlapping_bodies()

	for cuerpo in cuerpos:

		if cuerpo.is_in_group("jugador"):

			if cuerpo.esta_en_madriguera:

				# Activar impulso para sacar al jugador
				impulsoParaSacar.process_mode = Node.PROCESS_MODE_INHERIT

				await get_tree().create_timer(0.5).timeout

				# Desactivar impulso
				impulsoParaSacar.process_mode = Node.PROCESS_MODE_DISABLED

				cuerpo.salir_madriguera()

				break
