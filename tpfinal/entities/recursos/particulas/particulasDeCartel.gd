
extends GPUParticles2D

@onready var detector = $VisibleOnScreenNotifier2D

func _ready():
	emitting = false
	detector.screen_entered.connect(_activar_particulas)
	detector.screen_exited.connect(_desactivar_particulas)

func _activar_particulas():
	emitting = true

func _desactivar_particulas():
	emitting = false
