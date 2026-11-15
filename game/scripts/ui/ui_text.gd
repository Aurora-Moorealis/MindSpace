class_name UiText
extends RefCounted

## English player-facing strings shared by the machine panel, the HUD and the
## evaluation screen.
##
## Static only: the class is never instantiated. The project has no translation
## catalog yet, so this file is the single place to change when one arrives.
## Block-reason helpers return "" when the action is allowed; the caller decides
## whether to show anything.

const UNKNOWN_MACHINE: String = "Unknown machine"
const MISSING_MACHINE_DATA: String = "Machine data is unavailable."


## Visible name of a machine, humanized from its localization key
## ("water_recycler" -> "Water recycler"). The project has no translation
## catalog yet, so the key itself is the source of the text.
static func display_name(data: MachineData) -> String:
	if data == null or data.display_name_key == &"":
		return UNKNOWN_MACHINE
	var words: String = String(data.display_name_key).replace("_", " ")
	if words.is_empty():
		return UNKNOWN_MACHINE
	return words.substr(0, 1).to_upper() + words.substr(1)


## Label of an upgrade effect plus its signed delta, two decimals
## ("Power draw -3.00").
static func effect_label(stat: int, delta: float) -> String:
	var label: String = _effect_stat_label(stat)
	return "%s %+.2f" % [label, delta]


## Label of an event archetype; out-of-range values fall back to "Event".
static func archetype_label(archetype: int) -> String:
	match archetype:
		EventRow.Archetype.MACHINE_BREAKDOWN:
			return "Machine breakdown"
		EventRow.Archetype.PRODUCTION_DROP:
			return "Production drop"
		EventRow.Archetype.CONSUMPTION_SPIKE:
			return "Consumption spike"
		EventRow.Archetype.RADIATION_WINDOW:
			return "Radiation window"
		EventRow.Archetype.COMMS_BLACKOUT:
			return "Communications blackout"
	return "Event"


## Label of the cause that ended a run; unknown causes are reported as such.
static func end_cause_label(cause: StringName) -> String:
	match cause:
		&"radiation":
			return "Radiation exposure"
		&"hypoxia":
			return "Oxygen depleted"
		&"starvation":
			return "Starvation"
		&"dehydration":
			return "Dehydration"
		&"health":
			return "Injuries"
		&"debug":
			return "Mission ended from debug control"
	return "Unknown cause"


## Reason a repair cannot be started, or "" when it can. Checks run in the same
## order as GameSim.can_start_repair() so the panel explains the real blocker.
static func repair_block_reason(
	data: MachineData,
	machine: MachineState,
	energy: float,
	run_ended: bool
) -> String:
	if run_ended:
		return "The run has ended."
	if data == null or machine == null:
		return MISSING_MACHINE_DATA
	if machine.is_repairing():
		return "A repair is already in progress."
	if machine.health >= MachineState.MAX_HEALTH:
		return "The machine is at full health."
	if energy < maxf(0.0, data.repair_energy_cost):
		return "Not enough energy to repair."
	return ""


## Reason an upgrade cannot be applied, or "" when it can. Checks run in the
## same order as GameSim.can_apply_upgrade() so the panel explains the real
## blocker.
static func upgrade_block_reason(
	data: MachineData,
	machine: MachineState,
	upgrade: UpgradeData,
	energy: float,
	run_ended: bool
) -> String:
	if run_ended:
		return "The run has ended."
	if data == null or machine == null or upgrade == null:
		return MISSING_MACHINE_DATA
	if not data.supports_effect(upgrade.effect_stat):
		return "This machine cannot use that upgrade."
	if machine.is_broken():
		return "The machine is broken."
	if machine.applied_upgrades.has(upgrade.id):
		return "Upgrade already applied."
	if energy < maxf(0.0, upgrade.energy_cost):
		return "Not enough energy for this upgrade."
	return ""


## Label of one UpgradeData.EffectStat; out-of-range values fall back to
## "Effect".
static func _effect_stat_label(stat: int) -> String:
	match stat:
		UpgradeData.EffectStat.POWER_DRAW:
			return "Power draw"
		UpgradeData.EffectStat.SOLAR_OUTPUT:
			return "Solar output"
		UpgradeData.EffectStat.FOOD_OUTPUT:
			return "Food output"
		UpgradeData.EffectStat.OXYGEN_OUTPUT:
			return "Oxygen output"
		UpgradeData.EffectStat.WATER_OUTPUT:
			return "Water output"
		UpgradeData.EffectStat.DEGRADATION:
			return "Degradation"
		UpgradeData.EffectStat.REPAIR_SPEED:
			return "Repair speed"
		UpgradeData.EffectStat.MOVE_SPEED:
			return "Move speed"
		UpgradeData.EffectStat.HUNGER_MAX:
			return "Max hunger"
		UpgradeData.EffectStat.THIRST_MAX:
			return "Max thirst"
	return "Effect"
