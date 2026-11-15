class_name AirlockZone
extends Area2D

## Exterior boundary. While the astronaut overlaps one of these areas the run is
## marked as outside and the tick accumulates radiation. The definitive map can
## place as many as it needs; the astronaut only reads the group.


func _ready() -> void:
	add_to_group(&"exterior_zones")
