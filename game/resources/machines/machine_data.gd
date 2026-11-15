class_name MachineData
extends Resource

## Editable sheet of one machine: identity, repair cost, per-tick consumption
## and the upgrades it can offer.
##
## The sheet lives next to the machine content and MachineDatabase indexes all
## sheets. It only holds configuration; run-time values live in MachineState.

## Machine id, matching one of the ids frozen by SimState.MACHINE_IDS.
@export var id: StringName = &""
## Localization key for the display name.
@export var display_name_key: StringName = &""
## Short in-game hint shown on the machine panel.
@export_multiline var hint_text: String = ""
## Work divisions required to finish a repair at player speed 1.0.
@export_range(1, 10, 1) var repair_ticks: int = 1
## Energy charged when a repair starts.
@export_range(0.0, 1000.0, 0.01) var repair_energy_cost: float = 0.0
## Resources consumed per operating tick; an empty list means no consumption.
@export var consumption: Array[MachineConsumption] = []
## Upgrades this machine can offer, each applicable once.
@export var upgrades: Array[UpgradeData] = []


## Returns the upgrade with the given id, or null when it does not exist.
func get_upgrade(upgrade_id: StringName) -> UpgradeData:
	for upgrade: UpgradeData in upgrades:
		if upgrade != null and upgrade.id == upgrade_id:
			return upgrade
	return null


## True when this machine can express the given upgrade effect.
## Output effects are tied to the machine that produces that resource; power,
## degradation and the player statistics are valid on any machine.
func supports_effect(effect_stat: UpgradeData.EffectStat) -> bool:
	if effect_stat < UpgradeData.EffectStat.POWER_DRAW:
		return false
	if effect_stat > UpgradeData.EffectStat.THIRST_MAX:
		return false
	if effect_stat == UpgradeData.EffectStat.SOLAR_OUTPUT:
		return id == &"solar_array"
	if effect_stat == UpgradeData.EffectStat.FOOD_OUTPUT:
		return id == &"hydroponics"
	if effect_stat == UpgradeData.EffectStat.OXYGEN_OUTPUT:
		return id == &"hydroponics"
	if effect_stat == UpgradeData.EffectStat.WATER_OUTPUT:
		return id == &"water_recycler"
	return true


## Returns human-readable problems (empty array == valid sheet).
func validate() -> Array[String]:
	var messages: Array[String] = []
	var machine_label: String = String(id)

	if id == &"":
		messages.append("machine '': id is empty")
	if display_name_key == &"":
		messages.append("machine '%s': display_name_key is empty" % machine_label)
	if repair_ticks < 1:
		messages.append(
			"machine '%s': repair_ticks must be >= 1, got %d" % [machine_label, repair_ticks]
		)
	if repair_energy_cost < 0.0:
		messages.append(
			"machine '%s': repair_energy_cost must be >= 0.0, got %s"
			% [machine_label, repair_energy_cost]
		)

	var seen_resources: Dictionary[StringName, bool] = {}
	for index: int in consumption.size():
		var entry: MachineConsumption = consumption[index]
		if entry == null:
			messages.append("machine '%s': consumption %d is null" % [machine_label, index])
			continue
		for problem: String in entry.validate():
			messages.append("machine '%s': consumption %d: %s" % [machine_label, index, problem])
		if entry.resource != &"":
			if seen_resources.has(entry.resource):
				messages.append(
					"machine '%s': consumption %d: resource '%s' is duplicated"
					% [machine_label, index, String(entry.resource)]
				)
			else:
				seen_resources[entry.resource] = true

	var seen_upgrades: Dictionary[StringName, bool] = {}
	for index: int in upgrades.size():
		var upgrade: UpgradeData = upgrades[index]
		if upgrade == null:
			messages.append("machine '%s': upgrade %d is null" % [machine_label, index])
			continue
		if upgrade.id != &"":
			if seen_upgrades.has(upgrade.id):
				messages.append(
					"machine '%s': upgrade '%s' is duplicated"
					% [machine_label, String(upgrade.id)]
				)
			else:
				seen_upgrades[upgrade.id] = true
		if not supports_effect(upgrade.effect_stat):
			messages.append(
				"machine '%s': upgrade '%s': effect_stat %d is not supported by this machine"
				% [machine_label, String(upgrade.id), int(upgrade.effect_stat)]
			)
		for problem: String in upgrade.validate():
			messages.append("machine '%s': %s" % [machine_label, problem])

	return messages
