@tool
## Primera aparición de esta annotation. Esto va como freebie.
## La annotation "@tool" denota scripts que se pueden ejecutar
## tanto en runtime como en el editor.

extends Node2D

@export var turret_scene: PackedScene
@export var amount: int
@export var extents: Vector2: set = _set_extents


func _ready() -> void:
	## "Engine.editor_hint" es una flag que le permite al script saber en qué
	## contexto se está ejecutando, si en runtime del juego o en el contexto
	## del editor.
	if Engine.is_editor_hint():
		queue_redraw()
	else:
		_initialize.call_deferred()


## Fijarse como esta función se ejecuta tranquilamente, ya que controlamos
## de nunca llamarla en contexto del editor, solo en runtime.
func _initialize() -> void:
	for i in amount:
		var turret_instance: Node = turret_scene.instantiate()
		var turret_pos: Vector2 = Vector2(
			randf_range(global_position.x, global_position.x + extents.x),
			randf_range(global_position.y, global_position.y + extents.y)
		)
		add_child(turret_instance)
		turret_instance.initialize(turret_pos, self)


## Al definir el setter, se pueden asignar las variables en contexto de
## "tool" en el editor y utilizarlas.
func _set_extents(value: Vector2) -> void:
	extents = value
	
	## Aquí decimos "si estás en contexto del editor, manda un aviso de redibujado"
	if Engine.is_editor_hint():
		queue_redraw()


## Función primitiva de dibujo
func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2.ZERO, extents), Color.BLUE, false)
