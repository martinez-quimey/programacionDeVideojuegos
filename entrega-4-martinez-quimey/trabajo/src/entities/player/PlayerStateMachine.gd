## Esta State Machine en particular del player solo extiende la
## funcionalidad de la State Machine abstracta para ajustarse
## a las necesidades del personaje a usar. Para estructuras de juego
## más complejas, generalmente se abstraen estos métodos para crear
## un controller genérico que se pueda asignar a cualquier entidad.
extends GenericStateMachine


## Path al nodo de personaje a controlar. Si no se asigna,
## la máquina de estado no se inicializa.
@export var character: Node


# Asignamos el character a cada PlayerState
func _setup() -> void:
	if character == null:
		printerr("%s: character is not defined!" % name)
	for state: PlayerState in states_list:
		state.character = character


## Esta función deriva el handleo de cada golpe que recibe
## el personaje al estado actual particular, en vez de vincular
## la señal de "hit" a los estados que lo usan, ya que sino se
## podría ejecutar código de estados inactivos.
func notify_hit(amount: int) -> void:
	current_state.handle_event(&"hit", amount)


## Esta función no se utiliza aun, ya que aun no contamos con
## una pool de HP variable.
func notify_healed(amount: int) -> void:
	current_state.handle_event(&"healed", amount)
