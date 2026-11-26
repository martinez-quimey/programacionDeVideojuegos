
extends GPUParticles2D

@onready var detector = $VisibleOnScreenNotifier2D

func _ready():
	print("[PARTICULAS] _ready iniciado")
	print("[PARTICULAS] Nodo: ", get_path())
	print("[PARTICULAS] Cantidad de partículas: ", amount)
	print("[PARTICULAS] Estado inicial de emitting: ", emitting)

	emitting = false
	print("[PARTICULAS] Emisión desactivada")

	if detector == null:
		print("[ERROR PARTICULAS] No se encontró VisibleOnScreenNotifier2D")
		return

	print("[PARTICULAS] Detector encontrado: ", detector.get_path())

	detector.screen_entered.connect(_activar_particulas)
	detector.screen_exited.connect(_desactivar_particulas)

	print("[PARTICULAS] Señales conectadas correctamente")


func _activar_particulas():
	print("[PARTICULAS] ¡Entró en pantalla!")
	print("[PARTICULAS] Activando emisión")

	emitting = true

	print("[PARTICULAS] Emitting: ", emitting)


func _desactivar_particulas():
	print("[PARTICULAS] ¡Salió de pantalla!")
	print("[PARTICULAS] Desactivando emisión")

	emitting = false

	print("[PARTICULAS] Emitting: ", emitting)
