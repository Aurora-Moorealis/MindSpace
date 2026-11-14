class_name EconomyRow
extends Resource

@export var id: StringName = &""
@export_range(0.0, 1000000.0, 0.001) var value: float = 0.0
@export_range(0.0, 1000000.0, 0.001) var min_value: float = 0.0
@export_range(0.0, 1000000.0, 0.001) var max_value: float = 0.0
@export var unit: String = ""
@export var provenance: DataProvenance
