class_name MachineConsumption
extends Resource

## One resource a machine consumes on every operating tick.
##
## A MachineData with an empty consumption list consumes nothing, so this
## resource never needs a "none" resource value.

const RESOURCE_OXYGEN: StringName = &"oxygen"
const RESOURCE_WATER: StringName = &"water"
const RESOURCE_FOOD: StringName = &"food"
const RESOURCE_ENERGY: StringName = &"energy"

const VALID_RESOURCES: Array[StringName] = [
	RESOURCE_OXYGEN,
	RESOURCE_WATER,
	RESOURCE_FOOD,
	RESOURCE_ENERGY,
]

## Consumed resource: oxygen, water, food or energy.
@export var resource: StringName = &""
## Units of [member resource] removed from the pool per tick.
@export_range(0.0, 1000.0, 0.01) var amount_per_tick: float = 0.0


## Returns human-readable problems (empty array == valid entry).
func validate() -> Array[String]:
	var messages: Array[String] = []

	if resource == &"":
		messages.append("resource is empty")
	elif not VALID_RESOURCES.has(resource):
		messages.append(
			"resource '%s' must be one of oxygen, water, food, energy" % String(resource)
		)
	if amount_per_tick < 0.0:
		messages.append("amount_per_tick must be >= 0.0, got %s" % amount_per_tick)

	return messages
