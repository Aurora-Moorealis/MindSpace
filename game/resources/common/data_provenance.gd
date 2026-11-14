class_name DataProvenance
extends Resource

@export var source: String = ""
@export var source_url: String = ""
@export var date_archived: String = "" # ISO-8601; empty for placeholders
@export var archived: bool = false
@export var real_data: bool = false
