class_name Evaluation
extends Control

## End-of-run mission evaluation overlay.
##
## Reads the frozen run's aggregate from EventLog plus the final state of
## GameSim and shows it over the stopped game scene. It never changes scenes or
## mutates the simulation by itself: run_ui listens to restart_requested and
## menu_requested and decides what happens next.

signal restart_requested()
signal menu_requested()

## Shown when the recorded snapshot has no value for a resource.
const MISSING_RESOURCE: String = "--"

@onready var _reports_value: Label = %ReportsValue
@onready var _submissions_value: Label = %SubmissionsValue
@onready var _radiation_value: Label = %RadiationValue
@onready var _shelter_value: Label = %ShelterValue
@onready var _sols_value: Label = %SolsValue
@onready var _energy_value: Label = %EnergyValue
@onready var _oxygen_value: Label = %OxygenValue
@onready var _water_value: Label = %WaterValue
@onready var _food_value: Label = %FoodValue
@onready var _cause_value: Label = %CauseValue


## Fills every field with the current run summary and shows the overlay.
func present() -> void:
	AudioManager.play(AudioManager.Sfx.UI_OPEN)
	var summary: EvaluationSummary = EventLog.get_summary()
	_reports_value.text = str(summary.reports_sent)
	_submissions_value.text = str(summary.submissions_completed)
	_radiation_value.text = _format_amount(summary.peak_radiation)
	_shelter_value.text = str(summary.shelter_uses)
	_sols_value.text = str(summary.sols_elapsed)
	_energy_value.text = _format_amount(GameSim.state.get_energy_total())
	_oxygen_value.text = _resource_text(SimState.OXYGEN)
	_water_value.text = _resource_text(SimState.WATER)
	_food_value.text = _resource_text(SimState.FOOD)
	_cause_value.text = UiText.end_cause_label(GameSim.state.death_cause)
	visible = true


## Hides the overlay without touching the stored summary.
func hide_summary() -> void:
	visible = false


## One-decimal amount, or MISSING_RESOURCE when the snapshot lacks the key.
func _resource_text(resource: StringName) -> String:
	if not GameSim.state.resources.has(resource):
		return MISSING_RESOURCE
	var amount: float = GameSim.state.resources[resource]
	return _format_amount(amount)


func _format_amount(amount: float) -> String:
	return "%.1f" % amount


func _on_play_again_pressed() -> void:
	restart_requested.emit()


func _on_menu_pressed() -> void:
	menu_requested.emit()
