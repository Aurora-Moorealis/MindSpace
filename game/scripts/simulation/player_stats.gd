class_name PlayerStats
extends RefCounted

## Mutable player statistics for one run.
##
## Base values come from the economy database; upgrades modify them additively
## through SimState. Radiation is intentionally out of this version.

## Multiplier applied to repair work per tick.
var repair_speed_multiplier: float = 1.0
## Stored movement multiplier, consumed once the astronaut exists.
var move_speed_multiplier: float = 1.0
## Maximum hunger reserve in points.
var max_hunger: float = 100.0
## Maximum thirst reserve in points.
var max_thirst: float = 100.0


## Restores every statistic from the economy rows, clamping values that would
## make the simulation unusable.
func reset_from_economy(economy: EconomyData) -> void:
	repair_speed_multiplier = maxf(
		0.1, economy.get_value(&"player_repair_speed_multiplier", 1.0)
	)
	move_speed_multiplier = maxf(
		0.1, economy.get_value(&"player_move_speed_multiplier", 1.0)
	)
	max_hunger = maxf(1.0, economy.get_value(&"player_max_hunger", 100.0))
	max_thirst = maxf(1.0, economy.get_value(&"player_max_thirst", 100.0))
