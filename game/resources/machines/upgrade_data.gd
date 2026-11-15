class_name UpgradeData
extends Resource

## One single-use upgrade a machine can offer.
##
## [member effect_stat] decides where the additive [member delta] lands: a
## machine effect feeds the machine deltas on MachineState, a player effect
## feeds PlayerStats. The sheet never mutates; the tick reads base + delta.

enum EffectStat {
	POWER_DRAW,
	SOLAR_OUTPUT,
	FOOD_OUTPUT,
	OXYGEN_OUTPUT,
	WATER_OUTPUT,
	DEGRADATION,
	REPAIR_SPEED,
	MOVE_SPEED,
	HUNGER_MAX,
	THIRST_MAX,
}

## Upgrade id, unique inside its machine sheet.
@export var id: StringName = &""
## Statistic the upgrade changes.
@export var effect_stat: EffectStat = EffectStat.POWER_DRAW
## Additive change applied to [member effect_stat].
@export_range(-1000.0, 1000.0, 0.01) var delta: float = 0.0
## Energy charged when the upgrade is applied.
@export_range(0.0, 1000.0, 0.01) var energy_cost: float = 0.0
## Optional localization key for the upgrade flavor text.
@export var flavor_key: StringName = &""


## Returns human-readable problems (empty array == valid entry).
func validate() -> Array[String]:
	var messages: Array[String] = []
	var upgrade_label: String = String(id) if id != &"" else "<unnamed>"

	if id == &"":
		messages.append("upgrade: id is empty")
	if delta == 0.0:
		messages.append("upgrade '%s': delta must not be zero" % upgrade_label)
	if energy_cost < 0.0:
		messages.append(
			"upgrade '%s': energy_cost must be >= 0.0, got %s" % [upgrade_label, energy_cost]
		)
	if effect_stat < EffectStat.POWER_DRAW or effect_stat > EffectStat.THIRST_MAX:
		messages.append(
			"upgrade '%s': effect_stat %d is outside the EffectStat enum"
			% [upgrade_label, int(effect_stat)]
		)

	return messages
