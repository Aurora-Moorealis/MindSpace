extends Node2D
## Playable base scene: composes the generated lunar world with the astronaut.
##
## This scene is the only integration point between the two halves of the
## gameplay: it hands the generated [LunarMap] to the [Astronaut], bounds the
## gameplay camera to the map, makes that camera current and owns the run
## lifecycle through [GameSim]. [LunarMapWorld] keeps its own review camera for
## the debug scenes; this script makes the astronaut camera current after the
## world has made its camera current, so the gameplay view wins.

@onready var _world: LunarMapWorld = $LunarMapWorld
@onready var _astronaut: Astronaut = $Astronaut
@onready var _camera: Camera2D = $Astronaut/Camera2D


## Starts a clean run over the generated map, or reports the missing map and
## leaves the run frozen.
func _ready() -> void:
	var map: LunarMap = _world.get_map()
	if map == null:
		push_error("Base: LunarMapWorld did not generate a map; the run was not started.")
		return

	_astronaut.setup(map)

	var world_size: Vector2i = map.get_world_size()
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = world_size.x
	_camera.limit_bottom = world_size.y
	_camera.make_current()

	GameSim.start_run()


## Freezes the clock and clears the exterior flag when the playable scene is
## unloaded, so no later scene keeps consuming resources or radiation.
func _exit_tree() -> void:
	GameSim.stop_run()
