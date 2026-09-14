## Interfaz base para una máquina de estados genérica.
##
## Maneja la inicialización, configurar la máquina de estados
## activa o no, delegar llamados de _physics_process e _input
## a los nodos de Estado, y cambiar el estado actual/activo
@abstract
class_name GenericStateMachine extends Node

## Señal que notifica el cambio del estado activo actual.
signal state_changed(current_state: AbstractState)

## Es necesario asignar un nodo inicial desde el inspector o
## en el nodo que herede de esta interfaz de máquina de estado.
## Si no se asigna se toma el primer estado de [member states_list].
@export var start_state: AbstractState

## La lista completa de nodos de estado que conforman la máquina.
## Si un nodo no se agrega a la lista, no se lo tendrá en cuenta.
@export var states_list: Array[AbstractState]

## Estado activo actual.
var current_state: AbstractState = null
## Flag de control, indica si la máquina de estados esta activa o no.
var active: bool = false : set = set_active

# Cache de estados, inicializado en _ready con _initialize.
var _states_map: Dictionary[StringName, AbstractState] = {}


func _ready() -> void:
	set_active(false)
	# Llamamos a setup de manera deferida (en un frame siguiente) para
	# dar tiempo a que todos los sistemas se agreguen correctamente al árbol
	setup.call_deferred()


# Función privada de inicialización. 
# Nótese que esta función al no estar comentada con doble ## e iniciar con
# un "_" no va a aparecer documentada en la documentación autogenerada.
func setup() -> void:
	# Se chequea que se haya asignado un character a controlar y que la lista
	# de estados no este vacía
	if states_list.is_empty():
		return
	
	# Si no hay un estado inicial asignado, y dado que la lista de estados
	# no está vacía, se asigna el primer estado de la lista como estado inicial
	if start_state == null:
		start_state = states_list.front()
	
	_setup()
	initialize(start_state)


## Función de preinicialización abstracta para definir comportamiento custom
@abstract
func _setup() -> void


## Pone en marcha la state machine con un primer estado asignado.
## Se encarga de generar el cache de estados agregados en
## [member states_list], e inyecta la dependencia del
## [member character] elegido en cada [AbstractState].
## Puede ser llamada nuevamente si la máquina de estados se encuentra inactiva
## o no tiene un estado actual asignado, pasando un [param initial_state] válido
## como estado de inicio
func initialize(initial_state: AbstractState) -> void:
	# Se mapean los estados con sus ids correspondientes (sin ids repetidos)
	# y se inyectan los datos necesarios a cada estado
	for state: AbstractState in states_list:
		_states_map[state.state_id] = state
		state.finished.connect(_change_state)
	
	# Se setea como activa la flag active de la state machine
	set_active(true)
	
	# Y se asigna el estado inicial y se lo inicializa
	_change_state(initial_state.state_id)


## Función toggle que activa o desactiva la state machine.
func set_active(is_active: bool) -> void:
	active = is_active
	set_physics_process(active)
	set_process_input(active)
	if not active:
		current_state = null


# Delega el manejo de inputs al estado actual
func _input(event: InputEvent) -> void:
	current_state.handle_input(event)


# Delega los updates de _physics_process al estado actual
func _physics_process(delta: float) -> void:
	current_state.update(delta)


# Notifica al estado actual de la finalización de una animación
func _on_animation_finished(anim_name: StringName = &"") -> void:
	if !active:
		return
	current_state._on_animation_finished(anim_name)


# Función de cambio de estado
func _change_state(state_name: StringName) -> void:
	if !active:
		return
	
	# Sale del estado actual activo
	if current_state != null:
		current_state.exit()
	
	# Reemplaza el estado actual por el indicado
	current_state = _states_map[state_name]
	
	# Primero notifica del cambio de estado, por si algun
	# componente quiere hacer cambios en medio
	state_changed.emit(current_state)
	
	# Y se activa el estado nuevo
	current_state.enter()
